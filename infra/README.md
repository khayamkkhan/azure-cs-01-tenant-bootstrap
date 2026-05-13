# Bicep IaC — Tenant Baseline

This Bicep template reproduces the entire tenant baseline (Resource Group, Log Analytics workspace, Activity Log diagnostic setting, 3 tag policy assignments, monthly budget) **as code**.

It is the IaC counterpart to `../BASELINE.md`. If you want to re-create the baseline from scratch in a fresh tenant, deploy this template.

---

## What gets deployed

| # | Resource | Type | Scope |
|---|---|---|---|
| 1 | `rg-portfolio-baseline` | Resource Group | Subscription |
| 2 | `log-portfolio-baseline` | Log Analytics Workspace (PerGB2018, 30-day retention) | Inside RG |
| 3 | `send-activity-log-to-law` | Diagnostic Setting on the subscription Activity Log | Subscription |
| 4 | `require-tag-owner`, `require-tag-environment`, `require-tag-project` | 3 Policy Assignments (Audit mode) | Subscription |
| 5 | `portfolio-monthly-cap` | $10/month budget with 50% / 100% alert thresholds | Subscription |

What it does **NOT** deploy (intentional — out of scope for Project 01):

- Conditional Access policies (requires Entra P1 — Project 06)
- Defender for Cloud Standard plans (per-project as needed — Project 02)
- Networking, VMs, App Services (Projects 03+)
- Security Defaults (controlled at Entra ID tenant level, not Bicep)
- Break-glass user account (created interactively for safety — never in IaC)

---

## File layout

```
infra/
├── baseline.bicep            # Main subscription-scope template
└── modules/
    └── law.bicep             # Log Analytics workspace module (RG-scope)
```

---

## Prerequisites

- Azure CLI installed locally **OR** access to Azure Cloud Shell (built into portal — easier)
- Bicep CLI (auto-installed by Azure CLI on first use)
- Permissions: **Owner** or **Contributor + User Access Administrator** on the subscription

---

## How to validate (no-drift check)

Since the resources already exist (created via portal in Project 01 Block 1), running `what-if` shows whether this Bicep code accurately represents them. **Goal: "no changes" output.** If what-if shows changes, either the Bicep needs adjustment or the portal state has drifted from the documented baseline.

### Via Cloud Shell (recommended — no local install needed)

1. Open the Azure portal → click the **Cloud Shell** icon (terminal icon, top toolbar)
2. Choose **Bash**
3. Upload the `infra/` folder via Cloud Shell's upload button
4. Run:

```bash
az deployment sub what-if \
  --location eastus \
  --template-file baseline.bicep \
  --parameters alertEmail=khan.khayam.koh@gmail.com
```

### Via local Azure CLI

```bash
cd "infra/"
az login
az account set --subscription "Azure subscription 1"

az deployment sub what-if \
  --location eastus \
  --template-file baseline.bicep \
  --parameters alertEmail=khan.khayam.koh@gmail.com
```

### Expected output (success)

```
Resource changes: no changes.
```

This proves the Bicep is a faithful representation of the deployed baseline. Drift = something diverged.

---

## How to deploy (fresh tenant)

If you're applying this in a new subscription where nothing exists yet:

```bash
az deployment sub create \
  --location eastus \
  --template-file baseline.bicep \
  --parameters alertEmail=YOUR_EMAIL@example.com \
  --name "baseline-$(date +%Y%m%d-%H%M%S)"
```

Takes ~2 minutes. Verify the deployment in **Subscription → Deployments**.

---

## Parameter customization

Override defaults at deploy time:

```bash
az deployment sub create \
  --location eastus \
  --template-file baseline.bicep \
  --parameters \
      alertEmail=khan.khayam.koh@gmail.com \
      monthlyBudget=15 \
      retentionDays=60
```

| Parameter | Default | Notes |
|---|---|---|
| `location` | `eastus` | Region for RG + LAW |
| `rgName` | `rg-portfolio-baseline` | Resource group name |
| `workspaceName` | `log-portfolio-baseline` | Log Analytics name (must be globally unique within RG) |
| `defaultTags` | `{owner, environment, project}` | Applied to RG + LAW |
| `alertEmail` | `khan.khayam.koh@gmail.com` | Budget alert recipient |
| `monthlyBudget` | `10` (USD) | Budget cap (constrained 1–100) |
| `retentionDays` | `30` | LAW retention (30 = free tier ceiling) |

---

## What this Bicep does NOT manage (and why)

| Resource | Why not in Bicep | How it's managed |
|---|---|---|
| **Security Defaults** | Entra tenant-level toggle, not deployable via Bicep | Manual: Entra ID → Properties → Manage security defaults |
| **Break-glass user account** | Risky to fully automate; passwords and offline storage are deliberate | Manual (one-time) — see `../BASELINE.md` |
| **Microsoft Authenticator enrollment** | Per-user MFA registration is end-user, not IaC | User self-enrolls via myaccount.microsoft.com |
| **`ASC Default` policy initiative** | Auto-assigned by Azure on every new subscription | Implicit — no action needed |

---

## References

- Microsoft Docs — [Bicep subscription-scope deployments](https://learn.microsoft.com/azure/azure-resource-manager/bicep/deploy-to-subscription)
- Microsoft Docs — [az deployment sub what-if](https://learn.microsoft.com/cli/azure/deployment/sub#az-deployment-sub-what-if)
- Built-in policy `871b6d14-10aa-478d-b590-94f262ecfa99` — [Require a tag on resources](https://learn.microsoft.com/azure/governance/policy/samples/built-in-policies#tags)
