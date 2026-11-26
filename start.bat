@echo off
setlocal enabledelayedexpansion
title All-in-One CyberSecurity Suite

:MENU
cls
echo ================================================================
echo             ALL-IN-ONE CYBERSECURITY SUITE
echo ================================================================
echo.
echo   [1] Launch PentAGI          (Autonomous AI Multi-Agent Pentester)
echo   [2] Launch OWASP ZAP Web UI (DAST Security Scanner - Port 8080)
echo   [3] Run ZAP Target Scan     (Headless DAST baseline audit)
echo   [4] Launch SafeLine WAF     (Intelligent Web Application Firewall)
echo   [5] Run 0security Scanner   (Static SAST Sentinels & CVE Checker)
echo   [6] Launch REA              (Reverse Engineer Anything - Binaries & WebMCP)
echo   [7] Security Audit Guide    (6-Phase Adversarial Security Audit Skill)
echo   [8] Start Everything        (PentAGI + ZAP + SafeLine)
echo   [9] Stop All Services       (docker compose down across all tools)
echo   [0] Exit
echo.
echo ================================================================
set /p CHOICE="Enter your choice (0-9): "

if "%CHOICE%"=="1" goto PENTAGI
if "%CHOICE%"=="2" goto ZAP_WEB
if "%CHOICE%"=="3" goto ZAP_SCAN
if "%CHOICE%"=="4" goto SAFELINE
if "%CHOICE%"=="5" goto ZEROSEC
if "%CHOICE%"=="6" goto REA_TOOL
if "%CHOICE%"=="7" goto SEC_AUDIT
if "%CHOICE%"=="8" goto START_ALL
if "%CHOICE%"=="9" goto STOP_ALL
if "%CHOICE%"=="0" exit /b 0

echo Invalid choice. Please select 0-9.
timeout /t 2 >nul
goto MENU

:CHECK_DOCKER
docker info >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Docker daemon is not running!
    echo Please start Docker Desktop and wait until 'Engine running' appears.
    pause
    goto MENU
)
exit /b 0

:CHECK_ENV
if not exist .env (
    if exist .env.example (
        copy .env.example .env >nul
        echo [INFO] Created .env from .env.example
    )
)
exit /b 0

:PENTAGI
call :CHECK_DOCKER
call :CHECK_ENV
echo.
echo [*] Starting PentAGI...
cd tools\pentagi
if not exist .env (
    if exist ..\..\.env copy ..\..\.env .env >nul
)
powershell -Command "(Get-Content .env) -replace 'DOCKER_HOST=npipe:////./pipe/dockerDesktopLinuxEngine', 'DOCKER_HOST=unix:///var/run/docker.sock' | Set-Content .env -Encoding UTF8"
docker compose up -d
cd ..\..
echo.
echo [OK] PentAGI is live!
echo URL: https://localhost:8443
echo Login: admin@pentagi.com / admin
echo.
pause
goto MENU

:ZAP_WEB
call :CHECK_DOCKER
echo.
echo [*] Starting OWASP ZAP Web UI...
cd tools\zap
docker compose up -d zap-web
cd ..\..
echo.
echo [OK] OWASP ZAP Web UI is ready!
echo URL: http://localhost:8080/zap/
echo.
pause
goto MENU

:ZAP_SCAN
call :CHECK_DOCKER
call :CHECK_ENV
echo.
set /p SCAN_TARGET="Enter target URL to scan (e.g. http://localhost:3000): "
if "%SCAN_TARGET%"=="" set SCAN_TARGET=http://host.docker.internal:3000
echo [*] Running ZAP Baseline scan against %SCAN_TARGET%...
if not exist reports mkdir reports
docker run --rm -v "%cd%\reports:/zap/wrk/:rw" zaproxy/zap-stable:latest zap-baseline.py -t "%SCAN_TARGET%" -r zap-report.html -I
echo.
echo [OK] Scan finished! Report saved to reports\zap-report.html
pause
goto MENU

:SAFELINE
call :CHECK_DOCKER
echo.
echo [*] Starting SafeLine WAF...
cd tools\safeline
docker compose up -d
cd ..\..
echo.
echo [OK] SafeLine WAF is running!
echo URL: https://localhost:9443
echo.
pause
goto MENU

:ZEROSEC
echo.
echo [*] Running 0security SAST scanner...
if not exist reports mkdir reports
npx -y 0security scan . --output reports\0security-report.md
echo.
echo [OK] SAST scan complete. Report saved to reports\0security-report.md
pause
goto MENU

:REA_TOOL
echo.
echo [*] Launching REA (Reverse Engineer Anything)...
cd tools\rea
npm run build >nul 2>&1
npm start
cd ..\..
pause
goto MENU

:SEC_AUDIT
cls
echo ================================================================
echo             6-PHASE SECURITY AUDIT METHODOLOGY
echo ================================================================
echo.
echo  Phase 1: Surface Reconnaissance (Endpoints, routes, APIs, CSP)
echo  Phase 2: Static Analysis SAST   (SQLi, SSRF, IDOR, Auth bypass)
echo  Phase 3: Dynamic Fuzzing DAST   (ZAP, Parameter Tampering)
echo  Phase 4: Secret & Env Audit     (Leaked tokens, credentials, JWKs)
echo  Phase 5: Business Logic Flaws   (Rate limits, privilege escalation)
echo  Phase 6: Verification Gate      (Zero-false-positive repro proof)
echo.
echo Full instructions located at: tools\security-audit\skills\security-audit\SKILL.md
echo ================================================================
pause
goto MENU

:START_ALL
call :CHECK_DOCKER
call :CHECK_ENV
echo.
echo [*] Starting PentAGI, ZAP Web UI, and SafeLine WAF...
cd tools\pentagi
if not exist .env copy ..\..\.env .env >nul
powershell -Command "(Get-Content .env) -replace 'DOCKER_HOST=npipe:////./pipe/dockerDesktopLinuxEngine', 'DOCKER_HOST=unix:///var/run/docker.sock' | Set-Content .env -Encoding UTF8"
docker compose up -d
cd ..\zap
docker compose up -d zap-web
cd ..\safeline
docker compose up -d
cd ..\..
echo.
echo [OK] All security services started!
echo - PentAGI:   https://localhost:8443 (admin@pentagi.com / admin)
echo - OWASP ZAP: http://localhost:8080/zap/
echo - SafeLine:  https://localhost:9443
echo.
pause
goto MENU

:STOP_ALL
call :CHECK_DOCKER
echo.
echo [*] Stopping all security services...
cd tools\pentagi
docker compose down >nul 2>&1
cd ..\zap
docker compose down >nul 2>&1
cd ..\safeline
docker compose down >nul 2>&1
cd ..\..
echo.
echo [OK] All security services have been stopped.
pause
goto MENU
