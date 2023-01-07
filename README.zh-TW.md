# Windows Secure Auditor

> 可產生每日稽查報表的 PowerShell 腳本, 類似 Windows 版的 [Logwatch](https://sourceforge.net/projects/logwatch/)

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
.\SecureAuditor.ps1
```

範例輸出

````markdown
# Windows Secure Auditor: 0.0.12

## 系統資訊

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

## 預設帳號

- [x] Administrator: 不存在
- [x] Guest: 已停用

## 磁碟空間

- [x] C: 磁碟空間: 126.45 GB, 使用率: 14.94% <= 90%
- [x] D: 磁碟空間: 8.00 GB, 使用率: 13.03% <= 90%
- [x] E: 磁碟空間: 63.98 GB, 使用率: 14.77% <= 90%

## 事件記錄

- 等級: 錯誤, 事件識別碼: 2004, 記錄檔: Application, 計次: 1

```log
Unable to open the Server service performance object. The first four bytes (DWORD) of the Data section contains the status code.
```

- 等級: 錯誤, 事件識別碼: 36874, 記錄檔: System, 計次: 25

```log
An TLS 1.2 connection request was received from a remote client application, but none of the cipher suites supported by the client application are supported by the server. The TLS connection request has failed.
```

## 登入

- username 登入成功
  - 127.0.0.2: 7 次
- username 登入失敗
  - 127.0.0.3: 1 次

## 網路校時

- [x] Windows 時間同步服務已啟動

```log
Leap Indicator: 0(no warning)
Stratum: 4 (secondary reference - syncd by (S)NTP)
Precision: -23 (119.209ns per tick)
Root Delay: 0.0037284s
Root Dispersion: 0.0346264s
ReferenceId: 0x142B5EC7 (source IP:  20.43.94.199)
Last Successful Sync Time: 1/4/2023 9:41:39 PM
Source: time.windows.com,0x8 
Poll Interval: 6 (64s)
```

## 密碼逾期

- [ ] WDeployAdmin: 密碼永不逾期

## 密碼原則

- [x] 密碼最短使用期限(天): 1 >= 1
- [x] 密碼最長使用期限(天): 90 <= 90
- [x] 密碼長度下限: 12 >= 12
- [x] 密碼維護的歷程記錄長度: 3 >= 3
````
