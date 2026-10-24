"""HTTP server: OpenAI, Anthropic (Claude Code), Codex, and Google Gemini API endpoints."""
import json
import time
import uuid
import re
from http.server import HTTPServer, BaseHTTPRequestHandler
from socketserver import ThreadingMixIn

from .config import CONFIG
from .models import MODELS, resolve_model
from .gemini import generate, generate_stream, log
from .tools import (
    messages_to_prompt,
    parse_tool_calls,
    google_contents_to_prompt,
    parse_google_function_calls,
    anthropic_to_prompt,
)
from .multimodal import detect_image_mime, fetch_image_bytes, upload_image
from . import __version__


def _usage(prompt: str, text: str) -> dict:
    p = len(prompt) // 4
    c = len(text or "") // 4
    return {"prompt_tokens": p, "completion_tokens": c, "total_tokens": p + c}


def _upload_images(images: list) -> list:
    """Upload images and return list of file references. Returns None if no images."""
    if not images:
        return None
    file_refs = []
    for item in images:
        if not (isinstance(item, tuple) and len(item) == 2):
            continue
        data, mime = item
        if isinstance(data, str):
            data = fetch_image_bytes(data)
            mime = mime or "image/png"
        if not data:
            raise RuntimeError("image fetch failed")
        mime = detect_image_mime(data, mime or "image/png")
        try:
            ref = upload_image(data, "image.png", mime or "image/png")
            file_refs.append(ref)
        except Exception as e:
            raise RuntimeError(f"image upload failed: {e}") from e
    return file_refs if file_refs else None


