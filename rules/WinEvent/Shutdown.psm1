$i18n = Data {
    # culture="en-US"
    ConvertFrom-StringData @'
    Shutdown = Shutdown
'@
}

if ($PSUICulture -ne 'en-US') {
    Import-LocalizedData -BindingVariable i18n
}

function Test($config) {
    $ruleName = [System.IO.Path]::GetFileNameWithoutExtension($PSCommandPath)
    if (-not (Get-Command 'Get-WinEvent' -ErrorAction SilentlyContinue)) {
        Write-UnsupportedPlatform($ruleName)
        return
    }
    if (-not (IsLocalAdministrator)) {
        Write-RequireAdministrator($ruleName)
        return
    }
    $days = [int]$config.Shutdown.Days
    $maxEvents = [int]$config.Shutdown.MaxEvents
    # https://learn.microsoft.com/powershell/scripting/samples/creating-get-winevent-queries-with-filterhashtable
    $events = Get-WinEvent -FilterHashtable @{
        LogName   = 'System'
        Id        = 41, 1074, 1076, 6008
        StartTime = (get-date).AddDays($days * -1)
    } -MaxEvents $maxEvents -ErrorAction SilentlyContinue
    if ($events.Count -eq 0) {
        return
    }
    Write-Output "`n## $($i18n.Shutdown)`n"
    foreach ($event in $events) {
        Write-Output ("- {0:yyyy-MM-dd'T'HH:mm:ssK} | $($event.Message.Trim())" -f $event.TimeCreated)
    }
}
