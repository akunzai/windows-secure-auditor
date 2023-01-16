$i18n = Data {
    # culture="en-US"
    ConvertFrom-StringData @'
    Added = Added
    Deleted = Deleted
    FileIntegrityMonitoring = File Integrity Monitoring
    Hash = Hash
    LastModified = Last Modified
    Modified = Modified
    Scanning = Scanning
    SizeInBytes = Size(Bytes)
    ElapsedTime = Elapsed time
'@
}

if ($PSUICulture -ne 'en-US') {
    Import-LocalizedData -BindingVariable i18n
}

function Test($config) {
    if ([string]::IsNullOrWhiteSpace($config.FileIntegrityMonitoring.Paths)) {
        return
    }
    $paths = $config.FileIntegrityMonitoring.Paths -split ',\s*'
    if ($paths.Count -eq 0) {
        return
    }
    $baselinePath = $config.FileIntegrityMonitoring.BaselinePath
    if (-not [IO.Path]::IsPathRooted($baselinePath)) {
        $baselinePath = [IO.Path]::Combine($PSScriptRoot, '..', $baselinePath)
    }
    if (-not (Test-Path -Path $baselinePath -ErrorAction SilentlyContinue)) {
        $files = Get-MonitoringFile($config)
        if ($files.Count -gt 0) {
            $files | Export-Csv -Path $baselinePath -NoTypeInformation -Encoding 'UTF8'
        }
        return
    }
    $baseline = Import-Csv -Path $baselinePath -Encoding 'UTF8'
    $files = Get-MonitoringFile($config)
    if ($files.Count -gt 0) {
        $files | Export-Csv -Path $baselinePath -NoTypeInformation -Encoding 'UTF8'
    }
    # https://learn.microsoft.com/powershell/module/microsoft.powershell.utility/compare-object
    $diff = Compare-Object -ReferenceObject $baseline -DifferenceObject $files -Property Path, LastModified, Size, Hash
    if ($null -eq $diff -or $diff.Count -eq 0) {
        return
    }
    $maxRecords = [int]::Parse($config.FileIntegrityMonitoring.MaxRecords)
    $hashAlgorithm = $config.FileIntegrityMonitoring.HashAlgorithm
    Write-Output "`n## $($i18n.FileIntegrityMonitoring)"
    $groupDiff = $diff | Group-Object -Property Path
    $addedFiles = $groupDiff | Where-Object { $_.Count -eq 1 -and $_.Group[0].SideIndicator -eq '=>' } | Select-Object -ExpandProperty Group -First $maxRecords
    if ($addedFiles.Count -gt 0) {
        Write-Output "`n### $($i18n.Added)`n"
        foreach ($file in $addedFiles) {
            Write-Output "- $($file.Path) | $($i18n.LastModified): $($file.LastModified), $($i18n.SizeInBytes): $($file.Size), $($i18n.Hash)($($hashAlgorithm)): $($file.Hash)"
        }
    }
    $deletedFiles = $groupDiff | Where-Object { $_.Count -eq 1 -and $_.Group[0].SideIndicator -eq '<=' } | Select-Object -ExpandProperty Group -First $maxRecords
    if ($deletedFiles.Count -gt 0) {
        Write-Output "`n### $($i18n.Deleted)`n"
        foreach ($file in $deletedFiles) {
            Write-Output "- $($file.Path) | $($i18n.LastModified): $($file.LastModified), $($i18n.SizeInBytes): $($file.Size), $($i18n.Hash)($($hashAlgorithm)): $($file.Hash)"
        }
    }
    $modifiedFiles = $groupDiff | Where-Object { $_.Count -eq 2 } | Select-Object -First $maxRecords
    if ($modifiedFiles.Count -gt 0) {
        Write-Output "`n### $($i18n.Modified)`n"
        foreach ($modified in $modifiedFiles) {
            $path = $modified.Name
            $old = $modified.Group | Where-Object { $_.SideIndicator -eq '<=' }
            $new = $modified.Group | Where-Object { $_.SideIndicator -eq '=>' }
            Write-Output "- $($path)"
            if ($old.LastModified -ne $new.LastModified) {
                Write-Output "  - $($i18n.LastModified): $($old.LastModified) => $($new.LastModified)"
            }
            if ($old.Size -ne $new.Size) {
                Write-Output "  - $($i18n.SizeInBytes): $($old.Size) => $($new.Size)"
            }
            if ($old.Hash -ne $new.Hash) {
                Write-Output "  - $($i18n.Hash)($($hashAlgorithm)): $($old.Hash) => $($new.Hash)"
            }
        }
    }
}

