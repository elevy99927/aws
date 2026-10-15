# Terraform Best Practices – Slide Outline (with real examples)

> ההדגמות כאן הן פרודקשן-אוריינטד (AWS), וכוללות backend, locking, versioning, ו-CI/CD. התאימי שמות/אזורים/חשבונות לפי הסטאק שלך.

---

## Slide 1 – Terraform Best Practices (Intro)

**Goal:** Build reliable, team‑scale Infrastructure as Code

* Terraform manages real infrastructure via state
* Failures usually come from **process**, not syntax
* These practices focus on safety, collaboration, and automation

**Example (minimal, runnable skeleton)**

```hcl
terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  type    = string
  default = "eu-west-1"
}
```

---

## Slide 2 – BP1: Manipulate State Only via Terraform Commands

**Problem:** Manual state edits cause corruption

* Terraform state is a JSON representation of real infra
* Manual edits bypass Terraform logic
* Leads to drift, broken plans, undefined behavior

**Best Practice**

* Modify state **only** via `terraform plan` / `terraform apply`

**Example (safe state operations)**

```bash
# 1) Always inspect before apply
terraform fmt -recursive
terraform validate
terraform plan -out=tfplan

# 2) Apply the exact plan you reviewed
terraform apply tfplan

# 3) If you must change state, do it via terraform state commands
terraform state list
terraform state show aws_s3_bucket.state

# Example: move an address after refactor (no manual JSON edits)
terraform state mv aws_s3_bucket.old aws_s3_bucket.new

# Example: remove a resource from state (rare; only if you know why)
terraform state rm aws_iam_role.legacy
```

---

## Slide 3 – BP2: Use Remote State

**Problem:** Local state doesn’t work in teams

* Each engineer needs the latest state
* Local files cause conflicts and drift

**Best Practice**

* Store state in a **remote backend**

**Example (S3 backend, per env key)**

```hcl
terraform {
  backend "s3" {
    bucket         = "mycompany-terraform-state"
    key            = "platform/dev/terraform.tfstate" # env-specific
    region         = "eu-west-1"
    encrypt        = true
    dynamodb_table = "mycompany-terraform-locks"
  }
}
```

**Example (bootstrap backend resources – run once, separate stack)**

```hcl
# backend-bootstrap/main.tf
provider "aws" {
  region = "eu-west-1"
}

resource "aws_s3_bucket" "tf_state" {
  bucket = "mycompany-terraform-state"
}

resource "aws_s3_bucket_versioning" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_dynamodb_table" "tf_locks" {
  name         = "mycompany-terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
```

---

## Slide 4 – BP3: Enable State Locking

**Problem:** Concurrent Terraform runs corrupt state

* Two applies at the same time = broken infra

**Best Practice**

* Enable **state locking** in the backend

**Example (S3 + DynamoDB locking)**

```hcl
terraform {
  backend "s3" {
    bucket         = "mycompany-terraform-state"
    key            = "platform/dev/terraform.tfstate"
    region         = "eu-west-1"
    encrypt        = true
    dynamodb_table = "mycompany-terraform-locks" # enables locking
  }
}
```

**Validation (what you see when a lock exists)**

```bash
terraform apply
# Error: Error acquiring the state lock
# ... Lock Info:
#   ID:        ...
#   Operation: OperationTypeApply
#   Who:       ci@runner
#   Created:   ...
```

---

## Slide 5 – BP4: Back Up the State File

**Problem:** Lost or corrupted state = infra blindness

* Accidental overwrite
* Backend failure
* Human error

**Best Practice**

* Enable **versioning / backups** on the state backend

**Example (S3 versioning + basic safety posture)**

```hcl
resource "aws_s3_bucket_versioning" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Optional: block public access (recommended)
resource "aws_s3_bucket_public_access_block" "tf_state" {
  bucket                  = aws_s3_bucket.tf_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```

**Operational example (restore a previous version)**

```bash
# You restore previous object version via S3 versioning (console/CLI),
# then re-run terraform plan/apply from CI.
```

---

## Slide 6 – BP5: One State per Environment

**Problem:** Mixing environments is dangerous

* Dev, test, prod have different lifecycles
* Shared state causes cross‑environment damage

**Best Practice**

