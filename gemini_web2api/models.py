"""Model definitions and mapping from Gemini frontend JS source."""

# MODE_CATEGORY enum from 028-6eb337387583.js:
#   1=FAST, 2=THINKING, 3=PRO, 4=AUTO, 5=FAST_DYNAMIC_THINKING, 6=FLASH_LITE

MODELS = {
    "gemini-3.7-flash": {
        "mode": 1, "think": 4,
        "desc": "Latest all-around model (Gemini 3.7 Flash)",
    },
    "gemini-3.6-flash": {
        "mode": 1, "think": 4,
        "desc": "All-around model (Gemini 3.6 Flash)",
    },
    "gemini-3.5-flash": {
        "mode": 1, "think": 4,
        "desc": "Alias for gemini-3.6-flash (backend upgraded)",
    },
    "gemini-3.5-flash-thinking": {
        "mode": 2, "think": 0,
        "desc": "Deep thinking mode, longest output (~20k chars)",
    },
    "gemini-3.1-pro": {
        "mode": 3, "think": 4,
        "desc": "Pro model (requires cookie for real routing)",
    },
    "gemini-3.1-pro-enhanced": {
        "mode": 3, "think": 4, "extra": {31: 2, 80: 3},
        "desc": "Pro with enhanced output (experimental)",
    },
    "gemini-auto": {
        "mode": 4, "think": 4,
        "desc": "Auto model selection",
    },
    "gemini-3.5-flash-thinking-lite": {
        "mode": 5, "think": 0,
        "desc": "Dynamic thinking with adaptive depth",
    },
    "gemini-flash-lite": {
        "mode": 6, "think": 4,
        "desc": "Lightweight fast model",
    },
    # Claude Aliases
    "claude-opus-4-6": {
        "mode": 2, "think": 0,
        "desc": "Claude Opus 4.6 (routed to Gemini 3.5 Flash Thinking)",
    },
    "claude-sonnet-4-6": {
        "mode": 1, "think": 4,
        "desc": "Claude Sonnet 4.6 (routed to Gemini 3.7 Flash)",
    },
    "claude-3-7-sonnet-20250219": {
        "mode": 1, "think": 4,
        "desc": "Claude 3.7 Sonnet (routed to Gemini 3.7 Flash)",
    },
    "claude-3-7-sonnet-latest": {
        "mode": 1, "think": 4,
        "desc": "Claude 3.7 Sonnet Latest (routed to Gemini 3.7 Flash)",
    },
    "claude-3-5-sonnet-20241022": {
        "mode": 1, "think": 4,
        "desc": "Claude 3.5 Sonnet (routed to Gemini 3.7 Flash)",
    },
    "claude-3-5-sonnet-latest": {
        "mode": 1, "think": 4,
        "desc": "Claude 3.5 Sonnet Latest (routed to Gemini 3.7 Flash)",
    },
    "claude-3-5-haiku-20241022": {
        "mode": 1, "think": 4,
        "desc": "Claude 3.5 Haiku (routed to Gemini 3.6 Flash)",
    },
    "claude-3-5-haiku-latest": {
        "mode": 1, "think": 4,
        "desc": "Claude 3.5 Haiku Latest (routed to Gemini 3.6 Flash)",
    },
    "claude-3-haiku-20240307": {
        "mode": 6, "think": 4,
        "desc": "Claude 3 Haiku (routed to Gemini Flash Lite)",
    },
    "claude-3-opus-20240229": {
        "mode": 2, "think": 0,
        "desc": "Claude 3 Opus (routed to Gemini 3.5 Flash Thinking)",
    },
    "claude-3-opus-latest": {
        "mode": 2, "think": 0,
        "desc": "Claude 3 Opus Latest (routed to Gemini 3.5 Flash Thinking)",
    },
    # OpenAI / Codex Aliases
    "gpt-4o": {
        "mode": 1, "think": 4,
        "desc": "GPT-4o (routed to Gemini 3.7 Flash)",
    },
    "gpt-4o-mini": {
        "mode": 1, "think": 4,
        "desc": "GPT-4o mini (routed to Gemini 3.6 Flash)",
    },
    "gpt-4-turbo": {
        "mode": 1, "think": 4,
        "desc": "GPT-4 Turbo (routed to Gemini 3.7 Flash)",
    },
    "gpt-4": {
        "mode": 1, "think": 4,
        "desc": "GPT-4 (routed to Gemini 3.7 Flash)",
    },
    "o1": {
        "mode": 2, "think": 0,
        "desc": "o1 reasoning model (routed to Gemini 3.5 Flash Thinking)",
    },
    "o1-preview": {
        "mode": 2, "think": 0,
        "desc": "o1-preview (routed to Gemini 3.5 Flash Thinking)",
    },
    "o1-mini": {
        "mode": 5, "think": 0,
        "desc": "o1-mini (routed to Gemini 3.5 Flash Thinking Lite)",
    },
    "o3-mini": {
        "mode": 2, "think": 0,
        "desc": "o3-mini reasoning model (routed to Gemini 3.5 Flash Thinking)",
    },
    "codex": {
        "mode": 1, "think": 4,
        "desc": "OpenAI Codex CLI model (routed to Gemini 3.7 Flash)",
    },
    "code-davinci-002": {
        "mode": 1, "think": 4,
        "desc": "Code Davinci 002 (routed to Gemini 3.7 Flash)",
    },
}

