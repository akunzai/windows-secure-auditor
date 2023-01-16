[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [string]$From,
    [Parameter(Mandatory)]
    [string[]]$To,
    [string]$ApiKey,
    [switch]$UseSmtp,
    [switch]$UseSandbox
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

$subject = ("Secure Audit Report for {0}" -f [environment]::MachineName)
$auditorPath = [IO.Path]::Combine($PSScriptRoot, '../SecureAuditor.ps1')
$body = & $auditorPath | Out-String
$isHtml = $false
if (Get-Command 'ConvertFrom-Markdown' -ErrorAction SilentlyContinue) {
    # https://learn.microsoft.com/powershell/module/microsoft.powershell.utility/convertfrom-markdown
    $body = ($body | ConvertFrom-Markdown).Html
    $isHtml = $true
}

$config = Get-IniContent -file ([IO.Path]::Combine($PSScriptRoot, '../SecureAuditor.ini'))
$config = Get-IniContent -file ([IO.Path]::Combine($PSScriptRoot, '../SecureAuditor.local.ini')) -ini $config
if (-not [string]::IsNullOrWhiteSpace($config.FileIntegrityMonitoring.Paths)) {
    $attachmentPath = $config.FileIntegrityMonitoring.BaselinePath
    if (-not [IO.Path]::IsPathRooted($attachmentPath)) {
        $attachmentPath = [IO.Path]::Combine($PSScriptRoot, '..', $attachmentPath)
    }
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
    if ($isHtml) {
        $parameters.Add("BodyAsHtml", $true)
    }
    if ($null -ne $attachmentPath -and (Test-Path -Path $attachmentPath -ErrorAction SilentlyContinue)) {
        $filename = [IO.Path]::GetFileName($attachmentPath)
        $zipPath = [IO.Path]::Combine([System.IO.Path]::GetTempPath(), ("{0}.zip" -f $filename))
        Compress-Archive -LiteralPath $attachmentPath -DestinationPath $zipPath -CompressionLevel Optimal -Force
        $parameters.Add('Attachments', $zipPath)
    }
    Send-MailMessage @parameters
    return
}

# https://docs.sendgrid.com/api-reference/mail-send/mail-send
[mailaddress]$fromMail = $From
$parameters = @{
    subject          = $subject
    content          = @(@{
            type  = if ($isHtml) { 'text/html' } else { 'text/plain' };
            value = $body
        })
    from             = @{ email = $fromMail.Address }
    personalizations = @(
        @{ to = @() }
    )
}

if (![string]::IsNullOrWhiteSpace($fromaddr.DisplayName)) {
    $parameters.from.name = $fromaddr.DisplayName
}

if ($UseSandbox) {
    $parameters.mail_settings = @{
        sandbox_mode = @{
            enable = $true
        }
    }
}

if ($null -ne $attachmentPath -and (Test-Path -Path $attachmentPath -ErrorAction SilentlyContinue)) {
    $filename = [IO.Path]::GetFileName($attachmentPath)
    $zipPath = ("{0}.zip" -f [System.IO.Path]::GetTempFileName())
    Compress-Archive -LiteralPath $attachmentPath -DestinationPath $zipPath -CompressionLevel Optimal -Force
    # https://github.com/PowerShell/PowerShell/issues/14537
    $bytes = if ($PSVersionTable.PSEdition -eq 'Core') {
        Get-Content -Path $zipPath -AsByteStream
    }
    else {
        Get-Content -Path $zipPath -Encoding Byte
    }
    $content = [convert]::ToBase64String($bytes)
    $parameters.attachments = @(@{
            content  = $content
            type     = 'application/zip'
            filename = "$($filename).zip"
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

Invoke-WebRequest -Method POST -Uri 'https://api.sendgrid.com/v3/mail/send' `
    -Headers @{ Authorization = "Bearer $ApiKey" } `
    -ContentType 'application/json; charset=UTF-8' `
    -Body $json `
    -UseBasicParsing
