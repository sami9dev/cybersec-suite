#!/bin/bash
set -e

# ================================================================
#             ALL-IN-ONE CYBERSECURITY SUITE
# ================================================================

CHECK_DOCKER() {
    if ! command -v docker &> /dev/null; then
        echo "[ERROR] Docker is not installed or not in PATH!"
        exit 1
    fi
    if ! docker info &> /dev/null; then
        echo "[ERROR] Docker daemon is not running! Please start Docker first."
        exit 1
    fi
}

CHECK_ENV() {
    if [ ! -f .env ]; then
        if [ -f .env.example ]; then
            cp .env.example .env
            echo "[INFO] Created .env from .env.example"
        fi
    fi
}

while true; do
    clear
    echo "================================================================"
    echo "             ALL-IN-ONE CYBERSECURITY SUITE"
    echo "================================================================"
    echo ""
    echo "  [1] Launch PentAGI          (Autonomous AI Multi-Agent Pentester)"
    echo "  [2] Launch OWASP ZAP Web UI (DAST Security Scanner - Port 8080)"
    echo "  [3] Run ZAP Target Scan     (Headless DAST baseline audit)"
    echo "  [4] Launch SafeLine WAF     (Intelligent Web Application Firewall)"
    echo "  [5] Run 0security Scanner   (Static SAST Sentinels & CVE Checker)"
    echo "  [6] Start Everything        (PentAGI + ZAP + SafeLine)"
    echo "  [7] Stop All Services       (docker compose down across all tools)"
    echo "  [8] Exit"
    echo ""
    echo "================================================================"
    read -p "Enter your choice (1-8): " CHOICE

    case $CHOICE in
        1)
            CHECK_DOCKER
            CHECK_ENV
            echo ""
            echo "[*] Starting PentAGI..."
            cd tools/pentagi
            [ ! -f .env ] && cp ../../.env .env
            docker compose up -d
            cd ../..
            echo ""
            echo "[OK] PentAGI is live! https://localhost:8443 (admin@pentagi.com / admin)"
            read -p "Press Enter to return to menu..."
            ;;
        2)
            CHECK_DOCKER
            echo ""
            echo "[*] Starting OWASP ZAP Web UI..."
            cd tools/zap
            docker compose up -d zap-web
            cd ../..
            echo ""
            echo "[OK] OWASP ZAP Web UI ready! http://localhost:8080/zap/"
            read -p "Press Enter to return to menu..."
            ;;
        3)
            CHECK_DOCKER
            echo ""
            read -p "Enter target URL to scan (e.g. http://localhost:3000): " SCAN_TARGET
            [ -z "$SCAN_TARGET" ] && SCAN_TARGET="http://host.docker.internal:3000"
            mkdir -p reports
            docker run --rm -v "$(pwd)/reports:/zap/wrk/:rw" zaproxy/zap-stable:latest zap-baseline.py -t "$SCAN_TARGET" -r zap-report.html -I
            echo ""
            echo "[OK] Scan complete. Report saved to reports/zap-report.html"
            read -p "Press Enter to return to menu..."
            ;;
        4)
            CHECK_DOCKER
            echo ""
            echo "[*] Starting SafeLine WAF..."
            cd tools/safeline
            docker compose up -d
            cd ../..
            echo ""
            echo "[OK] SafeLine WAF running! https://localhost:9443"
            read -p "Press Enter to return to menu..."
            ;;
        5)
            echo ""
            echo "[*] Running 0security SAST scanner..."
            mkdir -p reports
            npx -y 0security scan . --output reports/0security-report.md
            read -p "Press Enter to return to menu..."
            ;;
        6)
            CHECK_DOCKER
            CHECK_ENV
            echo ""
            echo "[*] Starting PentAGI, ZAP Web UI, and SafeLine WAF..."
            cd tools/pentagi
            [ ! -f .env ] && cp ../../.env .env
            docker compose up -d
            cd ../zap
            docker compose up -d zap-web
            cd ../safeline
            docker compose up -d
            cd ../..
            echo ""
            echo "[OK] All security services started!"
            echo "- PentAGI:   https://localhost:8443"
            echo "- OWASP ZAP: http://localhost:8080/zap/"
            echo "- SafeLine:  https://localhost:9443"
            read -p "Press Enter to return to menu..."
            ;;
        7)
            CHECK_DOCKER
            echo ""
            echo "[*] Stopping all security services..."
            (cd tools/pentagi && docker compose down) 2>/dev/null || true
            (cd tools/zap && docker compose down) 2>/dev/null || true
            (cd tools/safeline && docker compose down) 2>/dev/null || true
            echo ""
            echo "[OK] All security services stopped."
            read -p "Press Enter to return to menu..."
            ;;
        8)
            exit 0
            ;;
        *)
            echo "Invalid choice. Please select 1-8."
            sleep 1
            ;;
    esac
done
