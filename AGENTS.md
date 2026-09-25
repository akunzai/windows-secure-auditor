# Windows Secure Auditor Developer Guidelines

PowerShell script to generate daily audit reports for Windows systems (similar to Logwatch), featuring modular rules, INI configuration, localization, and Markdown output.

## Commands

- Run auditor: `.\SecureAuditor.ps1`
- Run auditor (verbose): `.\SecureAuditor.ps1 -Verbose`
- Lint: `Invoke-ScriptAnalyzer -Path . -Settings PSScriptAnalyzerSettings.psd1 -Recurse`
- Run all tests: `Invoke-Pester -Path tests/ -PassThru`
- Run single test: `Invoke-Pester -Path tests/SecureAuditor.Tests.ps1`

## Pointers

- Auditor entry script: `SecureAuditor.ps1`
- Module manifest: `SecureAuditor.psd1`
- Core module functions: `SecureAuditor.psm1`
- Configuration specification: `SecureAuditor.ini`
- Audit rules: `rules/`
- Rule creation & contributing guide: `CONTRIBUTING.md`
- Gold-standard test: `tests/SecureAuditor.Tests.ps1`
- CI pipeline: `.github/workflows/build.yml`

## Prevent Recurrence

- **Candidate**: Name who hits this again, in which file, on what change. No such scenario, nothing to propose.
- **Promote**: Offer the first tier that reaches them and only that one, pending confirmation — enforce it (assert/type/test) with its size quoted, else a comment at that site, else an agent-facing doc (`docs/agents/<topic>.md`, else `docs/agents/lessons-learned.md`) with one backtick-path line under Pointers and one sentence on why the tiers above cannot hold it.
- **Prune**: When adding to a file, audit the rest of it in the same pass. Drop entries once stale (obsolete version, now enforced, duplicated, or a transcript) — not by a fixed count.
