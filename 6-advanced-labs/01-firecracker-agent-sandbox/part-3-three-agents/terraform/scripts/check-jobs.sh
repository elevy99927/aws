#!/bin/bash
# The Part 3 check: two jobs on two pinned repositories. Both leave three reports and a summary, the first one finds
# the planted problems, the second one is clean and started from a fresh guest, and nothing survives on the host.
source "$(dirname "$0")/common.sh"
set +e
pass=0; fail=0
ok() { if eval "$2" >/dev/null 2>&1; then echo "PASS  $1"; pass=$((pass+1)); else echo "FAIL  $1"; fail=$((fail+1)); fi; }
SAMPLE=https://github.com/elevy99927/fc-agents-sample; SAMPLE_SHA=c48a39a82205ff3b828d21393aa0e295da54f5e9
CLEAN=https://github.com/octocat/Hello-World;        CLEAN_SHA=7fd1a60b01f91b314f59955a4e4d4e80d8edf11d

step "Job 1: the sample repository, with planted problems"
./run-job.sh $SAMPLE $SAMPLE_SHA | tee job-1.log
J1=$(ls -d jobs/2* | tail -1)

step "Job 2: a clean repository"
./run-job.sh $CLEAN $CLEAN_SHA | tee job-2.log
J2=$(ls -d jobs/2* | tail -1)

step "The checks"
ok "job 1: three reports and a summary"      "[ -s $J1/results/deps.json ] && [ -s $J1/results/code.json ] && [ -s $J1/results/secrets.json ] && [ -s $J1/summary.json ]"
ok "job 1: verdict findings"                 "[ \"\$(jq -r .verdict $J1/summary.json)\" = findings ]"
ok "job 1: Trivy found vulnerable packages"  "[ \"\$(jq '[.Results[].Vulnerabilities // [] | length] | add' $J1/results/deps.json)\" -gt 0 ]"
ok "job 1: Semgrep found the eval"           "jq -e '.results[] | select(.check_id | test(\"eval\"))' $J1/results/code.json"
ok "job 1: Gitleaks found the planted token" "jq -e '.[0].RuleID' $J1/results/secrets.json"
ok "job 2: verdict clean"                    "[ \"\$(jq -r .verdict $J2/summary.json)\" = clean ]"
ok "job 2: started from a fresh guest"       "grep -q 'fresh: no /workspace, no /results' job-2.log"
ok "no Firecracker process"                  "! pgrep -x firecracker"
ok "no disk copies left"                     "! ls jobs/*/rootfs.ext4"
echo; echo "check-jobs.sh: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
