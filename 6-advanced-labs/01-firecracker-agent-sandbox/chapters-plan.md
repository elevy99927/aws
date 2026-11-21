# Firecracker Lab: Run AI Agents in Isolated MicroVMs — plan

**Status:** 2026-11-13. Part 1 recorded, Part 2 built and tested (page: [`part-2-ubuntu-microvm`](part-2-ubuntu-microvm/README.md)), Part 3 built and tested (page: [`part-3-three-agents`](part-3-three-agents/README.md)). Five parts, one video each (Part 2 and Part 5 may each become two). The two earlier drafts in this folder (`firecracker_security_sandbox_lab_plan.md`, `ai_agents_business_use_case.md`) stay as background; this file is the plan.

**Name:** *Firecracker Lab: Run AI Agents in Isolated MicroVMs*. Same pattern as 3.01 Lab 4, *Firecracker Lab: Run Your Own MicroVM*. Runner-up: *Firecracker Lab: A PR-Triggered Agent Sandbox*. Folder: `01-firecracker-agent-sandbox`.

**Prerequisite:** 3.01 Lab 4 (the `m7i-flex.large` host with nested virtualization, Ubuntu 24.04, Firecracker v1.17.0, TAP networking, the API). The host stays the same; the guest changes from BusyBox to Ubuntu.

## The story in one paragraph

I want to run AI agents with a high level of isolation. There are managed and higher-level options (Bedrock AgentCore Runtime, Kata Containers), but I chose Firecracker: it is the engine behind Lambda and AgentCore, and I prefer to learn a technology from the lower level. I'm not 100% sure what the final scenario will be. For now: Firecracker with an Ubuntu guest; a GitHub webhook fires a Lambda on every pull request; the Lambda starts a microVM on the host; inside it three agents scan the code and produce JSON results. Later the agents get tokens and permissions, and talk through a Matrix home server in dedicated rooms. Maybe this isn't the best way to solve the problem. I'm doing it to learn the technology.

## Parts

| # | Part (video) | Kind | End state (the check) |
|---|---|---|---|
| 1 | **Define the problem** | Talk, slides and one diagram | The viewer knows the goal, the alternatives, why Firecracker, the target architecture and the roadmap |
| 2 | **An Ubuntu microVM** | Hands-on, plus a Terraform shortcut | Ubuntu 24.04 boots in Firecracker on the Lab 4 host; SSH, DNS and HTTPS work; Docker runs a container inside the guest. Saved as the clean base image |
| 3 | **Three agents, one job** | Hands-on | `run-job.sh <git-url> [ref]` boots a fresh microVM, runs three scanners on the repo, leaves three JSON files and a summary on the host, and destroys the VM |
| 4 | **Lambda and the webhook** | Hands-on | A pull request on GitHub starts a job on the host with no manual step; results land in S3; a status appears on the PR |
| 5 | **The full system** | Hands-on, probably two videos | Terraform provisions everything; an AI reviewer agent reads the scanners' output with a short-lived token; agents and humans meet in a Matrix room per PR |

### Part 1 — Define the problem

A talk, no terminal. 6–8 minutes.

1. The goal: run AI agents on untrusted input with strong isolation.
2. The options: plain containers (shared kernel), Kata Containers (VM-backed containers, can use Firecracker underneath), Bedrock AgentCore Runtime (managed, microVM per session). Why Firecracker directly: it's the engine under Lambda and AgentCore, and learning from the lower level pays off later. One honest sentence: this is a learning path, not a recommendation.
3. The scenario: GitHub PR → webhook → Lambda → microVM on the EC2 host → three agents → JSON results. Later: tokens and permissions per agent, Matrix rooms.
4. One architecture fact to settle on screen: **Lambda cannot run Firecracker** (no KVM in Lambda). The Lambda is the trigger; a controller on the EC2 host starts the microVM. In Part 4 that controller call is SSM Run Command.
5. The roadmap: Parts 2–5, and what's still open (Part 5).

Deliverable for the page: one draw.io diagram of the target architecture, drawn with the dotted "later" boxes (tokens, Matrix). Don't name Fargate as Firecracker-based (see `TODO.md`): Lambda and AgentCore are the safe examples.

### Part 2 — An Ubuntu microVM

The longest hands-on part. If it passes 12 minutes, split: 2a *Build and boot the Ubuntu guest*, 2b *Network, SSH and Docker inside the guest*.

