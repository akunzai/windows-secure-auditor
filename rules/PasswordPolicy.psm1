$i18n = Data {
    # culture="en-US"
    ConvertFrom-StringData @'
    PasswordHistorySize = Password history size
    PasswordPolicy = Password Policy
    MaximumPasswordAge = Maximum password age(days)
    MinimumPasswordAge = Minimum password age(days)
    MinimumPasswordLength = Minimum password length
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
    # https://learn.microsoft.com/windows-server/administration/windows-commands/secedit-export
    $tempFileName = [System.IO.Path]::GetTempFileName()
    & secedit /export /cfg $tempFileName /areas securitypolicy /quiet | Out-Null
    $ini = Get-IniContent $tempFileName
    $policy = $ini.'System Access'

    Write-Output "`n## $($i18n.passwordPolicy)`n"
    $currentMinimumPasswordAge = [int]$policy.MinimumPasswordAge
    $requireMinimumPasswordAge = [int]$config.PasswordPolicy.MinimumPasswordAge
    Write-CheckList ($currentMinimumPasswordAge -ge $requireMinimumPasswordAge) "$($i18n.MinimumPasswordAge): $($currentMinimumPasswordAge) >= $($requireMinimumPasswordAge)"

    $currentMaximumPasswordAge = [int]$policy.MaximumPasswordAge
    $requireMaximumPasswordAge = [int]$config.PasswordPolicy.MaximumPasswordAge
    Write-CheckList ($currentMaximumPasswordAge -le $requireMaximumPasswordAge) "$($i18n.MaximumPasswordAge): $($currentMaximumPasswordAge) <= $($requireMaximumPasswordAge)"

    $currentMinimumPasswordLength = [int]$policy.MinimumPasswordLength
    $requireMinimumPasswordLength = [int]$config.PasswordPolicy.MinimumPasswordLength
    Write-CheckList ($currentMinimumPasswordLength -ge $requireMinimumPasswordLength) "$($i18n.MinimumPasswordLength): $($currentMinimumPasswordLength) >= $($requireMinimumPasswordLength)"

    $currentPasswordHistorySize = [int]$policy.PasswordHistorySize
    $requirePasswordHistorySize = [int]$config.PasswordPolicy.PasswordHistorySize
    Write-CheckList ($currentPasswordHistorySize -ge $requirePasswordHistorySize) "$($i18n.PasswordHistorySize): $($currentPasswordHistorySize) >= $($requirePasswordHistorySize)"
}
