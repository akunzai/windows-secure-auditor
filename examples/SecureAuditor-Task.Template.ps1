$from = 'from@example.com'
$to = 'to@example.com'
$smtpServer = 'smtp.example.com'

$auditorPath = [IO.Path]::Combine($PSScriptRoot, '../SecureAuditor.ps1')
$mailerPath = [IO.Path]::Combine($PSScriptRoot, './SecureAuditor-SendMail.ps1')
& $mailerPath -AuditorPath $auditorPath -From $from -To $to -SmtpServer $smtpServer