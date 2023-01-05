$i18n = Data {
    # culture="en-US"
    ConvertFrom-StringData @'
    PasswordExpires = Password Expires
    AccountPasswordNeverExpires = Account password never expires
'@
}

if ($PSUICulture -ne 'en-US') {
    Import-LocalizedData -BindingVariable i18n
}

function Test($config) {
    # https://learn.microsoft.com/windows/win32/cimwin32prov/win32-useraccount
    $userAccounts = Get-WmiObject -Query "SELECT * FROM Win32_UserAccount WHERE LocalAccount = true AND Disabled = false AND PasswordExpires = false"
    if ($userAccounts.Count -eq 0) {
        return;
    }
    $exclude = $config.PasswordExpires.Exclude;
    Write-Output "`n## $($i18n.PasswordExpires)`n"
    foreach ($userAccount in $userAccounts) {
        if (-not [string]::IsNullOrWhiteSpace($exclude) -and $userAccount.Name -match $exclude) {
            continue
        }
        Write-CheckList $false "$($userAccount.Name): $($i18n.AccountPasswordNeverExpires)"
    }
}