$i18n = Data {
    # culture="en-US"
    ConvertFrom-StringData @'
    DefaultAccount = Default Account
    NotFound = not found
    Disabled = disabled
'@
}

if ($PSUICulture -ne 'en-US') {
    Import-LocalizedData -BindingVariable i18n
}

function Test($config) {
    Write-Output "`n## $($i18n.DefaultAccount)`n"
    $userNames = $config.DefaultAccount.LocalUserNames -split ',\s*'
    foreach ($userName in $userNames) {
        $localUser = Get-LocalUser $userName -ErrorAction SilentlyContinue
        if ($null -eq $localUser) {
            Write-CheckList $true "$($userName): $($i18n.NotFound)"
            continue
        }
        Write-CheckList ($localUser.Enabled -eq $false) "$($userName): $($i18n.Disabled)"
    }
}