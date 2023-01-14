$i18n = Data {
    # culture="en-US"
    ConvertFrom-StringData @'
	FiledToCheckUpdates = Failed to check Windows Update
    PendingUpdates = Pending Windows Update
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
    try {
        $result = $updateSearcher.Search('IsInstalled=0')
        if ($result.updates.Count -eq 0) {
            return;
        }
        Write-Output "`n## $($i18n.PendingUpdates)`n"
        foreach ($update in $result.updates) {
            Write-CheckList $false $update.Title
        }
    }
    catch {
        Write-Host -ForegroundColor Red "> $($i18n.FiledToCheckUpdates): $_"
    }
}
