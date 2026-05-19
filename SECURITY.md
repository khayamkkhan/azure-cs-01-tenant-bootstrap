# Security Policy

## Project scope

This repository contains a hardened Azure tenant baseline (resource group, Log Analytics workspace, tag policies, diagnostic settings, MFA-on-admin) deployed via Bicep, as the foundation for the Microsoft Cybersecurity Architect Portfolio (Projects 02–09).

It is a personal learning/portfolio repository — **not a production system** — and does not handle real user data, secrets, or live workloads. However, because the patterns here are meant to be referenced and reused by others studying Azure security, responsible reports of issues in the configuration or documentation are welcomed.

## What counts as a security issue here

| In scope | Out of scope |
|---|---|
| Misconfigurations in `infra/baseline.bicep` that weaken the intended security posture | Suggestions to enable additional paid Defender plans (intentionally off for cost control) |
| Documentation that misleads readers into insecure setups | Stylistic preferences or unrelated linting |
| Leaked secrets, keys, or tenant identifiers in commit history | Theoretical attacks against Azure infrastructure itself |
| Bicep code that would deploy resources with hardcoded credentials, public exposure, or missing diagnostic logging | Issues in dependencies of dependencies |
| Tag policy bypasses or RBAC misuse patterns demonstrated in the build | Bugs in Azure itself (report to Microsoft Security Response Center) |

## How to report

Please **do not open a public GitHub issue** for anything that resembles a security concern. Instead, report privately via one of the following:

- **GitHub Security Advisories** — use the *Security* tab on this repository → *Report a vulnerability* (preferred — keeps history together with the fix)
- **Email** — `khan.khayam.koh@gmail.com` with subject prefix `[security][azure-cs-01]`
- **LinkedIn DM** — https://www.linkedin.com/in/khankhayamk/ (slower but works)

Please include:
- A clear description of the issue and the file(s) / commit(s) affected
- Repro steps (Bicep snippet, CLI command, or screenshot)
- The impact you believe it has (data exposure, privilege escalation, cost runaway, etc.)
- Optional: a suggested fix

## What I will do

- Acknowledge receipt within **5 business days**
- Triage and respond with my assessment within **14 business days**
- Credit reporters by name (unless they prefer otherwise) in the fix commit and in the project README's `## Acknowledgements` section
- Document fixes in the project's *Section 12 — Troubleshooting & Lessons Learned*, because real security feedback is some of the most valuable portfolio content there is

## What I won't do

- Threaten or pressure reporters
- Sit on disclosed issues — if I disagree, I'll explain why
- Pay bug bounties (this is a personal learning portfolio, not a funded program)

## Out-of-band notes

- The break-glass admin password mentioned in `BASELINE.md` is stored **offline only** and is never committed. Rotation procedure documented in the same file.
- All Bicep deployments are drift-validated with `az deployment sub what-if`; any unexplained drift is itself a security signal worth raising.

---

This file follows GitHub's recommended `SECURITY.md` format. See: <https://docs.github.com/code-security/getting-started/adding-a-security-policy-to-your-repository>.
