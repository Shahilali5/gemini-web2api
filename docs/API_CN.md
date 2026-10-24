# gemini-web2api 完整 API 接口文档

`gemini-web2api` 是一个零成本、跨平台、单文件的代理服务，将 Google Gemini 网页端的 StreamGenerate 协议转换为业界标准的 API 接口：
- **Anthropic Messages API**（完美适配 **Claude Code**、**Claude Desktop 官方桌面端** 及 Anthropic 官方 SDK）
- **OpenAI Responses API**（完美适配 **OpenAI Codex CLI** 及智能体工具）
- **OpenAI Chat Completions API**（适配 **Cursor**、**Aider**、**Cherry Studio**、**ChatBox**、**OpenAI Python SDK** 等）
- **Google AI Gemini Native API**（适配 **Gemini CLI** 及 Google 官方 SDK）

---

## 目录

1. [基础服务地址与端点概览](#1-基础服务地址与端点概览)
2. [鉴权方式](#2-鉴权方式)
3. [可用模型与别名映射](#3-可用模型与别名映射)
   - [思考深度控制 (`@think=N`)](#思考深度控制-thinkn)
   - [完整模型表](#完整模型表)
4. [接口详细参考](#4-接口详细参考)
   - [健康检查与状态 (`GET /`)](#健康检查与状态)
   - [OpenAI 聊天补全 (`/v1/chat/completions`)](#openai-聊天补全-v1chatcompletions)
   - [OpenAI Responses API (`/v1/responses` - Codex CLI)](#openai-responses-api-v1responses---codex-cli)
   - [Anthropic Messages API (`/v1/messages` - Claude Code)](#anthropic-messages-api-v1messages---claude-code)
   - [Anthropic Token 统计 (`/v1/messages/count_tokens`)](#anthropic-token-统计-v1messagescount_tokens)
   - [OpenAI 模型列表 (`/v1/models`)](#openai-模型列表-v1models)
   - [Google 原生模型列表 (`/v1beta/models`)](#google-原生模型列表-v1betamodels)
   - [Google 原生生成接口 (`/v1beta/models/...:generateContent`)](#google-原生生成接口)
5. [客户端连接与启动命令](#5-客户端连接与启动命令)
   - [Claude Code 连接指南与命令](#claude-code-连接指南与命令)
   - [OpenAI Codex CLI 连接指南与命令](#openai-codex-cli-连接指南与命令)
   - [curl 示例 (Bash 与 PowerShell)](#curl-示例)
   - [OpenAI Python SDK 示例](#openai-python-sdk-示例)
6. [配置文件与高级特性](#6-配置文件与高级特性)
   - [配置文件 `config.json`](#配置文件-configjson)
   - [Pro 模型 Cookie 配置](#pro-模型-cookie-配置)
   - [网络代理设置](#网络代理设置)
7. [状态码与故障排查](#7-状态码与故障排查)

---

## 1. 基础服务地址与端点概览

- **默认端口**: `8081`（可通过 `--port` 或 `config.json` 修改）
- **默认监听**: `0.0.0.0`（本机可通过 `http://127.0.0.1:8081` 或 `http://localhost:8081` 访问）

| 客户端协议类型 | 推荐 Base URL |
| :--- | :--- |
| **OpenAI 兼容客户端 / Codex CLI** | `http://localhost:8081/v1` |
| **Anthropic 客户端 / Claude Code** | `http://localhost:8081` 或 `http://localhost:8081/v1` |
| **Google Gemini CLI** | `http://localhost:8081` |

> [!TIP]
> 服务端对请求路径做了容错处理。无论客户端是否携带 `/v1` 前缀（如 `/chat/completions` 与 `/v1/chat/completions`、`/messages` 与 `/v1/messages`），均能被正确路由。

---

## 2. 鉴权方式

鉴权由 `config.json` 中的 `"api_keys"` 数组决定：

```json
{
  "api_keys": ["sk-gemini"]
}
```

- **免密模式**：当 `"api_keys": []` 时，任何客户端无需提供 API Key 即可使用。
- **校验模式**：当配置了一个或多个密钥时，客户端必须通过以下任一方式传递有效密钥：
  1. `Authorization: Bearer <key>`（标准 Bearer Token）
  2. `x-api-key: <key>`（Anthropic 及 OpenAI 标准 Header）
  3. `x-goog-api-key: <key>`（Google 原生 Header）
  4. URL 查询参数 `?key=<key>`（Gemini CLI 格式）

---

## 3. 可用模型与别名映射

Gemini 网页端通过 `MODE_CATEGORY` 区分生成模式：
- `1` = FAST（闪速模式，对应 Gemini 3.7 Flash / 3.6 Flash）
- `2` = THINKING（扩展思考，最长可输出 20,000+ 字符）
- `3` = PRO（Gemini Pro，需 Cookie 认证）
- `4` = AUTO（后端自动判定）
- `5` = FAST_DYNAMIC_THINKING（自适应动态思考）
- `6` = FLASH_LITE（极速轻量）

### 思考深度控制 (`@think=N`)

任意模型名后追加 `@think=N` 可精确调整思考深度：

| 后缀 | 深度等级 | 预估输出量 | 最佳应用场景 |
| :--- | :--- | :--- | :--- |
| `@think=0` | **最深思考** | ~20,000+ 字符 | 复杂架构设计、疑难代码排查、数学推导 |
| `@think=2` | **中等思考** | ~15,000 字符 | 日常编码开发、代码重构、代码审查 |
| `@think=4` | **最浅思考** | ~10,000 字符 | 快速对话、Shell 命令查询、简要概念解释 |

*示例*: `gemini-3.5-flash-thinking@think=0` 或 `claude-3-7-sonnet-20250219@think=2`。

### 完整模型表

| 模型标识 | 模式代号 | 默认思考等级 | 映射目标 | 说明 |
| :--- | :--- | :--- | :--- | :--- |
| **`gemini-3.7-flash`** | 1 | 4 | Gemini 3.7 Flash | 最新全能旗舰 Flash 模型 |
| **`gemini-3.6-flash`** | 1 | 4 | Gemini 3.6 Flash | 高性能日常模型 |
| **`gemini-3.5-flash`** | 1 | 4 | Gemini 3.6 Flash | 兼容性别名 |
| **`gemini-3.5-flash-thinking`** | 2 | 0 | Flash Thinking | 强推理、超长输出 (**~2万字**) |
| **`gemini-3.5-flash-thinking-lite`** | 5 | 0 | Dynamic Think | 动态自适应思考 |
| **`gemini-3.1-pro`** | 3 | 4 | Gemini 3.1 Pro | 需付费 Google Advanced Cookie |
| **`gemini-auto`** | 4 | 4 | Auto | 自动选型 |
| **`gemini-flash-lite`** | 6 | 4 | Flash Lite | 最低延迟轻量模型 |
| **`claude-3-7-sonnet-20250219`** | 1 | 4 | Gemini 3.7 Flash | **Claude Code 默认模型** |
| **`claude-3-7-sonnet-latest`** | 1 | 4 | Gemini 3.7 Flash | Claude 别名 |
| **`claude-3-5-sonnet-20241022`** | 1 | 4 | Gemini 3.7 Flash | Claude 别名 |
| **`claude-3-5-haiku-20241022`** | 1 | 4 | Gemini 3.6 Flash | Claude 轻量别名 |
| **`claude-3-opus-20240229`** | 2 | 0 | Flash Thinking | Claude 思考别名 |
| **`gpt-4o`** | 1 | 4 | Gemini 3.7 Flash | OpenAI 常用别名 |
| **`gpt-4o-mini`** | 1 | 4 | Gemini 3.6 Flash | OpenAI 轻量别名 |
| **`o3-mini`** | 2 | 0 | Flash Thinking | **Codex 思考别名** |
| **`o1`** | 2 | 0 | Flash Thinking | OpenAI 思考别名 |
| **`codex`** | 1 | 4 | Gemini 3.7 Flash | **OpenAI Codex CLI 别名** |

---

## 4. 接口详细参考

### 健康检查与状态

#### `GET /` 或 `GET /api/hello` 或 `GET /health`

**请求示例:**
```bash
curl http://localhost:8081/
```

**响应 (200 OK):**
```json
{
  "status": "ok",
  "version": "1.1.0",
  "models": ["gemini-3.7-flash", "gemini-3.5-flash-thinking", "claude-3-7-sonnet-20250219", "codex", "o3-mini"]
}
```

---

### OpenAI 聊天补全 (`/v1/chat/completions`)

#### `POST /v1/chat/completions`

完全兼容 OpenAI Chat Completions 规范。

**支持特性:**
- 流式输出（SSE，`"stream": true`）
- 工具调用（Function Calling，`"tools": [...]`）
- 多模态图片输入（支持 Base64 Data URL 与 HTTP 图片直链）

**curl 示例:**
```bash
curl http://localhost:8081/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer sk-gemini" \
  -d '{
    "model": "gemini-3.7-flash",
    "messages": [
      {"role": "user", "content": "你好，请介绍一下 Python 协程"}
    ]
  }'
```

---

### OpenAI Responses API (`/v1/responses` - Codex CLI)

#### `POST /v1/responses`

专为 **OpenAI Codex CLI** (`codex`) 与最新 OpenAI Agent 框架实现的 Responses 协议端点。

**支持格式:**
- 单一文本输入与结构化 `input` 数组
- `function_call` 与 `function_call_output` 历史回填
- 包含 `response.created`、`response.output_item.added`、`response.output_text.delta`、`response.completed` 的完整 SSE 事件流

**curl 示例:**
```bash
curl http://localhost:8081/v1/responses \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer sk-gemini" \
  -d '{
    "model": "codex",
    "instructions": "你是一个资深全栈工程师。",
    "input": "编写一个检测 8081 端口是否启动的 PowerShell 脚本"
  }'
```

---

### Anthropic Messages API (`/v1/messages` - Claude Code)

#### `POST /v1/messages`

专为 **Claude Code** (`claude` CLI) 实现的 Anthropic Messages 接口规范。

**支持特性:**
- 完整支持 Claude 系统的 `system` 指令与多轮对话历史
- 完整支持 Claude Code 的工具交互调用协议（`tool_use` 与 `tool_result`）
- 完整支持 Anthropic 规范的流式事件（`message_start`、`content_block_start`、`content_block_delta`、`content_block_stop`、`message_delta`、`message_stop`）

**curl 示例:**
```bash
curl http://localhost:8081/v1/messages \
  -H "Content-Type: application/json" \
  -H "x-api-key: sk-gemini" \
  -H "anthropic-version: 2023-06-01" \
  -d '{
    "model": "claude-3-7-sonnet-20250219",
    "max_tokens": 1024,
    "messages": [
      {"role": "user", "content": "测试 Claude Code 接口！"}
    ]
  }'
```

---

### Anthropic Token 统计 (`/v1/messages/count_tokens`)

#### `POST /v1/messages/count_tokens`

Claude Code 在执行任务前评估上下文长度时调用的标准接口。

---

### OpenAI 模型列表 (`/v1/models`)

#### `GET /v1/models`

返回标准 OpenAI 模型清单，供 Codex、Cursor、Cherry Studio 等客户端自动检测。

---

## 5. 客户端连接与启动命令

### Claude Code 连接指南与命令

Claude Code 需要配置以下 3 个环境变量：
- `ANTHROPIC_BASE_URL`: `http://127.0.0.1:8081`
- `ANTHROPIC_AUTH_TOKEN`: `sk-gemini`
- `ANTHROPIC_MODEL`: `gemini-3.7-flash` (或 `claude-3-7-sonnet-20250219`)

#### 方式 1: 使用内置一键连接脚本（仓库已自带）

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

##### Windows CMD (命令提示符):
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

#### 方式 3: 配置文件持久化 (`~/.claude/settings.json`)

在 `~/.claude/settings.json`（Windows 为 `%USERPROFILE%\.claude\settings.json`）中写入：

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

### OpenAI Codex CLI 连接指南与命令

Codex CLI 使用 `/v1` 端点。

#### 方式 1: 使用内置一键连接脚本

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

#### 方式 2: 终端命令

##### Windows PowerShell:
```powershell
$env:OPENAI_BASE_URL="http://127.0.0.1:8081/v1"
$env:OPENAI_API_BASE="http://127.0.0.1:8081/v1"
$env:OPENAI_API_KEY="sk-gemini"
$env:CODEX_API_BASE="http://127.0.0.1:8081/v1"
$env:CODEX_MODEL="gemini-3.7-flash"
codex
```

永久写入用户变量：
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

### curl 示例

#### Windows PowerShell:
```powershell
curl.exe --% http://127.0.0.1:8081/v1/chat/completions -H "Content-Type: application/json" -H "Authorization: Bearer sk-gemini" -d "{\"model\":\"gemini-3.7-flash\",\"messages\":[{\"role\":\"user\",\"content\":\"Hello\"}]}"
```

---

### OpenAI Python SDK 示例

```python
from openai import OpenAI

client = OpenAI(
    base_url="http://localhost:8081/v1",
    api_key="sk-gemini"
)

resp = client.chat.completions.create(
    model="gemini-3.5-flash-thinking",
    messages=[{"role": "user", "content": "如何写出高效的 Python 代码？"}]
)

print(resp.choices[0].message.content)
```

---

## 6. 配置文件与高级特性

### 配置文件 `config.json`

在服务同目录下创建 `config.json`：

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

- 将 `temporary_chats` 设为 `true`，可使用 Gemini 网页端临时聊天模式，不记录到账号历史。
- `api_keys` 为 `[]` 时关闭密码校验。

---

### Pro 模型 Cookie 配置

匿名访问下 `gemini-3.1-pro` 会回退到 Flash。要使用真实 Pro 路由，需要配置 **Gemini Advanced 付费账号** Cookie：

1. 浏览器登录已开通 Advanced 的 Google 账号，打开 [gemini.google.com](https://gemini.google.com)
2. 按 `F12` -> Application -> Cookies -> `https://gemini.google.com`
3. 复制 `SID`, `HSID`, `SSID`, `APISID`, `SAPISID`, `__Secure-1PSID` 的值
4. 创建 `cookie.txt`：
   ```text
   SID=...; HSID=...; SSID=...; APISID=...; SAPISID=...; __Secure-1PSID=...
   ```
5. 启动时加上 `--cookie-file cookie.txt` 即可。

---

### 网络代理设置

若直接连接 `gemini.google.com` 超时，可配置 HTTP 代理：
```bash
python gemini_web2api.py --proxy http://127.0.0.1:7890
```
或直接在 `config.json` 中配置 `"proxy": "http://127.0.0.1:7890"`。

---

## 7. 状态码与故障排查

| 状态码 | 含义 | 原因与处理建议 |
| :--- | :--- | :--- |
| **`200 OK`** | 请求成功 | 接口正常返回 |
| **`400 Bad Request`** | 参数错误 | 请求 JSON 格式不合法、prompt 为空或思考级别 `@think` 数值不正确 |
| **`401 Unauthorized`** | 鉴权失败 | 客户端提供的 Key 与 `config.json` 中的 `api_keys` 不匹配 |
| **`404 Not Found`** | 接口未找到 | 确认路径是否正确 |
| **`500 Internal Error`** | 服务端异常 | 代理服务内部解析异常 |
| **`502 Bad Gateway`** | 上游异常 | Google Gemini 网页端限制或返回 `BardErrorInfo`，服务会自动重试 |
