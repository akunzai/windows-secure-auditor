$i18n = Data {
	# culture="en-US"
	ConvertFrom-StringData @'
    SoftwareInstallation = Software Installation
	Install = Install
	Removal = Removal
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
	$days = [int]::Parse($config.SoftwareInstallation.Days) * -1
	$maxEvents = [int]::Parse($config.Login.MaxEvents)
	# https://learn.microsoft.com/powershell/scripting/samples/creating-get-winevent-queries-with-filterhashtable
	$installEvents = Get-WinEvent -FilterHashtable @{ 
		LogName   = 'Application'
		Id        = 11707
		StartTime = (get-date).AddDays($days)
	} -MaxEvents $maxEvents -ErrorAction SilentlyContinue
	$removalEvents = Get-WinEvent -FilterHashtable @{ 
		LogName   = 'Application'
		Id        = 11724
		StartTime = (get-date).AddDays($days)
	} -MaxEvents $maxEvents -ErrorAction SilentlyContinue
	if ($installEvents.Count -eq 0 -and $removalEvents.Count -eq 0) {
		return
	}
	Write-Output "`n## $($i18n.SoftwareInstallation)`n"
	if ($installEvents.Count -gt 0) {
		Write-Output "`n### $($i18n.Install)`n"
		foreach ($event in $installEvents) {
			Write-Output "- $($event.Message)"
		}
	}
	if ($removalEvents.Count -gt 0) {
		Write-Output "`n### $($i18n.Removal)`n"
		foreach ($event in $removalEvents) {
			Write-Output "- $($event.Message)"
		}
	}
}