$i18n = Data {
    # culture="en-US"
    ConvertFrom-StringData @'
    DiskSpace = Disk space
    Usage = Usage
'@
}

if ($PSUICulture -ne 'en-US') {
    Import-LocalizedData -BindingVariable i18n
}

function Test($config) {
    Write-Output "`n## $($i18n.DiskSpace)`n"
    # https://learn.microsoft.com/windows/win32/cimwin32prov/win32-logicaldisk
    $logicalDisks = Get-WmiObject -Query "SELECT * FROM Win32_LogicalDisk Where Size > 0"
    $exclude = $config.DiskSpace.Exclude
    $maximunDiskUsage = $config.DiskSpace.MaximunDiskUsage
    foreach ($logicalDisk in $logicalDisks) {
        if (-not [string]::IsNullOrWhiteSpace($exclude) -and $logicalDisk.DeviceID -match $exclude) {
            continue
        }
        $diskUsage = [Math]::Round((($logicalDisk.Size - $logicalDisk.FreeSpace) / $logicalDisk.Size) * 100, 2)
        Write-CheckList ($diskUsage -le $maximunDiskUsage) "$($logicalDisk.DeviceID) $($i18n.DiskSpace): $(($logicalDisk.Size/1GB).ToString('F2')) GB, $($i18n.Usage): $($diskUsage)% <= $($maximunDiskUsage)%"
    }
}