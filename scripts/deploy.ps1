<#
.SYNOPSIS
    Runs Terraform init + action for a given environment.

.DESCRIPTION
    Authenticates via ARM_* environment variables (set by the pipeline).
    The backend state key is injected by the pipeline via TF_CLI_ARGS_init
    or -backend-config — this script does not manage it.

.EXAMPLE
    .\scripts\deploy.ps1 -Environment dev  -Action plan
    .\scripts\deploy.ps1 -Environment uat  -Action apply
    .\scripts\deploy.ps1 -Environment prod -Action apply
#>

param(
    [Parameter(Mandatory)]
    [ValidateSet("dev", "uat", "prod")]
    [string]$Environment,

    [Parameter(Mandatory)]
    [ValidateSet("plan", "apply", "destroy", "output")]
    [string]$Action
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Step([string]$Message) {
    Write-Host "`n==> $Message" -ForegroundColor Cyan
}

# ── Pre-flight ────────────────────────────────────────────────────────────────
Write-Step "Pre-flight checks"

if (-not (Get-Command terraform -ErrorAction SilentlyContinue)) {
    Write-Error "Terraform not found. Install from https://developer.hashicorp.com/terraform/downloads"
}
Write-Host "  terraform : $(terraform version -json | ConvertFrom-Json | Select-Object -ExpandProperty terraform_version)"

# ── terraform init ────────────────────────────────────────────────────────────
Write-Step "Running: terraform init"
terraform init -reconfigure

if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

# ── Run the requested action ──────────────────────────────────────────────────
$VarFile = "environment/$Environment.tfvars"
Write-Step "Running: terraform $Action  [-var-file=$VarFile]"

switch ($Action) {
    "plan"    { terraform plan    -var-file=$VarFile }
    "apply"   { terraform apply   -var-file=$VarFile -auto-approve }
    "destroy" { terraform destroy -var-file=$VarFile -auto-approve }
    "output"  { terraform output }
}

exit $LASTEXITCODE
