# Getting Started: AWS Console & AWS CLI

Complete this module once, before you start the course labs.

## Sign in to the AWS Management Console

1. Open **https://console.aws.amazon.com**.
2. Choose how to sign in:
   - **IAM user** (recommended for the labs): enter the **Account ID** (12 digits) or the account alias, then your **IAM user name** and **password**.
   - **Root user**: enter the account's email address. Use it only for first-time setup, such as creating your first admin user and enabling MFA. **Don't use it for the labs.**
   - If your organization uses **IAM Identity Center**, use the **AWS access portal URL** you received instead, for example `https://d-xxxxxxxxxx.awsapps.com/start`.
3. Enter your **MFA code** if MFA is enabled.
4. Check the account and user name in the **top-right corner**, and select a **Region** in the Region selector. IAM is global, but S3 buckets and EC2 instances are Regional.

> Tip: IAM users can sign in directly with `https://<account-id>.signin.aws.amazon.com/console`. You can find this URL on the IAM Dashboard.

## Install the AWS CLI

Follow [Installing or updating the AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html), then check the installation:

```bash
aws --version          # aws-cli/2.x.x ...
```

## Give the CLI credentials (choose one option)

**Option 1 (recommended): `aws login` with your Console sign-in, no access keys**

```bash
aws login
```

A browser window opens. Sign in to the Console, or pick an existing session, and approve. The CLI receives **temporary credentials** and refreshes them automatically. If `aws login` isn't recognized, update the AWS CLI to the latest version.

**Option 2: access keys for an IAM user**

1. In the Console, open **IAM → Users → *your user* → Security credentials → Create access key**.
2. For the use case, select **Command Line Interface (CLI)**, confirm, and choose **Create access key**.
3. Copy the **Access key ID** and the **Secret access key**. The secret is shown **only once**.
4. Configure the CLI:

```bash
aws configure
# AWS Access Key ID [None]:     AKIA................
# AWS Secret Access Key [None]: ****************************************
# Default region name [None]:   eu-west-1
# Default output format [None]: json
```

The values are saved in `~/.aws/credentials` (the keys) and `~/.aws/config` (the Region and output format). You can keep several identities as **named profiles** with `aws configure --profile <name>`, and use one with `--profile <name>` or `export AWS_PROFILE=<name>`.

**Option 3: AWS CloudShell, no setup at all**

Choose the **CloudShell** icon (`>_`) in the Console's top bar. You get a terminal in the browser with the AWS CLI already installed and signed in as your Console identity.

## Verify

```bash
aws sts get-caller-identity
```

```json
{
    "UserId": "AIDAXXXXXXXXXXXXXXXXX",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/your-user-name"
}
```

If you see your account and user, you're ready.

> ⚠️ Treat access keys like passwords. Never commit them to Git or paste them in chats or tickets. Delete keys you no longer need from **IAM → Users → Security credentials**.

---

[⬅ 🏠 Home](../README.md) | [Next: 1.01 What is Cloud Computing? ➡](../1.01-what-is-cloud-computing/README.md)

---
## Contact

For questions or feedback, feel free to reach out:

- **Email**: eyal@levys.co.il
- **GitHub**: [https://github.com/elevy99927](https://github.com/elevy99927)
