[CmdletBinding()]
param()

if ($PSVersionTable.PSVersion.Major -lt 6) {
    # Progress bar can significantly impact cmdlet performance
    # https://github.com/PowerShell/PowerShell/issues/2138
    $ProgressPreference = 'SilentlyContinue'
}

Import-Module ([IO.Path]::Combine($PSScriptRoot, 'SecureAuditor.psm1')) -Force

$i18n = Data {
    # culture="en-US"
    ConvertFrom-StringData @'
    ClrVersion = .NET CLR Version
    Culture = Culture
    DateTime = DateTime
    Hostname = Hostname
    Hours = Hour(s)
    OS = OS
    Platform = Platform
    PowerShellVersion = PowerShell Version
    SystemInfo = System Information
    TimeZone = TimeZone
    UICulture = UI Culture
    UpTime = UpTime
'@
}

if ($PSUICulture -ne 'en-US') {
    Import-LocalizedData -BindingVariable i18n
}

$manifest = Import-PowerShellDataFile ([IO.Path]::Combine($PSScriptRoot, 'SecureAuditor.psd1'))

Write-Output "# Windows Secure Auditor: $($manifest.ModuleVersion)`n"

$config = Get-IniContent -file ([IO.Path]::Combine($PSScriptRoot, 'SecureAuditor.ini'))
$config = Get-IniContent -file ([IO.Path]::Combine($PSScriptRoot, 'SecureAuditor.local.ini')) -ini $config

# System Information
$now = Get-Date
Write-Output "## $($i18n.SystemInfo)`n"
Write-Output "- $($i18n.Hostname): $([environment]::MachineName)"
Write-Output "- $($i18n.TimeZone): $(Get-TimeZone)"
Write-Output ("- $($i18n.DateTime): {0:yyyy-MM-dd'T'HH:mm:ss}" -f $now)
Write-Output "- $($i18n.Culture): $($PSCulture)"
Write-Output "- $($i18n.UICulture): $($PSUICulture)"

if ($PSVersionTable.Platform -eq 'Win32NT') {
    # https://learn.microsoft.com/windows/win32/cimwin32prov/win32-operatingsystem
    $os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction SilentlyContinue
    Write-Output "- $($i18n.OS): $($os.Caption) - $($os.Version)"
    Write-Output ("- $($i18n.UpTime): {0:0.##} $($i18n.Hours)" -f ($now - $os.LastBootUpTime).TotalHours)
}
else {
    Write-Output "- $($i18n.OS): $($PSVersionTable.OS)"
    Write-Output ("- $($i18n.UpTime): {0:0.##} $($i18n.Hours)" -f (Get-Uptime).TotalHours)
}

Write-Output "- $($i18n.PowerShellVersion): $($PSVersionTable.PSVersion)"
Write-Output "- $($i18n.ClrVersion): $([Environment]::Version)"

if ($PSVersionTable.PSEdition -eq 'Desktop' -and $PSVersionTable.Platform -eq 'Win32NT') {
    $props = $config.ComputerInfo.Properties -split ',\s*'
    if ($props.Count -gt 0) {
        $info = Get-ComputerInfo -Property $props
        foreach ($prop in $props) {
            if ($prop -eq 'OsHotFixes' -and $info.OsHotFixes.Count -gt 0) {
                Write-Output "- OsHotFixes:"
                foreach ($hotFix in $info.OsHotFixes) {
                    Write-Output "  - $($hotFix.HotFixID): $($hotFix.InstalledOn) $($hotFix.Description)"
                }
                continue;
            }
            Write-Output "- $($prop): $($info.$prop)"
        }
    }
}

# Test Rules
Get-ChildItem -Path ([IO.Path]::Combine($PSScriptRoot, 'rules')) -Recurse -Filter *.psm1 | ForEach-Object {
    $ruleName = [System.IO.Path]::GetFileNameWithoutExtension($_.FullName)
    $exclude = $config.Rules.Exclude;
    if (-not [string]::IsNullOrWhiteSpace($exclude) -and $ruleName -match $exclude) {
        return
    }
    $include = $config.Rules.Include;
    if (-not [string]::IsNullOrWhiteSpace($include) -and $ruleName -notmatch $include) {
        return
    }
    try {
        $rule = Import-Module $_.FullName -AsCustomObject -PassThru -Force
        $rule.Test($config)
    }
    catch {
        $exception = $_.Exception;
        if ($null -ne $exception.InnerException) {
            $exception = $exception.InnerException
        }
        Write-Error -Message "> $($exception.Message)`n$($exception.ErrorRecord.InvocationInfo.PositionMessage)" -ErrorAction Stop
    }
}
