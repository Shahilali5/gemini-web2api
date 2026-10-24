# gemini-web2api Complete API Reference Documentation

`gemini-web2api` is a zero-cost, cross-platform reverse proxy that transforms Google Gemini's web StreamGenerate interface into standard, production-ready APIs compatible with:
- **Anthropic Messages API** (optimized for **Claude Code**, **Claude Desktop App**, and Anthropic SDKs)
- **OpenAI Responses API** (optimized for **OpenAI Codex CLI** and agents)
- **OpenAI Chat Completions API** (compatible with **Cursor**, **Aider**, **Cherry Studio**, **ChatBox**, **OpenAI Python SDK**, etc.)
- **Google AI Gemini Native API** (compatible with **Gemini CLI** and Google GenAI SDKs)

---

## Table of Contents

1. [Server Information & Base URLs](#1-server-information--base-urls)
2. [Authentication](#2-authentication)
3. [Models & Alias Routing](#3-models--alias-routing)
   - [Thinking Depth Modifier (`@think=N`)](#thinking-depth-modifier-thinkn)
   - [Full Models & Compatibility Table](#full-models--compatibility-table)
4. [Endpoint Reference](#4-endpoint-reference)
   - [Health Check & Server Status](#health-check--server-status)
   - [OpenAI Chat Completions API (`/v1/chat/completions`)](#openai-chat-completions-api-v1chatcompletions)
   - [OpenAI Responses API (`/v1/responses` - Codex CLI)](#openai-responses-api-v1responses---codex-cli)
   - [Anthropic Messages API (`/v1/messages` - Claude Code)](#anthropic-messages-api-v1messages---claude-code)
   - [Anthropic Token Count API (`/v1/messages/count_tokens`)](#anthropic-token-count-api-v1messagescount_tokens)
   - [OpenAI Models API (`/v1/models`)](#openai-models-api-v1models)
   - [Google Native Models API (`/v1beta/models`)](#google-native-models-api-v1betamodels)
   - [Google Native Content Generation (`/v1beta/models/{model}:generateContent`)](#google-native-content-generation-v1betamodelsmodelgeneratecontent)
5. [Client Connection Quickstart](#5-client-connection-quickstart)
   - [Claude Code Setup & Commands](#claude-code-setup--commands)
   - [OpenAI Codex Setup & Commands](#openai-codex-setup--commands)
   - [curl Examples (Bash & PowerShell)](#curl-examples-bash--powershell)
   - [OpenAI Python SDK](#openai-python-sdk)
6. [Advanced Server Configuration](#6-advanced-server-configuration)
   - [Configuration File (`config.json`)](#configuration-file-configjson)
   - [Pro Model & Cookies Setup](#pro-model--cookies-setup)
   - [Proxy Settings](#proxy-settings)
7. [Error Handling & Status Codes](#7-error-handling--status-codes)

---

## 1. Server Information & Base URLs

- **Default Port**: `8081` (configurable via `--port` or in `config.json`)
- **Default Host**: `0.0.0.0` (accessible locally at `http://127.0.0.1:8081` or `http://localhost:8081`)

| Client Protocol | Base URL Format |
| :--- | :--- |
| **OpenAI Clients / Codex CLI** | `http://localhost:8081/v1` |
| **Anthropic Clients / Claude Code** | `http://localhost:8081` or `http://localhost:8081/v1` |
| **Google Gemini CLI** | `http://localhost:8081` |

> [!TIP]
> The server automatically normalizes request paths. Both `/v1/chat/completions` and `/chat/completions`, as well as `/v1/messages` and `/messages`, are handled interchangeably without 404 errors.

---

## 2. Authentication

Authentication is controlled by the `"api_keys"` array in `config.json`.

```json
{
  "api_keys": ["sk-gemini", "my-custom-key"]
}
```

- **Authentication Disabled**: When `"api_keys": []` (empty array), all requests are allowed without an API key.
- **Authentication Enabled**: When one or more keys are configured, clients must provide a valid key via any of the following standard headers:
  1. `Authorization: Bearer <key>` (Standard OpenAI & Anthropic bearer format)
  2. `x-api-key: <key>` (Anthropic & OpenAI header format)
  3. `x-goog-api-key: <key>` (Google GenAI header format)
  4. Query parameter `?key=<key>` (Google Gemini CLI URL format)

---

## 3. Models & Alias Routing

Gemini Web exposes multiple generation modes via the internal `MODE_CATEGORY` parameter:
- `1` = FAST (Gemini Flash)
- `2` = THINKING (Gemini Flash Extended Thinking)
- `3` = PRO (Gemini Pro, requires cookie)
- `4` = AUTO (Automatic backend routing)
- `5` = FAST_DYNAMIC_THINKING (Adaptive thinking depth)
- `6` = FLASH_LITE (Ultra-fast response)

### Thinking Depth Modifier (`@think=N`)

You can control how deeply the model thinks before answering by appending `@think=N` to **any** model name:

| Suffix | Depth | Typical Output Length | Best Used For |
| :--- | :--- | :--- | :--- |
| `@think=0` | **Deepest** | ~20,000+ characters | Complex software architectures, difficult bugs, mathematics |
| `@think=2` | **Medium** | ~15,000 characters | General coding, refactoring, code review |
| `@think=4` | **Shallowest** | ~10,000 characters | Fast chat, command lookups, explanations |

*Example*: `gemini-3.5-flash-thinking@think=0` or `claude-3-7-sonnet-20250219@think=2`.

### Full Models & Compatibility Table

| Model Identifier | Mode | Think Default | Target Gemini Model | Typical Output | Notes |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`gemini-3.7-flash`** | 1 | 4 | Gemini 3.7 Flash | ~12k chars | Latest all-around model |
| **`gemini-3.6-flash`** | 1 | 4 | Gemini 3.6 Flash | ~12k chars | Fast, versatile |
| **`gemini-3.5-flash`** | 1 | 4 | Gemini 3.6 Flash | ~12k chars | Alias for backward compatibility |
| **`gemini-3.5-flash-thinking`** | 2 | 0 | Gemini 3.5 Flash Thinking | **~20k chars** | Deep reasoning & planning |
| **`gemini-3.5-flash-thinking-lite`**| 5 | 0 | Gemini 3.5 Dynamic Think | ~15k chars | Dynamic adaptive thinking |
| **`gemini-3.1-pro`** | 3 | 4 | Gemini 3.1 Pro | ~12k chars | Requires Advanced subscription cookie |
| **`gemini-auto`** | 4 | 4 | Gemini Auto | Varies | Auto model selection |
| **`gemini-flash-lite`** | 6 | 4 | Gemini Flash Lite | ~10k chars | Lowest latency |
| **`claude-3-7-sonnet-20250219`** | 1 | 4 | Gemini 3.7 Flash | ~12k chars | Claude Code default |
| **`claude-3-7-sonnet-latest`** | 1 | 4 | Gemini 3.7 Flash | ~12k chars | Claude Code alias |
| **`claude-3-5-sonnet-20241022`** | 1 | 4 | Gemini 3.7 Flash | ~12k chars | Claude Code alias |
| **`claude-3-5-sonnet-latest`** | 1 | 4 | Gemini 3.7 Flash | ~12k chars | Claude Code alias |
| **`claude-3-5-haiku-20241022`** | 1 | 4 | Gemini 3.6 Flash | ~12k chars | Fast lightweight Claude |
| **`claude-3-opus-20240229`** | 2 | 0 | Gemini 3.5 Flash Thinking | ~20k chars | Claude Opus thinking alias |
| **`claude-opus-4-6`** | 2 | 0 | Gemini 3.5 Flash Thinking | ~20k chars | Extended thinking alias |
| **`claude-sonnet-4-6`** | 1 | 4 | Gemini 3.7 Flash | ~12k chars | Sonnet alias |
| **`gpt-4o`** | 1 | 4 | Gemini 3.7 Flash | ~12k chars | OpenAI / Codex alias |
| **`gpt-4o-mini`** | 1 | 4 | Gemini 3.6 Flash | ~12k chars | OpenAI alias |
| **`o1`** | 2 | 0 | Gemini 3.5 Flash Thinking | ~20k chars | OpenAI reasoning alias |
| **`o3-mini`** | 2 | 0 | Gemini 3.5 Flash Thinking | ~20k chars | Codex reasoning alias |
| **`codex`** | 1 | 4 | Gemini 3.7 Flash | ~12k chars | OpenAI Codex CLI alias |

---

## 4. Endpoint Reference

### Health Check & Server Status

#### `GET /` or `GET /api/hello` or `GET /health`

Returns basic health information, version, and the list of supported models.

**Request:**
```bash
curl http://localhost:8081/
```

**Response (200 OK):**
```json
{
  "status": "ok",
  "version": "1.1.0",
  "models": [
    "gemini-3.7-flash",
    "gemini-3.6-flash",
    "gemini-3.5-flash",
    "gemini-3.5-flash-thinking",
    "gemini-3.1-pro",
    "gemini-auto",
    "gemini-3.5-flash-thinking-lite",
    "gemini-flash-lite",
    "claude-3-7-sonnet-20250219",
    "claude-3-5-sonnet-20241022",
    "gpt-4o",
    "o3-mini",
    "codex"
  ]
}
```

---

### OpenAI Chat Completions API (`/v1/chat/completions`)

#### `POST /v1/chat/completions`

Drop-in replacement for OpenAI `/v1/chat/completions`. Supports:
- Streaming (`"stream": true`) via Server-Sent Events (SSE)
- Tool / Function Calling (`"tools": [...]`)
- Multimodal / Vision inputs (base64 data URIs or HTTP image URLs)

**Request Headers:**
- `Content-Type: application/json`
- `Authorization: Bearer <key>` (if `api_keys` configured)

**Request Body Parameters:**
| Parameter | Type | Required | Description |
| :--- | :--- | :--- | :--- |
| `model` | string | Optional | Model identifier (defaults to `gemini-3.6-flash`) |
| `messages` | array | Required | Array of message objects (`role`, `content`) |
| `stream` | boolean | Optional | Whether to stream response chunks via SSE (default: `false`) |
| `tools` | array | Optional | List of OpenAI function definitions |
| `temperature` | number | Optional | Passed through for client compatibility |

#### Non-Streaming Example:

```bash
curl http://localhost:8081/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer sk-gemini" \
  -d '{
    "model": "gemini-3.7-flash",
    "messages": [
      {"role": "user", "content": "Explain async/await in Python in 2 sentences."}
    ]
  }'
```

**Response (200 OK):**
```json
{
  "id": "chatcmpl-a1b2c3d4e5f6",
  "object": "chat.completion",
  "created": 1729760000,
  "model": "gemini-3.7-flash",
  "choices": [
    {
      "index": 0,
      "message": {
        "role": "assistant",
        "content": "Async/await in Python allows you to write concurrent code that looks like synchronous code using the asyncio event loop. By awaiting coroutines, the program can pause execution of one task to let other tasks proceed without blocking the thread."
      },
      "finish_reason": "stop"
    }
  ],
  "usage": {
    "prompt_tokens": 14,
    "completion_tokens": 42,
    "total_tokens": 56
  }
}
```

#### Streaming Example (SSE):

```bash
curl http://localhost:8081/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer sk-gemini" \
  -d '{
    "model": "gemini-3.7-flash",
    "stream": true,
    "messages": [{"role": "user", "content": "Count from 1 to 3."}]
  }'
```

**Response Stream:**
```text
data: {"id": "chatcmpl-...", "object": "chat.completion.chunk", "created": 1729760000, "model": "gemini-3.7-flash", "choices": [{"index": 0, "delta": {"role": "assistant"}, "finish_reason": null}]}

data: {"id": "chatcmpl-...", "object": "chat.completion.chunk", "created": 1729760000, "model": "gemini-3.7-flash", "choices": [{"index": 0, "delta": {"content": "1, 2, 3"}, "finish_reason": null}]}

data: {"id": "chatcmpl-...", "object": "chat.completion.chunk", "created": 1729760000, "model": "gemini-3.7-flash", "choices": [{"index": 0, "delta": {}, "finish_reason": "stop"}]}

data: [DONE]
```

#### Tool Calling Example:

```bash
curl http://localhost:8081/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer sk-gemini" \
  -d '{
    "model": "gemini-3.7-flash",
    "messages": [{"role": "user", "content": "What is the weather in Tokyo?"}],
    "tools": [{
      "type": "function",
      "function": {
        "name": "get_weather",
        "description": "Fetch current weather conditions for a city",
        "parameters": {
          "type": "object",
          "properties": {
            "city": {"type": "string"}
          },
          "required": ["city"]
        }
      }
    }]
  }'
```

**Response:**
```json
{
  "id": "chatcmpl-...",
  "object": "chat.completion",
  "choices": [
    {
      "index": 0,
      "message": {
        "role": "assistant",
        "content": null,
        "tool_calls": [
          {
            "id": "call_1234abcd",
            "type": "function",
            "function": {
              "name": "get_weather",
              "arguments": "{\"city\": \"Tokyo\"}"
            }
          }
        ]
      },
      "finish_reason": "tool_calls"
    }
  ]
}
```

---

### OpenAI Responses API (`/v1/responses` - Codex CLI)

#### `POST /v1/responses`

Dedicated compatibility endpoint for the **OpenAI Codex CLI** (`codex`) and newer OpenAI Agent protocols.

**Supported Input Formats:**
- String prompt: `"input": "Fix bug in app.py"`
- Structured items list:
  - `{"type": "input_text", "text": "..."}`
  - `{"type": "function_call", "call_id": "...", "name": "...", "arguments": "..."}`
  - `{"type": "function_call_output", "call_id": "...", "output": "..."}`
  - `{"type": "message", "role": "assistant", "content": [...]}`

**SSE Event Sequence (`"stream": true`):**
1. `response.created`
2. `response.in_progress`
3. `response.output_item.added`
4. `response.output_text.delta` (or `response.function_call_arguments.delta`)
5. `response.output_text.done` (or `response.function_call_arguments.done`)
6. `response.output_item.done`
7. `response.completed`

**Example Request:**
```bash
curl http://localhost:8081/v1/responses \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer sk-gemini" \
  -d '{
    "model": "codex",
    "instructions": "You are a professional software engineer.",
    "input": "Write a bash function to check if port 8081 is open."
  }'
```

---

### Anthropic Messages API (`/v1/messages` - Claude Code)

#### `POST /v1/messages`

Full compatibility implementation of the **Anthropic Messages API (2023-06-01)**, designed specifically to power **Claude Code** (`claude` CLI).

**Key Features:**
- Works directly with `ANTHROPIC_BASE_URL=http://localhost:8081`
- Handles Claude system prompts (both single strings and arrays of system blocks)
- Handles Anthropic tool definitions (`input_schema`) and converts tool results (`tool_use` and `tool_result` blocks)
- Emits standard Anthropic SSE streaming events:
  - `message_start`
  - `content_block_start`
  - `content_block_delta` (`text_delta` or `input_json_delta`)
  - `content_block_stop`
  - `message_delta`
  - `message_stop`

**Example Request:**
```bash
curl http://localhost:8081/v1/messages \
  -H "Content-Type: application/json" \
  -H "x-api-key: sk-gemini" \
  -H "anthropic-version: 2023-06-01" \
  -d '{
    "model": "claude-3-7-sonnet-20250219",
    "max_tokens": 1024,
    "system": "You are an expert software developer.",
    "messages": [
      {"role": "user", "content": "How do I read a file line by line in Python?"}
    ]
  }'
```

**Response (200 OK):**
```json
{
  "id": "msg_0123456789abcdef01234567",
  "type": "message",
  "role": "assistant",
  "model": "claude-3-7-sonnet-20250219",
  "content": [
    {
      "type": "text",
      "text": "The most efficient and idiomatic way is to iterate over the open file object:\n\n```python\nwith open('filename.txt', 'r', encoding='utf-8') as f:\n    for line in f:\n        print(line.strip())\n```"
    }
  ],
  "stop_reason": "end_turn",
  "stop_sequence": null,
  "usage": {
    "input_tokens": 25,
    "output_tokens": 58
  }
}
```

---

### Anthropic Token Count API (`/v1/messages/count_tokens`)

#### `POST /v1/messages/count_tokens`

Required by Claude Code before issuing complex generation calls to evaluate context window consumption.

**Request:**
```bash
curl http://localhost:8081/v1/messages/count_tokens \
  -H "Content-Type: application/json" \
  -H "x-api-key: sk-gemini" \
  -d '{
    "messages": [{"role": "user", "content": "Hello Claude Code"}]
  }'
```

**Response (200 OK):**
```json
{
  "input_tokens": 4
}
```

---

### OpenAI Models API (`/v1/models`)

#### `GET /v1/models`

Returns standard OpenAI model list object for auto-discovery by tools like Codex, Cursor, Cherry Studio, and Aider.

**Response:**
```json
{
  "object": "list",
  "data": [
    {"id": "gemini-3.7-flash", "object": "model", "created": 1700000000, "owned_by": "google", "description": "Latest all-around model (Gemini 3.7 Flash)"},
    {"id": "gemini-3.5-flash-thinking", "object": "model", "created": 1700000000, "owned_by": "google", "description": "Deep thinking mode, longest output (~20k chars)"},
    {"id": "claude-3-7-sonnet-20250219", "object": "model", "created": 1700000000, "owned_by": "google", "description": "Claude 3.7 Sonnet (routed to Gemini 3.7 Flash)"},
    {"id": "codex", "object": "model", "created": 1700000000, "owned_by": "google", "description": "OpenAI Codex CLI model (routed to Gemini 3.7 Flash)"}
  ]
}
```

---

### Google Native Models API (`/v1beta/models`)

#### `GET /v1beta/models`

Model discovery endpoint for the official Google Gemini CLI.

---

### Google Native Content Generation (`/v1beta/models/{model}:generateContent`)

#### `POST /v1beta/models/{model}:generateContent`
#### `POST /v1beta/models/{model}:streamGenerateContent`

Used by Google Gemini CLI:
```bash
export GOOGLE_GEMINI_BASE_URL=http://localhost:8081
export GEMINI_API_KEY=none
gemini "Tell me a joke"
```

---

## 5. Client Connection Quickstart

### Claude Code Setup & Commands

Claude Code requires three environment variables:
- `ANTHROPIC_BASE_URL`: `http://127.0.0.1:8081`
- `ANTHROPIC_AUTH_TOKEN`: `sk-gemini` (or any string matching `api_keys`)
- `ANTHROPIC_MODEL`: `gemini-3.7-flash` (or `claude-3-7-sonnet-20250219`)

#### Option A: One-Click Connection Scripts (Included in Repo)

- **Windows PowerShell**:
  ```powershell
  .\connect-claudecode.ps1
  ```
- **Windows Command Prompt (CMD)**:
  ```cmd
  connect-claudecode.bat
  ```
- **macOS / Linux (Bash/Zsh)**:
  ```bash
  chmod +x connect-claudecode.sh
  ./connect-claudecode.sh
  ```

#### Option B: Terminal Commands

##### Windows PowerShell:
```powershell
$env:ANTHROPIC_BASE_URL="http://127.0.0.1:8081"
$env:ANTHROPIC_AUTH_TOKEN="sk-gemini"
$env:ANTHROPIC_MODEL="gemini-3.7-flash"
claude
```

To set permanently for your user account:
```powershell
[Environment]::SetEnvironmentVariable("ANTHROPIC_BASE_URL", "http://127.0.0.1:8081", "User")
[Environment]::SetEnvironmentVariable("ANTHROPIC_AUTH_TOKEN", "sk-gemini", "User")
[Environment]::SetEnvironmentVariable("ANTHROPIC_MODEL", "gemini-3.7-flash", "User")
```

##### Windows CMD (Command Prompt):
```cmd
set ANTHROPIC_BASE_URL=http://127.0.0.1:8081
set ANTHROPIC_AUTH_TOKEN=sk-gemini
set ANTHROPIC_MODEL=gemini-3.7-flash
claude
```

##### macOS / Linux:
```bash
export ANTHROPIC_BASE_URL=http://127.0.0.1:8081
export ANTHROPIC_AUTH_TOKEN=sk-gemini
export ANTHROPIC_MODEL=gemini-3.7-flash
claude
```

#### Option C: Claude Code Settings File (`~/.claude/settings.json`)

You can permanently configure Claude Code by adding this to `~/.claude/settings.json` (or `%USERPROFILE%\.claude\settings.json` on Windows):

```json
{
  "env": {
    "ANTHROPIC_BASE_URL": "http://127.0.0.1:8081",
    "ANTHROPIC_AUTH_TOKEN": "sk-gemini",
    "ANTHROPIC_MODEL": "gemini-3.7-flash"
  }
}
```

---

### OpenAI Codex Setup & Commands

OpenAI Codex and OpenAI CLI tools connect to the `/v1` base URL.

#### Option A: One-Click Connection Scripts (Included in Repo)

- **Windows PowerShell**:
  ```powershell
  .\connect-codex.ps1
  ```
- **Windows CMD**:
  ```cmd
  connect-codex.bat
  ```
- **macOS / Linux**:
  ```bash
  chmod +x connect-codex.sh
  ./connect-codex.sh
  ```

#### Option B: Terminal Commands

##### Windows PowerShell:
```powershell
$env:OPENAI_BASE_URL="http://127.0.0.1:8081/v1"
$env:OPENAI_API_BASE="http://127.0.0.1:8081/v1"
$env:OPENAI_API_KEY="sk-gemini"
$env:CODEX_API_BASE="http://127.0.0.1:8081/v1"
$env:CODEX_MODEL="gemini-3.7-flash"
codex
```

To set permanently in PowerShell:
```powershell
[Environment]::SetEnvironmentVariable("OPENAI_BASE_URL", "http://127.0.0.1:8081/v1", "User")
[Environment]::SetEnvironmentVariable("OPENAI_API_KEY", "sk-gemini", "User")
[Environment]::SetEnvironmentVariable("CODEX_API_BASE", "http://127.0.0.1:8081/v1", "User")
```

##### Windows CMD:
```cmd
set OPENAI_BASE_URL=http://127.0.0.1:8081/v1
set OPENAI_API_BASE=http://127.0.0.1:8081/v1
set OPENAI_API_KEY=sk-gemini
set CODEX_API_BASE=http://127.0.0.1:8081/v1
codex
```

##### macOS / Linux:
```bash
export OPENAI_BASE_URL=http://127.0.0.1:8081/v1
export OPENAI_API_BASE=http://127.0.0.1:8081/v1
export OPENAI_API_KEY=sk-gemini
export CODEX_API_BASE=http://127.0.0.1:8081/v1
codex
```

---

### curl Examples (Bash & PowerShell)

#### Test Chat Completion in Bash / macOS / Linux:
```bash
curl http://127.0.0.1:8081/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer sk-gemini" \
  -d '{"model":"gemini-3.7-flash","messages":[{"role":"user","content":"Hello!"}]}'
```

#### Test Chat Completion in Windows PowerShell:
```powershell
curl.exe --% http://127.0.0.1:8081/v1/chat/completions -H "Content-Type: application/json" -H "Authorization: Bearer sk-gemini" -d "{\"model\":\"gemini-3.7-flash\",\"messages\":[{\"role\":\"user\",\"content\":\"Hello!\"}]}"
```

#### Test Claude Messages API in Windows PowerShell:
```powershell
curl.exe --% http://127.0.0.1:8081/v1/messages -H "Content-Type: application/json" -H "x-api-key: sk-gemini" -H "anthropic-version: 2023-06-01" -d "{\"model\":\"claude-3-7-sonnet-20250219\",\"messages\":[{\"role\":\"user\",\"content\":\"Test Claude Code API!\"}]}"
```

---

### OpenAI Python SDK

```python
from openai import OpenAI

client = OpenAI(
    base_url="http://localhost:8081/v1",
    api_key="sk-gemini"
)

response = client.chat.completions.create(
    model="gemini-3.5-flash-thinking",
    messages=[
        {"role": "user", "content": "How do binary search trees work?"}
    ]
)

print(response.choices[0].message.content)
```

---

## 6. Advanced Server Configuration

### Configuration File (`config.json`)

Create `config.json` alongside `gemini_web2api.py`:

```json
{
  "port": 8081,
  "host": "0.0.0.0",
  "retry_attempts": 3,
  "retry_delay_sec": 2,
  "request_timeout_sec": 180,
  "gemini_bl": "boq_assistant-bard-web-server_20260716.08_p0",
  "auth_user": null,
  "xsrf_token": null,
  "default_model": "gemini-3.7-flash",
  "api_keys": ["sk-gemini"],
  "cookie_file": null,
  "proxy": null,
  "log_requests": true,
  "temporary_chats": false
}
```

| Key | Default | Description |
| :--- | :--- | :--- |
| `port` | `8081` | Server listening port |
| `host` | `"0.0.0.0"` | Bind IP (`0.0.0.0` for all interfaces) |
| `api_keys` | `[]` | Allowed API keys. If empty, auth is disabled |
| `default_model`| `"gemini-3.6-flash"` | Fallback model when client omits model name |
| `temporary_chats` | `false` | If `true`, does not store chat history in Google Account |
| `cookie_file` | `null` | Path to cookie file for real Pro model routing |
| `proxy` | `null` | HTTP proxy address (e.g. `http://127.0.0.1:7890`) |

---

### Pro Model & Cookies Setup

While anonymous requests work for Flash and Thinking models, Google routes anonymous requests for `gemini-3.1-pro` back to Flash. To obtain real Pro routing, a **Gemini Advanced (paid subscription)** account cookie is required:

1. Sign in to [gemini.google.com](https://gemini.google.com) on your browser with your Gemini Advanced account.
2. Open DevTools (`F12`) -> Application -> Cookies -> `https://gemini.google.com`.
3. Copy: `SID`, `HSID`, `SSID`, `APISID`, `SAPISID`, and `__Secure-1PSID`.
4. Create a `cookie.txt` file:
   ```text
   SID=...; HSID=...; SSID=...; APISID=...; SAPISID=...; __Secure-1PSID=...
   ```
5. Specify `--cookie-file cookie.txt` or set `"cookie_file": "cookie.txt"` in `config.json`.

---

### Proxy Settings

If Google Gemini is unreachable directly in your region:
1. Pass via CLI: `python gemini_web2api.py --proxy http://127.0.0.1:7890`
2. Or set in `config.json`: `{"proxy": "http://127.0.0.1:7890"}`
3. Or set standard system environment variables:
   - Linux/macOS: `export HTTPS_PROXY=http://127.0.0.1:7890`
   - Windows PowerShell: `$env:HTTPS_PROXY="http://127.0.0.1:7890"`

---

## 7. Error Handling & Status Codes

| Status Code | Description | Cause & Resolution |
| :--- | :--- | :--- |
| **`200 OK`** | Success | Request was processed normally |
| **`400 Bad Request`** | Invalid Request | Empty prompt, invalid JSON, or invalid thinking depth level |
| **`401 Unauthorized`**| Invalid API Key | Client did not provide a key matching `api_keys` in `config.json` |
| **`404 Not Found`** | Endpoint Not Found | Path is not registered on the proxy |
| **`500 Internal Error`**| Proxy Exception | Internal server parsing error |
| **`502 Bad Gateway`** | Upstream Error | Google Gemini rejected the connection, throttled rate limit, or BL token expired. Server retries automatically. |
