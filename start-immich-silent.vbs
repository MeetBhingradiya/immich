Option Explicit

Dim WshShell, fso, appDir, bunExe, scriptJs

Set WshShell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")

appDir = "G:\immich-app"
bunExe = "C:\Users\1\.bun\bin\bun.exe"
scriptJs = "G:\immich-app\start-immich-native.js"

If fso.FolderExists(appDir) Then
    WshShell.CurrentDirectory = appDir
End If

If fso.FileExists(bunExe) And fso.FileExists(scriptJs) Then
    WshShell.Run """" & bunExe & """ run """ & scriptJs & """", 0, False
End If

Set WshShell = Nothing
Set fso = Nothing
