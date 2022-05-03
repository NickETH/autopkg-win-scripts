# Run AutoPkg jobs on Windows.
# It can run AutoPkg, write log files and send out Emails.
# Run AutoPKG Commands, which must be lines in the Jobfile
# Ex: PowerShell.exe -NoProfile -ExecutionPolicy Bypass -Command "& '%cd%\AutoPKGwin-run.ps1' -jobfile %cd%\AutoPkg-Jobs.txt -Emailfile %cd%\Autopkg_Email.json -Logfile %cd%\log\Autopkg-run.log"
# Version 1.0, Nick Heim

Param(
    [Parameter(mandatory=$true)][string]$jobfile,
    [Parameter(mandatory=$false)][string]$EmailFile,
    [Parameter(mandatory=$false)][string]$LogFile
)

echo $jobfile
echo $args.Length
echo $LogFile

If($LogFile){
    #$logfile = "C:\Tools\AutoPKG\log\Autopkg-run.log"
    $logpath = Split-Path $LogFile -Parent
    # echo $logpath
    $logfilebase = Split-Path $logfile -Leaf
    # echo $logfilebase
    $logfilesplited = $logfilebase -split '\.'
    # echo $logfilesplited
    $newlogfile =  $logfilesplited[0] + "-" + (Get-Date -Format yyyyMMdd-HHmm) + '.' + $logfilesplited[1]
    # echo $newlogfile
    $logfile = Join-Path $logpath $newlogfile
    # echo $logfile
}

if (!$jobfile){
    echo "Run with: AutoPKGwin.ps1 -jobfile Jobs.txt -Emailfile Email.json -Logfile Autopkg-run.log"
}
else {
    $jobpath = Split-Path $jobfile -Parent
    echo ("AutoPKG on " + $env:COMPUTERNAME) | Out-File $logfile
    $pinfo = New-Object System.Diagnostics.ProcessStartInfo
    $pinfo.FileName = "python.exe"
    $pinfo.RedirectStandardError = $true
    $pinfo.RedirectStandardOutput = $true
    $pinfo.UseShellExecute = $false
    foreach ($line in Get-Content ($jobfile)) {
        echo $line  | Out-File $logfile -Append        
        $fullautopkgpath = Join-Path $jobpath "autopkg.py"
        $pinfo.Arguments = $fullautopkgpath ,$line
        #$pinfo.Arguments = "autopkg.py",$line
        $p = New-Object System.Diagnostics.Process
        $p.StartInfo = $pinfo
        # echo $pinfo
        $p.Start()
        
        $stdout = $p.StandardOutput.ReadToEnd()
        $stderr = $p.StandardError.ReadToEnd()
		# WaitForExit must come after the ReadToEnds. See: https://stackoverflow.com/questions/139593/processstartinfo-hanging-on-waitforexit-why
        $p.WaitForExit()

        $stderr | Out-File $logfile -Append
        $stdout | Out-File $logfile -Append
    }
}

If($EmailFile){
    $EmailParams = (Get-Content $EmailFile -Raw) | ConvertFrom-Json
    $PSEmailServer = $EmailParams.AutoPkg_Email.Server
    $body = Get-Content -Path $logfile -Raw
    Send-MailMessage -To $EmailParams.AutoPkg_Email.Sendto -From $EmailParams.AutoPkg_Email.Sendfrom -Subject $EmailParams.AutoPkg_Email.Subject -Body $body -Port $EmailParams.AutoPkg_Email.Port
}