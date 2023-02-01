$i18n = Data {
    # culture="en-US"
    ConvertFrom-StringData @'
    DiskSpace = Disk Space
    Free = Free
    Used = Used
    Usage = Usage
'@
}

if ($PSUICulture -ne 'en-US') {
    Import-LocalizedData -BindingVariable i18n
}

function Test($config) {
    if (-not (Get-Command 'Get-PSDrive' -ErrorAction SilentlyContinue)) {
        $ruleName = [System.IO.Path]::GetFileNameWithoutExtension($PSCommandPath)
        Write-UnsupportedPlatform($ruleName)
        return
    }
    # https://learn.microsoft.com/powershell/module/microsoft.powershell.management/get-psdrive
    $drives = Get-PSDrive -PSProvider FileSystem | Where-Object { $null -ne $_.Used -and $_.Used -gt 0 }
    $exclude = $config.DiskSpace.Exclude
    if (-not [string]::IsNullOrWhiteSpace($exclude)) {
        $drives = $drives | Where-Object { $_.Name -inotmatch $exclude }
    }
    if ($drives.Count -eq 0) {
        return
    }
    Write-Output "`n## $($i18n.DiskSpace)`n"
    $maxUsage = $config.DiskSpace.MaxUsage
    foreach ($drive in $drives) {
        $usage = [Math]::Round(($drive.Used / ($drive.Used + $drive.Free)) * 100, 2)
        Write-CheckList ($usage -le $maxUsage) `
        ("$($drive.Name) | $($i18n.Used): {0:0.##} GB | $($i18n.Free): {1:0.##} GB | $($i18n.Usage): {2:0.##}% <= {3}%" `
                -f ($drive.Used / 1GB), ($drive.Free / 1GB), $usage, $maxUsage)
    }
}
