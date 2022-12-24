param (
  [Parameter(Mandatory)]
  [string]$AuditorPath,
  [Parameter(Mandatory)]
  [string]$From,
  [Parameter(Mandatory)]
  [string[]]$To,
  [string]$apiKey,
  [bool]$useSmtp = $false
)

if ($PSVersionTable.PSVersion.Major -lt 6) {
  # Progress bar can significantly impact cmdlet performance
  # https://github.com/PowerShell/PowerShell/issues/2138
  $ProgressPreference = 'SilentlyContinue'
}

if ($env:SENDGRID_API_KEY) {
  $apiKey = $env:SENDGRID_API_KEY
}

$subject = "Secure Audit Report for $env:COMPUTERNAME"
$body = & $AuditorPath | Out-String

if ($useSmtp) {
  $password = $apiKey | ConvertTo-SecureString -AsPlainText -Force
  $credential = New-Object Management.Automation.PSCredential ( 'apikey', $password )
  # https://learn.microsoft.com/powershell/module/microsoft.powershell.utility/send-mailmessage
  Send-MailMessage -From $From -To $To `
    -Subject $subject `
    -Body $body `
    -Encoding UTF8 `
    -SmtpServer smtp.sendgrid.net `
    -Port 587 `
    -UseSSL `
    -Credential $credential
  return
}

# https://docs.sendgrid.com/api-reference/mail-send/mail-send
$parameters = @{
  subject          = $subject
  content          = @(@{ type = 'text/plain'; value = $body })
  from             = @{ email = $From }
  personalizations = @()
}

foreach ($email in $To) {
  $parameters.personalizations.Add(@{ to = @( @{ email = $email } ) })
}

$json = $parameters | ConvertTo-Json -Depth 4 -Compress

Invoke-WebRequest -UseBasicParsing `
  -Uri https://api.sendgrid.com/v3/mail/send `
  -ContentType "application/json" `
  -Headers @{ Authorization = "Bearer $apiKey" } `
  -Method POST `
  -Body $json