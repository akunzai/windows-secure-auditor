$i18n = Data {
    # culture="en-US"
    ConvertFrom-StringData @'
    IpAddress = IP Address
    Login = Login
    LoginFailed = Login failed
    LoginSuccess = Login success
    Times = Times
    Username = Username
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
    $days = [int]::Parse($config.Login.Days) * -1
    # https://learn.microsoft.com/windows/security/threat-protection/auditing/basic-audit-logon-events
    $events = Get-WinEvent -FilterHashtable @{ 
        LogName   = 'Security';
        Id        = 4624, 4625;
        StartTime = (get-date).AddDays($days);
    } -ErrorAction SilentlyContinue
    if ($events.Count -eq 0) {
        return
    }
    $loginSuccessForUser = @{}
    $loginFailedForUser = @{}
    foreach ($event in $events) {
        $logonType = $event.Properties[8].Value
        if ($logonType -notmatch '(3|8|10)') {
            continue
        }
        $ipAddress = $event.Properties[18].Value
        if ($ipAddress -eq '-') {
            continue
        }
        $username = $event.Properties[5].Value
        # https://learn.microsoft.com/windows/security/threat-protection/auditing/event-4624
        if ($event.Id -eq 4624) {
            if ($loginSuccessForUser[$username] -isnot [hashtable]) {
                $loginSuccessForUser[$username] = @{}
            }
            $loginSuccessForUser[$username][$ipAddress] += 1;
        }
        # https://learn.microsoft.com/windows/security/threat-protection/auditing/event-4625
        elseif ($event.Id -eq 4625) {
            if ($loginFailedForUser[$username] -isnot [hashtable]) {
                $loginFailedForUser[$username] = @{}
            }
            $loginFailedForUser[$username][$ipAddress] += 1;
        }
    }
    $maxEvents = [int]::Parse($config.Login.MaxEvents)
    if ($loginSuccessForUser.Count -gt 0) {
        Write-Output "`n## $($i18n.LoginSuccess)`n"
        Write-Output "| $($i18n.Username) | $($i18n.IpAddress) | $($i18n.Times) |"
        Write-Output "|----------|------------|-------|"
        $eventCount = 0
        :success foreach ($username in $loginSuccessForUser.Keys) {
            foreach ($ipAddress in $loginSuccessForUser[$username].Keys) {
                if ($eventCount -ge $maxEvents) {
                    break success
                }
                $times = $loginSuccessForUser[$username][$ipAddress]
                Write-Output "| $($username) | $($ipAddress) | $($times) |"
                $eventCount += 1
            }
        }
    }
    if ($loginFailedForUser.Count -gt 0) {
        Write-Output "`n## $($i18n.LoginFailed)`n"
        Write-Output "| $($i18n.Username) | $($i18n.IpAddress) | $($i18n.Times) |"
        Write-Output "|----------|------------|-------|"
        $eventCount = 0
        :failed foreach ($username in $loginFailedForUser.Keys) {
            foreach ($ipAddress in $loginFailedForUser[$username].Keys) {
                if ($eventCount -ge $maxEvents) {
                    break failed
                }
                $times = $loginFailedForUser[$username][$ipAddress]
                Write-Output "| $($username) | $($ipAddress) | $($times) |"
                $eventCount += 1
            }
        }
    }
}