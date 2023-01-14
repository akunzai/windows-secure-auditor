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

$config = Get-IniContent -file ([IO.Path]::Combine($PSScriptRoot, '../SecureAuditor.ini'))
$config = Get-IniContent -file ([IO.Path]::Combine($PSScriptRoot, '../SecureAuditor.local.ini')) -ini $config
$attachmentPath = $config.FileIntegrityMonitoring.BaselinePath
if (-not [IO.Path]::IsPathRooted($attachmentPath)) {
    $attachmentPath = [IO.Path]::Combine($PSScriptRoot, '..', $attachmentPath)
}

if ($UseSmtp) {
    $password = $ApiKey | ConvertTo-SecureString -AsPlainText -Force
    $credential = New-Object Management.Automation.PSCredential ( 'apikey', $password )
    # https://learn.microsoft.com/powershell/module/microsoft.powershell.utility/send-mailmessage
    $parameters = @{
        From       = $From
        To         = $To
        Subject    = $Subject
        Body       = $body
        Encoding   = 'UTF8'
        SmtpServer = 'smtp.sendgrid.net'
        Port       = 587
        UseSsl     = $true
        Credential = $credential
    }
    if (Test-Path -Path $attachmentPath -ErrorAction SilentlyContinue) {
        $parameters.Add('Attachments', $attachmentPath)
    }
    Send-MailMessage @parameters
    return
}

# https://docs.sendgrid.com/api-reference/mail-send/mail-send
[mailaddress]$fromMail = $From
$parameters = @{
    subject          = $subject
    content          = @(@{ type = 'text/plain'; value = $body })
    from             = @{ email = $fromMail.Address }
    personalizations = @(
        @{ to = @() }
    )
    attachments      = @()
}

if (![string]::IsNullOrWhiteSpace($fromaddr.DisplayName)) {
    $parameters.from.name = $fromaddr.DisplayName
}

if (Test-Path -Path $attachmentPath -ErrorAction SilentlyContinue) {
    $filename = [IO.Path]::GetFileName($attachmentPath)
    # https://github.com/PowerShell/PowerShell/issues/14537
    $bytes = if ($PSVersionTable.PSEdition -eq 'Core') {
        Get-Content -Path $attachmentPath -AsByteStream
    }
    else {
        Get-Content -Path $attachmentPath -Encoding Byte
    }
    $content = [convert]::ToBase64String($bytes)
    $parameters.attachments += @(@{
            content  = $content
            type     = 'text/csv'
            filename = $filename
        })
}

foreach ($email in $To) {
    [mailaddress]$toMail = $email
    $recipient = @{ email = $toMail.Address }
    if (![string]::IsNullOrWhiteSpace($toMail.DisplayName)) {
        $recipient.name = $toMail.DisplayName
    }
    $parameters.personalizations[0].to += @($recipient)
}

$json = $parameters | ConvertTo-Json -Depth 4 -Compress

Invoke-WebRequest -UseBasicParsing `
    -Uri https://api.sendgrid.com/v3/mail/send `
    -ContentType "application/json" `
    -Headers @{ Authorization = "Bearer $apiKey" } `
    -Method POST `
    -Body $json
