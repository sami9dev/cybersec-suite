@echo off
setlocal enabledelayedexpansion

echo ================================================================
echo             CYBERSECURITY SUITE - HEALTH CHECK
echo ================================================================
echo.

:: 1. Check Docker
docker info >nul 2>&1
if %errorlevel% equ 0 (
    echo [✓] Docker Daemon:       RUNNING
) else (
    echo [X] Docker Daemon:       STOPPED / NOT CONNECTED
)

:: 2. Check PentAGI (port 8443)
curl.exe -k -s -I -m 2 https://127.0.0.1:8443 >nul 2>&1
if %errorlevel% equ 0 (
    echo [✓] PentAGI Console:     ONLINE  (https://localhost:8443)
) else (
    echo [ ] PentAGI Console:     OFFLINE (Port 8443)
)

:: 3. Check OWASP ZAP (port 8080)
curl.exe -s -I -m 2 http://127.0.0.1:8080 >nul 2>&1
if %errorlevel% equ 0 (
    echo [✓] OWASP ZAP Web UI:    ONLINE  (http://localhost:8080/zap/)
) else (
    echo [ ] OWASP ZAP Web UI:    OFFLINE (Port 8080)
)

:: 4. Check SafeLine WAF (port 9443)
curl.exe -k -s -I -m 2 https://127.0.0.1:9443 >nul 2>&1
if %errorlevel% equ 0 (
    echo [✓] SafeLine WAF:        ONLINE  (https://localhost:9443)
) else (
    echo [ ] SafeLine WAF:        OFFLINE (Port 9443)
)

echo.
echo ================================================================
pause
