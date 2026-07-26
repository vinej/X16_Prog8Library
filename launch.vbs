' =====================================================================
' launch.vbs -- launch.bat with no console window.
'
' Double-click this instead of the .bat and the only window that appears
' is the emulator's own. The batch still runs (it syncs the build onto
' the card first), it just runs in a console nobody has to look at.
'
' launch.bat already runs the console-less x16emuw.exe and does not wait
' around, so its own window is brief -- this removes even that flash. If
' the batch fails, its exit code comes back and this says so rather than
' vanishing silently.
' =====================================================================
Option Explicit

Dim sh, fso, here, bat, rc
Set sh  = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")

here = fso.GetParentFolderName(WScript.ScriptFullName)
bat  = here & "\launch.bat"

' 0 = hidden window, True = wait, so the exit code is worth reading
rc = sh.Run("""" & bat & """", 0, True)

If rc <> 0 Then
    MsgBox "launch.bat failed (exit code " & rc & ")." & vbCrLf & vbCrLf & _
           "Run it from a command prompt to see why.", _
           vbExclamation, "X16 Desktop"
End If
