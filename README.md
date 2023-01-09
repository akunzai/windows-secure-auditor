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

## Installation

> [git](https://git-scm.com/downloads) is required

```powershll
# Use git to clone this repo
git clone https://github.com/akunzai/windows-secure-auditor.git

# Enter the directory
cd windows-secure-auditor

# In the future, you can update to the latest version through `git pull`
git pull
```

## Usage

> See more sample usage in [examples](./examples/)

```powershell
.\SecureAuditor.ps1
```

> The corresponding configuration of `SecureAuditor.local.ini` can be overridden by creating `SecureAuditor.local.ini` in the project directory

Sample output

````markdown
# Windows Secure Auditor: 0.2.1

## System Information

- OSName: Microsoft Windows Server 2019 Datacenter
- OsVersion: 10.0.17763
- OsLocale: en-US
- OsLocalDateTime: 01/04/2023 21:41:44
- TimeZone: (UTC+08:00) Taipei
- OsUpTime: 10.04:26:15.1008481
- OsHotFixes:
  - KB5020874: 12/25/2022 Update
  - KB4486153: 12/24/2022 Update
  - KB5012170: 12/24/2022 Security Update
  - KB5021237: 12/11/2022 Security Update
  - KB5020374: 12/11/2022 Security Update

## Default Account

- [x] Administrator: not found
- [x] Guest: disabled

## Disk Space

- [x] C: Size: 126.45 GB, FreeSpace: 107.56 GB, Usage: 14.94% <= 90%
- [x] D: Size: 8.00 GB, FreeSpace: 6.96 GB, Usage: 13.03% <= 90%

## Event Logs

- Level: Error, Event ID: 2004, LogName: Application, ProviderName: Microsoft-Windows-PerfNet, Count: 1

```log
Unable to open the Server service performance object. The first four bytes (DWORD) of the Data section contains the status code.
```

- Level: Error, Event ID: 36874, LogName: System, ProviderName: Schannel, Count: 25

```log
An TLS 1.2 connection request was received from a remote client application, but none of the cipher suites supported by the client application are supported by the server. The TLS connection request has failed.
```

## Idle Account

- [ ] alice: last logon at 2022-01-01

## Login

- bob: login success
  - 127.0.0.2: 7 Times
- bob: login failed
  - 127.0.0.3: 1 Times

## Network Time Sync

- [x] Windows Time Service Started

```log
Leap Indicator: 0(no warning)
Stratum: 4 (secondary reference - syncd by (S)NTP)
Precision: -23 (119.209ns per tick)
Root Delay: 0.0037284s
Root Dispersion: 0.0346264s
ReferenceId: 0x142B5EC7 (source IP:  127.0.0.3)
Last Successful Sync Time: 1/4/2023 9:41:39 PM
Source: time.windows.com,0x8
Poll Interval: 6 (64s)
```

## Password Expires

- [ ] WDeployAdmin: password never expires

## Password Policy

- [x] Minimum password age(days): 1 >= 1
- [x] Maximum password age(days): 90 <= 90
- [x] Minimum password length: 12 >= 12
- [x] Password history size: 3 >= 3
````
