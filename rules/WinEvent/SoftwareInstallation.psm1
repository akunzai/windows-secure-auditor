$i18n = Data {
    # culture="en-US"
    ConvertFrom-StringData @'
    SoftwareInstallation = Software Installation
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
    $days = [int]$config.SoftwareInstallation.Days
    $maxEvents = [int]$config.SoftwareInstallation.MaxEvents
    # https://learn.microsoft.com/powershell/scripting/samples/creating-get-winevent-queries-with-filterhashtable
    $events = Get-WinEvent -FilterHashtable @{
        LogName   = 'Application'
        Id        = 11707, 11724
        StartTime = (get-date).AddDays($days * -1)
    } -MaxEvents $maxEvents -ErrorAction SilentlyContinue
    if ($events.Count -eq 0) {
        return
    }
    Write-Output "`n## $($i18n.SoftwareInstallation)`n"
    foreach ($event in $events) {
        Write-Output "- $($event.Message.Trim())"
    }
}
