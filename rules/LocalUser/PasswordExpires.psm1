$i18n = Data {
    # culture="en-US"
    ConvertFrom-StringData @'
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
    $users = Get-LocalUser | Where-Object { $_.Enabled -and $null -eq $_.PasswordExpires }
    $exclude = $config.PasswordExpires.Exclude;
    if (-not [string]::IsNullOrWhiteSpace($exclude)) {
        $users = $users | Where-Object { $_.Name -notmatch $exclude }
    }
    if ($users.Count -eq 0) {
        return;
    }
    Write-Output "`n## $($i18n.PasswordExpires)`n"
    foreach ($user in $users) {
        Write-CheckList $false "$($user.Name): $($i18n.PasswordNeverExpires)"
    }
}
