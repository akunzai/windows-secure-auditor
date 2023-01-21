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
- 可覆寫的[配置](./SecureAuditor.ini)

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
# 執行此腳本
.\SecureAuditor.ps1

# 執行此腳本時顯示詳細資訊
. .\SecureAuditor.ps1 -Verbose
```

> 可透過在專案目錄建立 `SecureAuditor.local.ini` 來覆寫 `SecureAuditor.ini` 的對應配置

範例輸出

````markdown
# Windows Secure Auditor: 0.12.9

## 系統資訊

- OSName: Microsoft Windows Server 2019 Datacenter
- OsVersion: 10.0.17763
- OsLocale: zh-TW
- OsLocalDateTime: 01/04/2023 00:00:00
- TimeZone: (UTC+08:00) Taipei
- OsUpTime: 10.04:26:15.1008481

## 防毒軟體

- [x] 已安裝: Microsoft Defender 4.18.2211.5
- [x] 更新狀態: 2023-01-03T09:30:00+08:00 - 1.381.1994.0

## 磁碟空間

- [x] C | 已使用: 18.89 GB | 可用: 107.56 GB | 使用率: 14.94% <= 90%
- [x] D | 已使用: 1.04 GB | 可用: 6.96 GB | 使用率: 13.03% <= 90%

## 檔案完整性監控

### 已新增

- D:\Backup\website.2023-01-03.zip

### 已刪除

- D:\Backup\website.2022-12-26.zip

### 已異動

- D:\WebSites\example.com\web.config
  - 最後異動時間: 2023-01-02T16:00:00Z => 2023-01-3T16:00:00Z
  - 大小(位元): 128 => 129
  - 雜湊值(SHA256): EDEAAFF3F1774AD2888673770C6D64097E391BC362D7D6FB34982DDF0EFD18CB => E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855

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

## 密碼原則

- [x] 密碼最短使用期限(天): 1 >= 1
- [x] 密碼最長使用期限(天): 90 <= 90
- [x] 密碼長度下限: 12 >= 12
- [x] 密碼維護的歷程記錄長度: 3 >= 3

## 待安裝的 Windows 更新

- [x] Security Intelligence Update for Microsoft Defender Antivirus - KB2267602 (Version 1.381.1969.0)

## 失敗的 HTTP 請求

- 狀態碼: 500
  - `/api/search?q=test`: 1 次
- 狀態碼: 404
  - `/favicon.ico`: 2 次
  - `/robots.txt`: 1 次

## 預設帳號

- [x] Administrator: 不存在
- [x] Guest: 已停用

## 閒置帳號

- [ ] alice: 上次登入於 2021-01-01T09:10:00+08:00

## 密碼逾期

- [ ] WDeployAdmin: 密碼永不逾期

## 事件記錄

- 等級: 錯誤 | 事件識別碼: 2004
  - 記錄檔: Application
  - 來源: Microsoft-Windows-PerfNet
  - 計次: 1

```log
Unable to open the Server service performance object. The first four bytes (DWORD) of the Data section contains the status code.
```

- 等級: 錯誤 | 事件識別碼: 36874
  - 記錄檔: System
  - 來源: Schannel
  - 計次: 25

```log
An TLS 1.2 connection request was received from a remote client application, but none of the cipher suites supported by the client application are supported by the server. The TLS connection request has failed.
```

## 登入

- bob: 登入成功
  - 127.0.0.2: 7 次
- bob: 登入失敗
  - 127.0.0.3: 1 次

## 系統關機

- 2023-01-03T08:30:00+08:00 | 系統已重新開機，但未先正常關機。若系統停止回應、當機或電力意外中斷，就可能會造成此錯誤。
- 2023-01-03T23:00:00+08:00 | 處理程序 C:\Windows\system32\svchost.exe (DEMO)已代表使用者 NT AUTHORITY\SYSTEM 啟動電腦 DEMO 的電源關閉，原因如下: 作業系統: Service Pack (計劃之中)
 理由代碼: 0x80020010
 關機類型: 重新啟動
 註解:

## 軟體安裝

- Product: windows_exporter -- Installation completed successfully.
- Product: Bonjour -- Removal completed successfully.

## 使用者帳號管理

- 2023-01-03T21:20:00+08:00 | `bob` 刪除 `john`
- 2023-01-03T21:10:00+08:00 | `bob` 建立 `john`
````
