# 🛡️ All-in-One CyberSecurity Suite

A unified, modular, 1-command deployment and scanning suite combining premier open-source cybersecurity tools into a single workflow.

---

## 🧰 Included Tools

| Tool | Category | Interface / Endpoint | Description |
|---|---|---|---|
| **PentAGI** | AI Agent Pentesting | `https://localhost:8443` | Autonomous LLM-driven security agent running Kali Linux tools inside isolated Docker containers. |
| **OWASP ZAP** | Dynamic DAST Scanner | `http://localhost:8080/zap/` | World's most popular open-source web application scanner (Web GUI & baseline CLI scans). |
| **0security** | Static SAST Sentinels | CLI / Markdown Reports | 6 adversarial sentinels scanning source code for CVEs, injection, secrets, and SSRF flaws. |
| **SafeLine WAF** | Defense & Protection | `https://localhost:9443` | High-performance open-source Web Application Firewall with AI semantic analysis. |
| **Shannon** | Exploit Hunter | CLI / Automated Agent | Autonomous agent designed to discover zero-days and verify vulnerabilities. |
| **REA** | Reverse Engineering | CLI / WebMCP / API | Reverse Engineer Anything: Native binaries, managed runtimes (.NET/Java), Electron, and firmware. |
| **Security Audit Skill** | Methodology & Rules | `SKILL.md` / Checklist | Production 6-Phase security audit framework used by top security teams. |

---

## ⚡ Quick Start (Any Machine)

### 1. Prerequisites
* **Docker Desktop** (or Docker Engine + Docker Compose) installed and running.

---

### 2. Windows Setup (1-Command)

Open PowerShell or Command Prompt:
```cmd
git clone https://github.com/sami9dev/cybersec-suite.git
cd cybersec-suite
start.bat
```
*(Or simply double-click `start.bat` in Windows File Explorer)*.

---

### 3. Linux / macOS Setup (1-Command)

```bash
git clone https://github.com/sami9dev/cybersec-suite.git
cd cybersec-suite
chmod +x start.sh && ./start.sh
```

---

## 🖥️ Interactive Master Menu

When you launch `start.bat` or `start.sh`, you get an interactive menu:

```text
================================================================
             ALL-IN-ONE CYBERSECURITY SUITE
================================================================

  [1] Launch PentAGI          (Autonomous AI Multi-Agent Pentester)
  [2] Launch OWASP ZAP Web UI (DAST Security Scanner - Port 8080)
  [3] Run ZAP Target Scan     (Headless DAST baseline audit)
  [4] Launch SafeLine WAF     (Intelligent Web Application Firewall)
  [5] Run 0security Scanner   (Static SAST Sentinels & CVE Checker)
  [6] Launch REA              (Reverse Engineer Anything - Binaries & WebMCP)
  [7] Security Audit Guide    (6-Phase Adversarial Security Audit Skill)
  [8] Start Everything        (PentAGI + ZAP + SafeLine)
  [9] Stop All Services       (docker compose down across all tools)
  [0] Exit
================================================================
```

---

## 🔑 AI Key Configuration (.env)

Edit the root `.env` file to add your API keys:
```env
GEMINI_API_KEY=your_gemini_key_here
OPEN_AI_KEY=your_openai_key_here
TARGET_URL=https://your-website.com
```

---

## 📊 Reports Directory

All automated scans (ZAP baseline, 0security audit, exploit verifications) generate clean HTML / Markdown reports inside the `reports/` folder:
* `reports/zap-report.html` — Dynamic vulnerabilities, missing security headers, cookie flags.
* `reports/0security-report.md` — Source code vulnerabilities, injection points, insecure dependencies.
