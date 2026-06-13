# Change Advisory Board (CAB) — Change Request

---

## Document Control

| Field | Details |
|---|---|
| **Document Title** | Infrastructure Automation via Terraform — CAB Change Request |
| **Project Name** | vm-ss-automation |
| **Prepared By** | Kishore Avula |
| **Department** | Corporate IT — Cloud Infrastructure Team |
| **Date Submitted** | 2026-06-12 |
| **Target Environment** | Azure (Dev → UAT → Production) |
| **Change Type** | Standard Change — New Capability Adoption |
| **Priority** | Medium |
| **Status** | Pending CAB Approval |

---

## 1. Executive Summary

This change request seeks formal CAB approval to adopt **Terraform** as the standard Infrastructure-as-Code (IaC) tool for provisioning and managing Azure cloud infrastructure across Corporate IT. The automation framework has been designed, built, and validated over several months and is now ready for official organizational adoption.

The goal is to replace manual, ad-hoc Azure portal provisioning with a repeatable, auditable, version-controlled deployment pipeline that reduces human error, enforces security standards, and accelerates environment delivery.

---

## 2. Business Justification

| Problem | Impact |
|---|---|
| Manual provisioning through the Azure Portal is error-prone | Config drift between environments; inconsistent security posture |
| No version history for infrastructure changes | Impossible to audit what changed, when, and by whom |
| Environment duplication takes days | Slows new project onboarding and release cycles |
| Security controls applied inconsistently | Risk of misconfigured resources reaching production |

**Expected Benefits after adoption:**

- **Consistency** — Identical infrastructure across Dev, UAT, and Production using the same codebase with environment-specific variable overrides
- **Speed** — New environment provisioning reduced from days to under 30 minutes
- **Auditability** — Every infrastructure change tracked in Git with author, timestamp, and reason
- **Security by Default** — Network isolation, managed identity, and Azure Policy enforced automatically at deploy time
- **Cost Visibility** — All resources tagged consistently, enabling accurate cost allocation by project, department, and environment

---

## 3. Scope of Change

### 3.1 What Is Changing

This change introduces a **Terraform-based automated provisioning framework** for Azure infrastructure. It does not modify existing production workloads. The framework provisions a standardized set of Azure resources per environment.

### 3.2 What Is NOT Changing

- Existing manually provisioned resources (no migration of existing infra in scope)
- Application code or CI/CD pipelines for application deployments
- Azure Active Directory / Entra ID configuration (identities, users, groups)
- Networking topology outside the provisioned VNets

### 3.3 Environments in Scope

| Environment | Purpose | Status |
|---|---|---|
| **Dev** | Development and validation | Ready |
| **UAT** | User acceptance testing and pre-prod validation | Ready |
| **Production** | Production workloads | Pending CAB approval |

---

## 4. Infrastructure Components Provisioned

The framework provisions the following Azure resources via Terraform modules:

| Module | Resource(s) Created | Purpose |
|---|---|---|
| **network** | VNet, 3 Subnets, NSG | Network isolation — Logic App, VM, and Private Endpoint subnets |
| **storage** | Storage Account | Backend storage for Logic App Standard |
| **dns_zone** | 5 Private DNS Zones + VNet links | DNS resolution for all private endpoints (blob, table, queue, file, Redis) |
| **private_endpoints** | 5 Private Endpoints | Removes public access for Storage and Redis; traffic stays on private network |
| **logic_app** | Logic App Standard, App Service Plan | Workflow automation engine |
| **vm** | Windows Virtual Machine, NIC | Automation and management VM |
| **identity** | User-Assigned Managed Identity | Passwordless authentication for Azure resources |
| **redis_cache** | Azure Managed Redis (Balanced tier) | Session state and caching layer |
| **monitoring** | Log Analytics Workspace, Application Insights | Centralized logging and performance monitoring |
| **governance** | Azure Policy Assignments, Management Lock | Tag enforcement and accidental-deletion protection |
| **diagnostic_setting** | Diagnostic Settings (per resource) | Forwards logs and metrics to Log Analytics Workspace |

### 4.1 Resource Naming Convention

All resources follow the standard naming pattern:

```
{resource-prefix}-{subscription-code}-{location-code}-{app-name}-{environment}-{instance}

Example: la-corit-eus-app-dev-01  (Logic App)
         rg-corit-eus-app-dev      (Resource Group)
         redis-corit-eus-app-dev-01 (Redis Cache)
```

---

## 5. Environment Strategy

Each environment (`dev`, `uat`, `prod`) uses the same Terraform codebase with a separate `.tfvars` file controlling environment-specific values:

| Parameter | Dev | UAT | Production |
|---|---|---|---|
| VM Size | Standard_D4s_v5 | Standard_D4s_v5 | Standard_D8s_v5 |
| Storage SKU | Standard_LRS | Standard_LRS | Standard_ZRS (Zone-Redundant) |
| Redis SKU | Balanced_B0 | Balanced_B0 | Balanced_B1 |
| Management Lock | CanNotDelete | CanNotDelete | CanNotDelete |
| VNet CIDR | 10.3.0.0/16 | 10.4.0.0/16 | 10.5.0.0/16 |

