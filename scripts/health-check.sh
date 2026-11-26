#!/bin/bash

echo "================================================================"
echo "            CYBERSECURITY SUITE - HEALTH CHECK"
echo "================================================================"
echo ""

# 1. Docker
if docker info &> /dev/null; then
    echo "[✓] Docker Daemon:       RUNNING"
else
    echo "[X] Docker Daemon:       STOPPED / NOT CONNECTED"
fi

# 2. PentAGI
if curl -k -s -I -m 2 https://127.0.0.1:8443 &> /dev/null; then
    echo "[✓] PentAGI Console:     ONLINE  (https://localhost:8443)"
else
    echo "[ ] PentAGI Console:     OFFLINE (Port 8443)"
fi

# 3. ZAP
if curl -s -I -m 2 http://127.0.0.1:8080 &> /dev/null; then
    echo "[✓] OWASP ZAP Web UI:    ONLINE  (http://localhost:8080/zap/)"
else
    echo "[ ] OWASP ZAP Web UI:    OFFLINE (Port 8080)"
fi

# 4. SafeLine WAF
if curl -k -s -I -m 2 https://127.0.0.1:9443 &> /dev/null; then
    echo "[✓] SafeLine WAF:        ONLINE  (https://localhost:9443)"
else
    echo "[ ] SafeLine WAF:        OFFLINE (Port 9443)"
fi

echo ""
echo "================================================================"
