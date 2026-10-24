# gemini-web2api

<p align="center">
  <img src="logo.png" width="200" alt="gemini-web2api logo">
</p>

[English](README.md) | [完整 API 接口文档 (中文)](docs/API_CN.md) | [Full API Documentation (EN)](docs/API.md)

将 Google Gemini 网页端转换为标准的 OpenAI 与 Anthropic 兼容 API。零成本、跨平台、单文件。

---

## 特性

- **可选密钥**: `api_keys` 为空时免密, 填入密钥后按 OpenAI / Anthropic Bearer Key 校验。
- **Claude Code 原生支持**: 完整支持 Anthropic Messages API (`/v1/messages` 及 `/v1/messages/count_tokens`)、流式 SSE 与工具调用。
- **OpenAI Codex CLI 支持**: 完整实现 Responses API (`/v1/responses`) 与多步事件流，无缝对接 Codex 与 Agent。
- **OpenAI 兼容**: 直接替换 `/v1/chat/completions` 和 `/v1/models` (完美适配 Cursor, Aider, Cherry Studio, ChatBox)。
- **工具调用**: 完整的 Function Calling 支持 (OpenAI 及 Anthropic 格式)。
- **多模型**: Gemini 3.7 Flash, Flash 扩展思考 (2万字+超长输出), Pro, Auto, Lite。
- **思考深度**: 通过 `@think=N` 后缀调节 (0=最深, 4=最浅)。
- **联网搜索**: 内置互联网访问 (Gemini 原生联网搜索)。
- **多模态**: 支持 Base64 Data URL 与 HTTP 图片直链输入。
- **Gemini CLI**: Google 原生 API (`/v1beta/models`) 兼容 Gemini CLI。
- **一键连接脚本**: 自带 Windows PowerShell、CMD、Linux/macOS Bash 启动脚本。

---

## 快速开始

### 本地启动
```bash
pip install httpx
python gemini_web2api.py
```
服务默认启动在 `http://localhost:8081`（Base URL: `http://localhost:8081/v1`）。

### 🚀 Linux VPS 一键部署
在任意 Linux VPS 上一键安装并以后台 `systemd` 服务运行（支持开机自启）：
```bash
curl -fsSL https://raw.githubusercontent.com/Shahilali5/gemini-web2api/main/install.sh | bash
```
或者在克隆的目录内直接执行：
```bash
bash install.sh
```
该脚本会自动安装依赖、创建虚拟环境、注册并启动 `gemini-web2api.service` 服务。

---

## 客户端连接指南与命令

### 🤖 Claude Code (`claude`)

gemini-web2api 原生支持 Anthropic Messages API (`/v1/messages` 及 `/v1/messages/count_tokens`)，全面支持流式输出与文件/终端工具调用。

#### 方式 1: 使用内置一键连接脚本（推荐）

- **Windows PowerShell**:
  ```powershell
  .\connect-claudecode.ps1
  ```
- **Windows 命令提示符 (CMD)**:
  ```cmd
  connect-claudecode.bat
  ```
- **macOS / Linux**:
  ```bash
  chmod +x connect-claudecode.sh
  ./connect-claudecode.sh
  ```

#### 方式 2: 终端命令直接运行

##### Windows PowerShell:
```powershell
# 当前窗口生效
$env:ANTHROPIC_BASE_URL="http://127.0.0.1:8081"
$env:ANTHROPIC_AUTH_TOKEN="sk-gemini"
$env:ANTHROPIC_MODEL="gemini-3.7-flash"
claude
```

如需永久写入用户环境变量：
```powershell
[Environment]::SetEnvironmentVariable("ANTHROPIC_BASE_URL", "http://127.0.0.1:8081", "User")
[Environment]::SetEnvironmentVariable("ANTHROPIC_AUTH_TOKEN", "sk-gemini", "User")
[Environment]::SetEnvironmentVariable("ANTHROPIC_MODEL", "gemini-3.7-flash", "User")
```

##### Windows 命令提示符 (CMD):
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

#### 方式 3: 写入 Claude Code 配置文件 (`~/.claude/settings.json`)

在 `~/.claude/settings.json`（Windows 为 `%USERPROFILE%\.claude\settings.json`）中添加：

```json
{
  "env": {
    "ANTHROPIC_BASE_URL": "http://127.0.0.1:8081",
    "ANTHROPIC_AUTH_TOKEN": "sk-gemini",
    "ANTHROPIC_MODEL": "gemini-3.7-flash"
  }
}
```

