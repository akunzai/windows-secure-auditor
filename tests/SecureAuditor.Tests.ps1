BeforeAll {
    Import-Module $PSScriptRoot/../SecureAuditor.psm1 -Force
}

Describe "SecureAuditor Module" {
    Context "Get-IniContent" {
        It "should return empty hashtable if file does not exist" {
            $result = Get-IniContent -filePath "nonexistent_file.ini"
            $result.Count | Should -Be 0
        }

        It "should parse sections and keys correctly" {
            $tempFile = [System.IO.Path]::GetTempFileName()
            @'
[SystemInfo]
Enabled = 1

[Rules]
Exclude = RuleA
'@ | Out-File -FilePath $tempFile -Encoding utf8

            try {
                $result = Get-IniContent -filePath $tempFile
                $result.SystemInfo.Enabled | Should -Be "1"
                $result.Rules.Exclude | Should -Be "RuleA"
            }
            finally {
                Remove-Item $tempFile -Force
            }
        }
    }
}
