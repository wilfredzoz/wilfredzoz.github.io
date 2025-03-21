If Not WScript.Arguments.Named.Exists("elevate") Then
  CreateObject("Shell.Application").ShellExecute WScript.FullName, """" & WScript.ScriptFullName & """ /elevate", "", "runas", 10
  WScript.Quit
End If

Set oShell = CreateObject("WScript.Shell")
Set oEnvSystem = oShell.Environment("SYSTEM")
Set oFS = CreateObject("Scripting.FileSystemObject")

Dim sBasePath, sJarFile
sBasePath = oFS.GetParentFolderName(oFS.GetParentFolderName(WScript.ScriptFullName))
sJarFile = sBasePath & "\ja-netfilter.jar"

If Not oFS.FileExists(sJarFile) Then
    MsgBox "ja-netfilter.jar not found", vbOKOnly Or vbCritical
    WScript.Quit -1
End If
MsgBox "请先关闭需要激活的软件,点击确定继续.."
MsgBox "脚本运行可能需要一会时间..." & vbCrLf & vbCrLf & "点击确定,等待弹出运行成功的提示!"

Dim sEnvKey, sEnvVal, aJBProducts
aJBProducts = Array("idea", "clion", "phpstorm", "goland", "pycharm", "webstorm", "webide", "rider", "datagrip", "rubymine", "appcode", "dataspell", "gateway", "jetbrains_client", "jetbrainsclient", "studio", "devecostudio")

Set re = New RegExp
re.Global     = True
re.IgnoreCase = True
re.Pattern    = "^\-javaagent:.*[\/\\]ja\-netfilter\.jar.*"

Sub RemoveEnv(env)
    On Error Resume Next

    For Each sPrd in aJBProducts
        sEnvKey = UCase(sPrd) & "_VM_OPTIONS"
        sEnvVal = oShell.ExpandEnvironmentStrings("%" & sEnvKey & "%")
        If sEnvVal <> ("%" & sEnvKey & "%") Then
            env.Remove(sEnvKey)
        End If
        Next
End Sub

RemoveEnv oShell.Environment("USER")

Dim sVmOptionsFile
For Each sPrd in aJBProducts
    sEnvKey = UCase(sPrd) & "_VM_OPTIONS"
    sVmOptionsFile = sBasePath & "\vmoptions\" & sPrd & ".vmoptions"
    If oFS.FileExists(sVmOptionsFile) Then
        ProcessVmOptions sVmOptionsFile
        oEnvSystem(sEnvKey) = sVmOptionsFile
    End If
Next

Sub ProcessVmOptions(ByVal file)
    Dim sLine, sNewContent, bMatch
    Set oFile = oFS.OpenTextFile(file, 1, 0)

    sNewContent = ""
    Do Until oFile.AtEndOfStream
        sLine = oFile.ReadLine
        bMatch = re.Test(sLine)
        If Not bMatch Then
            sNewContent = sNewContent & sLine & vbLf
        End If
    Loop
    oFile.Close

    sNewContent = sNewContent & "-javaagent:" & sJarFile & "=jetbrains"
    Set oFile = oFS.OpenTextFile(file, 2, 0)
    oFile.Write sNewContent
    oFile.Close
End Sub

MsgBox "安装成功,请将文件夹内的zcode文件拖进软件激活码框内激活."