> **提示**: 模型名称也可填写 `claude-3-7-sonnet-20250219`、`gemini-3.5-flash-thinking`，或添加 `@think=0` 开启最深思考！

---

### 🖥️ 官方 Claude Desktop 桌面客户端

Anthropic 官方 Claude Desktop 客户端支持**第三方推理网关 (Third-Party Inference Gateway)**，可直接接入 `gemini-web2api` 的 Anthropic Messages API (`/v1/messages`)。

#### 方式 1: Windows 一键注册表配置脚本 (推荐)

- **Windows 命令提示符 (CMD)**:
  ```cmd
  connect-claudedesktop.bat
  ```
- **Windows PowerShell**:
  ```powershell
  .\connect-claudedesktop.ps1
  ```
  *(随时可一键恢复官方登录: `.\connect-claudedesktop.ps1 -Restore`)*

#### 方式 2: 应用内开发者模式设置 (Windows / macOS)

1. 打开 **Claude Desktop** 桌面应用。
2. 点击菜单 **Help** → **Troubleshooting** → **Enable Developer Mode** (或 **Help** → **Enable Developer Mode**)。
3. 应用会自动重启并开启开发者选项。
4. 点击顶部菜单栏的 **Developer** → **Configure Third-Party Inference…**。
5. 填写网关配置:
   - **Provider**: 选择 `Gateway`
   - **Base URL / Endpoint**: 填入 `http://localhost:8081` (如果是 VPS 请填 `http://<VPS_IP>:8081`)
   - **API Key**: 填入 `sk-gemini` (或任意字符)
6. 保存并重启 Claude Desktop，所有对话与工具调用将全部走 `gemini-web2api`！

---

### 💻 OpenAI Codex CLI (`codex`)

gemini-web2api 实现了 OpenAI Responses API (`/v1/responses`) 和 Chat Completions API (`/v1/chat/completions`)。

#### 方式 1: 使用内置一键连接脚本（推荐）

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

#### 方式 2: 终端命令直接运行

##### Windows PowerShell:
```powershell
$env:OPENAI_BASE_URL="http://127.0.0.1:8081/v1"
$env:OPENAI_API_BASE="http://127.0.0.1:8081/v1"
$env:OPENAI_API_KEY="sk-gemini"
$env:CODEX_API_BASE="http://127.0.0.1:8081/v1"
$env:CODEX_MODEL="gemini-3.7-flash"
codex
```

永久设置环境变量：
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

### 🎨 Cherry Studio / ChatBox / Cursor / 任何 OpenAI 客户端

| 字段 | 值 |
|------|-----|
| **Base URL** | `http://localhost:8081/v1` |
| **API Key** | `config.json` 中的任意 `api_keys`（如 `sk-gemini`）；未配置时随便填 |
| **Model** | `gemini-3.7-flash` 或 `gemini-3.5-flash-thinking` |

---

### 🔍 curl 测试

#### bash / macOS / Linux
```bash
curl http://localhost:8081/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer sk-gemini" \
  -d '{"model":"gemini-3.7-flash","messages":[{"role":"user","content":"你好!"}]}'
```

#### Windows PowerShell
```powershell
curl.exe --% http://127.0.0.1:8081/v1/chat/completions -H "Content-Type: application/json" -H "Authorization: Bearer sk-gemini" -d "{\"model\":\"gemini-3.7-flash\",\"messages\":[{\"role\":\"user\",\"content\":\"你好!\"}]}"
```

---

### 🐍 OpenAI Python SDK

```python
from openai import OpenAI
client = OpenAI(base_url="http://localhost:8081/v1", api_key="sk-gemini")
resp = client.chat.completions.create(
    model="gemini-3.5-flash-thinking",
    messages=[{"role": "user", "content": "用简单的话解释量子计算"}]
)
print(resp.choices[0].message.content)
```

---

### 🌐 Google Gemini CLI

```bash
export GEMINI_API_KEY=none
export GOOGLE_GEMINI_BASE_URL=http://localhost:8081
gemini "讲个笑话"
```

支持原生接口:
- `GET /v1beta/models` — 模型列表
- `POST /v1beta/models/{model}:generateContent` — 非流式生成
- `POST /v1beta/models/{model}:streamGenerateContent` — 流式生成 (SSE)

---

## 可用模型

