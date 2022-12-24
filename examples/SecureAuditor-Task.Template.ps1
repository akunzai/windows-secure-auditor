$from = 'from@example.com'
$to = 'to@example.com'
$smtpServer = 'smtp.example.com'

$auditorPath = Resolve-Path ../SecureAuditor.ps1
$mailerPath = Resolve-Path ./SecureAuditor-SendMail.ps1
& $mailerPath -AuditorPath $auditorPath -From $from -To $to -SmtpServer $smtpServer