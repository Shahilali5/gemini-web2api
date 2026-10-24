#!/usr/bin/env bash
# ==============================================================================
# gemini-web2api VPS Easy Installer & Systemd Service Setup
# Repository: https://github.com/Shahilali5/gemini-web2api
# Author: Shahil Ali (https://github.com/Shahilali5)
# ==============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

echo -e "${CYAN}${BOLD}"
echo "=========================================================="
echo "    🚀 gemini-web2api VPS Auto Installer & Setup          "
echo "    Maintained by Shahilali5 (https://github.com/Shahilali5)"
echo "=========================================================="
echo -e "${NC}"

# 1. Require root or sudo privileges
SUDO=""
if [ "$(id -u)" != "0" ]; then
    if command -v sudo >/dev/null 2>&1; then
        SUDO="sudo"
        echo -e "${YELLOW}[!] Non-root user detected. Using sudo for system tasks.${NC}"
    else
        echo -e "${RED}[ERROR] This script requires root privileges or sudo to configure systemd.${NC}"
        exit 1
    fi
fi

# 2. Detect Package Manager & Install System Prerequisites
echo -e "${CYAN}[1/6] Checking system dependencies...${NC}"
if command -v apt-get >/dev/null 2>&1; then
    $SUDO apt-get update -y
    $SUDO apt-get install -y python3 python3-pip python3-venv git curl
elif command -v dnf >/dev/null 2>&1; then
    $SUDO dnf install -y python3 python3-pip git curl
elif command -v yum >/dev/null 2>&1; then
    $SUDO yum install -y python3 python3-pip git curl
elif command -v pacman >/dev/null 2>&1; then
    $SUDO pacman -Sy --noconfirm python python-pip git curl
elif command -v apk >/dev/null 2>&1; then
    $SUDO apk update
    $SUDO apk add python3 py3-pip git curl bash
else
    echo -e "${YELLOW}[WARN] Could not detect package manager. Ensure Python 3.8+ and git are installed.${NC}"
fi

# 3. Determine Repository Location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || echo "")"
DEFAULT_INSTALL_DIR="/opt/gemini-web2api"

if [ -f "$SCRIPT_DIR/gemini_web2api.py" ]; then
    INSTALL_DIR="$SCRIPT_DIR"
    echo -e "${GREEN}[OK] Running inside existing repo: $INSTALL_DIR${NC}"
else
    INSTALL_DIR="$DEFAULT_INSTALL_DIR"
    echo -e "${CYAN}[2/6] Cloning gemini-web2api into $INSTALL_DIR...${NC}"
    if [ -d "$INSTALL_DIR/.git" ]; then
        echo -e "${YELLOW}[*] Existing repository found at $INSTALL_DIR. Pulling latest...${NC}"
        cd "$INSTALL_DIR"
        git pull origin main || true
    else
        $SUDO mkdir -p "$INSTALL_DIR"
        $SUDO chown -R "$(id -u):$(id -g)" "$INSTALL_DIR"
        git clone https://github.com/Shahilali5/gemini-web2api.git "$INSTALL_DIR"
    fi
fi

cd "$INSTALL_DIR"

# 4. Set Up Python Virtual Environment
echo -e "${CYAN}[3/6] Setting up Python virtual environment...${NC}"
if [ ! -d "venv" ]; then
    python3 -m venv venv || {
        echo -e "${RED}[ERROR] Failed to create virtual environment. Ensure python3-venv is installed.${NC}"
        exit 1
    }
fi

echo -e "${CYAN}[4/6] Installing dependencies...${NC}"
"$INSTALL_DIR/venv/bin/pip" install --upgrade pip -q
"$INSTALL_DIR/venv/bin/pip" install -r requirements.txt -q

# 5. Initialize config.json if not present
if [ ! -f "config.json" ]; then
    if [ -f "config.example.json" ]; then
        cp config.example.json config.json
        echo -e "${GREEN}[OK] Created config.json from config.example.json${NC}"
    fi
fi

# 6. Configure Systemd Service
SERVICE_FILE="/etc/systemd/system/gemini-web2api.service"
CURRENT_USER="$(id -un)"