* One isolated state per environment (separate state files)

**Example A (recommended): separate backend keys per environment)**

```hcl
# dev/backend.tf
terraform {
  backend "s3" {
    bucket         = "mycompany-terraform-state"
    key            = "platform/dev/terraform.tfstate"
    region         = "eu-west-1"
    encrypt        = true
    dynamodb_table = "mycompany-terraform-locks"
  }
}

# prod/backend.tf
terraform {
  backend "s3" {
    bucket         = "mycompany-terraform-state"
    key            = "platform/prod/terraform.tfstate"
    region         = "eu-west-1"
    encrypt        = true
    dynamodb_table = "mycompany-terraform-locks"
  }
}
```

**Example B (workspaces – acceptable, but be consistent)**

```hcl
terraform {
  backend "s3" {
    bucket         = "mycompany-terraform-state"
    key            = "platform/terraform.tfstate" # workspace suffix is managed by backend
    region         = "eu-west-1"
    encrypt        = true
    dynamodb_table = "mycompany-terraform-locks"
  }
}

# CLI
terraform workspace new dev
terraform workspace select dev
```

---

## Slide 7 – BP6: Store Terraform Code in Git

**Problem:** Untracked infra changes

* No history
* No review
* No rollback

**Best Practice**

* Treat Terraform like application code
* Store in a **dedicated Git repository**

**Example (repo layout that scales)**

```text
infra/
  modules/
    vpc/
    eks/
    rds/
  envs/
    dev/
      main.tf
      backend.tf
      versions.tf
      variables.tf
      dev.tfvars
    prod/
      main.tf
      backend.tf
      versions.tf
      variables.tf
      prod.tfvars
  .github/workflows/
    terraform-plan.yml
    terraform-apply.yml
```

**Example (module usage)**

```hcl
# envs/dev/main.tf
module "vpc" {
  source = "../../modules/vpc"

  name   = "platform-dev"
  cidr   = "10.10.0.0/16"
}
```

---

## Slide 8 – BP7: Use CI for Terraform Code

**Problem:** Direct commits = unsafe infrastructure

* No validation
* No peer review

**Best Practice**

* CI pipeline for Terraform (`fmt`, `validate`, `plan`)
* PR/MR review gates

**Example (GitHub Actions – plan on PR)**

```yaml
name: terraform-plan
on:
  pull_request:
    paths:
      - "infra/**"

jobs:
  plan:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      pull-requests: write

    steps:
      - uses: actions/checkout@v4

      - uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: 1.9.4

      - name: Terraform fmt
        working-directory: infra/envs/dev
        run: terraform fmt -check -recursive

      - name: Terraform init
        working-directory: infra/envs/dev
        run: terraform init -input=false

      - name: Terraform validate
        working-directory: infra/envs/dev
        run: terraform validate

      - name: Terraform plan
        working-directory: infra/envs/dev
        env:
          AWS_REGION: eu-west-1
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        run: terraform plan -input=false -no-color
```

---

## Slide 9 – BP8: Execute Terraform Only via Automation

**Problem:** Manual applies from laptops

* No audit trail
* No control
* Environment‑dependent behavior

**Best Practice**

* `terraform apply` runs only from CI/CD (single controlled execution point)

**Example (GitHub Actions – apply on main, with environment protection)**

```yaml
name: terraform-apply
on:
  push:
    branches: ["main"]
    paths:
      - "infra/**"

jobs:
  apply:
    runs-on: ubuntu-latest
    environment: prod # use GitHub "Environments" for manual approvals

    steps:
      - uses: actions/checkout@v4

      - uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: 1.9.4

      - name: Terraform init
        working-directory: infra/envs/prod
        run: terraform init -input=false

      - name: Terraform apply
        working-directory: infra/envs/prod
        env:
          AWS_REGION: eu-west-1
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        run: terraform apply -auto-approve -input=false
```

---

## Slide 10 – Key Takeaway

**Terraform at scale = GitOps**

* Version‑controlled intent
* Automated execution
* Locked, backed‑up state
* Safe collaboration

Terraform becomes a **production‑grade platform**, not a script.

**Example (one-liner principle)**

```text
All infra changes happen via PR -> CI plan -> review -> merge -> CD apply
```
