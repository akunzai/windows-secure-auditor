$i18n = Data {
    # culture="en-US"
    ConvertFrom-StringData @'
    NTP = Network Time Protocol
    NtpSource = NTP source
    ServiceStarted = Windows Time service started
'@
}

if ($PSUICulture -ne 'en-US') {
    Import-LocalizedData -BindingVariable i18n
}

function Test($config) {
    $ruleName = [System.IO.Path]::GetFileNameWithoutExtension($PSCommandPath)
    if ($PSVersionTable.PSEdition -eq 'Core' -and $PSVersionTable.Platform -ne 'Win32NT') {
        Write-UnsupportedPlatform($ruleName)
        return
    }
    if (-not (IsLocalAdministrator)) {
        Write-RequireAdministrator($ruleName)
        return
    }
    Write-Output "`n## $($i18n.NTP)`n"
    # https://learn.microsoft.com/windows-server/networking/windows-time-service/windows-time-service-tools-and-settings
    $service = Get-Service -Name w32time -ErrorAction SilentlyContinue
    Write-CheckList ($service.Status -eq 'Running') "$($i18n.ServiceStarted)"
    if ($service.Status -ne 'Running') {
        Write-CheckList $false "$($i18n.NtpSource)"
        return
    }
    $source = (& w32tm /query /source | Out-String).Trim()
    Write-CheckList ($source -inotmatch '(Free-running System Clock|Local CMOS Clock)') "$($i18n.NtpSource): $($source)"
    $status = (& w32tm /query /status | Out-String).Trim()
    Write-Output "`n``````log`n$($status)`n``````"
}