MODEL_ALIASES = {
    # Claude aliases
    "claude-opus-4-6": "gemini-3.5-flash-thinking",
    "claude-sonnet-4-6": "gemini-3.7-flash",
    "claude-3-7-sonnet-20250219": "gemini-3.7-flash",
    "claude-3-7-sonnet-latest": "gemini-3.7-flash",
    "claude-3-5-sonnet-20241022": "gemini-3.7-flash",
    "claude-3-5-sonnet-latest": "gemini-3.7-flash",
    "claude-3-5-haiku-20241022": "gemini-3.6-flash",
    "claude-3-5-haiku-latest": "gemini-3.6-flash",
    "claude-3-haiku-20240307": "gemini-flash-lite",
    "claude-3-opus-20240229": "gemini-3.5-flash-thinking",
    "claude-3-opus-latest": "gemini-3.5-flash-thinking",
    # OpenAI / Codex aliases
    "gpt-4o": "gemini-3.7-flash",
    "gpt-4o-mini": "gemini-3.6-flash",
    "gpt-4-turbo": "gemini-3.7-flash",
    "gpt-4": "gemini-3.7-flash",
    "o1": "gemini-3.5-flash-thinking",
    "o1-preview": "gemini-3.5-flash-thinking",
    "o1-mini": "gemini-3.5-flash-thinking-lite",
    "o3-mini": "gemini-3.5-flash-thinking",
    "codex": "gemini-3.7-flash",
    "code-davinci-002": "gemini-3.7-flash",
    "openai/codex": "gemini-3.7-flash",
}


def resolve_model(model_name: str, default: str = "gemini-3.6-flash"):
    """Resolve model name to (name, mode_id, think_mode, error, extra_fields).

    Unknown model names fall back to appropriate defaults rather than erroring,
    since upstream clients (Claude Code, Codex CLI, Cursor) may request arbitrary model identifiers.
    """
    think_override = None
    if not model_name:
        model_name = default
    if "@think=" in model_name:
        model_name, think_str = model_name.rsplit("@think=", 1)
        try:
            think_override = int(think_str)
        except ValueError:
            return None, None, None, f"Invalid think level: {think_str}", None

    target = MODEL_ALIASES.get(model_name, model_name)
    cfg = MODELS.get(target)
    if not cfg:
        from .gemini import log
        lower = model_name.lower()
        if "o1" in lower or "o3" in lower or "thinking" in lower or "reason" in lower:
            target = "gemini-3.5-flash-thinking"
            cfg = MODELS.get(target)
        elif "claude" in lower or "gpt-4" in lower or "codex" in lower:
            target = "gemini-3.7-flash" if "gemini-3.7-flash" in MODELS else default
            cfg = MODELS.get(target)
        else:
            target = default
            cfg = MODELS.get(target, MODELS.get("gemini-3.6-flash"))
        log(f"Unknown model '{model_name}', routed to '{target}'")

    mode_id = cfg["mode"]
    think_mode = think_override if think_override is not None else cfg["think"]
    extra = cfg.get("extra")
    return target, mode_id, think_mode, None, extra
