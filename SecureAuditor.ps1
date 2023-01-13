if ($PSVersionTable.PSVersion.Major -lt 6) {
    # Progress bar can significantly impact cmdlet performance
    # https://github.com/PowerShell/PowerShell/issues/2138
    $ProgressPreference = 'SilentlyContinue'
}

Import-Module ([IO.Path]::Combine($PSScriptRoot, 'SecureAuditor.psm1')) -Force

$i18n = Data {
    # culture="en-US"
    ConvertFrom-StringData @'
	SystemInfo = System Information
	Error = Error
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
Write-Output "## $($i18n.SystemInfo)`n"
$props = $config.ComputerInfo.Properties -split ',\s*'
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
        Write-Host -ForegroundColor Red "`n> $($ruleName): $($i18n.Error)"
        Write-Host -ForegroundColor Red "> $_"
    }
}
