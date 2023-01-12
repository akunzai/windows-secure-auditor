$i18n = Data {
    # culture="en-US"
    ConvertFrom-StringData @'
    IdleAccount = Idle Account
    LastLogonAt = last logon at
'@
}

if ($PSUICulture -ne 'en-US') {
    Import-LocalizedData -BindingVariable i18n
}

function Test($config) {
    $days = [int]::Parse($config.IdleAccount.Days) * -1
    $idleCheckpoint = (get-date).AddDays($days)
    # https://learn.microsoft.com/powershell/module/microsoft.powershell.localaccounts/get-localuser
    $users = Get-LocalUser | Where-Object { $_.Enabled -and $null -ne $_.LastLogon -and $idleCheckpoint -gt $_.LastLogon }
    $exclude = $config.IdleAccount.Exclude;
    if (-not [string]::IsNullOrWhiteSpace($exclude)) {
        $users = $users | Where-Object { $_.Name -notmatch $exclude }
    }
    if ($users.Count -eq 0) {
        return;
    }
    Write-Output "`n## $($i18n.IdleAccount)`n"
    foreach ($user in $users) {
        Write-CheckList $false ("$($user.Name): $($i18n.LastLogonAt) {0:yyyy-MM-dd'T'HH:mm:ssK}" -f $user.LastLogon)
    }
}
