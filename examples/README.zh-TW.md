# 範例

## 翻譯

- [English](./README.md)

## 排程每日寄出資安稽查報表

> 下列排程可在 `Windows 工作排程器` 的根目錄找到

```powershell
# 自範本建立工作腳本
cp ./SecureAuditor-Task.Template.ps1 ./SecureAuditor-Task.ps1

# 依需求修改工作腳本
notepad ./SecureAuditor-Task.ps1

# 測試工作腳本
./SecureAuditor-Task.ps1

# 設置每日排程以執行工作腳本
$pwsh = if (Get-Command 'pwsh.exe' -ErrorAction SilentlyContinue) { 'pwsh.exe' } else { 'powershell.exe' }
$taskPath = Resolve-Path ./SecureAuditor-Task.ps1
Register-ScheduledTask -TaskName SecureAuditor `
-Trigger (New-JobTrigger -Daily -At 0am) `
-User SYSTEM `
-RunLevel Highest `
-Action (New-ScheduledTaskAction `
 -Execute $pwsh `
 -Argument "-NoProfile -ExecutionPolicy Bypass -File ""$taskPath""" `
 )
```
