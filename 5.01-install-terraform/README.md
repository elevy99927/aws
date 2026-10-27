# 5.01 Install Terraform

Terraform describes your infrastructure as code: you write the AWS resources you want in `.tf` files, and Terraform creates, changes and deletes them for you. This chapter installs it. The next chapters use it to build AWS resources.

The commands below come from HashiCorp's official page, [Install Terraform](https://developer.hashicorp.com/terraform/install). Check it for other systems and for the latest version (1.17.0 at the time of writing).

## Install (choose your system)

**macOS (Homebrew)**

```bash
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
```

To update later: `brew upgrade hashicorp/tap/terraform`.

**Windows**

1. Download the zip for your computer from the [install page](https://developer.hashicorp.com/terraform/install): **AMD64** for most PCs, **ARM64** for Arm laptops.
2. Unzip it. It contains a single file, `terraform.exe`. Move it to a folder such as `C:\terraform`.
3. Add the folder to your `PATH`: **Start → Edit the system environment variables → Environment Variables → Path → Edit → New**, enter `C:\terraform`, and choose **OK**.
4. Open a **new** terminal (PowerShell or Command Prompt), so it reads the new `PATH`.

**Linux: Ubuntu / Debian**

```bash
wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform
```

**Linux: Amazon Linux (EC2 and AWS CloudShell)**

```bash
sudo yum install -y yum-utils shadow-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
sudo yum install -y terraform
```

> **AWS CloudShell** keeps only your home directory between sessions. Terraform is installed outside it, so run these three commands again when you start a new session.

## Verify

```bash
terraform -version
```

```text
Terraform v1.17.0
on darwin_arm64
```

The version and platform depend on your computer (`linux_amd64`, `windows_amd64`, …). If you see `command not found` (or *not recognized* on Windows), open a new terminal; on Windows, also check the `PATH` step.

---

[⬅ Previous: 4.05 Support Plans & Course Review](../4.05-support-plans-and-review/README.md) | [🏠 Home](../README.md)

---
## Contact

For questions or feedback, feel free to reach out:

- **Email**: eyal@levys.co.il
- **GitHub**: [https://github.com/elevy99927](https://github.com/elevy99927)