Manual path, on the Lab 4 host:

1. Download Canonical's Ubuntu 24.04 **minimal root archive** (`…-root.tar.xz`) and verify the checksum. Not the `.img`: that one is a QCow2 UEFI disk, not an ext4 root.
2. Create a 4 GB ext4 image and extract the archive into it. Set fstab, the serial console (`ttyS0`), a static address with systemd-networkd, DNS, hostname and the SSH key.
3. The kernel: start with Firecracker CI's `vmlinux-6.18.54` from Lab 4 and check its config for what Docker needs (namespaces, cgroups v2, overlayfs, veth, bridge, netfilter and NAT). If something is missing, use the kernel the course supplies, with its config and build notes in an appendix. No kernel compile on camera.
4. TAP and NAT as in Lab 4, then boot through a Firecracker config file (vCPU, memory, kernel, root drive, boot args). Read the serial console, SSH in, test DNS and an HTTPS download.
5. Install Docker Engine and the Compose plugin inside the guest. Run one container that writes a file to a volume; test DNS and HTTPS from inside a container (the second network layer).
6. Shut down. This image is the **clean base image**; every job in Part 3 starts from a copy of it.

Terraform shortcut, the same end state: one `terraform apply` creates the host (nested virtualization in `cpu_options`), copies the same scripts (`build-rootfs.sh`, `boot-guest.sh`, `install-docker.sh`) and runs them with user data, then `check.sh` proves the Part 2 checks. The video ends with a two-minute walkthrough of this path. Both paths must pass the same `check.sh` before Part 3.

### Part 3 — Three agents, one job

No AI in this part, on purpose. An *agent* here is a container with one job and a fixed contract; in Part 5 an LLM gets the same contract. The contract is what stays stable:

- Input: the repo at `/workspace` (read-only), `GIT_URL` and `REF` as environment variables.
- Output: `/results/<agent>.json` and an exit code.

The three agents, as one-shot Docker Compose services, images pre-pulled into the base image (no registry pulls at job time):

| Agent | Tool | Looks for |
|---|---|---|
| deps | Trivy (`vuln,misconfig`) | Vulnerable dependencies, bad Dockerfiles and IaC |
| code | Semgrep (`p/supply-chain`, `p/security-audit`, plus a few course rules) | `eval`, shelling out, obfuscated strings, install-time scripts (`preinstall`/`postinstall`) |
| secrets | Gitleaks | Keys and tokens in the tree and the history |

If you want a literal signature scanner in the third slot, ClamAV works too (its database is ~300 MB, baked into the image). Trivy, Semgrep and Gitleaks all write JSON natively, which is why they're the proposal.

The job, from the host:

```
run-job.sh <git-url> [ref]
  1. cp base image → jobs/<id>/rootfs.ext4; own TAP, own socket
  2. start Firecracker, wait for SSH
  3. ssh guest: git clone (the only network the job needs), then
     docker compose up (three services in parallel, exit codes collected)
  4. scp /results/*.json → jobs/<id>/results/; write summary.json (jq)
  5. kill the VM, delete the TAP and the rootfs copy
```

The clone runs inside the guest, so the untrusted code never touches the host. `summary.json` has the job id, repo, ref, one status per agent (ok, findings, failed) and an overall verdict. The check: run it twice on two pinned repos; both leave results, no VM or disk copy survives, and the second job sees nothing from the first.

**As built (2026-11-13), where it differs from the sketch above:** one job at a time on the shared `tap0` and guest address (a file lock, and a refusal while a Firecracker process runs), not a TAP per job: a per-job TAP would need its own NAT rules. Plain `docker compose up` and the exit codes from `docker compose ps`, not `--abort-on-container-exit`, which stops every service when the first one exits. The agents run with `network_mode: none`; the images, Trivy's database and Semgrep's rule sets are baked at build time, which needs an 8 GiB base image (version 2). The test repositories: `elevy99927/fc-agents-sample` (planted problems, pinned) and `octocat/Hello-World` (clean, pinned).

### Part 4 — Lambda and the webhook