| 模型 | 说明 | 输出量 |
|------|------|--------|
| `gemini-3.7-flash` | 最新全能主力模型 (Gemini 3.7 Flash) | ~1.2万字 |
| `gemini-3.6-flash` | 高速通用模型 | ~1.2万字 |
| `gemini-3.5-flash` | gemini-3.6-flash 兼容别名 | ~1.2万字 |
| `gemini-3.5-flash-thinking` | 扩展深度思考, 超长输出 | **~2万字** |
| `gemini-3.5-flash-thinking-lite` | 自适应思考深度 | ~1.5万字 |
| `gemini-3.1-pro` | 高级数学与代码 (需 cookie) | ~1.2万字 |
| `gemini-auto` | 自动选择模型 | 不定 |
| `gemini-flash-lite` | 最快响应, 轻量 | ~1万字 |
| `claude-3-7-sonnet-20250219` | 映射至 Gemini 3.7 Flash | ~1.2万字 |
| `claude-3-5-sonnet-20241022` | 映射至 Gemini 3.7 Flash | ~1.2万字 |
| `o3-mini` / `o1` | 映射至 Gemini 3.5 Flash Thinking | **~2万字** |
| `gpt-4o` / `codex` | 映射至 Gemini 3.7 Flash | ~1.2万字 |

详见 [完整 API 接口文档 (中文)](docs/API_CN.md)。

### 思考深度控制

在模型名后追加 `@think=N`:

```
gemini-3.5-flash-thinking@think=0   # 最深思考 (默认)
gemini-3.5-flash-thinking@think=2   # 中等思考
gemini-3.5-flash-thinking@think=4   # 最浅思考
```

---

## 完整 API 接口文档

关于每个接口的详细协议、JSON 结构体、SSE 事件格式及排错指南，请参阅：
- [完整 API 接口文档 (中文)](docs/API_CN.md)
- [Full API Reference Documentation (English)](docs/API.md)

---

## 配置文件

在同目录创建 `config.json`:

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

---

## 可选: Cookie 配置 (Pro 模型)

匿名访问对所有模型有效, 但 `gemini-3.1-pro` 在无认证时会路由到 Flash. 要获得真正的 Pro 路由, 需要 **Gemini Advanced (付费订阅)** 账号的 cookie:

```bash
python gemini_web2api.py --cookie-file cookie.txt
```

### 如何获取 Cookie:
1. 打开 Chrome 访问 [gemini.google.com](https://gemini.google.com) 并登录已开通 Advanced 的 Google 账号。
2. 打开开发者工具 (F12) → Application → Cookies → `https://gemini.google.com`。
3. 复制以下值: `SID`, `HSID`, `SSID`, `APISID`, `SAPISID`, `__Secure-1PSID`。
4. 创建 `cookie.txt`:
   ```text
   SID=...; HSID=...; SSID=...; APISID=...; SAPISID=...; __Secure-1PSID=...
   ```

---

## Docker 部署

```bash
cp config.example.json config.json
docker build -t gemini-web2api .
docker run -d --name gemini-web2api -p 8081:8081 -v ./config.json:/app/config.json gemini-web2api
```

---

## 代理配置

如果无法直接访问 `gemini.google.com` (连接超时), 需要配置代理:
- **命令行参数**: `python gemini_web2api.py --proxy http://127.0.0.1:7890`
- **config.json**: `{"proxy": "http://127.0.0.1:7890"}`
- **环境变量**: `set HTTPS_PROXY=http://127.0.0.1:7890`

---

## 📤 GitHub 仓库与推送配置

项目仓库地址: [https://github.com/Shahilali5/gemini-web2api](https://github.com/Shahilali5/gemini-web2api)

### 一键推送脚本
- **Windows 命令提示符 (CMD)**:
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

### 手动 Git 提交与推送命令
```bash
git init
git branch -M main
git remote add origin https://github.com/Shahilali5/gemini-web2api.git
git add .
git commit -m "feat: complete API docs, Claude Code & Codex integration, and VPS installer"
git push -u origin main
```

---

## 👥 贡献者与维护者 (Contributors)

<div align="center">

<a href="https://github.com/Shahilali5">
  <img src="https://github.com/Shahilali5.png" width="100" height="100" style="border-radius: 50%;" alt="Shahilali5" />
  <br />
  <b>Shahil Ali (@Shahilali5)</b>
</a>
<br />
<sub>🚀 核心贡献者与项目维护者 (Core Contributor & Maintainer)</sub>

</div>

---

欢迎提交 PR、Issue 或功能建议！详情请查看 [Issues 页面](https://github.com/Shahilali5/gemini-web2api/issues)。

---

## 系统要求

- Python 3.8+
- `httpx` (`pip install httpx`) — 用于流式请求
- 需要能访问 `gemini.google.com` (部分地区需代理)

---

## License

MIT
