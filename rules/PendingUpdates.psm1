$i18n = Data {
    # culture="en-US"
    ConvertFrom-StringData @'
    PendingUpdates = Pending Windows Update
    RebootRequired = Reboot required
'@
}

if ($PSUICulture -ne 'en-US') {
    Import-LocalizedData -BindingVariable i18n
}

function Test($config) {
    if ($PSVersionTable.PSEdition -eq 'Core' -and $PSVersionTable.Platform -ne 'Win32NT') {
        $ruleName = [System.IO.Path]::GetFileNameWithoutExtension($PSCommandPath)
        Write-UnsupportedPlatform($ruleName)
        return
    }
    $updateSession = New-Object -ComObject Microsoft.Update.Session
    $updateSession.ClientApplicationID = 'Windows Secure Auditor'
    $updateSearcher = $updateSession.CreateUpdateSearcher()
    $result = $updateSearcher.Search('IsHidden=0 and IsInstalled=0')
    if ($result.updates.Count -eq 0) {
        return;
    }
    Write-Output "`n## $($i18n.PendingUpdates)`n"
    foreach ($update in $result.updates) {
        Write-CheckList $false $update.Title
        if ($update.RebootRequired) {
            Write-Output "  - $($i18n.RebootRequired)"
        }
    }
}