Terraform **state is isolated per environment**. No shared state between Dev, UAT, and Production.

---

## 6. Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Terraform misconfiguration deploys wrong resources | Low | Medium | `terraform plan` reviewed and approved before every `apply`; changes go Dev → UAT → Prod |
| State file corrupted or lost | Low | High | State stored in Azure Blob Storage with versioning and soft-delete enabled |
| Accidental resource deletion via `terraform destroy` | Low | High | `CanNotDelete` Management Lock applied to all resource groups |
| Credentials or secrets exposed in code | Very Low | Critical | No secrets in code; passwords in `.tfvars` (excluded from git via `.gitignore`); moving to Key Vault in next phase |
| Provider API breaking change | Low | Medium | Provider versions pinned (`azurerm ~> 4.0`, `azapi ~> 2.0`); upgrades tested in Dev first |
| Azure region service unavailability during deploy | Very Low | Low | Terraform is idempotent; re-run resumes from last successful state |

**Overall Risk Rating: LOW**

---

## 7. Rollback Plan

Terraform maintains a full state history. In the event of a failed or undesired deployment:

| Scenario | Rollback Procedure | Time Estimate |
|---|---|---|
| Failed `terraform apply` mid-run | Re-run `terraform apply` — Terraform will resume from current state | < 10 min |
| Resources need to be reverted to previous config | Revert the Git commit, run `terraform apply` with the previous code | 15–30 min |
| Full environment rollback | Run `terraform destroy` (requires Management Lock removal first) then re-apply previous version | 30–60 min |
| State file corruption | Restore state from Azure Blob Storage versioning | 10–15 min |

> **Note:** Management Locks must be manually removed by a privileged user before `terraform destroy` can execute. This is an intentional safeguard.

---

## 8. Testing & Validation

### 8.1 Testing Completed

| Test | Method | Result |
|---|---|---|
| `terraform validate` | Validates HCL syntax and provider schema | Passed |
| `terraform plan` — Dev | Reviewed plan output before apply | Passed |
| `terraform apply` — Dev | Full deployment to Dev environment | Passed |
| Private Endpoint connectivity | Verified PaaS resources unreachable via public internet | Passed |
| Managed Identity authentication | Logic App authenticated to Storage without access keys | Passed |
| Tag policy enforcement | Verified Azure Policy blocks resource groups missing required tags | Passed |
| Diagnostic settings | Confirmed logs flowing to Log Analytics Workspace | Passed |

### 8.2 Validation Before Production Apply

The following gates must pass before Production apply is approved:

- [ ] `terraform plan -var-file="environment/prod.tfvars"` output reviewed and signed off by lead engineer
- [ ] UAT environment has been running stable for minimum 72 hours
- [ ] Security team sign-off on Security Review document
- [ ] CAB approval obtained (this document)
- [ ] Maintenance window confirmed (recommended: off-peak hours)

---

## 9. Implementation Plan

| Step | Action | Owner | Duration |
|---|---|---|---|
| 1 | CAB approval obtained | Kishore Avula | — |
| 2 | Security team review and sign-off | Security Team | 2–3 days |
| 3 | `terraform init` and `terraform plan` run for Production | Kishore Avula | 30 min |
| 4 | Plan output reviewed by second engineer | Lead Engineer | 1 hour |
| 5 | `terraform apply` executed during maintenance window | Kishore Avula | 30–45 min |
| 6 | Post-deployment validation (connectivity, logging, policies) | Kishore Avula | 1 hour |
| 7 | Stakeholder notification of completion | Kishore Avula | 15 min |

---

## 10. Dependencies

| Dependency | Status |
|---|---|
| Azure Subscription with Contributor access | Available |
| Terraform CLI >= 1.3.0 installed on deployment machine | Available |
| Azure CLI authenticated (`az login`) | Required at deploy time |
| Terraform state storage (Azure Blob) configured | Required before Production apply |
| Security team review complete | Pending |

---

## 11. Stakeholder Sign-Off

> All approvers must sign before Production deployment proceeds.

| Role | Name | Approval | Date | Notes |
|---|---|---|---|---|
| Requestor | Kishore Avula | ✅ Submitted | 2026-06-12 | |
| Team Lead / Line Manager | | ☐ Pending | | |
| Security Team Lead | | ☐ Pending | | |
| Cloud Platform Owner | | ☐ Pending | | |
| CAB Chair | | ☐ Pending | | |

---

## 12. References

| Document | Location |
|---|---|
| Security & Procedure Document | `docs/Security-and-Procedures.md` |
| Terraform codebase | `vm-ss-automation/` (internal Git repository) |
| Azure Naming Convention | `locals.tf` |
| Environment configurations | `environment/dev.tfvars`, `environment/uat.tfvars`, `environment/prod.tfvars` |
