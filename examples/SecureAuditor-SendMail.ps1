param (
	[Parameter(Mandatory)]
	[string]$From,
	[Parameter(Mandatory)]
	[string[]]$To,
	[Parameter(Mandatory)]
	[string]$SmtpServer,
	[string]$Port = 25,
	[pscredential]$Credential = $null,
	[bool]$UseSSL = $false
)

if ($PSVersionTable.PSVersion.Major -lt 6) {
	# Progress bar can significantly impact cmdlet performance
	# https://github.com/PowerShell/PowerShell/issues/2138
	$ProgressPreference = 'SilentlyContinue'
}

$subject = "Secure Audit Report for $env:COMPUTERNAME"
$auditorPath = [IO.Path]::Combine($PSScriptRoot, '../SecureAuditor.ps1')
$body = & $auditorPath | Out-String

# https://learn.microsoft.com/powershell/module/microsoft.powershell.utility/send-mailmessage
$parameters = @{
	From       = $From
	To         = $To
	Subject    = $Subject
	Body       = $Body
	Encoding   = 'UTF8'
	SmtpServer = $SmtpServer
	Port       = $Port
}
if ($useSsl -eq $true) {
	$parameters.Add('UseSSL', $true)
}
if ($credential -ne $null) {
	$parameters.Add('Credential', $Credential)
}
Send-MailMessage @parameters