# Terraform Best Practices 

## Overview

Terraform is a leading Infrastructure as Code (IaC) tool. Its effectiveness at scale depends less on syntax and more on **state management**, **team workflows**, and **automation discipline**. The following summary distills **8 core best practices** that significantly improve reliability, collaboration, and safety in Terraform-based environments.

---

## Index – 8 Best Practices

1. [Manipulate State Only via Terraform Commands](#bp1)
2. [Use Remote State](#bp2)
3. [Enable State Locking](#bp3)
4. [Back Up the State File](#bp4)
5. [Use One State per Environment](#bp5)
6. [Store Terraform Code in Git](#bp6)
7. [Use CI for Terraform Code](#bp7)
8. [Execute Terraform Only via Automation](#bp8)

---

## 1. Manipulate State Only via Terraform Commands

Terraform state is a JSON file that represents the real infrastructure. Although editable, **manual changes must be avoided**. State should only be modified indirectly through `terraform plan` and `terraform apply` to prevent corruption and undefined behavior.

---

## 2. Use Remote State

Local state does not scale for teams. A **shared remote backend** (e.g., S3, Terraform Cloud, Azure Storage) ensures that all team members work against the same, up-to-date infrastructure state.

---

## 3. Enable State Locking

Concurrent Terraform executions can corrupt state. **State locking** prevents parallel modifications by allowing only one operation at a time. For example, S3 backends commonly use DynamoDB for locking.

---

## 4. Back Up the State File

State loss equals infrastructure blindness. Enable **versioning or backups** on the remote backend to recover from corruption, accidental deletion, or bad applies. This also provides an audit trail of infrastructure changes.

---

## 5. Use One State per Environment

Different environments (dev, test, prod) must be **fully isolated**. Each environment should have its own state file, backend, locking, and backup configuration to avoid cross-environment impact.

---

## 6. Store Terraform Code in Git

Terraform code is production code. It must live in a **dedicated Git repository**, enabling collaboration, history tracking, change review, and rollback—just like application code.

---

## 7. Use CI for Terraform Code

Changes to infrastructure must go through **code review and validation pipelines**. A CI process ensures formatting, validation, planning, and peer review before infrastructure is modified.

---

## 8. Execute Terraform Only via Automation

Terraform should never be applied manually from developer machines. All `terraform apply` operations must run from a **controlled, automated CI/CD pipeline**, creating a single, auditable source of truth for infrastructure changes.

---

## Key Takeaway

These practices align Terraform with **GitOps principles**: version-controlled intent, automated execution, and safe collaboration. Together, they transform Terraform from a local scripting tool into a **production-grade infrastructure platform**.

