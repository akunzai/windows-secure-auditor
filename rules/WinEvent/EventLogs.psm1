﻿$i18n = Data {
    # culture="en-US"
    ConvertFrom-StringData @'
    Count = Count
    EventId = Event ID
    EventLogs = Event Logs
    Level = Level
    LogName = LogName
    Message = Message
    ProviderName = ProviderName
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
    $logNames = $config.EventLogs.LogNames -split ',\s*'
    $levels = $config.EventLogs.Levels -split ',\s*' | ForEach-Object { [int]$_ }
    $days = [int]$config.EventLogs.Days
    # https://learn.microsoft.com/powershell/scripting/samples/creating-get-winevent-queries-with-filterhashtable
    $events = Get-WinEvent -FilterHashtable @{
        LogName   = $logNames
        Level     = $levels
        StartTime = (Get-Date).AddDays($days * -1)
    } -ErrorAction SilentlyContinue
    if ($events.Count -eq 0) {
        return
    }
    Write-Output "`n## $($i18n.EventLogs)"
    $events = $events | Select-Object Id, Level, LevelDisplayName, LogName, Message, ProviderName | Sort-Object -Property Level, Id | Group-Object -Property Level, Id
    $maxEvents = [int]$config.EventLogs.MaxEvents
    $exclude = $config.EventLogs.Exclude
    $eventCount = 0
    foreach ($event in $events) {
        if ($eventCount -ge $maxEvents) {
            break
        }
        $eventId = $event.Group[0].Id
        if (-not [string]::IsNullOrWhiteSpace($exclude) -and $eventId -match $exclude) {
            continue
        }
        $level = $event.Group[0].LevelDisplayName
        $logName = $event.Group[0].LogName
        $message = $event.Group[0].Message
        $providerName = $event.Group[0].ProviderName
        $count = $event.Count;
        Write-Output "`n- $($i18n.Level): $($level) | $($i18n.EventId): $($eventId)"
        Write-Output "  - $($i18n.LogName): $($logName)"
        Write-Output "  - $($i18n.ProviderName): $($providerName)"
        Write-Output "  - $($i18n.Count): $($count)"
        if ($null -ne $message) {
            Write-Output "`n``````log`n$($message.Trim())`n``````"
        }
        $eventCount += 1
    }
}
