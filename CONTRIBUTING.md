# Contributing to Windows Secure Auditor

First off, thank you for considering contributing to Windows Secure Auditor! It's people like you that make it a great tool.

This guide outlines the process and conventions for contributing to the project.

## Table of Contents
1. [Reporting Bugs](#reporting-bugs)
2. [Suggesting Features](#suggesting-features)
3. [Running Tests & Linting](#running-tests--linting)
4. [Writing Custom Rules](#writing-custom-rules)
5. [Submitting Pull Requests](#submitting-pull-requests)

---

## Reporting Bugs

If you find a bug, please check the existing issues to see if it has already been reported. If not, open a new issue and include as much detail as possible:
*   **Operating System:** Exact Windows version/edition (e.g., Windows Server 2019 Datacenter).
*   **PowerShell Version:** Output of `$PSVersionTable.PSVersion`.
*   **Steps to Reproduce:** Clear instructions on how to trigger the bug.
*   **Actual vs. Expected Behavior:** What happened, and what you expected to happen instead.
*   **Logs/Output:** Any error messages, stack traces, or relevant console output.

---

## Suggesting Features

We welcome ideas for new features and audit rules! To suggest a feature:
1.  Check the existing issues to ensure it hasn't been requested already.
2.  Open a new issue describing:
    *   The problem you want to solve.
    *   The proposed solution or rule implementation.
    *   Any relevant security baseline or reference (e.g., CIS Benchmarks, Microsoft Security Baselines).

---

## Running Tests & Linting

Before submitting your code, make sure it is tested and follows the project's coding standards.

### 1. Manual Testing
Run the main script to verify your changes do not break the execution and output correct Markdown:
```powershell
# Run the auditor
.\SecureAuditor.ps1

# Run with verbose logging to inspect execution details
.\SecureAuditor.ps1 -Verbose
```

### 2. Linting (PSScriptAnalyzer)
We use [PSScriptAnalyzer](https://github.com/PowerShell/PSScriptAnalyzer) to enforce code quality and styling. The settings are defined in `PSScriptAnalyzerSettings.psd1`.

To run the linter locally:
1.  Install the module (if not already installed):
    ```powershell
    Install-Module PSScriptAnalyzer -Scope CurrentUser -Force
    ```
2.  Run the analyzer on the repository:
    ```powershell
    Invoke-ScriptAnalyzer -Path . -Settings PSScriptAnalyzerSettings.psd1 -Recurse
    ```
Ensure there are no errors or warnings before committing your changes.

---

## Writing Custom Rules

Windows Secure Auditor is built to be extensible. You can add new rules by creating a PowerShell script module (`.psm1`) in the `rules/` directory.

### Rule Directory Structure
Rules can be added directly under `rules/` or in a subdirectory (e.g., `rules/WinEvent/`) for organization:
```
rules/
├── zh-TW/                  # Root-level rules localization
│   └── MyRule.psd1
├── MyRule.psm1             # Rule module file
└── SubCategory/
    ├── zh-TW/              # Sub-category rules localization
    │   └── SubRule.psd1
    └── SubRule.psm1        # Sub-category rule module file
```

### Step-by-Step Guide to Adding a Rule

#### 1. Define Configuration in `SecureAuditor.ini`
If your rule requires settings or parameters, add a new section to `SecureAuditor.ini`:
```ini
[MyRule]
Enabled = true
MaxLimit = 5
```

#### 2. Create the Rule Module (`rules/MyRule.psm1`)
Create your rule script module. Every rule module must implement and export a `Test` function that accepts a `$config` parameter:

```powershell
# rules/MyRule.psm1

# 1. Define localizable strings (default: en-US)
$i18n = Data {
    # culture="en-US"
    ConvertFrom-StringData @'
    Header = My Custom Security Check
    ItemDescription = Validation check of MyRule limit
'@
}

# 2. Import localized strings if the UI culture is not en-US
if ($PSUICulture -ne 'en-US') {
    Import-LocalizedData -BindingVariable i18n
}

# 3. Implement the Test function
function Test($config) {
    $ruleName = [System.IO.Path]::GetFileNameWithoutExtension($PSCommandPath)

    # (Optional) Check for platform support
    if ($PSVersionTable.PSEdition -eq 'Core' -and $PSVersionTable.Platform -ne 'Win32NT') {
        Write-UnsupportedPlatform($ruleName)
        return
    }

    # (Optional) Check for Administrator privileges
    if (-not (IsLocalAdministrator)) {
        Write-RequireAdministrator($ruleName)
        return
    }

    # (Optional) Respect the enabled/disabled status in configuration
    # Note: SecureAuditor.ps1 automatically filters rules by Rules.Include/Rules.Exclude,
    # but rule-specific Enabled flags should be checked inside the Test function.
    if ($config.MyRule -and $config.MyRule.Enabled -eq 'false') {
        return
    }

    # 4. Output the results in Markdown format
    Write-Output "`n## $($i18n.Header)`n"

    # Get configuration value
    $limit = [int]$config.MyRule.MaxLimit

    # Run check logic
    $currentValue = 3 # (Replace with actual system check logic)
    $isPass = $currentValue -le $limit

    # 5. Use Write-CheckList to print standard pass/fail items
    # Format: Write-CheckList [bool] "message"
    Write-CheckList $isPass "$($i18n.ItemDescription): $currentValue <= $limit"
}
```

#### 3. Create Translation File (`rules/zh-TW/MyRule.psd1`)
To support translations, create a corresponding folder and `.psd1` file under `rules/zh-TW/`:
```powershell
# rules/zh-TW/MyRule.psd1
# culture="zh-TW"
ConvertFrom-StringData -StringData @'
Header = 我的自訂安全檢查
ItemDescription = MyRule 限制驗證檢查
'@
```

### Shared Helper Functions
The main module (`SecureAuditor.psm1`) provides several helper functions that you can use in your rules:
*   `IsLocalAdministrator()`: Returns `$true` if the current process is running with elevated Administrator privileges.
*   `Write-RequireAdministrator($ruleName)`: Prints a standard warning that the rule was skipped because it requires Administrator privileges.
*   `Write-UnsupportedPlatform($ruleName)`: Prints a standard warning that the rule was skipped because the OS platform is unsupported.
*   `Write-CheckList([bool]$pass, [string]$item)`: Outputs a checklist item formatted in Markdown: `- [x] Item` (pass) or `- [ ] Item` (fail).

---

## Submitting Pull Requests

1.  **Fork the repository** and create your branch from `main`:
    ```bash
    git checkout -b feature/my-new-rule
    ```
2.  **Keep changes focused.** Do not mix unrelated refactoring or formatting changes in your pull request.
3.  **Run linting and manual tests** to verify that everything works and complies with project standards.
4.  **Commit your changes** using descriptive and structured messages:
    ```bash
    git add .
    git commit -m "feat: add MyRule for monitoring xyz"
    ```
5.  **Push to your branch** and open a **Pull Request** to the `main` branch. Provide a clear description of the changes and reference any related issues.
