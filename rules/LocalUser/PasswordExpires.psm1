$i18n = Data {
    # culture="en-US"
    ConvertFrom-StringData @'
    Days = days
    LastSetAt = last set at
    PasswordExpires = Password Expires
    PasswordNeverExpires = password never expires
'@
}

if ($PSUICulture -ne 'en-US') {
    Import-LocalizedData -BindingVariable i18n
}

function Test($config) {
    if (-not (Get-Command 'Get-LocalUser' -ErrorAction SilentlyContinue)) {
        $ruleName = [System.IO.Path]::GetFileNameWithoutExtension($PSCommandPath)
        Write-UnsupportedPlatform($ruleName)
        return
    }
    # https://learn.microsoft.com/powershell/module/microsoft.powershell.localaccounts/get-localuser
    $users = Get-LocalUser | Where-Object { $_.Enabled }
    $exclude = $config.PasswordExpires.Exclude;
    if (-not [string]::IsNullOrWhiteSpace($exclude)) {
        $users = $users | Where-Object { $_.Name -notmatch $exclude }
    }
    $maximumPasswordAge = [int]$config.PasswordPolicy.MaximumPasswordAge;
    $now = Get-Date;
    $users = $users | Where-Object { $null -eq $_.PasswordExpires -or ($now - $_.PasswordLastSet).TotalDays -gt $maximumPasswordAge }
    if ($users.Count -eq 0) {
        return;
    }
    Write-Output "`n## $($i18n.PasswordExpires)`n"
    foreach ($user in $users) {
        if ($null -eq $user.PasswordExpires) {
            Write-CheckList $false "$($user.Name): $($i18n.PasswordNeverExpires)"
        }
        else {
            Write-CheckList $false ("$($user.Name): $($i18n.LastSetAt) {0:yyyy-MM-dd'T'HH:mm:ssK} > $($maximumPasswordAge) $($i18n.Days)" -f $user.PasswordLastSet)
        }
    }
}
