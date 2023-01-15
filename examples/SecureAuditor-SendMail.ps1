param (
    [Parameter(Mandatory)]
    [string]$From,
    [Parameter(Mandatory)]
    [string[]]$To,
    [Parameter(Mandatory)]
    [string]$SmtpServer,
    [string]$Port = 25,
    [pscredential]$Credential = $null,
    [switch]$UseSSL
)

if ($PSVersionTable.PSVersion.Major -lt 6) {
    # Enable tls1.2 from default (Ssl3, Tls)
    # https://stackoverflow.com/questions/41618766/powershell-invoke-webrequest-fails-with-ssl-tls-secure-channel
    [Net.ServicePointManager]::SecurityProtocol = 'tls12, tls11, tls'

    # Progress bar can significantly impact cmdlet performance
    # https://github.com/PowerShell/PowerShell/issues/2138
    $ProgressPreference = 'SilentlyContinue'
}

$subject = ("Secure Audit Report for {0}" -f [environment]::MachineName)
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
$config = Get-IniContent -file ([IO.Path]::Combine($PSScriptRoot, '../SecureAuditor.ini'))
$config = Get-IniContent -file ([IO.Path]::Combine($PSScriptRoot, '../SecureAuditor.local.ini')) -ini $config
if (-not [string]::IsNullOrWhiteSpace($config.FileIntegrityMonitoring.Paths)) {
    $attachmentPath = $config.FileIntegrityMonitoring.BaselinePath
    if (-not [IO.Path]::IsPathRooted($attachmentPath)) {
        $attachmentPath = [IO.Path]::Combine($PSScriptRoot, '..', $attachmentPath)
    }
}
if ($null -ne $attachmentPath -and (Test-Path -Path $attachmentPath -ErrorAction SilentlyContinue)) {
    $filename = [IO.Path]::GetFileName($attachmentPath)
    $zipPath = [IO.Path]::Combine([System.IO.Path]::GetTempPath(), ("{0}.zip" -f $filename))
    Compress-Archive -LiteralPath $attachmentPath -DestinationPath $zipPath -CompressionLevel Optimal -Force
    $parameters.Add('Attachments', $zipPath)
}
Send-MailMessage @parameters
