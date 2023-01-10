$i18n = Data {
	# culture="en-US"
	ConvertFrom-StringData @'
    Antivirus = Antivirus
    Installed = Installed
    UpToDate = Up-To-Date
'@
}

if ($PSUICulture -ne 'en-US') {
	Import-LocalizedData -BindingVariable i18n
}

function Test($config) {
	# https://jdhitsolutions.com/blog/powershell/5187/get-antivirus-product-status-with-powershell/
	$products = Get-CimInstance -Namespace root/SecurityCenter2 -ClassName AntivirusProduct -ErrorAction SilentlyContinue
	if ($null -eq $products -or $products.Count -eq 0) {
		# TODO: SecurityCenter2 was not available on Windows Server
		return
	}
	Write-Output "`n## $($i18n.Antivirus)`n"
	$enabled = $products | Where-Object { ('0x{0:x}' -f $_.ProductState).SubString(3, 2) -notmatch '00|01' } | Sort-Object -Property timestamp -Descending
	Write-CheckList ($enabled.Count -gt 0) "$($i18n.Installed): $($enabled[0].displayName)"
	if ($enabled.Count -gt 0) {
		$upToDate = $enabled | Where-Object { ('0x{0:x}' -f $_.ProductState).SubString(5) -eq '00' }
		Write-CheckList ($upToDate.Count -gt 0) "$($i18n.UpToDate): $($upToDate[0].timestamp)"
	}
}