class GeminiHandler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        client_ip = self.client_address[0] if self.client_address else "-"
        log(f"{client_ip} {fmt % args}")

    def send_json(self, data, status=200):
        body = json.dumps(data, ensure_ascii=False).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)
        self.wfile.flush()

    def _start_sse(self, extra_headers=None):
        self.send_response(200)
        self.send_header("Content-Type", "text/event-stream")
        self.send_header("Cache-Control", "no-cache")
        self.send_header("Access-Control-Allow-Origin", "*")
        if extra_headers:
            for k, v in extra_headers.items():
                self.send_header(k, v)
        self.end_headers()
        self.wfile.flush()

    def _parse_body(self, body: bytes) -> dict:
        try:
            return json.loads(body)
        except (json.JSONDecodeError, ValueError):
            return None

    def _read_request_body(self) -> bytes:
        transfer_encoding = self.headers.get("Transfer-Encoding", "")
        if "chunked" in transfer_encoding.lower():
            chunks = []
            while True:
                size_line = self.rfile.readline()
                if not size_line:
                    break
                size_text = size_line.split(b";", 1)[0].strip()
                try:
                    size = int(size_text, 16)
                except ValueError:
                    raise ValueError("invalid chunked request body")
                if size == 0:
                    while True:
                        trailer = self.rfile.readline()
                        if trailer in (b"\r\n", b"\n", b""):
                            break
                    break
                chunks.append(self.rfile.read(size))
                self.rfile.read(2)
            return b"".join(chunks)

        length = int(self.headers.get("Content-Length", 0))
        return self.rfile.read(length) if length else b""

    def _authorized(self):
        keys = CONFIG.get("api_keys") or []
        if not keys:
            return True
        # Authorization: Bearer <key>
        auth = self.headers.get("Authorization", "")
        if auth.startswith("Bearer ") and auth[7:] in keys:
            return True
        # header keys (OpenAI x-api-key / Google x-goog-api-key)
        for h in ("x-api-key", "x-goog-api-key"):
            if self.headers.get(h, "") in keys:
                return True
        # query param ?key= (Gemini CLI native style)
        if "?" in self.path:
            for pair in self.path.split("?", 1)[1].split("&"):
                if pair.startswith("key=") and pair[4:] in keys:
                    return True
        return False

    def do_OPTIONS(self):
        self.send_response(204)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS, HEAD")
        self.send_header("Access-Control-Allow-Headers", "*")
        self.end_headers()
        self.wfile.flush()

    def do_HEAD(self):
        self.send_response(200)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS, HEAD")
        self.send_header("Access-Control-Allow-Headers", "*")
        self.end_headers()
        self.wfile.flush()

    def do_GET(self):
        try:
            path = self.path.split("?")[0].rstrip("/")
            if (path.startswith("/v1") or path.startswith("/models") or path.startswith("/messages")) and not self._authorized():
                self.send_json({"error": {"message": "invalid api key"}}, 401)
                return
            if path in ("/v1/models", "/models", "/v1/v1/models"):
                self.send_json({"object": "list", "data": [
                    {"id": n, "object": "model", "created": 1700000000,
                     "owned_by": "google", "description": c["desc"]}
                    for n, c in MODELS.items()
                ]})
            elif path.startswith("/v1beta/models"):
                models = [
                    {"name": f"models/{n}", "displayName": n, "description": c["desc"],
                     "supportedGenerationMethods": ["generateContent", "streamGenerateContent"]}
                    for n, c in MODELS.items()
                ]
                self.send_json({"models": models})
            elif path in ("", "/", "/api/hello", "/health"):
                self.send_json({"status": "ok", "version": __version__, "models": list(MODELS.keys())})
            else:
                self.send_json({"error": "not found"}, 404)
        except (BrokenPipeError, ConnectionResetError):
            pass
        except Exception as e:
            log(f"GET error: {e}")

    def do_POST(self):
        try:
            path = self.path.split("?")[0].rstrip("/")
            if (path.startswith("/v1") or path.startswith("/messages") or path.startswith("/chat") or path.startswith("/responses")) and not self._authorized():
                self.send_json({"error": {"message": "invalid api key"}}, 401)
                return
            body = self._read_request_body()
            if path in ("/v1/chat/completions", "/chat/completions", "/v1/v1/chat/completions") or path.endswith("/chat/completions"):
                self._handle_chat(body)
            elif path in ("/v1/responses", "/responses", "/v1/v1/responses") or path.endswith("/responses"):
                self._handle_responses(body)
            elif path in ("/v1/messages/count_tokens", "/messages/count_tokens", "/v1/v1/messages/count_tokens") or path.endswith("/messages/count_tokens"):
                self._handle_count_tokens(body)
            elif path in ("/v1/messages", "/messages", "/v1/v1/messages") or (path.endswith("/messages") and not path.endswith("/count_tokens")):
                self._handle_messages(body)
            elif ":streamGenerateContent" in path:
                self._handle_google_generate(body, stream=True)
            elif ":generateContent" in path:
                self._handle_google_generate(body, stream=False)
            else:
                self.send_json({"error": "not found"}, 404)
        except (BrokenPipeError, ConnectionResetError):
            pass
        except Exception as e:
            log(f"POST error: {e}")
            try:
                self.send_json({"error": {"message": str(e)}}, 500)
            except Exception:
                pass

    # ─── /v1/chat/completions ─────────────────────────────────────────────────

    def _handle_chat(self, body: bytes):
        req = self._parse_body(body)
        if req is None:
            self.send_json({"error": {"message": "invalid JSON"}}, 400)
            return
        model_name, model_id, think_mode, err, extra_fields = resolve_model(
            req.get("model", CONFIG["default_model"]))
        if err:
            self.send_json({"error": {"message": err}}, 400)
            return

        tools = req.get("tools")
        tool_choice = req.get("tool_choice", "auto")
        prompt, images = messages_to_prompt(req.get("messages", []), tools, tool_choice)
        if not prompt.strip():
            self.send_json({"error": {"message": "empty prompt"}}, 400)
            return

        stream = req.get("stream", False)
        cid = f"chatcmpl-{uuid.uuid4().hex[:12]}"
        try:
            file_refs = _upload_images(images)
        except RuntimeError as e:
            self.send_json({"error": {"message": f"upstream error: {e}"}}, 502)
            return

        if stream and (not tools or tool_choice == "none"):
            try:
                self._start_sse()
                first_chunk = {
                    "id": cid,
                    "object": "chat.completion.chunk",
                    "created": int(time.time()),
                    "model": model_name,
                    "choices": [{
                        "index": 0,
                        "delta": {"role": "assistant"},
                        "finish_reason": None,
                    }],
                }
                self.wfile.write(f"data: {json.dumps(first_chunk)}\n\n".encode())
                self.wfile.flush()
                for delta in generate_stream(prompt, model_id, think_mode, file_refs, extra_fields):
                    chunk = {"id": cid, "object": "chat.completion.chunk", "created": int(time.time()),
                             "model": model_name, "choices": [{"index": 0, "delta": {"content": delta}, "finish_reason": None}]}
                    self.wfile.write(f"data: {json.dumps(chunk, ensure_ascii=False)}\n\n".encode())
                    self.wfile.flush()
                end = {"id": cid, "object": "chat.completion.chunk", "created": int(time.time()),
                       "model": model_name, "choices": [{"index": 0, "delta": {}, "finish_reason": "stop"}]}
                self.wfile.write(f"data: {json.dumps(end)}\n\n".encode())
                self.wfile.write(b"data: [DONE]\n\n")
                self.wfile.flush()
            except (BrokenPipeError, ConnectionResetError):
                pass
            except Exception as e:
                log(f"Stream error: {e}")
            return

        try:
            text = generate(prompt, model_id, think_mode, file_refs, extra_fields)
        except Exception as e:
            self.send_json({"error": {"message": f"upstream error: {e}"}}, 502)
            return

        tool_calls = None
        if tools and text and tool_choice != "none":
            text, tool_calls = parse_tool_calls(text)
        msg = {"role": "assistant", "content": text or None}
        if tool_calls:
            msg["tool_calls"] = tool_calls
        finish = "tool_calls" if tool_calls else "stop"

        if stream:
            self._start_sse()
            chunk = {"id": cid, "object": "chat.completion.chunk", "created": int(time.time()),
                     "model": model_name, "choices": [{"index": 0, "delta": msg, "finish_reason": finish}]}
            self.wfile.write(f"data: {json.dumps(chunk, ensure_ascii=False)}\n\n".encode())
            self.wfile.write(b"data: [DONE]\n\n")
            self.wfile.flush()
        else:
            self.send_json({
                "id": cid, "object": "chat.completion", "created": int(time.time()),
                "model": model_name,
                "choices": [{"index": 0, "message": msg, "finish_reason": finish}],
                "usage": {"prompt_tokens": len(prompt)//4, "completion_tokens": len(text or "")//4,
                          "total_tokens": (len(prompt)+len(text or ""))//4},
            })

    # ─── /v1/responses (Codex CLI) ───────────────────────────────────────────

    def _handle_responses(self, body: bytes):
        req = self._parse_body(body)
        if req is None:
            self.send_json({"error": {"message": "invalid JSON"}}, 400)
            return
        model_name, model_id, think_mode, err, extra_fields = resolve_model(
            req.get("model", CONFIG["default_model"]))
        if err:
            self.send_json({"error": {"message": err}}, 400)
            return

        input_items = req.get("input", [])
        tools = req.get("tools")
        messages = []
        if req.get("instructions"):
            messages.append({"role": "system", "content": req["instructions"]})
        if isinstance(input_items, str):
            messages.append({"role": "user", "content": input_items})
        elif isinstance(input_items, list):
            for item in input_items:
                if isinstance(item, str):
                    messages.append({"role": "user", "content": item})
                elif isinstance(item, dict):
                    if item.get("type") == "function_call":
                        messages.append({
                            "role": "assistant",
                            "content": None,
                            "tool_calls": [{
                                "id": item.get("call_id", item.get("id", "call_0")),
                                "type": "function",
                                "function": {
                                    "name": item.get("name", ""),
                                    "arguments": item.get("arguments", "{}"),
                                },
                            }],
                        })
                    elif item.get("type") == "function_call_output":
                        messages.append({"role": "tool", "tool_call_id": item.get("call_id", ""),
                                         "name": item.get("name", ""), "content": item.get("output", "")})
                    elif item.get("type") in ("input_text", "input_image", "image"):
                        messages.append({"role": "user", "content": [item]})
                    elif item.get("role") == "assistant" or (item.get("type") == "message" and item.get("role") == "assistant"):
                        cp = item.get("content", [])
                        text_acc, tc_list = "", []
                        if isinstance(cp, list):
                            for c in cp:
                                if isinstance(c, dict):
                                    if c.get("type") == "output_text":
                                        text_acc += c.get("text", "")
                                    elif c.get("type") == "function_call":
                                        tc_list.append(c)
                        elif isinstance(cp, str):
                            text_acc = cp
                        m = {"role": "assistant", "content": text_acc or None}
                        if tc_list:
                            m["tool_calls"] = [{"id": tc.get("call_id", f"call_{i}"), "type": "function",
                                                "function": {"name": tc.get("name", ""), "arguments": tc.get("arguments", "{}")}}
                                               for i, tc in enumerate(tc_list)]
                        messages.append(m)
                    else:
                        role = item.get("role", "user")
                        messages.append({"role": role, "content": item.get("content", "")})

        if tools:
            tools = [{"type": "function", "function": {"name": t["name"], "description": t.get("description", ""), "parameters": t.get("parameters", {})}}
                     if t.get("type") == "function" and "function" not in t else t for t in tools]

        tool_choice = req.get("tool_choice", "auto")
        prompt, images = messages_to_prompt(messages, tools, tool_choice)
        if not prompt.strip():
            self.send_json({"error": {"message": "empty input"}}, 400)
            return

        try:
            file_refs = _upload_images(images)
            text = generate(prompt, model_id, think_mode, file_refs, extra_fields)
        except Exception as e:
            self.send_json({"error": {"message": f"upstream error: {e}"}}, 502)
            return

        tool_calls = None
        if tools and text and tool_choice != "none":
            text, tool_calls = parse_tool_calls(text)

        rid = f"resp_{uuid.uuid4().hex[:16]}"
        mid = f"msg_{uuid.uuid4().hex[:12]}"
        output = []
        if tool_calls:
            for tc in tool_calls:
                output.append({"type": "function_call", "id": tc["id"], "call_id": tc["id"],
                               "name": tc["function"]["name"], "arguments": tc["function"]["arguments"], "status": "completed"})
        if text or not tool_calls:
            output.append({"type": "message", "id": mid, "role": "assistant", "status": "completed",
                           "content": [{"type": "output_text", "text": text or "", "annotations": []}]})

        if req.get("stream"):
            self._start_sse()
            sequence_number = 0

            def emit(event_type, **fields):
                nonlocal sequence_number
                sequence_number += 1
                event = {
                    "type": event_type,
                    "sequence_number": sequence_number,
                    **fields,
                }
                self.wfile.write(
                    f"event: {event_type}\ndata: {json.dumps(event)}\n\n".encode()
                )

            usage = {
                "input_tokens": len(prompt) // 4,
                "output_tokens": len(text or "") // 4,
                "total_tokens": (len(prompt) + len(text or "")) // 4,
            }
            base_response = {
                "id": rid,
                "object": "response",
                "created_at": int(time.time()),
                "model": model_name,
            }
            emit(
                "response.created",
                response={
                    **base_response,
                    "status": "in_progress",
                    "output": [],
                    "usage": None,
                },
            )
            emit(
                "response.in_progress",
                response={
                    **base_response,
                    "status": "in_progress",
                    "output": [],
                    "usage": None,
                },
            )
            for output_index, item in enumerate(output):
                if item["type"] == "function_call":
                    pending_item = {
                        "type": "function_call",
                        "id": item["id"],
                        "call_id": item["call_id"],
                        "name": item["name"],
                        "arguments": "",
                        "status": "in_progress",
                    }
                    emit(
                        "response.output_item.added",
                        output_index=output_index,
                        item=pending_item,
                    )
                    emit(
                        "response.function_call_arguments.delta",
                        item_id=item["id"],
                        output_index=output_index,
                        delta=item["arguments"],
                    )
                    emit(
                        "response.function_call_arguments.done",
                        item_id=item["id"],
                        output_index=output_index,
                        arguments=item["arguments"],
                    )
                    emit(
                        "response.output_item.done",
                        output_index=output_index,
                        item=item,
                    )
                elif item["type"] == "message":
                    pending_item = {
                        "type": "message",
                        "id": item["id"],
                        "role": "assistant",
                        "status": "in_progress",
                        "content": [],
                    }
                    emit(
                        "response.output_item.added",
                        output_index=output_index,
                        item=pending_item,
                    )
                    for content_index, content_part in enumerate(item["content"]):
                        event_fields = {
                            "item_id": item["id"],
                            "output_index": output_index,
                            "content_index": content_index,
                        }
                        emit(
                            "response.content_part.added",
                            **event_fields,
                            part={
                                "type": "output_text",
                                "text": "",
                                "annotations": [],
                            },
                        )
                        emit(
                            "response.output_text.delta",
                            **event_fields,
                            delta=content_part["text"],
                        )
                        emit(
                            "response.output_text.done",
                            **event_fields,
                            text=content_part["text"],
                        )
                        emit(
                            "response.content_part.done",
                            **event_fields,
                            part=content_part,
                        )
                    emit(
                        "response.output_item.done",
                        output_index=output_index,
                        item=item,
                    )
            emit(
                "response.completed",
                response={
                    **base_response,
                    "status": "completed",
                    "output": output,
                    "usage": usage,
                },
            )
            self.wfile.flush()
        else:
            self.send_json({"id": rid, "object": "response", "created_at": int(time.time()), "status": "completed",
                            "model": model_name, "output": output,
                            "usage": {"input_tokens": len(prompt)//4, "output_tokens": len(text or "")//4, "total_tokens": (len(prompt)+len(text or ""))//4}})

    # ─── Anthropic Messages API (Claude Code compatible) ─────────────────────

    def _handle_count_tokens(self, body: bytes):
        try:
            req = json.loads(body)
            prompt, _ = anthropic_to_prompt(req)
            tokens = max(1, len(prompt) // 4)
            self.send_json({"input_tokens": tokens})
        except Exception:
            self.send_json({"input_tokens": 100})

    def _handle_messages(self, body: bytes):
        req = self._parse_body(body)
        if req is None:
            self.send_json({"type": "error", "error": {"type": "invalid_request_error", "message": "invalid JSON"}}, 400)
            return

        raw_model = req.get("model", CONFIG.get("default_model", "gemini-3.6-flash"))
        model_name, model_id, think_mode, err, extra_fields = resolve_model(raw_model)
        if err:
            model_name, model_id, think_mode, _, extra_fields = resolve_model(CONFIG.get("default_model", "gemini-3.6-flash"))

        tools = req.get("tools")
        prompt, images = anthropic_to_prompt(req)
        if not prompt.strip():
            self.send_json({"type": "error", "error": {"type": "invalid_request_error", "message": "empty prompt"}}, 400)
            return

        stream = req.get("stream", False)
        msg_id = f"msg_{uuid.uuid4().hex[:24]}"
        try:
            file_refs = _upload_images(images)
        except RuntimeError as e:
            self.send_json({"type": "error", "error": {"type": "api_error", "message": f"upstream error: {e}"}}, 502)
            return

        input_tokens = max(1, len(prompt) // 4)

        if stream and not tools:
            try:
                self._start_sse(extra_headers={"anthropic-version": "2023-06-01"})
                start_evt = {
                    "type": "message_start",
                    "message": {
                        "id": msg_id,
                        "type": "message",
                        "role": "assistant",
                        "model": raw_model,
                        "content": [],
                        "stop_reason": None,
                        "stop_sequence": None,
                        "usage": {"input_tokens": input_tokens, "output_tokens": 1},
                    },
                }
                self.wfile.write(f"event: message_start\ndata: {json.dumps(start_evt)}\n\n".encode())

                block_start = {
                    "type": "content_block_start",
                    "index": 0,
                    "content_block": {"type": "text", "text": ""},
                }
                self.wfile.write(f"event: content_block_start\ndata: {json.dumps(block_start)}\n\n".encode())
                self.wfile.flush()

                output_tokens = 0
                for delta_text in generate_stream(prompt, model_id, think_mode, file_refs, extra_fields):
                    output_tokens += max(1, len(delta_text) // 4)
                    chunk = {
                        "type": "content_block_delta",
                        "index": 0,
                        "delta": {"type": "text_delta", "text": delta_text},
                    }
                    self.wfile.write(f"event: content_block_delta\ndata: {json.dumps(chunk, ensure_ascii=False)}\n\n".encode())
                    self.wfile.flush()

                block_stop = {"type": "content_block_stop", "index": 0}
                self.wfile.write(f"event: content_block_stop\ndata: {json.dumps(block_stop)}\n\n".encode())

                msg_delta = {
                    "type": "message_delta",
                    "delta": {"stop_reason": "end_turn", "stop_sequence": None},
                    "usage": {"output_tokens": max(1, output_tokens)},
                }
                self.wfile.write(f"event: message_delta\ndata: {json.dumps(msg_delta)}\n\n".encode())
                self.wfile.write(b"event: message_stop\ndata: {\"type\":\"message_stop\"}\n\n")
                self.wfile.flush()
            except (BrokenPipeError, ConnectionResetError):
                pass
            except Exception as e:
                log(f"Anthropic stream error: {e}")
            return

        try:
            text = generate(prompt, model_id, think_mode, file_refs, extra_fields)
        except Exception as e:
            self.send_json({"type": "error", "error": {"type": "api_error", "message": f"upstream error: {e}"}}, 502)
            return

        tool_calls = None
        if tools and text:
            text, tool_calls = parse_tool_calls(text)

        content_blocks = []
        if text:
            content_blocks.append({"type": "text", "text": text})

        if tool_calls:
            for tc in tool_calls:
                fn = tc.get("function", {})
                tool_name = fn.get("name", "")
                try:
                    tool_args = json.loads(fn.get("arguments", "{}"))
                except Exception:
                    tool_args = {}
                call_id = tc.get("id", f"toolu_{uuid.uuid4().hex[:16]}")
                if not call_id.startswith("toolu_"):
                    call_id = f"toolu_{call_id.replace('call_', '')}"
                content_blocks.append({
                    "type": "tool_use",
                    "id": call_id,
                    "name": tool_name,
                    "input": tool_args,
                })

        stop_reason = "tool_use" if tool_calls else "end_turn"
        output_tokens = max(1, len(text or "") // 4 + len(tool_calls or []) * 20)

        if stream:
            try:
                self._start_sse(extra_headers={"anthropic-version": "2023-06-01"})
                start_evt = {
                    "type": "message_start",
                    "message": {
                        "id": msg_id,
                        "type": "message",
                        "role": "assistant",
                        "model": raw_model,
                        "content": [],
                        "stop_reason": None,
                        "stop_sequence": None,
                        "usage": {"input_tokens": input_tokens, "output_tokens": 1},
                    },
                }
                self.wfile.write(f"event: message_start\ndata: {json.dumps(start_evt)}\n\n".encode())

                for idx, blk in enumerate(content_blocks):
                    if blk["type"] == "text":
                        self.wfile.write(f"event: content_block_start\ndata: {json.dumps({'type': 'content_block_start', 'index': idx, 'content_block': {'type': 'text', 'text': ''}})}\n\n".encode())
                        self.wfile.write(f"event: content_block_delta\ndata: {json.dumps({'type': 'content_block_delta', 'index': idx, 'delta': {'type': 'text_delta', 'text': blk['text']}}, ensure_ascii=False)}\n\n".encode())
                        self.wfile.write(f"event: content_block_stop\ndata: {json.dumps({'type': 'content_block_stop', 'index': idx})}\n\n".encode())
                    elif blk["type"] == "tool_use":
                        self.wfile.write(f"event: content_block_start\ndata: {json.dumps({'type': 'content_block_start', 'index': idx, 'content_block': {'type': 'tool_use', 'id': blk['id'], 'name': blk['name'], 'input': {}}})}\n\n".encode())
                        self.wfile.write(f"event: content_block_delta\ndata: {json.dumps({'type': 'content_block_delta', 'index': idx, 'delta': {'type': 'input_json_delta', 'partial_json': json.dumps(blk['input'], ensure_ascii=False)}}, ensure_ascii=False)}\n\n".encode())
                        self.wfile.write(f"event: content_block_stop\ndata: {json.dumps({'type': 'content_block_stop', 'index': idx})}\n\n".encode())

                msg_delta = {
                    "type": "message_delta",
                    "delta": {"stop_reason": stop_reason, "stop_sequence": None},
                    "usage": {"output_tokens": output_tokens},
                }
                self.wfile.write(f"event: message_delta\ndata: {json.dumps(msg_delta)}\n\n".encode())
                self.wfile.write(b"event: message_stop\ndata: {\"type\":\"message_stop\"}\n\n")
                self.wfile.flush()
            except (BrokenPipeError, ConnectionResetError):
                pass
            except Exception as e:
                log(f"Anthropic stream error: {e}")
        else:
            self.send_json({
                "id": msg_id,
                "type": "message",
                "role": "assistant",
                "model": raw_model,
                "content": content_blocks,
                "stop_reason": stop_reason,
                "stop_sequence": None,
                "usage": {
                    "input_tokens": input_tokens,
                    "output_tokens": output_tokens,
                },
            })

    # ─── /v1beta/models (Google Gemini CLI) ──────────────────────────────────

    def _handle_google_generate(self, body: bytes, stream: bool):
        req = self._parse_body(body)
        if req is None:
            self.send_json({"error": {"message": "invalid JSON"}}, 400)
            return
        m = re.match(r'/v1beta/models/([^:?]+)', self.path)
        model_name = m.group(1) if m else CONFIG["default_model"]
        model_name, model_id, think_mode, err, extra_fields = resolve_model(model_name)
        if err:
            self.send_json({"error": {"message": err}}, 400)
            return

        tool_config = req.get("toolConfig", {})
        fc_mode = tool_config.get("functionCallingConfig", {}).get("mode", "AUTO")
        has_tools = bool(req.get("tools")) and fc_mode != "NONE"
        prompt, images = google_contents_to_prompt(req)
        if not prompt.strip():
            self.send_json({"error": {"message": "empty content"}}, 400)
            return

        try:
            file_refs = _upload_images(images)
        except RuntimeError as e:
            self.send_json({"error": {"message": f"upstream error: {e}"}}, 502)
            return
        log(f"Google API: model={model_name} stream={stream} tools={has_tools} prompt_len={len(prompt)}")

        if stream and not has_tools:
            try:
                self._start_sse()
                full_text = ""
                for delta in generate_stream(prompt, model_id, think_mode, file_refs, extra_fields):
                    if not delta:
                        continue
                    full_text += delta
                    chunk_obj = {
                        "candidates": [{"content": {"parts": [{"text": delta}], "role": "model"}, "index": 0}],
                        "modelVersion": model_name,
                    }
                    self.wfile.write(f"data: {json.dumps(chunk_obj, ensure_ascii=False)}\n\n".encode())
                    self.wfile.flush()
                final_chunk = {
                    "candidates": [{"finishReason": "STOP", "index": 0}],
                    "usageMetadata": {
                        "promptTokenCount": len(prompt) // 4,
                        "candidatesTokenCount": len(full_text) // 4,
                        "totalTokenCount": (len(prompt) + len(full_text)) // 4,
                    },
                    "modelVersion": model_name,
                }
                self.wfile.write(f"data: {json.dumps(final_chunk, ensure_ascii=False)}\n\n".encode())
                self.wfile.flush()
            except (BrokenPipeError, ConnectionResetError):
                pass
            except Exception as e:
                log(f"Google stream error: {e}")
            return

        try:
            text = generate(prompt, model_id, think_mode, file_refs, extra_fields)
        except Exception as e:
            self.send_json({"error": {"message": f"upstream error: {e}"}}, 502)
            return

        if not text:
            log("Warning: empty response from Gemini")

        response_parts = []
        if has_tools and text:
            clean_text, function_calls = parse_google_function_calls(text)
            if function_calls:
                if clean_text:
                    response_parts.append({"text": clean_text})
                for fc in function_calls:
                    response_parts.append({"functionCall": {"name": fc["name"], "args": fc["args"]}})
            else:
                response_parts.append({"text": text})
        else:
            response_parts.append({"text": text or "I apologize, but I was unable to generate a response. Please try again."})

        candidate = {
            "content": {"parts": response_parts, "role": "model"},
            "finishReason": "STOP",
            "index": 0,
        }
        usage = {
            "promptTokenCount": len(prompt) // 4,
            "candidatesTokenCount": len(text or "") // 4,
            "totalTokenCount": (len(prompt) + len(text or "")) // 4,
        }
        response_obj = {
            "candidates": [candidate],
            "usageMetadata": usage,
            "modelVersion": model_name,
        }

        if stream:
            self._start_sse()
            self.wfile.write(f"data: {json.dumps(response_obj, ensure_ascii=False)}\n\n".encode())
            self.wfile.flush()
        else:
            self.send_json(response_obj)


class ThreadedServer(ThreadingMixIn, HTTPServer):
    daemon_threads = True
    allow_reuse_address = True
