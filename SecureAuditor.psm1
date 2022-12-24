$i18n = Data {
	# culture="en-US"
	ConvertFrom-StringData @'
	RequireAdministrator = Require Administrator
	SkipRule = Skip rule
'@
}

if ($PSUICulture -ne 'en-US'){
	Import-LocalizedData -BindingVariable i18n
}

# https://devblogs.microsoft.com/scripting/use-powershell-to-work-with-any-ini-file/
function Get-IniContent([string]$filePath, [hashtable]$ini = @{}) {
	if (-not (Test-Path $filePath -ErrorAction SilentlyContinue)) {
		return $ini;
	}
	switch -regex -file $filePath {
		"^\[(.+)\]" {
			# Section
			$section = $matches[1]
			$ini[$section] = if ($null -eq $ini[$section]) { @{} } else { $ini[$section] }
		}
		"^((;|#).*)$" {
			# Comment
			continue
		}
		"(.+?)\s*=\s*(.*)\s*" {
			# Key
			$name, $value = $matches[1..2]
			if ($null -eq $section){
				$section = 'Root'
			}
			$ini[$section][$name] = $value
		}
	}
	return $ini
}

function IsLocalAdministrator() {
	$principal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
	if ($principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)) {
		return $true;
	}
	return $false;
}

function Write-RequireAdministrators($ruleName) {
	Write-Host "`n> $($i18n.SkipRule): $($ruleName) ($($i18n.RequireAdministrator)) ..."
}

function Write-CheckList([bool]$pass, [string]$item) {
	Write-Output "- [$(if($pass) {'x'} else {' '})] $($item)"
}