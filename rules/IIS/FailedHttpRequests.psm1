$i18n = Data {
    # culture="en-US"
    ConvertFrom-StringData @'
    FailedHttpRequests = Failed HTTP Requests
    StatusCode = Status code
    Times = Times
'@
}

if ($PSUICulture -ne 'en-US') {
    Import-LocalizedData -BindingVariable i18n
}

function Test($config) {
    $ruleName = [System.IO.Path]::GetFileNameWithoutExtension($PSCommandPath)
    if ($PSVersionTable.PSEdition -eq 'Core' -and $PSVersionTable.Platform -ne 'Win32NT') {
        Write-UnsupportedPlatform($ruleName)
        return
    }
    if (-not (IsLocalAdministrator)) {
        Write-RequireAdministrator($ruleName)
        return
    }
    $logFiles = Get-LogFile($config)
    if ($null -eq $logFiles -or $logFiles.Count -eq 0) {
        return
    }
    $today = Get-Date
    $days = [int]::Parse($config.FailedHttpRequests.Days) * -1
    $fromDate = $today.AddDays($days)
    $failedRequestsForStatus = @{}
    $verbose = $null -ne $PSCmdlet -and $PSCmdlet.MyInvocation.BoundParameters.ContainsKey("Verbose") -and $PSCmdlet.MyInvocation.BoundParameters["Verbose"] -eq $true
    foreach ($logFile in $logFiles) {
        Write-Verbose "Parsing: $($logFile) ..." -Verbose:$verbose
        $logs = Get-Content $logFile | Select-Object -skip 3 | Foreach-Object { $_ -replace '#Fields: ', '' } | ConvertFrom-Csv -Delimiter ' ' `
        | Where-Object { $_.date -ne 'date' -and $_.'sc-status' -gt '399' } `
        | Where-Object { $fromDate -lt [datetime]::Parse($_.date, [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::AdjustToUniversal).Add([timespan]::Parse($_.time, [System.Globalization.CultureInfo]::InvariantCulture)) } `
        | Group-Object -Property sc-status, cs-uri-stem
        if ($logs.Count -eq 0) {
            continue
        }
        foreach ($log in $logs) {
            $status = $log.Group[0].'sc-status'
            $url = $log.Group[0].'cs-uri-stem'
            if ($failedRequestsForStatus[$status] -isnot [hashtable]) {
                $failedRequestsForStatus[$status] = @{}
            }
            $failedRequestsForStatus[$status][$url] = $log.Count;
        }
    }
    if ($failedRequestsForStatus.Count -eq 0) {
        return
    }
    Write-Output "`n## $($i18n.FailedHttpRequests)`n"
    $maxRecords = [int]::Parse($config.FailedHttpRequests.MaxRecords)
    foreach ($status in $failedRequestsForStatus.Keys | Sort-Object -Descending) {
        Write-Output "- $($i18n.StatusCode): $($status)"
        $count = 0
        foreach ($url in $failedRequestsForStatus[$status].Keys) {
            if ($count -ge $maxRecords) {
                break
            }
            $times = $failedRequestsForStatus[$status][$url]
            Write-Output "  - $($url): $($times) $($i18n.Times)"
            $count += 1
        }
    }
}

function Get-LogFile($config) {
    Import-Module WebAdministration -ErrorAction SilentlyContinue
    if (-not (Get-Command 'Get-WebSite' -ErrorAction SilentlyContinue)) {
        return @()
    }
    $webSites = Get-WebSite | Where-Object { $_.State -eq 'Started' -and $_.LogFile.Enabled -eq $true }
    if ($null -eq $webSites -or $webSites.Count -eq 0) {
        return @()
    }
    $items = [System.Collections.ArrayList]::new()
    $today = Get-Date
    $days = [int]::Parse($config.FailedHttpRequests.Days) + 1
    $dates = [System.Linq.Enumerable]::Range(0, $days) | ForEach-Object { $today.AddDays($_ * -1) }
    foreach ($webSite in $webSites) {
        $logBasePath = [IO.Path]::Combine($webSite.LogFile.Directory.Replace('%SystemDrive%', $env:SystemDrive), ("W3SVC{0}" -f $webSite.Id))
        foreach ($date in $dates) {
            $logFilePath = [IO.Path]::Combine($logBasePath, ("u_ex{0:yyMMdd}.log" -f $date))
            if (Test-Path -Path $logFilePath -ErrorAction SilentlyContinue) {
                [void]$items.Add($logFilePath)
            }
        }
    }
    # enforce returning array
    return , $items.ToArray()
}
