param (
    [Parameter(Mandatory)]
    [string]$From,
    [Parameter(Mandatory)]
    [string[]]$To,
    [string]$ApiKey,
    [bool]$UseSmtp = $false
)

if ($PSVersionTable.PSVersion.Major -lt 6) {
    # Enable tls1.2 from default (Ssl3, Tls)
    # https://stackoverflow.com/questions/41618766/powershell-invoke-webrequest-fails-with-ssl-tls-secure-channel
    [Net.ServicePointManager]::SecurityProtocol = 'tls12, tls11, tls'

    # Progress bar can significantly impact cmdlet performance
    # https://github.com/PowerShell/PowerShell/issues/2138
    $ProgressPreference = 'SilentlyContinue'
}

if ([string]::IsNullOrWhiteSpace($ApiKey) -and -not [string]::IsNullOrWhiteSpace($env:SENDGRID_API_KEY)) {
    $ApiKey = $env:SENDGRID_API_KEY
}

$subject = "Secure Audit Report for $env:COMPUTERNAME"
$auditorPath = [IO.Path]::Combine($PSScriptRoot, '../SecureAuditor.ps1')
$body = & $auditorPath | Out-String

if ($UseSmtp) {
    $password = $ApiKey | ConvertTo-SecureString -AsPlainText -Force
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
    personalizations = New-Object System.Collections.ArrayList
}

foreach ($email in $To) {
    [void]$parameters.personalizations.Add(@{ to = @( @{ email = $email } ) })
}

$json = $parameters | ConvertTo-Json -Depth 4 -Compress

Invoke-WebRequest -UseBasicParsing `
    -Uri https://api.sendgrid.com/v3/mail/send `
    -ContentType "application/json" `
    -Headers @{ Authorization = "Bearer $apiKey" } `
    -Method POST `
    -Body $json
