$from = 'from@example.com'
$to = 'to@example.com'
$smtpServer = 'smtp.example.com'

$mailerPath = [IO.Path]::Combine($PSScriptRoot, './SecureAuditor-SendMail.ps1')
& $mailerPath -From $from -To $to -SmtpServer $smtpServer