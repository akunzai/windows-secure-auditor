$i18n = Data {
	# culture="en-US"
	ConvertFrom-StringData @'
    PendingUpdates = Pending Windows Update
'@
}

if ($PSUICulture -ne 'en-US') {
	Import-LocalizedData -BindingVariable i18n
}

function Test($config) {
	$updateSession = New-Object -ComObject Microsoft.Update.Session
	$updateSession.ClientApplicationID = 'Windows Secure Auditor'
	$updateSearcher = $updateSession.CreateUpdateSearcher()
	$result = $updateSearcher.Search('IsInstalled=0')
	if ($result.updates.Count -eq 0) {
		return;
	}
	Write-Output "`n## $($i18n.PendingUpdates)`n"
	foreach ($update in $result.updates) {
		Write-CheckList $false $update.Title
	}
}