$i18n = Data {
	# culture="en-US"
	ConvertFrom-StringData @'
    UserAccountCreated = User Account Created
    Creator = creator
	CreatedAt = created at
'@
}

if ($PSUICulture -ne 'en-US') {
	Import-LocalizedData -BindingVariable i18n
}

function Test($config) {
	if (-not (IsLocalAdministrator)) {
		$ruleName = [System.IO.Path]::GetFileNameWithoutExtension($PSCommandPath)
		Write-RequireAdministrator($ruleName)
		return
	}
	$days = [int]::Parse($config.UserAccountCreated.Days) * -1
	# https://learn.microsoft.com/windows/security/threat-protection/auditing/event-4720
	$events = Get-WinEvent -FilterHashtable @{ 
		LogName   = 'Security'
		Id        = 4720
		StartTime = (get-date).AddDays($days)
	} -ErrorAction SilentlyContinue
	if ($events.Count -eq 0) {
		return
	}
	Write-Output "`n## $($i18n.UserAccountCreated)`n"
	foreach ($event in $events) {
		$username = $event.Properties[0].Value
		$creator = $event.Properties[4].Value
		Write-Output ("- $($username), $($i18n.Creator): $($creator), $($i18n.CreatedAt): {0:o}" -f $event.TimeCreated)
	}
}