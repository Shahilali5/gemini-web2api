@echo off
cd /d "%~dp0"
echo Starting gemini-web2api server...
if exist "venv\Scripts\python.exe" (
    venv\Scripts\python.exe gemini_web2api.py
) else (
    python gemini_web2api.py
)
pause
