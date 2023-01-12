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
    if (-not (IsLocalAdministrator)) {
        $ruleName = [System.IO.Path]::GetFileNameWithoutExtension($PSCommandPath)
        Write-RequireAdministrator($ruleName)
        return
    }
    $days = [int]::Parse($config.SoftwareInstallation.Days) * -1
    $maxEvents = [int]::Parse($config.SoftwareInstallation.MaxEvents)
    # https://learn.microsoft.com/powershell/scripting/samples/creating-get-winevent-queries-with-filterhashtable
    $events = Get-WinEvent -FilterHashtable @{ 
        LogName   = 'Application'
        Id        = 11707, 11724
        StartTime = (get-date).AddDays($days)
    } -MaxEvents $maxEvents -ErrorAction SilentlyContinue
    if ($events.Count -eq 0) {
        return
    }
    Write-Output "`n## $($i18n.SoftwareInstallation)`n"
    foreach ($event in $events) {
        Write-Output "- $($event.Message)"
    }
}
