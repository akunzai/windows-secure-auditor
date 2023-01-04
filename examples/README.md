# Example

## Schedule daily email reports

> Scheduled task can be found in Windows Task scheduler under `/` folder

```powershell
# Create the task from template
Copy-Item ./SecureAuditor-Task.Template.ps1 -Destination ./SecureAuditor-Task.ps1

# Modify task as you need
notepad ./SecureAuditor-Task.ps1

# Test task
./SecureAuditor-Task.ps1

# Schedule daily task
$taskPath = Resolve-Path ./SecureAuditor-Task.ps1
Register-ScheduledTask -TaskName SecureAuditor `
-Trigger (New-JobTrigger -Daily -At 0am) `
-User SYSTEM `
-RunLevel Highest `
-Action (New-ScheduledTaskAction `
 -Execute powershell `
 -Argument "-NoProfile -ExecutionPolicy Bypass -File ""$taskPath""" `
 )
```
