# Windows Secure Auditor

> 可產生每日稽查報表的 PowerShell 腳本, 類似 Windows 版的 [Logwatch](https://sourceforge.net/projects/logwatch/)

## 翻譯

- [English](./README.md)

## 環境需求

- .NET Framework Runtime >= 4.5
- PowerShell >= 5.1
- Windows 作業系統

## 功能特色

- 輸出格式為 Markdown
- [本地化](https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_script_internationalization)
- 可擴充的[規則](./rules/)
- 可覆寫的配置 (`SecureAuditor.local.ini`)

## 安裝

> 需要使用 [git](https://git-scm.com/downloads)

```powershll
# 使用 git 複製此專案
git clone https://github.com/akunzai/windows-secure-auditor.git

# 進入專案目錄
cd windows-secure-auditor

# 未來可透過 `git pull` 來更新至最新版本
git pull
```

## 使用方式

> 可在 [examples](./examples/) 看到更多使用範例

```powershell
.\SecureAuditor.ps1
```

> 可透過在專案目錄建立 `SecureAuditor.local.ini` 來覆寫 `SecureAuditor.local.ini` 的對應配置

範例輸出

````markdown
# Windows Secure Auditor: 0.8.1

## 系統資訊

- OSName: Microsoft Windows Server 2019 Datacenter
- OsVersion: 10.0.17763
- OsLocale: en-US
- OsLocalDateTime: 01/04/2023 00:00:00
- TimeZone: (UTC+08:00) Taipei
- OsUpTime: 10.04:26:15.1008481
- OsHotFixes:
  - KB5020874: 12/25/2022 Update
  - KB4486153: 12/24/2022 Update
  - KB5012170: 12/24/2022 Security Update
  - KB5021237: 12/11/2022 Security Update
  - KB5020374: 12/11/2022 Security Update

## 防毒軟體

- [x] 已安裝: Windows Defender 4.18.2211.5
- [x] 更新狀態: 2023-01-03T09:30:00+08:00 - 1.381.1994.0

## 預設帳號

- [x] Administrator: 不存在
- [x] Guest: 已停用

## 磁碟空間

- [x] C: 容量: 126.45 GB, 可用空間: 107.56 GB, 使用率: 14.94% <= 90%
- [x] D: 容量: 8.00 GB, 可用空間: 6.96 GB, 使用率: 13.03% <= 90%

## 事件記錄

- 等級: 錯誤, 事件識別碼: 2004, 記錄檔: Application, 提供者: Microsoft-Windows-PerfNet, 計次: 1

```log
Unable to open the Server service performance object. The first four bytes (DWORD) of the Data section contains the status code.
```

- 等級: 錯誤, 事件識別碼: 36874, 記錄檔: System, 提供者: Schannel, 計次: 25

```log
An TLS 1.2 connection request was received from a remote client application, but none of the cipher suites supported by the client application are supported by the server. The TLS connection request has failed.
```

## 閒置帳號

- [ ] alice: 上次登入於 2021-01-01T09:10:00+08:00

## 登入

- bob: 登入成功
  - 127.0.0.2: 7 次
- bob: 登入失敗
  - 127.0.0.3: 1 次

## 網路校時

- [x] Windows 時間同步服務已啟動

```log
躍進式指示器: 0(沒有警告)
組織層: 3 (次要參照 - 依 (S)NTP 同步處理)
精確度: -23 (119.209ns 每個滴答)
根延遲: 0.0037284s
根散佈: 0.0346264s
參照識別碼: 0xC0A81704 (來源 IP:  127.0.0.3)
上次成功同步處理時間: 2023/1/3 下午 23:59:39
來源: time.windows.com,0x8
輪詢間隔: 6 (64s)
```

## 密碼逾期

- [ ] WDeployAdmin: 密碼永不逾期

## 密碼原則

- [x] 密碼最短使用期限(天): 1 >= 1
- [x] 密碼最長使用期限(天): 90 <= 90
- [x] 密碼長度下限: 12 >= 12
- [x] 密碼維護的歷程記錄長度: 3 >= 3

## 待安裝的 Windows 更新

- [ ] Security Intelligence Update for Microsoft Defender Antivirus - KB2267602 (Version 1.381.1969.0)

## 軟體安裝

- Product: windows_exporter -- Installation completed successfully.
- Product: Bonjour -- Removal completed successfully.

## 使用者帳號管理

- 2023-01-03T21:20:00+08:00| `bob` 刪除 `john`
- 2023-01-03T21:10:00+08:00| `bob` 建立 `john`
````
