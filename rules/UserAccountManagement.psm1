$i18n = Data {
	# culture="en-US"
	ConvertFrom-StringData @'
	Create = create
	Delete = delete
    UserAccountManagement = User Account Management
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
	$days = [int]::Parse($config.UserAccountManagement.Days) * -1
	# https://learn.microsoft.com/powershell/scripting/samples/creating-get-winevent-queries-with-filterhashtable
	$events = Get-WinEvent -FilterHashtable @{ 
		LogName   = 'Security'
		Id        = 4720, 4726
		StartTime = (get-date).AddDays($days)
	} -ErrorAction SilentlyContinue
	if ($events.Count -eq 0) {
		return
	}
	Write-Output "`n## $($i18n.UserAccountManagement)`n"
	foreach ($event in $events) {
		$username = $event.Properties[0].Value
		$actor = $event.Properties[4].Value
		# https://learn.microsoft.com/windows/security/threat-protection/auditing/event-4720
		if ($event.Id -eq 4720) {
			Write-Output ("- {0:yyyy-MM-dd'T'HH:mm:ssK} | ``$($actor)`` $($i18n.Create) ``$($username)``" -f $event.TimeCreated)
		}
		# https://learn.microsoft.com/windows/security/threat-protection/auditing/event-4726
		elseif ($event.Id -eq 4726) {
			Write-Output ("- {0:yyyy-MM-dd'T'HH:mm:ssK} | ``$($actor)`` $($i18n.Delete) ``$($username)``" -f $event.TimeCreated)
		}
	}
}
