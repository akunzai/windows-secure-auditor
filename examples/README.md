# Example

## Translations

- [繁體中文](./README.zh-TW.md)

## Scheduling daily mailing of security audit reports

> Following scheduled task can be found in `Windows Task scheduler` under `/` folder

```powershell
# Create the task script from template
cp .\SecureAuditor-Task.Template.ps1 .\SecureAuditor-Task.ps1

# Modify the task script as you need
notepad .\SecureAuditor-Task.ps1

# Test the task script
.\SecureAuditor-Task.ps1

# Set up a daily schedule to execute the task script
$pwsh = if (Get-Command 'pwsh.exe' -ErrorAction SilentlyContinue) { 'pwsh.exe' } else { 'powershell.exe' }
$taskPath = Resolve-Path .\SecureAuditor-Task.ps1
Register-ScheduledTask -TaskName SecureAuditor `
-Trigger (New-JobTrigger -Daily -At 0am) `
-User SYSTEM `
-RunLevel Highest `
-Action (New-ScheduledTaskAction `
 -Execute $pwsh `
 -Argument "-NoProfile -ExecutionPolicy Bypass -File ""$taskPath""" `
 )
```
