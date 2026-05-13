# Azure Tenant Baseline

> **Snapshot date**: 2026-05-13
> **Owner**: Khayam Khan
> **Purpose**: Document the hardened baseline state of the Azure tenant created in Project 01. Every subsequent project in this portfolio (Projects 02–09) assumes this baseline exists.

---

## Identity

| Field | Value |
|---|---|
| **Tenant name** | Default Directory |
| **Tenant ID** | `a93600fa-d14b-4f18-b35d-a0fe4e44cf52` |
| **Primary domain** | `khankhayamkohgmail.onmicrosoft.com` |
| **Entra ID license** | Microsoft Entra ID Free |
| **Total users** | 2 (1 primary admin + 1 break-glass) |

### Global Administrators

| Account | UPN | Notes |
|---|---|---|
| Khayam Khan | `khan.khayam.koh@gmail.com` | Primary admin. MFA enrolled via Microsoft Authenticator. |
| Break Glass Admin | `breakglass@khankhayamkohgmail.onmicrosoft.com` | Emergency-only account. 32-char password stored offline. Created 2026-05-13. **Never used in normal operations.** |

---

## Authentication Hardening

| Control | Status | Method |
|---|---|---|
| Two-step verification (primary admin) | ✅ ON | Microsoft Authenticator (push notification) + email backup |
| Security Defaults (tenant-wide MFA enforcement) | ✅ Enabled | Free, no Entra P1 required |
| Break-glass account | ✅ Created | 32-char random password, stored offline in password manager |

**Why Security Defaults instead of Conditional Access**: Free tier (no Entra P1). Will revisit in Project 06 (Entra ID Zero Trust) where Conditional Access becomes available.

---

## Subscription

| Field | Value |
|---|---|
| **Subscription name** | Azure subscription 1 |
| **Subscription ID** | `e676f7e7-4a6f-4cbd-bf78-89dbee20edd4` |
| **Offer** | Free Trial → Pay-As-You-Go (after trial ends) |
| **Parent management group** | Tenant Root Group |
| **Primary region** | East US |

---

## Cost Discipline

| Control | Threshold | Action |
|---|---|---|
| **Budget alert (warning)** | $5 / month | Email notification to `khan.khayam.koh@gmail.com` |
| **Budget alert (stop)** | $10 / month | Email notification — investigate immediately |
| **Budget name** | `portfolio-monthly-cap` | Scope: subscription |
| **Budget reset** | Monthly | Expires 2030-01-01 |

**Rationale**: A portfolio at this stage should never exceed $10/mo. Any spend approaching the cap signals either an attack (crypto-mining, unauthorized resource creation) or a forgotten resource (App Gateway, Bastion, etc.) that needs immediate teardown.

---

## Foundation Resources (rg-portfolio-baseline)

| Resource | Type | Purpose |
|---|---|---|
| `rg-portfolio-baseline` | Resource Group | Holds all "always-on" baseline resources |
| `log-portfolio-baseline` | Log Analytics Workspace | Central logging destination for all subscription Activity Logs (and future Sentinel data) |

### Log Analytics Workspace details

| Field | Value |
|---|---|
| **Workspace ID** | `e4ef81c3-4921-4c02-b006-21b9f6707c25` |
| **Pricing tier** | Pay-as-you-go (PerGB2018) |
| **Region** | East US |
| **Retention** | 30 days (Free Tier of Log Analytics covers first 31 days, 5 GB/month) |

---

## Governance — Tag Policy

Three Azure Policy assignments at subscription scope, all in **Audit** mode (surfaces non-compliance without blocking deployments):

| Assignment | Required tag | Effect |
|---|---|---|
| `require-tag-owner` | `owner` | Audit |
| `require-tag-environment` | `environment` | Audit |
| `require-tag-project` | `project` | Audit |

**Standard tag values for this portfolio:**

| Tag | Value |
|---|---|
| `owner` | `khayam` |
| `environment` | `lab` (or `dev`, `prod` for later projects) |
| `project` | `baseline`, `contoso-webapp`, `sentinel-soc`, etc. — one per project |

