[CmdletBinding()]
param()

$from = 'from@example.com'
$to = 'to@example.com'
$sendGridApiKey = $env:SENDGRID_API_KEY

if (-not [string]::IsNullOrWhiteSpace($sendGridApiKey)) {
    $mailerPath = [IO.Path]::Combine($PSScriptRoot, './SecureAuditor-SendGrid.ps1')
    & $mailerPath -From $from -To $to -ApiKey $sendGridApiKey
    return
}

$smtpServer = 'smtp.example.com'
# $username = 'username'
# $password = 'password' | ConvertTo-SecureString -AsPlainText -Force
# $credential = New-Object Management.Automation.PSCredential ( $username, $password )

$mailerPath = [IO.Path]::Combine($PSScriptRoot, './SecureAuditor-SendMail.ps1')
& $mailerPath -From $from -To $to -SmtpServer $smtpServer # -Credential $credential
