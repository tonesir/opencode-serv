# Opencode Serv (VBS Script) - Implementation Plan & Status

## Project Overview
**Opencode Serv** (formerly `opencode_launcher.vbs`) is a dedicated Windows management script for `opencode serve`. It solves the issue of port conflicts (specifically port 3737) when the service crashes, allowing for one-click startup, auto-recovery, and background execution without visible console windows.

---

## Final Features
- **Hidden Execution**: Runs `opencode serve` in the background (no black command window).
- **Auto-Recovery**: Automatically detects if Port 3737 is occupied by a zombie process.
- **Smart Cleanup**:
  - Tries graceful shutdown first (using `taskkill /T`).
  - Waits 3 seconds.
  - If still running, prompts user to force kill.
  - Cleans up entire process tree to prevent orphan Node.js processes.
- **Health Check**:
  - Uses `netstat` to find PID.
  - Uses `HTTP GET` to verify service responsiveness.
  - Polling mechanism (up to 10s) after startup to ensure success.
- **Flexible Parameters**:
  - `(No args)`: Start on Port 3737 (Silent mode for startup).
  - `[Port]`: Start on custom Port (Manual mode with success dialog).
  - `stop`: Stop Port 3737.
  - `stop [Port]`: Stop custom Port.
- **Startup Integration**: Installed directly into Windows Startup folder.

---

## File Structure
- `opencode_srv.vbs`: Main script (Logic + Execution).
- Location: `C:\Users\Tones\Develop\Opencode-Serv\` AND `shell:startup`

---

## Implementation History

### Phase 1: Core Logic
- [x] Implemented `GetPidOnPort` using `netstat`.
- [x] Implemented `StartService` using `WScript.Shell.Run` (hidden).
- [x] Added `HandlePortCleanup` with graceful/force kill logic.

### Phase 2: Refinement
- [x] Renamed to `opencode_srv.vbs`.
- [x] Added parameter support (`stop`, custom port).
- [x] Enhanced cleanup with `/T` (Tree Kill) to handle Node.js child processes.
- [x] Fixed VBScript syntax errors (removed Chinese comments to prevent encoding issues).

### Phase 3: Deployment
- [x] Added HTTP Polling to verify startup success.
- [x] Implemented Silent Mode logic (silent on default start, alert on failure).
- [x] Deployed directly to Windows Startup folder.

---

## Usage Guide

### 1. Manual Start
Double-click `opencode_srv.vbs` in the folder.
- Starts on Port 3737.
- Silent success (unless failure occurs).

### 2. Custom Port
Run from command line:
```cmd
cscript //nologo opencode_srv.vbs 4000
```
- Starts on Port 4000.
- Shows "Success" dialog upon completion.

### 3. Stop Service
Run from command line:
```cmd
cscript //nologo opencode_srv.vbs stop
```
- Stops service on Port 3737.

---

## Verification Status
- [x] Port 3737 startup verified.
- [x] Zombie process cleanup verified.
- [x] Startup folder deployment verified.
