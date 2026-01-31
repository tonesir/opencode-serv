' Opencode Serve Launcher (Enhanced with Parameters & Logging)
' Function: One-click start/stop for opencode serve, auto port cleanup and health check.
' Parameters:
'   (No arg)         -> Start 3737 (Silent mode)
'   [Port]           -> Start specific Port (Show result)
'   stop             -> Stop 3737
'   stop [Port]      -> Stop specific Port
'   log              -> Can be added to any command to enable logging

Option Explicit

Dim shell, fso, logEnabled, logFile
Set shell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")
logEnabled = False

' Default settings
Dim targetPort, healthUrl, waitTime
targetPort = 3737
waitTime = 3000

Main

Sub Main()
    Dim pid, arg1, arg, mode
    mode = "START" ' Default mode

    ' Check for 'log' argument anywhere
    For Each arg In WScript.Arguments
        If LCase(arg) = "log" Then
            logEnabled = True
            Exit For
        End If
    Next

    If logEnabled Then
        Set logFile = fso.OpenTextFile("opencode_srv.log", 8, True) ' 8 = ForAppending, True = Create if not exists
        WriteLog "--- Script Start ---"
    End If

    ' Parse primary arguments
    If WScript.Arguments.Count > 0 Then
        arg1 = LCase(WScript.Arguments(0))
        
        If arg1 = "stop" Then
            mode = "STOP"
            If WScript.Arguments.Count > 1 Then
                If IsNumeric(WScript.Arguments(1)) Then
                    targetPort = CInt(WScript.Arguments(1))
                End If
            End If
        ElseIf IsNumeric(arg1) Then
            targetPort = CInt(arg1)
        End If
    End If

    healthUrl = "http://localhost:" & targetPort & "/"
    WriteLog "Mode: " & mode & ", Port: " & targetPort & ", Health URL: " & healthUrl

    ' Execute logic
    If mode = "STOP" Then
        DoStop
    Else
        DoStart
    End If

    WriteLog "--- Script End ---" & vbCrLf
    If logEnabled Then
        logFile.Close
    End If
End Sub

Sub WriteLog(message)
    If logEnabled Then
        logFile.WriteLine(Now() & " | " & message)
    End If
End Sub

Sub DoStart()
    Dim pid
    WriteLog "Starting 'DoStart' procedure."
    pid = GetPidOnPort(targetPort)

    If pid <> "" Then
        WriteLog "Port " & targetPort & " is occupied by PID: " & pid
        WriteLog "Checking service health..."
        If IsHealthy(healthUrl) Then
            WriteLog "Service is healthy and responsive."
            If MsgBox("Opencode Serve (Port " & targetPort & ") is currently healthy." & vbCrLf & "Are you sure you want to restart?", vbQuestion + vbYesNo, "Service Check") = vbYes Then
                WriteLog "User chose to restart."
                HandlePortCleanup pid
                StartService
            Else
                WriteLog "User cancelled restart."
            End If
        Else
            WriteLog "Service is unresponsive. Proceeding with auto-cleanup."
            HandlePortCleanup pid
            StartService
        End If
    Else
        WriteLog "Port " & targetPort & " is free. Starting service directly."
        StartService
    End If
End Sub

Sub DoStop()
    Dim pid
    WriteLog "Starting 'DoStop' procedure."
    pid = GetPidOnPort(targetPort)
    If pid <> "" Then
        WriteLog "Found process with PID " & pid & " on port " & targetPort & ". Stopping it."
        HandlePortCleanup pid
        MsgBox "Opencode Serve (Port " & targetPort & ") has been stopped.", vbInformation, "Stopped"
        WriteLog "Stop command completed."
    Else
        WriteLog "No process found on port " & targetPort & "."
        MsgBox "Opencode Serve is not running on Port " & targetPort & ".", vbInformation, "Service Not Found"
    End If
End Sub

Function IsHealthy(url)
    On Error Resume Next
    Dim xmlHttp
    Set xmlHttp = CreateObject("MSXML2.XMLHTTP")
    xmlHttp.Open "GET", url, False
    xmlHttp.Send
    
    If Err.Number = 0 Then
        If xmlHttp.Status = 200 Then
            IsHealthy = True
        Else
            IsHealthy = False
            WriteLog "Health check failed. HTTP Status: " & xmlHttp.Status
        End If
    Else
        IsHealthy = False
        WriteLog "Health check failed. Error: " & Err.Description
    End If
    On Error GoTo 0
End Function

Function GetPidOnPort(port)
    Dim exec, line, parts
    Set exec = shell.Exec("cmd /c netstat -ano | findstr /R /C "": " & port & " .* LISTENING""")
    Do Until exec.StdOut.AtEndOfStream
        line = Trim(exec.StdOut.ReadLine())
        If InStr(line, "LISTENING") > 0 Then
            parts = Split(line, " ")
            GetPidOnPort = parts(UBound(parts))
            Exit Function
        End If
    Loop
    GetPidOnPort = ""
End Function

Sub HandlePortCleanup(pid)
    WriteLog "Attempting graceful shutdown for PID: " & pid
    shell.Run "taskkill /PID " & pid & " /T", 0, True
    WScript.Sleep waitTime
    
    If IsProcessRunning(pid) Then
        WriteLog "Graceful shutdown failed."
        If MsgBox("Failed to stop process (PID: " & pid & ") gracefully." & vbCrLf & "Force kill?", vbExclamation + vbYesNo, "Stop Failed") = vbYes Then
            WriteLog "Attempting force kill for PID: " & pid
            shell.Run "taskkill /F /PID " & pid & " /T", 0, True
            WScript.Sleep 1000
        Else
            WriteLog "User cancelled force kill. Aborting."
            MsgBox "Operation cancelled. Please resolve manually.", vbInformation, "Aborted"
            WScript.Quit
        End If
    Else
        WriteLog "Graceful shutdown successful."
    End If
End Sub

Function IsProcessRunning(pid)
    Dim objWMIService, colProcessList
    Set objWMIService = GetObject("winmgmts:{impersonationLevel=impersonate}!\\.\root\cimv2")
    Set colProcessList = objWMIService.ExecQuery("Select * from Win32_Process Where ProcessId = " & pid)
    If colProcessList.Count > 0 Then
        IsProcessRunning = True
    Else
        IsProcessRunning = False
    End If
End Function

Sub StartService()
    WriteLog "Executing command: opencode serve --hostname 0.0.0.0 --port " & targetPort
    shell.Run "cmd /c opencode serve --hostname 0.0.0.0 --port " & targetPort, 0, False
    
    WriteLog "Starting post-launch verification..."
    Dim i, isUp
    isUp = False
    
    For i = 1 To 10
        WScript.Sleep 1000
        If IsHealthy(healthUrl) Then
            isUp = True
            Exit For
        End If
    Next
    
    If isUp Then
        WriteLog "Service started and verified successfully after " & i & " seconds."
        If WScript.Arguments.Count > 0 Then
            ' Don't show success for 'log' only in silent mode
            Dim nonLogArgs
            nonLogArgs = False
            For Each arg In WScript.Arguments
                If LCase(arg) <> "log" Then
                    nonLogArgs = True
                    Exit For
                End If
            Next
            If nonLogArgs Then
                 MsgBox "Opencode Serve started successfully on port " & targetPort & ".", vbInformation, "Success"
            End If
        End If
    Else
        WriteLog "Startup failed. Service did not respond within 10 seconds."
        MsgBox "Failed to start Opencode Serve on port " & targetPort & "." & vbCrLf & "Service did not respond to HTTP check within 10 seconds.", vbCritical, "Startup Failed"
    End If
End Sub