1. GitHub webhook on the repo, `pull_request` events (`opened`, `synchronize`), to a **Lambda Function URL**. No API Gateway.
2. The Lambda **verifies `X-Hub-Signature-256`** with the webhook secret from Parameter Store. This is the trust boundary of the whole system; it's never skipped. Then it reads the clone URL, head SHA and PR number.
3. The Lambda calls **SSM Run Command** (`AWS-RunShellScript`) on the host: `run-job.sh <url> <sha> <pr>`. Why SSM and not an HTTP call into the host: no inbound port, IAM only, and the output is logged in SSM.
4. The host uploads `jobs/<id>/results/` to `s3://<bucket>/<repo>/pr-<n>/<sha>/` with its instance role. **The guest never holds AWS credentials.**
5. The payoff on screen: a commit status on the PR (the host posts it at the end of `run-job.sh`, token from Parameter Store). If the video runs long, the status is the first thing to drop; S3 is still the proof.

The "operator", kept minimal in this part: `jobctl list | logs <id> | stop <id> | gc`, with the `jobs/<id>/` directory and its `status` file as the only state. A queue (SQS plus a host daemon) is the upgrade when two PRs arrive at once; it's noted, not built. My recommendation: no AI in Part 4. Keep this part about the trigger path; AI arrives in Part 5 where its token story belongs.

Cost note for the page: the host costs money while it runs, even idle. Stop it between sessions; a Lambda that starts a stopped host is a possible later step.

### Part 5 — The full system

The most open part. Decide its final shape after Part 4 ships; today's proposal:

1. **Terraform for everything:** the host (reusing the Part 2 module), the S3 bucket, the Lambda and its Function URL, IAM, the Parameter Store secrets, and the Matrix server. One `apply`, one `destroy`.
2. **The AI reviewer:** a fourth agent with the same contract. An LLM (Bedrock, or the Claude API) reads the three JSON files and the diff and writes `review.json`: verdict, explanation, what to look at first. The three scanners stay deterministic; the model prioritizes and explains, it doesn't replace them.
3. **Tokens and permissions:** the host hands the reviewer a short-lived, job-scoped credential (an assumed role, 15 minutes, `bedrock:InvokeModel` on one model) through the guest environment. Nothing long-lived enters the guest. This is the "provision the agents" lesson.
4. **Matrix:** a home server (Conduit or conduwuit, a single binary, is enough; Synapse if you want the reference implementation), one room per PR. Each agent has a Matrix user and posts its findings; the reviewer posts the verdict; humans join and reply. The controller creates the agents' access tokens per job and revokes them when the job ends.

If this grows, split it: 5a *Terraform and the AI reviewer*, 5b *Matrix rooms for agents and humans*.

## Decisions and risks

| Topic | Decision |
|---|---|
| Lambda and Firecracker | Lambda has no KVM. It triggers the host over SSM Run Command; the host runs the microVM. |
| Host size | `m7i-flex.large` (2 vCPU, 8 GiB) from Lab 4. Give the guest 1–2 vCPUs and 2–3 GiB; Semgrep is the memory hog. Measure in Part 3. |
| Ubuntu image | The minimal **root archive** into an ext4 image you create. Never the `.img`. A Dockerfile-built rootfs (as in hostinger/fireactions-images) was rejected on 2026-11-08: Docker on the host next to Docker in the guest would confuse students. |
| Guest kernel | The CI kernel from Lab 4 first; check its config for Docker. Fallback: a pinned course kernel with build notes. A booting Ubuntu is not enough; Docker must run. |
| Two network layers | Host NAT to the guest, and Docker's bridge and firewall rules inside the guest. Test guest egress and container egress separately. |
| Untrusted code | Cloned inside the guest only. Base image pre-pulled, so the job's only network use is the clone. No host Docker socket in the guest. |
| Credentials | None in the guest until Part 5, and then only short-lived and scoped. The host uploads to S3 and posts to GitHub. |
| Webhook | Signature verification is mandatory; the secret lives in Parameter Store. |
| Jailer | Not used, as in Lab 4. Say so plainly in Part 1; it's a candidate for Part 5. |
| Terraform and nested virtualization | Check that the AWS provider exposes the nested-virtualization CPU option; otherwise a launch template or a `local-exec` with the CLI flag. |
| Results after a failure | `summary.json` is written after success, failure or timeout; a failed scanner is a status, not a missing file. |
| What the lab claims | A microVM shrinks the blast radius; it doesn't prove the code is safe. Say it in Part 1 and again in Part 3. |

## Next step

Prove Part 2 end to end on the real host before writing any script or page: the Ubuntu root archive boots under the CI kernel, Docker runs inside the guest, a container reaches the internet. That's the one feasibility question the rest of the lab depends on.
