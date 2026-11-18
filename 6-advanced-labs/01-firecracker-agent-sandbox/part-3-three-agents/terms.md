# Part 3: the terms

The technical terms used in [Part 3: Three agents, one job](README.md), in the order they appear. One line each; the lab page has the details. Part 2's terms (microVM, TAP, NAT, base image, …) are in [Part 2's list](../part-2-ubuntu-microvm/terms.md).

| Term | What it means here |
|---|---|
| **Agent** | In this part, a container with one job and a fixed contract. No AI yet; in Part 5 an LLM gets the same contract |
| **Agent contract** | A formal definition of how agents talk to each other, divide the responsibility and pass results: six parts, input, output, responsibilities, permissions, error handling, acceptance criteria |
| **The contract** (ours) | What every agent gets and what it owes: the repository at `/workspace` (read-only) and `GIT_URL`, `REF` in; `/results/<agent>.json` and an exit code out |
| **Schema** | The agreed shape of a JSON result: which fields, which types. An output contract usually names one |
| **Acceptance criteria** | The conditions that say a task is done; here: the report exists and the exit code is 0 or 1 |
| **Job** | One run of `run-job.sh`: a fresh microVM, one repository, three agents, the results on the host, the VM destroyed |
| **Scanner** | A tool that looks for one kind of risk in code and reports it; deterministic: the same input gives the same report |
| **Trivy** | The `deps` agent: known vulnerabilities in dependencies (`vuln`) and bad configuration in Dockerfiles and IaC (`misconfig`) |
| **Semgrep** | The `code` agent: pattern rules over source code; here the registry rule sets `p/supply-chain` and `p/security-audit` plus two course rules |
| **Gitleaks** | The `secrets` agent: keys and tokens in the files and in the git history |
| **Rule set** | A collection of Semgrep rules; `p/…` names come from the Semgrep registry and are downloaded at bake time |
| **Vulnerability database** | Trivy's list of known CVEs per package version, downloaded at bake time and used offline |
| **CVE** | A public identifier of a known vulnerability (for example `CVE-2018-18074` in `requests` 2.19.1) |
| **Misconfiguration** | A risky setting in a Dockerfile or infrastructure file, such as a container that runs as root |
| **Install-time script** | `preinstall` or `postinstall` in `package.json`: code that runs on `npm install`, before anyone reads it |
| **Obfuscated string** | Code hidden in an encoded string (base64) and executed at run time; a red flag in an untrusted repository |
| **Docker Compose** | Runs the three agents from one file (`compose.yaml`), each in its own container, in parallel |
| **One-shot service** | A Compose service that runs once and exits, rather than a server that keeps running |
| **`network_mode: none`** | The container gets no network at all; the scanners have everything they need baked in |
| **`pull_policy: never`** | Compose must use the image already in the guest and never pull from a registry at job time |
| **Pinned image** | An image with an exact version tag (`aquasec/trivy:0.76.2`), so you know what ran |
| **Bake** | Put the images, the database and the rules into the base image once, so a job has nothing to download |
| **Base image, version 2** | `ubuntu-agents-base.ext4`: Part 2's base image plus git, the three images and their data |
| **`cp --sparse=always`** | Copies a disk image without writing its empty blocks: fast, and the copy takes no real space until the job writes |
| **`flock`** | A file lock; `run-job.sh` takes it so that only one job runs at a time (every job uses `tap0` and the address `172.16.0.2`) |
| **Exit code** | The number a process ends with: 0 clean, 1 findings, anything else failed. Compose reports one per service |
| **`summary.json`** | The job's result for the next part: one status per agent (`ok`, `findings`, `failed`) and a verdict (`clean`, `findings`, `failed`). Written on every path |
| **`jq`** | A command-line tool for JSON: writes the summary on the host and reads the reports |
| **`scp`** | Secure copy over SSH; brings the three reports from the guest to the host |
| **`trap … EXIT`** | A shell trap that runs the cleanup (summary, kill the VM, delete the disk copy) however the script ends |
| **Timeout** | `timeout 900` around the scan: a stuck scanner ends the job with a `failed` status instead of hanging |
| **Exit code 137** | A process killed by signal 9, usually the kernel's OOM killer when a container runs out of memory |
| **Blast radius** | How far a failure or an attack can reach; the microVM shrinks it, it doesn't make the code safe |
| **Pinned repository** | A repository and an exact commit (`ref`), so a job is repeatable |
