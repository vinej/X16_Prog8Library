' =====================================================================
' launch_cart.vbs -- launch_cart.bat with no console window.
' See launch.vbs for the why; this one boots the cartridge edition.
' =====================================================================
Option Explicit

Dim sh, fso, here, bat, rc
Set sh  = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")

here = fso.GetParentFolderName(WScript.ScriptFullName)
bat  = here & "\launch_cart.bat"

rc = sh.Run("""" & bat & """", 0, True)

If rc <> 0 Then
    MsgBox "launch_cart.bat failed (exit code " & rc & ")." & vbCrLf & vbCrLf & _
           "Run it from a command prompt to see why.", _
           vbExclamation, "X16 Desktop"
End If
