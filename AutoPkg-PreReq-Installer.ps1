# Install prerequisites for AutoPkg on Windows x64
# In a first stage, all neccessary package are downloaded to the local folder.
# In a second stage, those packages are installed with elevated privileges.
# In a third stage, we populate the MSITools folder and create a py.ini file
# And finally, we install AutoPkg.msi for the current user.
# Version 1.0 20220502, Nick Heim
# Version 1.1 20231116, Nick Heim. Updated github download links, dotnet3 install

# Could be neccessary:
# [HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Internet Explorer\Main]
# "DisableFirstRunCustomize"=dword:00000001

# make sure, we are in the script dir
cd $PSScriptRoot

# Initialize batch file
"@echo on" | Out-File -FilePath AP-Prereq-Install.cmd -Encoding ascii

Add-Content -Path AP-Prereq-Install.cmd -Value ("cd " + $PSScriptRoot) -Encoding Ascii

# Add the "InstallerTools" folder create command to the batch file
$InstToolsFldr = "C:\Tools\MSITools"
if (-Not (Test-Path -Path $InstToolsFldr)) {
    Add-Content -Path AP-Prereq-Install.cmd -Value ("md " + $InstToolsFldr + " -Force")
}

# Install Python3 latest x64
$DownloadFile = "Python3-x64.exe"
# $URL = (Invoke-WebRequest https://www.python.org/downloads/ -UseBasicParsing | Select -ExpandProperty links | ?  href -like "*exe*").href
$URL = (Invoke-WebRequest https://www.python.org/downloads/windows/ -UseBasicParsing | Select -ExpandProperty links | ?  href -match ".*python-3.11.[0-9]+-amd64.exe").href[0]

$request = Invoke-WebRequest -Uri "$URL" -OutFile $DownloadFile
# Add the install command to the batch file
Add-Content -Path AP-Prereq-Install.cmd -Value ($DownloadFile + " /quiet InstallAllUsers=1 PrependPath=1")

# Install VS BuildTools 2022
$DownloadFile = "vs_BuildTools.exe"
$URL = "https://aka.ms/vs/17/release/vs_BuildTools.exe"
$request = Invoke-WebRequest -Uri "$URL" -OutFile $DownloadFile
# Add the install command to the batch file
Add-Content -Path AP-Prereq-Install.cmd -Value ($DownloadFile + " --add Microsoft.VisualStudio.Workload.MSBuildTools --quiet --wait")

# Install latest Windows 10 SDK
$DownloadFile = "winsdksetup.exe"
$URL = "https://go.microsoft.com/fwlink/?linkid=2164145"
$request = Invoke-WebRequest -Uri "$URL" -OutFile $DownloadFile
# Add the install command to the batch file
Add-Content -Path AP-Prereq-Install.cmd -Value ($DownloadFile + " /features OptionId.MSIInstallTools OptionId.DesktopCPPx86 OptionId.DesktopCPPx64 OptionId.SigningTools /ceip off /q /norestart")

# Install the latest 7-zip x64 MSI
$DownloadFile = "7zip-x64.msi"
$URL = "https://www.7-zip.org/$((Invoke-WebRequest https://www.7-zip.org/download.html -UseBasicParsing |Select -ExpandProperty Links |where -Property href -like "*-x64.msi")[0].href)"
$request = Invoke-WebRequest -Uri "$URL" -OutFile $DownloadFile
$MSIArguments = @(
    "/i"
    ('"{0}"' -f $DownloadFile)
    "/qn"
    "/norestart"
)
# Add the install command to the batch file
Add-Content -Path AP-Prereq-Install.cmd -Value ("msiexec.exe " + $MSIArguments)

# Install the latest Git x64 Installer
$DownloadFile = "Git-x64.exe"
$URL = (((Invoke-WebRequest https://git-scm.com/download/win -UseBasicParsing).Links) | where -Property outerHTML -Match "64-bit Git for Windows Setup").href
$request = Invoke-WebRequest -Uri "$URL" -OutFile $DownloadFile
# Add the install command to the batch file
Add-Content -Path AP-Prereq-Install.cmd -Value ($DownloadFile + ' /ALLUSERS /COMPONENTS="*ext,gitlfs,assoc,assoc_sh" /VERYSILENT')

# Install NANT
$DownloadFile = "NANT.zip"
$URL = "https://sourceforge.net/projects/nant/files/nant/0.92/nant-0.92-bin.zip/download"
if (!($PSDefaultParameterValues.ContainsKey('Invoke-WebRequest:UserAgent'))) {$PSDefaultParameterValues.Add('Invoke-WebRequest:UserAgent','NotABrowser')}
$request = Invoke-WebRequest -Uri "$URL" -OutFile $DownloadFile
# Add the epand command to the batch file
Add-Content -Path AP-Prereq-Install.cmd -Value ('powershell.exe ' + '"Expand-Archive ' + $DownloadFile + ' -DestinationPath C:\Tools -Force"')

# Activate DotNet 3.5 (get it online)
# Add the install command to the batch file
# Add-Content -Path AP-Prereq-Install.cmd -Value ('powershell.exe ' + '"Enable-WindowsOptionalFeature -Online -FeatureName NetFx3 -Source D:\sources\sxs"')
Add-Content -Path AP-Prereq-Install.cmd -Value ('powershell.exe ' + '"Enable-WindowsOptionalFeature -Online -FeatureName NetFx3 -NoRestart"')

# Install Wix Toolset
$DownloadFile = "WixToolset.exe"
$releases = "https://api.github.com/repos/wixtoolset/wix3/releases"
$URL = (Invoke-WebRequest $releases | ConvertFrom-Json)[0].assets.browser_download_url | where { $_ -Like "*wix3*.exe" }
#$URL = ("https://github.com" + ((Invoke-WebRequest github.com/wixtoolset/wix3/releases/latest -UseBasicParsing)| Select-Object -ExpandProperty Links | Where-Object -Property href -Like "*wix3*.exe").href)
$request = Invoke-WebRequest -Uri "$URL" -OutFile $DownloadFile
# Add the install command to the batch file
Add-Content -Path AP-Prereq-Install.cmd -Value ($DownloadFile + " /install /quiet /norestart")

# Download and Advertise AutoPkg
$DownloadFile = "AutoPkg.msi"
$releases = "https://api.github.com/repos/NickETH/autopkg/releases"
$URL = (Invoke-WebRequest $releases | ConvertFrom-Json)[0].assets.browser_download_url
#$URL = ("https://github.com" + ((Invoke-WebRequest github.com/NickETH/autopkg/releases/latest -UseBasicParsing)| Select-Object -ExpandProperty Links | Where-Object -Property href -Like "*AutoPkg*.msi")[0].href)
$request = Invoke-WebRequest -Uri "$URL" -OutFile $DownloadFile
$MSIArguments = @(
    "/jm"
    ('"{0}"' -f $DownloadFile)
)
# Add the install command to the batch file
Add-Content -Path AP-Prereq-Install.cmd -Value ("msiexec.exe " + $MSIArguments)

# Self-elevate the script if required
if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
 if ([int](Get-CimInstance -Class Win32_OperatingSystem | Select-Object -ExpandProperty BuildNumber) -ge 6000) {
  $CommandLine = "-File `"" + $MyInvocation.MyCommand.Path + "`" " + $MyInvocation.UnboundArguments
  Start-Process -Wait -FilePath "AP-Prereq-Install.cmd" -Verb Runas
 }
}else {
  Start-Process -Wait -FilePath "AP-Prereq-Install.cmd"
}

# Create a py.ini file to redirect the shebang to the Windows python.exe
$SearchPathPython = Get-ChildItem -Path "C:\Program Files" -Filter "Python.exe" -Recurse -ErrorAction SilentlyContinue -Force
$PythonExePath = $SearchPathPython[0].FullName
$Py_INI = @"
[commands]
/usr/local/autopkg/python=$PythonExePath
"@
New-Item ($env:LOCALAPPDATA + "\py.ini") -type file -force -value $Py_INI

$SearchPathArr = Get-ChildItem -Path "C:\Program Files (x86)\Windows Kits\10\bin" -Filter "WiMakCab.vbs" -Recurse -ErrorAction SilentlyContinue -Force
Foreach ($DirEntry in $SearchPathArr)
{
    if($DirEntry.DirectoryName.Contains(‘x86’)) {
        $SdkX64Bin = $DirEntry.DirectoryName
    }
}

# Execute the copy commands
Copy-Item ($SdkX64Bin + "\Wi*.vbs") -Destination $InstToolsFldr -Force
Copy-Item ($SdkX64Bin + "\Msi*.exe") -Destination $InstToolsFldr -Force

# Install MultiMakeCab.vbs
$DownloadFile = "MultiMakeCab.vbs.zip"
$UnzipTempFldr = ($PSScriptRoot + "\unzip")
$URL = "https://gist.github.com/NickETH/acf4e01124a20cef0d45e0922e058fcb/archive/31b431cb140ba4b2d58812eeb7f9db892ee762f5.zip"
$request = Invoke-WebRequest -Uri "$URL" -OutFile $DownloadFile
Expand-Archive $DownloadFile -DestinationPath $UnzipTempFldr
Move-Item -Path ($UnzipTempFldr + "\*\MultiMakeCab.vbs") -Destination $InstToolsFldr
Remove-Item -Path $UnzipTempFldr -Recurse -Force

Start-Process -Wait -FilePath "msiexec.exe" -ArgumentList "/i AutoPkg.msi"
Start-Process -Wait -FilePath "cmd.exe" -ArgumentList "/k cd C:\Tools\AutoPkg && autopkg.py"