**Future enforcement**: After 30 days of clean compliance, migrate effect from `Audit` → `Deny` to block untagged resources at creation time.

---

## Audit Trail — Diagnostic Settings

Activity Log is exported to `log-portfolio-baseline` for permanent KQL-queryable history.

| Setting | Value |
|---|---|
| **Diagnostic setting name** | `send-activity-log-to-law` |
| **Destination** | Log Analytics workspace `log-portfolio-baseline` |
| **Categories captured** | Administrative, Security, ServiceHealth, Alert, Recommendation, Policy, Autoscale, ResourceHealth (all 8) |

This is the foundation for every detection rule and IR investigation in Projects 02–09.

---

## Defender for Cloud (auto-applied)

The `ASC Default` policy initiative is auto-assigned by Azure to every new subscription. This is the free-tier Defender for Cloud baseline — provides security recommendations against the Microsoft Cloud Security Benchmark. No cost until Defender Standard plans are enabled (planned for Project 02).

---

## What This Baseline Does NOT Include (Scope Honesty)

| Out of scope | Why | Project that addresses it |
|---|---|---|
| Conditional Access policies | Requires Entra P1 ($6/user/month) | Project 06 — Entra ID Zero Trust |
| Defender for Cloud Standard plans | Cost — only enabled per-project as needed | Project 02 — Defender + Sentinel Tour |
| Hub-and-spoke network | No network resources yet | Project 03 — Hub-and-Spoke VNet |
| Sentinel workspace | Built on top of LAW in a later project | Project 05 — Sentinel SOC Build-Out |
| Custom domain | Requires Entra P1 + domain ownership | Optional, may skip |
| Privileged Identity Management (PIM) | Requires Entra P2 ($9/user/month) | Project 06 — Entra ID Zero Trust |

---

## Recovery / Disaster Plan

**If primary admin loses MFA device:**
1. Sign in with `breakglass@khankhayamkohgmail.onmicrosoft.com` using the offline-stored 32-char password
2. Complete MFA setup on whatever device is available (Security Defaults will force this)
3. Re-register primary admin's MFA from the break-glass account
4. Document the incident in `incidents/IR-NNN.md`

**If the subscription is suspended for cost:**
1. Sign in to Azure portal
2. Cost Management → Cost analysis → identify the offending resource
3. Delete or downgrade the resource
4. Contact Azure billing support if dispute needed

---

## Cleanup Policy

**Never delete:**
- `rg-portfolio-baseline` (and `log-portfolio-baseline` inside it)
- Policy assignments
- Cost alerts
- Diagnostic settings
- Break-glass account

These are foundational. Every later project depends on them. Idle cost: **~$2/month** (essentially free under Free Tier).

---

## Verification Commands

To verify the baseline state at any future date:

```bash
# Login
az login

# Confirm subscription
az account show --query "{name:name, id:id, state:state}"

# Confirm RG and tags
az group show --name rg-portfolio-baseline --query "{name:name, location:location, tags:tags}"

# Confirm LAW
az monitor log-analytics workspace show \
  --resource-group rg-portfolio-baseline \
  --workspace-name log-portfolio-baseline \
  --query "{name:name, retentionDays:retentionInDays, sku:sku.name}"

# List tag policies
az policy assignment list --query "[?contains(displayName, 'tag')].{name:name, scope:scope}"

# Confirm activity log diagnostic setting
az monitor diagnostic-settings subscription list --query "value[].{name:name, workspaceId:workspaceId}"

# Confirm both Global Admins
az ad user list --query "[].{displayName:displayName, upn:userPrincipalName}" -o table
```

---

## References

- Microsoft Learn — [AZ-900 learning path](https://learn.microsoft.com/training/courses/az-900t00)
- Microsoft Docs — [Security defaults in Microsoft Entra ID](https://learn.microsoft.com/entra/fundamentals/security-defaults)
- Microsoft Docs — [Azure Policy built-in policies](https://learn.microsoft.com/azure/governance/policy/samples/built-in-policies)
- Microsoft Docs — [Azure Activity Log diagnostic settings](https://learn.microsoft.com/azure/azure-monitor/essentials/activity-log)
