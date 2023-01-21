$i18n = Data {
    # culture="en-US"
    ConvertFrom-StringData @'
    NTP = Network Time Protocol
    WindowsTimeServiceStarted = Windows Time Service Started
'@
}

if ($PSUICulture -ne 'en-US') {
    Import-LocalizedData -BindingVariable i18n
}

function Test($config) {
    if ($PSVersionTable.PSEdition -eq 'Core' -and $PSVersionTable.Platform -ne 'Win32NT') {
        $ruleName = [System.IO.Path]::GetFileNameWithoutExtension($PSCommandPath)
        Write-UnsupportedPlatform($ruleName)
        return
    }
    Write-Output "`n## $($i18n.NTP)`n"
    # https://learn.microsoft.com/windows-server/networking/windows-time-service/windows-time-service-tools-and-settings
    $pinfo = New-Object System.Diagnostics.ProcessStartInfo
    $pinfo.FileName = "w32tm"
    $pinfo.Arguments = "/query /status"
    $pinfo.RedirectStandardError = $true
    $pinfo.RedirectStandardOutput = $true
    $pinfo.UseShellExecute = $false
    $p = New-Object System.Diagnostics.Process
    $p.StartInfo = $pinfo
    $p.Start() | Out-Null
    $p.WaitForExit()
    $output = $p.StandardOutput.ReadToEnd().Trim()
    Write-CheckList ($p.ExitCode -eq 0) "$($i18n.WindowsTimeServiceStarted)"
    Write-Output "`n``````log`n$($output)`n``````"
}
