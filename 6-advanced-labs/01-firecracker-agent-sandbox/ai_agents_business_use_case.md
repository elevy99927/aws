# Business Use Case: Secure, On-Demand Multi-Agent Execution

## 1. Technical Background — Business Problem

An insurance company processes claims through business workflows that may last several days or a week. Each workflow invokes a changing set of AI agents for short bursts of work, while the process may spend hours or days waiting for external information or human approval.

The organization needs to execute thousands of agent tasks without maintaining an always-running environment for every workflow. Some tasks may also run continuously for hours. Agents may execute third-party code sourced from GitHub, open-source dependencies, or external vendors, introducing software supply-chain risk.

**Problem statement:** How can an organization execute dynamic, isolated multi-agent workflows on demand, minimizing idle compute and limiting the impact of potentially malicious code, while preserving workflow continuity and reliability?

This use case is technology-neutral. No assumption is made that Kubernetes, Firecracker, or another runtime is the right answer.

## 2. Example — Insurance Claim Processing

A claim enters the system and starts a workflow with three agents:

1. **Document Analysis Agent:** extracts information from submitted documents.
2. **Policy Validation Agent:** compares extracted information with policy terms.
3. **Recommendation Agent:** combines the findings into a recommendation for a human reviewer.

The workflow can then wait for an additional document or a human decision. Once the dependency is satisfied, the next execution segment begins. The overall claim may remain open for a week, although the agents run for only minutes at a time.

A third-party library used by one agent could be compromised. The execution environment must reduce the chance that compromising one workflow also compromises its host or neighboring workflows. This does not imply that an isolated runtime can prevent misuse of credentials or network permissions intentionally granted to that workload.

### Six business requirements

| # | Requirement | Expected outcome |
|---|---|---|
| 1 | Isolation | One claim's execution cannot access another claim's processes or memory through the runtime boundary. |
| 2 | Resource efficiency | No dedicated active compute environment is required while a workflow is intentionally waiting. |
| 3 | Elasticity | The number of concurrent execution environments adjusts to changing demand. |
| 4 | Workflow continuity | Business processes can continue over days, independently of the lifetime of an individual execution environment. |
| 5 | Reliability | Failures are detected and recovery/retry behavior is explicit, without silently losing completed work. |
| 6 | Untrusted-code containment | A compromise inside one execution environment should not grant control over the host or neighboring environments; the achievable isolation and its overhead must be evaluated. |

## 3. Basic Exercise — Define a Measurable Workflow

**Objective:** Describe a three-agent claim workflow without choosing infrastructure.

1. Define the input and output contract of each agent.
2. Define the dependency between agents and the point where human approval is required.
3. Specify which state must persist while no agent is running.
4. Define success, failure, and timeout outcomes for each step.
5. Identify what must be isolated per claim.

**Validation:** A workflow description exists that can be resumed after an execution environment has been terminated, without depending on in-memory process state.

## 4. Advanced Exercise — Evaluate Execution Alternatives

**Scenario:** Hundreds of claims arrive in a burst. Some agents finish within minutes, some perform hours of continuous computation, and some workflows wait days for approval. One agent executes code from an external dependency.

Compare candidate execution models (for example, hardened containers and MicroVMs) using the same workload. Measure startup latency, memory/CPU overhead, concurrency, idle-resource cost, and operational complexity. Assess the runtime isolation boundary and blast radius using a tightly scoped, authorized containment test; do not expand this into a broad credential or network-permission test campaign.

**Validation:** Produce an evidence-based comparison and state which solution meets the requirements at acceptable cost and complexity. No preferred technology is assumed in advance.

## Troubleshooting & Pitfalls

- **Workflow never resumes:** The dependency or wake-up condition was not recorded. Define explicit waiting conditions, event correlations, and timeout/retry policies.
- **Duplicate agent execution:** Multiple workers claim the same work after a retry. Use execution IDs, leases or conditional state transitions, and idempotent operations.
- **False confidence in isolation:** Runtime isolation is mistaken for authorization control. Evaluate host/neighbor isolation separately from the permissions deliberately granted to a workload.

## Scope and Non-Goals

The business problem and evaluation criteria come first. Detailed orchestrator implementation, Pause/Snapshot mechanics, and the choice of AWS services are outside this initial use case. Credential exfiltration using legitimately granted access is not the focus of the runtime-isolation comparison.
