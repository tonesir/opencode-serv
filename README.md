# Opencode Serv (Windows Launcher)

A lightweight, robust VBScript launcher designed to manage `opencode serve` on Windows. It solves common issues like port conflicts (zombie processes) and provides a clean, background execution experience.

## Files

- **`opencode_srv.vbs`**: The main script. Handles starting, stopping, and monitoring the service.

## Features

- **🚀 One-Click Start**: Launches `opencode serve` in the background (no visible console window).
- **🛡️ Auto-Recovery**: Automatically detects if Port 3737 is occupied by a dead process and cleans it up.
- **🧹 Smart Cleanup**: Uses "Tree Kill" (`taskkill /T`) to ensure no orphan Node.js processes are left behind.
- **🤫 Silent Mode**: Default startup is silent (perfect for Windows Startup), only alerting on errors.
- **⚙️ Flexible Control**: Supports custom ports and manual stop commands.
- **📝 Logging**: Supports an optional `log` parameter to create a detailed execution log (`opencode_srv.log`).

## Installation (Auto-Start)

To make Opencode Serve start automatically with Windows:

1. Press `Win + R` on your keyboard.
2. Type `shell:startup` and press Enter.
3. Copy the `opencode_srv.vbs` file into this folder.
4. **Done!** The service will now start silently on every boot.

## Usage

### 1. Default Start (Port 3737)
Simply double-click `opencode_srv.vbs`.
- **Behavior**: Checks Port 3737. If free, starts the service silently.
- **Feedback**: No popup on success (Silent Mode). Popups only on error or if restart is needed.

### 2. Start on Custom Port
Open Command Prompt (cmd) or PowerShell and run:
```cmd
cscript //nologo opencode_srv.vbs 4000
```
- **Behavior**: Starts service on Port 4000.
- **Feedback**: Displays a "Success" dialog when the service is ready.

### 3. Stop Service
To cleanly stop the background service:
```cmd
cscript //nologo opencode_srv.vbs stop
```
- **Behavior**: Finds the process using Port 3737 and terminates it (gracefully first, then force if needed).

To stop a custom port:
```cmd
cscript //nologo opencode_srv.vbs stop 4000
```

### 4. Enabling Logging
To troubleshoot or see the script's actions in detail, you can add the `log` parameter to any command. This will create an `opencode_srv.log` file in the same directory.

Example:
```cmd
cscript //nologo opencode_srv.vbs 4000 log
```

Or when stopping:
```cmd
cscript //nologo opencode_srv.vbs stop log
```

## How It Works

1. **Check**: It looks for any process listening on the target port using `netstat`.
2. **Health**: If occupied, it pings `http://localhost:[port]/` to see if it's responsive.
   - If responsive: Asks if you want to restart.
   - If unresponsive: Automatically kills the zombie process tree.
3. **Launch**: Runs `opencode serve` using `WScript.Shell` with window style `0` (Hidden).
4. **Verify**: Polls the HTTP endpoint for up to 10 seconds to ensure the service is actually up.

## License

MIT