function Get-MonitoringFile($config) {
    $monitoringPaths = $config.FileIntegrityMonitoring.Paths -split ',\s*'
    $exclude = $config.FileIntegrityMonitoring.Exclude
    $hashAlgorithm = $config.FileIntegrityMonitoring.HashAlgorithm
    $items = [System.Collections.ArrayList]::new()
    $stopWatch = [System.Diagnostics.Stopwatch]::new()
    $verbose = $null -ne $PSCmdlet -and $PSCmdlet.MyInvocation.BoundParameters.ContainsKey("Verbose") -and $PSCmdlet.MyInvocation.BoundParameters["Verbose"] -eq $true
    $path = @{label = "Path"; expression = { $_.FullName } }
    $lastModified = @{label = "LastModified"; expression = { ("{0:yyyy-MM-dd'T'HH:mm:ssK}" -f $_.LastWriteTimeUtc) } }
    $size = @{label = "Size"; expression = { $_.Length } }
    # https://learn.microsoft.com/powershell/module/microsoft.powershell.utility/get-filehash
    $hash = @{label = "Hash"; expression = { (Get-FileHash -Path $_.FullName -Algorithm $hashAlgorithm).Hash } }
    foreach ($monitoringPath in $monitoringPaths) {
        $fsInfo = Get-Item $monitoringPath -Force -ErrorAction SilentlyContinue
        if ($null -eq $fsInfo) {
            continue
        }
        if ([string]::IsNullOrWhiteSpace($exclude) -and $fsInfo.FullName -imatch $exclude) {
            continue
        }
        $stopWatch.Restart()
        if ($fsInfo -is [System.IO.FileInfo]) {
            Write-Verbose "> $($i18n.Scanning): $($fsInfo.FullName) ..." -Verbose:$verbose
            $item = $fsInfo | Select-Object $path, $lastModified, $size, $hash
            $stopWatch.Stop()
            Write-Verbose "> $($i18n.ElapsedTime): $($stopWatch.Elapsed)" -Verbose:$verbose
            [void]$items.Add($item)
            continue
        }
        # https://learn.microsoft.com/powershell/module/microsoft.powershell.management/get-childitem
        $parameters = @{
            Path        = $monitoringPath
            File        = $true
            Force       = $true
            Recurse     = $true
            ErrorAction = 'SilentlyContinue'
        }
        $item = if ([string]::IsNullOrWhiteSpace($exclude)) {
            Get-ChildItem @parameters | ForEach-Object { Write-Verbose "> $($i18n.Scanning): $($_.FullName) ..." -Verbose:$verbose ; $_ } | Select-Object $path, $lastModified, $size, $hash
        }
        else {
            Get-ChildItem @parameters | Where-Object { $_.FullName -inotmatch $exclude } | ForEach-Object { Write-Verbose "> $($i18n.Scanning): $($_.FullName) ..." -Verbose:$verbose ; $_ } | Select-Object $path, $lastModified, $size, $hash
        }
        $stopWatch.Stop()
        Write-Verbose "> $($i18n.ElapsedTime): $($stopWatch.Elapsed)" -Verbose:$verbose
        if ($null -eq $item) {
            continue
        }
        if ($item -is [array]) {
            [void]$items.AddRange($item)
            continue
        }
        [void]$items.Add($item)
    }
    # enforce returning array
    return , $items.ToArray()
}