if command -v systemctl >/dev/null 2>&1; then
    echo -e "${CYAN}[5/6] Creating systemd service ($SERVICE_FILE)...${NC}"
    $SUDO bash -c "cat > '$SERVICE_FILE'" <<EOF
[Unit]
Description=gemini-web2api Proxy Server
After=network.target

[Service]
Type=simple
User=$CURRENT_USER
WorkingDirectory=$INSTALL_DIR
ExecStart=$INSTALL_DIR/venv/bin/python $INSTALL_DIR/gemini_web2api.py
Restart=always
RestartSec=5
Environment=PYTHONUNBUFFERED=1
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

    echo -e "${CYAN}[6/6] Enabling and starting gemini-web2api service...${NC}"
    $SUDO systemctl daemon-reload
    $SUDO systemctl enable gemini-web2api.service
    $SUDO systemctl restart gemini-web2api.service

    sleep 2

    # Health check
    if curl -s http://127.0.0.1:8081/ >/dev/null 2>&1 || curl -s http://127.0.0.1:8081/health >/dev/null 2>&1; then
        echo -e "${GREEN}${BOLD}[SUCCESS] gemini-web2api is up and running!${NC}"
    else
        echo -e "${YELLOW}[!] Service started. Check logs if it doesn't respond yet: journalctl -u gemini-web2api -f${NC}"
    fi
else
    echo -e "${YELLOW}[WARN] systemd not found. Starting in background via nohup...${NC}"
    nohup "$INSTALL_DIR/venv/bin/python" gemini_web2api.py > gemini.log 2>&1 &
    echo -e "${GREEN}[OK] Started in background (PID: $!). Logs in gemini.log${NC}"
fi

# 7. Get Public IP for convenience
PUBLIC_IP=$(curl -s -m 3 https://ifconfig.me 2>/dev/null || curl -s -m 3 https://api.ipify.org 2>/dev/null || echo "YOUR_VPS_IP")

echo ""
echo -e "${GREEN}${BOLD}==========================================================${NC}"
echo -e "${GREEN}${BOLD}   🎉 Installation Complete! gemini-web2api is ready!     ${NC}"
echo -e "${GREEN}${BOLD}==========================================================${NC}"
echo ""
echo -e "${BOLD}Local Address:${NC}  http://127.0.0.1:8081"
echo -e "${BOLD}Public Address:${NC} http://${PUBLIC_IP}:8081"
echo -e "${BOLD}Install Dir:${NC}    $INSTALL_DIR"
echo ""
echo -e "${CYAN}${BOLD}Useful Management Commands:${NC}"
echo -e "  Check Status:   ${YELLOW}sudo systemctl status gemini-web2api${NC}"
echo -e "  View Live Logs: ${YELLOW}sudo journalctl -u gemini-web2api -f${NC}"
echo -e "  Restart Server: ${YELLOW}sudo systemctl restart gemini-web2api${NC}"
echo -e "  Stop Server:    ${YELLOW}sudo systemctl stop gemini-web2api${NC}"
echo ""
echo -e "${CYAN}${BOLD}Connect Claude Code to this VPS:${NC}"
echo -e "  export ANTHROPIC_BASE_URL=\"http://${PUBLIC_IP}:8081\""
echo -e "  export ANTHROPIC_AUTH_TOKEN=\"sk-gemini\""
echo -e "  export ANTHROPIC_MODEL=\"gemini-3.7-flash\""
echo -e "  claude"
echo ""
echo -e "${CYAN}${BOLD}Connect OpenAI Codex CLI to this VPS:${NC}"
echo -e "  export OPENAI_BASE_URL=\"http://${PUBLIC_IP}:8081/v1\""
echo -e "  export OPENAI_API_BASE=\"http://${PUBLIC_IP}:8081/v1\""
echo -e "  export OPENAI_API_KEY=\"sk-gemini\""
echo -e "  export CODEX_API_BASE=\"http://${PUBLIC_IP}:8081/v1\""
echo -e "  export CODEX_MODEL=\"gemini-3.7-flash\""
echo -e "  codex"
echo ""
echo -e "${CYAN}GitHub Repository: ${BOLD}https://github.com/Shahilali5/gemini-web2api${NC}"
echo -e "${CYAN}Author: ${BOLD}Shahil Ali (@Shahilali5)${NC}"
echo "=========================================================="
