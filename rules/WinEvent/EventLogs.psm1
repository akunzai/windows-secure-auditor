$i18n = Data {
    # culture="en-US"
    ConvertFrom-StringData @'
    Count = Count
    EventId = Event ID
    EventLogs = Event Logs
    Level = Level
    LogName = LogName
    Message = Message
    Source = Source
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
    $logNames = $config.EventLogs.LogNames -split ',\s*'
    $levels = $config.EventLogs.Levels -split ',\s*' | ForEach-Object { [int]$_ }
    $days = [int]$config.EventLogs.Days
    $exclude = $config.EventLogs.Exclude
    # https://learn.microsoft.com/powershell/scripting/samples/creating-get-winevent-queries-with-filterhashtable
    $events = Get-WinEvent -FilterHashtable @{
        LogName   = $logNames
        Level     = $levels
        StartTime = (Get-Date).AddDays($days * -1)
    } -ErrorAction SilentlyContinue
    if (-not [string]::IsNullOrWhiteSpace($exclude)) {
        $events = $events | Where-Object { $_.Id -notmatch $exclude }
    }
    if ($events.Count -eq 0) {
        return
    }
    Write-Output "`n## $($i18n.EventLogs)"
    $events = $events | Select-Object Id, Level, LevelDisplayName, LogName, Message, ProviderName | Sort-Object -Property Level, Id | Group-Object -Property Level, Id
    $maxEvents = [int]$config.EventLogs.MaxEvents
    $maxMessageLength = [int]$config.EventLogs.MaxMessageLength
    $eventCount = 0
    foreach ($event in $events) {
        if ($eventCount -ge $maxEvents) {
            break
        }
        $eventId = $event.Group[0].Id
        $level = $event.Group[0].LevelDisplayName
        $logName = $event.Group[0].LogName
        $message = $event.Group[0].Message
        $source = $event.Group[0].ProviderName
        $count = $event.Count;
        Write-Output "`n- $($i18n.Level): $($level) | $($i18n.EventId): $($eventId)"
        Write-Output "  - $($i18n.LogName): $($logName)"
        Write-Output "  - $($i18n.Source): $($source)"
        Write-Output "  - $($i18n.Count): $($count)"
        if ($null -ne $message) {
            # remove special characters
            # https://en.wikipedia.org/wiki/ANSI_escape_code
            $message = $message.Trim() -replace '[\x1b]\[\d+([\d;]+)?m', ''
            if ($message.length -le $maxMessageLength) {
                Write-Output ("`n``````log`n{0}`n``````" -f $message)
            }
            else {
                Write-Output ("`n``````log`n{0}...`n``````" -f $message.Substring(0, $maxMessageLength))
            }
        }
        $eventCount += 1
    }
}
