# gemini-web2api

<p align="center">
  <img src="logo.png" width="200" alt="gemini-web2api logo">
</p>

[Full API Documentation](docs/API.md) | [Claude Code & Desktop Setup](#-client-connection-guides--commands) | [VPS Deployment](#-1-command-vps-setup-linux) | [GitHub Repository](https://github.com/Shahilali5/gemini-web2api)

Convert Google Gemini's web interface into an OpenAI- and Anthropic-compatible API. Zero cost, cross-platform, single file.

---

## Features

- **Optional API Keys**: No auth when `api_keys` is `[]`, OpenAI/Anthropic-style Bearer auth when configured.
- **Claude Code Ready**: Full support for Anthropic Messages API (`/v1/messages` and `/v1/messages/count_tokens`), streaming SSE, and tool use.
- **OpenAI Codex CLI Ready**: Responses API (`/v1/responses`) with multi-step sequence events and function calling.
- **OpenAI Compatible**: Drop-in replacement for `/v1/chat/completions` and `/v1/models` (Cursor, Aider, Cherry Studio, ChatBox, NextChat).
- **Tool Calling**: Full function calling support (OpenAI and Anthropic formats).
- **Multiple Models**: Gemini 3.7 Flash, Extended Thinking (~20k+ char output), Pro, Auto, Lite.
- **Thinking Depth**: Adjustable via `@think=N` suffix (0=deepest, 4=shallowest).
- **Web Search**: Built-in internet access (Gemini's native web search).
- **Multimodal**: Vision support via Base64 data URLs or HTTP image links.
- **Gemini CLI**: Google native API (`/v1beta/models`) for Google Gemini CLI compatibility.
- **1-Click Connect Scripts**: Ready-to-use launch scripts for PowerShell, Windows CMD, and Bash.

---

## Quick Start

### Local Setup
```bash
pip install httpx
python gemini_web2api.py
```
Server starts at `http://localhost:8081` (Base URL: `http://localhost:8081/v1`).

### 🚀 1-Command VPS Setup (Linux)
Deploy and run `gemini-web2api` as a background `systemd` service with automatic startup on your Linux VPS:
```bash
curl -fsSL https://raw.githubusercontent.com/Shahilali5/gemini-web2api/main/install.sh | bash
```
Or run directly inside the repository:
```bash
bash install.sh
```
This automatically sets up Python, creates a virtual environment, configures systemd (`systemctl status gemini-web2api`), and starts the proxy on port `8081`.

---

## Client Connection Guides & Commands

### 🤖 Claude Code (`claude`)

gemini-web2api provides full support for the Anthropic Messages API (`/v1/messages`, `/v1/messages/count_tokens`), SSE streaming, and Claude Code file/terminal tools.

#### Method 1: Ready-to-Use 1-Click Launchers (Recommended)

- **Windows PowerShell**:
  ```powershell
  .\connect-claudecode.ps1
  ```
- **Windows Command Prompt (CMD)**:
  ```cmd
  connect-claudecode.bat
  ```
- **macOS / Linux**:
  ```bash
  chmod +x connect-claudecode.sh
  ./connect-claudecode.sh
  ```

#### Method 2: Command Line Setup

##### Windows (PowerShell):
```powershell
# Set for current session
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

##### Windows (Command Prompt / CMD):
```cmd
set ANTHROPIC_BASE_URL=http://127.0.0.1:8081
set ANTHROPIC_AUTH_TOKEN=sk-gemini
set ANTHROPIC_MODEL=gemini-3.7-flash
claude
```

##### macOS / Linux (Bash / Zsh):
```bash
export ANTHROPIC_BASE_URL=http://127.0.0.1:8081
export ANTHROPIC_AUTH_TOKEN=sk-gemini
export ANTHROPIC_MODEL=gemini-3.7-flash
claude
```

#### Method 3: Persistent Configuration in `~/.claude/settings.json`

Add this to `~/.claude/settings.json` (or `%USERPROFILE%\.claude\settings.json` on Windows):

```json
{
  "env": {
    "ANTHROPIC_BASE_URL": "http://127.0.0.1:8081",
    "ANTHROPIC_AUTH_TOKEN": "sk-gemini",
    "ANTHROPIC_MODEL": "gemini-3.7-flash"
  }
}
```

> **Tip**: You can also use `claude-3-7-sonnet-20250219`, `gemini-3.5-flash-thinking`, or append `@think=0` for deepest reasoning!

---

### 🖥️ Official Claude Desktop App

The official Anthropic Claude Desktop app supports **Third-Party Inference Gateways** using the Anthropic Messages API (`/v1/messages`), allowing it to connect directly to `gemini-web2api`.

#### Method 1: 1-Click Configurator (Windows)

- **Windows Command Prompt (CMD)**:
  ```cmd
  connect-claudedesktop.bat
  ```
- **Windows PowerShell**:
  ```powershell
  .\connect-claudedesktop.ps1
  ```
  *(To revert back to standard claude.ai login at any time, run: `.\connect-claudedesktop.ps1 -Restore`)*

#### Method 2: In-App Developer Mode (Windows & macOS)

1. Launch **Claude Desktop**.
2. Click **Help** → **Troubleshooting** → **Enable Developer Mode** (or **Help** → **Enable Developer Mode**).
3. The app will restart with developer options enabled.
4. Click **Developer** → **Configure Third-Party Inference…** in the top menu bar.
5. Fill in the gateway settings:
   - **Provider**: `Gateway`
   - **Base URL / Endpoint**: `http://localhost:8081` (or your VPS: `http://<VPS_IP>:8081`)
   - **API Key**: `sk-gemini` (or any placeholder string)
6. Save and restart Claude Desktop. All conversations will now route directly through `gemini-web2api`!

---

### 💻 OpenAI Codex CLI (`codex`)

gemini-web2api implements the OpenAI Responses API (`/v1/responses`) and Chat Completions API (`/v1/chat/completions`) for OpenAI Codex and AI agents.

#### Method 1: Ready-to-Use 1-Click Launchers (Recommended)

- **Windows PowerShell**:
  ```powershell
  .\connect-codex.ps1
  ```
- **Windows Command Prompt (CMD)**:
  ```cmd
  connect-codex.bat
  ```
- **macOS / Linux**:
  ```bash
  chmod +x connect-codex.sh
  ./connect-codex.sh
  ```

#### Method 2: Command Line Setup

##### Windows (PowerShell):
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

##### Windows (CMD):
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

### 🎨 Cherry Studio / ChatBox / Cursor / Any OpenAI Client

| Field | Value |
|-------|-------|
| **Base URL** | `http://localhost:8081/v1` |
| **API Key** | any `api_keys` value from `config.json` (e.g. `sk-gemini`); anything if not configured |
| **Model** | `gemini-3.7-flash` or `gemini-3.5-flash-thinking` |

---

### 🔍 curl Test Commands

#### bash / macOS / Linux
```bash
curl http://localhost:8081/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer sk-gemini" \
  -d '{"model":"gemini-3.7-flash","messages":[{"role":"user","content":"Hello!"}]}'
```

#### PowerShell (Windows)
```powershell
curl.exe --% http://127.0.0.1:8081/v1/chat/completions -H "Content-Type: application/json" -H "Authorization: Bearer sk-gemini" -d "{\"model\":\"gemini-3.7-flash\",\"messages\":[{\"role\":\"user\",\"content\":\"Hello!\"}]}"
```

> Note: On Windows PowerShell, use `curl.exe` and `--%` so PowerShell does not reinterpret JSON quoting or curl options.

---

### 🐍 OpenAI Python SDK

```python
from openai import OpenAI

client = OpenAI(base_url="http://localhost:8081/v1", api_key="sk-gemini")
resp = client.chat.completions.create(
    model="gemini-3.5-flash-thinking",
    messages=[{"role": "user", "content": "Explain quantum computing in simple terms."}]
)
print(resp.choices[0].message.content)
```

---

### 🌐 Google Gemini CLI

```bash
export GEMINI_API_KEY=none
export GOOGLE_GEMINI_BASE_URL=http://localhost:8081
gemini "Tell me a joke"
```

Supports Google native API endpoints:
- `GET /v1beta/models` — list models
- `POST /v1beta/models/{model}:generateContent` — non-streaming
- `POST /v1beta/models/{model}:streamGenerateContent` — streaming (SSE)

---

## Available Models

| Model | Description | Output |
|-------|-------------|--------|
| `gemini-3.7-flash` | Latest all-around model (Gemini 3.7 Flash) | ~12k chars |
| `gemini-3.6-flash` | High-speed all-around model | ~12k chars |
| `gemini-3.5-flash` | Alias for gemini-3.6-flash | ~12k chars |
| `gemini-3.5-flash-thinking` | Extended thinking, longest output | **~20k chars** |
| `gemini-3.5-flash-thinking-lite` | Adaptive thinking depth | ~15k chars |
| `gemini-3.1-pro` | Advanced math & code (needs cookie) | ~12k chars |
| `gemini-auto` | Auto model selection | varies |
| `gemini-flash-lite` | Fastest answers, lightweight | ~10k chars |
| `claude-3-7-sonnet-20250219` | Routed to Gemini 3.7 Flash | ~12k chars |
| `claude-3-5-sonnet-20241022` | Routed to Gemini 3.7 Flash | ~12k chars |
| `o3-mini` / `o1` | Routed to Gemini 3.5 Flash Thinking | **~20k chars** |
| `gpt-4o` / `codex` | Routed to Gemini 3.7 Flash | ~12k chars |

For the complete list and aliases, see [Full API Documentation](docs/API.md).

### Thinking Depth

Append `@think=N` to any model name:

```
gemini-3.5-flash-thinking@think=0   # deepest (default for thinking)
gemini-3.5-flash-thinking@think=2   # medium
gemini-3.5-flash-thinking@think=4   # shallowest
```

---

## Full API Documentation

For complete endpoint specifications, JSON request/response bodies, SSE stream formats, and troubleshooting, see:
- [Full API Reference Documentation](docs/API.md)

---

## Configuration

Create `config.json` in the same directory:

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

- When `api_keys` is `[]`, authentication is disabled.
- Set `temporary_chats` to `true` to use Gemini Web temporary chats without saving to account history.

---

## Optional: Cookie for Pro

Anonymous access works for all models, but `gemini-3.1-pro` routes to Flash without authentication. To get real Pro routing, you need a **Gemini Advanced (paid subscription)** account cookie:

```bash
python gemini_web2api.py --cookie-file cookie.txt
```

### How to get cookies:
1. Open Chrome, go to [gemini.google.com](https://gemini.google.com) and sign in with a **Gemini Advanced** account.
2. Open DevTools (F12) → Application → Cookies → `https://gemini.google.com`.
3. Copy these cookie values: `SID`, `HSID`, `SSID`, `APISID`, `SAPISID`, `__Secure-1PSID`.
4. Create `cookie.txt`:
   ```
   SID=your_sid; HSID=your_hsid; SSID=your_ssid; APISID=your_apisid; SAPISID=your_sapisid; __Secure-1PSID=your_1psid
   ```

---

## Docker

```bash
cp config.example.json config.json
docker build -t gemini-web2api .
docker run -d --name gemini-web2api -p 8081:8081 -v ./config.json:/app/config.json gemini-web2api
```

---

## Proxy

If you cannot access `gemini.google.com` directly:
- **CLI argument**: `python gemini_web2api.py --proxy http://127.0.0.1:7890`
- **config.json**: `{"proxy": "http://127.0.0.1:7890"}`
- **Environment variable**: `export HTTPS_PROXY=http://127.0.0.1:7890`

---

## 📤 GitHub Setup & Push Commands

Repository: [https://github.com/Shahilali5/gemini-web2api](https://github.com/Shahilali5/gemini-web2api)

### 🔐 1-Click GitHub Login Helper
If you need to sign into GitHub before pushing:
- **Windows Command Prompt (CMD)**:
  ```cmd
  git-login.bat
  ```
- **Windows PowerShell**:
  ```powershell
  .\git-login.ps1
  ```

### 1-Click Push Scripts
- **Windows Command Prompt (CMD)**:
  ```cmd
  push.bat
  ```
- **Windows PowerShell**:
  ```powershell
  .\push.ps1
  ```
- **Linux / macOS**:
  ```bash
  chmod +x push.sh
  ./push.sh
  ```

### Manual Git Push Commands
```bash
git init
git branch -M main
git remote add origin https://github.com/Shahilali5/gemini-web2api.git
git add .
git commit -m "feat: complete API docs, Claude Code & Codex integration, and VPS installer"
git push -u origin main
```

---

## 👥 Contributors & Maintainers

<div align="center">

<a href="https://github.com/Shahilali5">
  <img src="https://github.com/Shahilali5.png" width="100" height="100" style="border-radius: 50%;" alt="Shahilali5" />
  <br />
  <b>Shahil Ali (@Shahilali5)</b>
</a>
<br />
<sub>🚀 Core Contributor & Maintainer</sub>

</div>

---

## Requirements

- Python 3.8+
- `httpx` (`pip install httpx`) — used for streaming requests
- Network access to `gemini.google.com` (proxy/VPN if needed)

---

## License

MIT
