# Windows Secure Auditor

> PowerShell script to generate daily audit report, like [Logwatch](https://sourceforge.net/projects/logwatch/) for Windows

## Translations

- [繁體中文](./README.zh-TW.md)

## Requirements

- .NET Framework Runtime >= 4.5
- PowerShell >= 5.1
- Windows OS

## Features

- Output as Markdown, make it easy to convert to HTML
- Localization
- Extensible [rules](./rules/)
- Overridable settings (`SecureAuditor.local.ini`)

## Usage

> See more sample usage in [examples](./examples/)

```powershell
# Generate audit report to Standard output
.\SecureAuditor.ps1

# Generate audit report and convert it to HTML
# The ConvertFrom-Markdown cmdlet was introduced since PowerShell 6.1
(.\SecureAuditor.ps1 | ConvertFrom-Markdown).Html
```
