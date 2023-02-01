# Windows Secure Auditor

> PowerShell script to generate daily audit report, like [Logwatch](https://sourceforge.net/projects/logwatch/) for Windows

## Translations

- [繁體中文](./README.zh-TW.md)

## Requirements

- PowerShell >= 5.1
- Windows Server 2012 R2 or newer

## Features

- Output as Markdown
- [Localization](https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_script_internationalization)
- Extensible [rules](./rules/)
- Overridable [settings](./SecureAuditor.ini)

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
# run this script
.\SecureAuditor.ps1

# run this script with verbose messages
. .\SecureAuditor.ps1 -Verbose
```

> The corresponding configuration of `SecureAuditor.ini` can be overridden by creating `SecureAuditor.local.ini` in the project directory

Sample output

````markdown
# Windows Secure Auditor: 0.13.5

## System Information

- OSName: Microsoft Windows Server 2019 Datacenter
- OsVersion: 10.0.17763
- OsLocale: en-US
- OsLocalDateTime: 01/04/2023 00:00:00
- TimeZone: (UTC+08:00) Taipei
- OsUpTime: 10.04:26:15.1008481

## Antivirus

- [x] Installed: Microsoft Defender 4.18.2211.5
- [x] Updated Status: 2023-01-03T09:30:00+08:00 - 1.381.1994.0

## Disk Space

- [x] C | Used: 18.89 GB | Free: 107.56 GB | Usage: 14.94% <= 90%
- [x] D | Used: 1.04 GB | Free: 6.96 GB | Usage: 13.03% <= 90%

## File Integrity Monitoring

### Added

- D:\Backup\website.2023-01-03.zip

### Deleted

- D:\Backup\website.2022-12-26.zip

### Modified

- D:\WebSites\example.com\web.config
  - Last Modified: 2023-01-02T16:00:00Z => 2023-01-3T16:00:00Z
  - Size(Bytes): 128 => 129
  - Hash(SHA256): EDEAAFF3F1774AD2888673770C6D64097E391BC362D7D6FB34982DDF0EFD18CB => E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855

## Network Time Protocol

- [x] Windows Time service started
- [x] NTP source: time.windows.com,0x8

```log
Leap Indicator: 0(no warning)
Stratum: 4 (secondary reference - syncd by (S)NTP)
Precision: -23 (119.209ns per tick)
Root Delay: 0.0037284s
Root Dispersion: 0.0346264s
ReferenceId: 0x142B5EC7 (source IP:  127.0.0.3)
Last Successful Sync Time: 1/3/2023 23:59:39 PM
Source: time.windows.com,0x8
Poll Interval: 6 (64s)
```

## Password Policy

- [x] Minimum password age(days): 1 >= 1
- [x] Maximum password age(days): 90 <= 90
- [x] Minimum password length: 12 >= 12
- [x] Password history size: 3 >= 3

## Pending Windows Update

- [x] Security Intelligence Update for Microsoft Defender Antivirus - KB2267602 (Version 1.381.1969.0)

## Failed HTTP Requests

- Status code: 500
  - `/api/search?q=test`: 1 Time(s)
- Status code: 404
  - `/favicon.ico`: 2 Time(s)
  - `/robots.txt`: 1 Time(s)

## Default Account

- [x] Administrator: not found
- [x] Guest: disabled

## Idle Account

- [ ] alice: last logon at 2021-01-01T09:10:00+08:00

## Password Expires

- [ ] WDeployAdmin: password never expires

## Event Logs

- Level: Error | Event ID: 2004
  - LogName: Application
  - Source: Microsoft-Windows-PerfNet
  - Count: 1

```log
Unable to open the Server service performance object. The first four bytes (DWORD) of the Data section contains the status code.
```

- Level: Error | Event ID: 36874
  - LogName: System
  - Source: Schannel
  - Count: 25

```log
An TLS 1.2 connection request was received from a remote client application, but none of the cipher suites supported by the client application are supported by the server. The TLS connection request has failed.
```

## Login

- bob: login success
  - 127.0.0.2: 7 Time(s)
- bob: login failed
  - 127.0.0.3: 1 Time(s)

## Shutdown

- 2023-01-03T08:30:00+08:00 | The system has rebooted without cleanly shutting down first.
- 2023-01-03T23:00:00+08:00 | The process C:\Windows\system32\svchost.exe (DEMO) has initiated the restart of computer DEMO on behalf of user NT AUTHORITY\SYSTEM for the following reason: Operating System: Service pack (Planned)
  Reason Code: 0x80020010
  Shutdown Type: restart
  Comment:

## Software Installation

- Product: windows_exporter -- Installation completed successfully.
- Product: Bonjour -- Removal completed successfully.

## User Account Management

- 2023-01-03T21:20:00+08:00 | `bob` delete `john`
- 2023-01-03T21:10:00+08:00 | `bob` create `john`
````
