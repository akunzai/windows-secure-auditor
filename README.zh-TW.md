# Windows Secure Auditor

> 可產生每日稭查報表的 PowerShell 腳本, 類似 Windows 版的 [Logwatch](https://sourceforge.net/projects/logwatch/)

## 翻譯

- [English](./README.md)

## 環境需求

- .NET Framework Runtime >= 4.5
- PowerShell >= 5.1
- Windows 作業系統

## 功能特色

- 輸出為 Markdown 格式, 易於轉換為 HTML 格式
- 本地化
- 可擴充的[規則](./rules/)
- 可覆寫的配置 (`SecureAuditor.local.ini`)

## 使用方式

> 可在 [examples](./examples/) 看到更多使用範例

```powershell
# 產生資安稽查報告至標準輸出
.\SecureAuditor.ps1

# 產生資安稽查報告並轉換為 HTML 格式
(.\SecureAuditor.ps1 | ConvertFrom-Markdown).Html
```
