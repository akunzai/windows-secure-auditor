$i18n = Data {
    # culture="en-US"
    ConvertFrom-StringData @'
    Antivirus = Antivirus
    FailedToDetectAntivirus = Failed to detect AntiVirus
    Installed = Installed
    UpdatedStatus = Updated Status
'@
}

if ($PSUICulture -ne 'en-US') {
    Import-LocalizedData -BindingVariable i18n
}

function Test($config) {
    if (-not [bool]$config.Antivirus.Enabled) {
        return
    }
    if ($PSVersionTable.PSEdition -eq 'Core' -and $PSVersionTable.Platform -ne 'Win32NT') {
        $ruleName = [System.IO.Path]::GetFileNameWithoutExtension($PSCommandPath)
        Write-UnsupportedPlatform($ruleName)
        return
    }
    Write-Output "`n## $($i18n.Antivirus)`n"
    $osInfo = Get-CimInstance -ClassName Win32_OperatingSystem
    if ($osInfo.ProductType -ne 1) {
        # Windows Server
        # https://help.eset.com/efsw/9.0/en-US/work_wmi_provider_data.html
        $product = Get-CimInstance -Namespace root/ESET -ClassName ESET_Product -ErrorAction SilentlyContinue
        if ($null -ne $product) {
            Write-CheckList $true "$($i18n.Installed): $($product.Name) $($product.Version)"
            Write-CheckList ($product.StatusCode -eq 0) "$($i18n.UpdatedStatus): $($product.VirusDBLastUpdate) - $($product.VirusDBVersion)"
            return
        }
        # The Microsoft Defender module was not found before Windows Server 2016
        # https://www.powershellgallery.com/packages/WindowsDefender/
        if (Get-Command 'Get-MpComputerStatus' -ErrorAction SilentlyContinue) {
            # https://learn.microsoft.com/powershell/module/defender/get-mpcomputerstatus
            $product = Get-MpComputerStatus -ErrorAction SilentlyContinue
            if ($null -ne $product) {
                Write-CheckList $product.AntivirusEnabled "$($i18n.Installed): Microsoft Defender $($product.AMProductVersion)"
                Write-CheckList (-not $product.DefenderSignaturesOutOfDate) ("$($i18n.UpdatedStatus): {0:yyyy-MM-dd'T'HH:mm:ssK} - $($product.AntivirusSignatureVersion)" -f $product.AntivirusSignatureLastUpdated)
                return
            }
        }
    }
    # https://jdhitsolutions.com/blog/powershell/5187/get-antivirus-product-status-with-powershell/
    $products = Get-CimInstance -Namespace root/SecurityCenter2 -ClassName AntivirusProduct -ErrorAction SilentlyContinue
    if ($null -eq $products -or $products.Count -eq 0) {
        Write-CheckList $false "$($i18n.Installed): $($i18n.FailedToDetectAntivirus)"
        Write-CheckList $false "$($i18n.UpdatedStatus): $($i18n.FailedToDetectAntivirus)"
        return
    }
    $enabled = $products | Where-Object { ('0x{0:x}' -f $_.ProductState).SubString(3, 2) -notmatch '00|01' } | Sort-Object -Property timestamp -Descending
    Write-CheckList ($enabled.Count -gt 0) "$($i18n.Installed): $($enabled[0].displayName)"
    if ($enabled.Count -gt 0) {
        $upToDate = $enabled | Where-Object { ('0x{0:x}' -f $_.ProductState).SubString(5) -eq '00' }
        Write-CheckList ($upToDate.Count -gt 0) "$($i18n.UpdatedStatus): $($upToDate[0].timestamp)"
    }
}
