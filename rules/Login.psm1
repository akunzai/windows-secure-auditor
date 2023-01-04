$i18n = Data {
    # culture="en-US"
    ConvertFrom-StringData @'
    Count = Count
    Login = Login
    LoginFailed = Login Failed
    LoginSuccess = Login Success
    IpAddress = IP Address
'@
}

if ($PSUICulture -ne 'en-US') {
    Import-LocalizedData -BindingVariable i18n
}

function Test($config) {
    if (-not (IsLocalAdministrator)) {
        $ruleName = [System.IO.Path]::GetFileNameWithoutExtension($PSCommandPath)
        Write-RequireAdministrators($ruleName)
        return
    }
    $days = [int]::Parse($config.Login.Days) * -1
    # https://learn.microsoft.com/windows/security/threat-protection/auditing/basic-audit-logon-events
    $events = Get-WinEvent -FilterHashtable @{ 
        LogName   = 'Security';
        Id        = 4624, 4625;
        LogonType = 2, 3, 8, 10;
        StartTime = (get-date).AddDays($days);
    } -ErrorAction SilentlyContinue
    if ($events.Count -eq 0) {
        return
    }
    $loginSuccessForUser = [ordered]@{}
    $loginFailedForUser = [ordered]@{}
    foreach ($event in $events) {
        if ($events.Properties.Count -gt 25) {
            # %%1842 => Yes
            # %%1843 => No
            $isVirtualAccount = $event.Properties[25].Value -eq '%%1842'
            if ($isVirtualAccount) {
                continue
            }
        }
        $username = $event.Properties[5].Value
        $ipAddress = $event.Properties[18].Value
        # https://learn.microsoft.com/windows/security/threat-protection/auditing/event-4624
        if ($event.Id -eq 4624) {
            if ($loginSuccessForUser[$username] -isnot [ordered]) {
                $loginSuccessForUser[$username] = [ordered]@{}
            }
            $loginSuccessForUser[$username][$ipAddress] += 1;
        }
        # https://learn.microsoft.com/windows/security/threat-protection/auditing/event-4625
        elseif ($event.Id -eq 4625) {
            if ($loginFailedForUser[$username] -isnot [ordered]) {
                $loginFailedForUser[$username] = [ordered]@{}
            }
            $loginFailedForUser[$username][$ipAddress] += 1;
        }
    }
    if ($loginSuccessForUser.Count -eq 0 -and $loginFailedForUser.Count -eq 0) {
        return
    }
    Write-Output "`n## $($i18n.Login)`n"
    $maxEvents = [int]::Parse($config.Login.MaxEvents)
    $eventCount = 0
    :failed foreach ($username in $loginFailedForUser.Keys) {
        foreach ($ipAddress in $loginFailedForUser[$username].Keys) {
            if ($eventCount -ge $maxEvents) {
                break failed
            }
            $count = $loginFailedForUser[$username][$ipAddress]
            Write-Output "- $($username) $($i18n.LoginFailed) $($i18n.IpAddress):$($ipAddress), $($i18n.Count): $($count)"
            $eventCount += 1
        }
    }
    :success foreach ($username in $loginSuccessForUser.Keys) {
        foreach ($ipAddress in $loginSuccessForUser[$username].Keys) {
            if ($eventCount -ge $maxEvents) {
                break success
            }
            $count = $loginSuccessForUser[$username][$ipAddress]
            Write-Output "- $($username) $($i18n.LoginSuccess) $($i18n.IpAddress):$($ipAddress), $($i18n.Count): $($count)"
            $eventCount += 1
        }
    }
}