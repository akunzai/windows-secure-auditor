$i18n = Data {
    # culture="en-US"
    ConvertFrom-StringData @'
    DiskSpace = Disk Space
    FreeSpace = FreeSpace
    Size = Size
    Usage = Usage
'@
}

if ($PSUICulture -ne 'en-US') {
    Import-LocalizedData -BindingVariable i18n
}

function Test($config) {
    if ($PSVersionTable.PSEdition -eq 'Core' -and $PSVersionTable.Platform -ne 'Win32NT') {
        $ruleName = [System.IO.Path]::GetFileNameWithoutExtension($PSCommandPath)
        Write-UnsupportedPlatform($ruleName)
        return
    }
    Write-Output "`n## $($i18n.DiskSpace)`n"
    # https://learn.microsoft.com/windows/win32/cimwin32prov/win32-logicaldisk
    $logicalDisks = Get-CimInstance -Query "SELECT * FROM Win32_LogicalDisk Where Size > 0"
    $exclude = $config.DiskSpace.Exclude
    $maxUsage = $config.DiskSpace.MaxUsage
    foreach ($logicalDisk in $logicalDisks) {
        if (-not [string]::IsNullOrWhiteSpace($exclude) -and $logicalDisk.DeviceID -match $exclude) {
            continue
        }
        $usage = [Math]::Round((($logicalDisk.Size - $logicalDisk.FreeSpace) / $logicalDisk.Size) * 100, 2)
        Write-CheckList ($usage -le $maxUsage) `
        ("$($logicalDisk.DeviceID) | $($i18n.Size): {0:0.##} GB | $($i18n.FreeSpace): {1:0.##} GB | $($i18n.Usage): {2:0.##}% <= {3}%" `
                -f ($logicalDisk.Size / 1GB), ($logicalDisk.FreeSpace / 1GB), $usage, $maxUsage)
    }
}
