#!/bin/bash
# run-job.sh <git-url> [ref]
# One job: a fresh microVM from the base image, the repository cloned inside it, the three agents on it, the
# results copied to jobs/<id>/ on the host, and the VM destroyed. summary.json is written on every path: success,
# a failed scanner, a timeout, or a guest that never booted.
# ponytail: one job at a time (flock), because every job uses tap0 and the guest address 172.16.0.2.
# Two jobs at once need a TAP, an address and NAT rules per job, and a queue in front: Part 4 only reports "host busy"; the queue comes later.
set -uo pipefail
cd "$HOME/fc"
URL=${1:?usage: run-job.sh <git-url> [ref]}; REF=${2:-HEAD}
GUEST=172.16.0.2; BASE=ubuntu-agents-base.ext4; TIMEOUT=900
ID=$(date +%Y%m%d-%H%M%S); JOB=jobs/$ID
mkdir -p $JOB/results jobs
log() { echo "[job $ID] $*"; }
g()   { ssh -o ConnectTimeout=5 root@$GUEST "$@"; }

exec 9>jobs/.lock
flock -w 1 9 || { echo "another job is running"; exit 1; }
pgrep -x firecracker >/dev/null && { echo "a microVM is already running on this host (pgrep -a firecracker); stop it first"; exit 1; }

# The summary: one status per agent, from the exit code and the report file; one verdict for the job.
summary() {
  local a c s v=clean args=()
  for a in deps code secrets; do
    c=$(awk -v a=$a '$1==a{print $2}' $JOB/exit-codes.txt 2>/dev/null)
    if   [ ! -s $JOB/results/$a.json ]; then s=failed
    elif [ "$c" = 0 ]; then s=ok
    elif [ "$c" = 1 ]; then s=findings
    else s=failed; fi
    [ $s = failed ] && v=failed
    [ $s = findings ] && [ $v = clean ] && v=findings
    args+=(--arg $a $s)
  done
  jq -n --arg job $ID --arg repo "$URL" --arg ref "$REF" "${args[@]}" --arg verdict $v \
    '{job: $job, repo: $repo, ref: $ref, agents: {deps: $deps, code: $code, secrets: $secrets}, verdict: $verdict}' \
    > $JOB/summary.json
  echo $v
}

# Always: the summary, then the VM, its disk copy and its socket are gone.
finish() {
  v=$(summary)
  log "results: $JOB/results  summary: $v"
  kill $FC 2>/dev/null; wait $FC 2>/dev/null
  rm -f $JOB/rootfs.ext4 $JOB/fc.sock
  log "vm destroyed"
}

# 1. A fresh VM for this job
./host-net.sh
log "copy base image ... boot ..."
cp --sparse=always $BASE $JOB/rootfs.ext4
sed "s|\"ubuntu.ext4\"|\"$JOB/rootfs.ext4\"|" vm.json > $JOB/vm.json
./firecracker --api-sock $JOB/fc.sock --config-file $JOB/vm.json > $JOB/console.log 2>&1 &
FC=$!
trap finish EXIT
T0=$SECONDS
for _ in $(seq 1 60); do g true 2>/dev/null && break; sleep 1; done
g true 2>/dev/null || { log "the guest did not answer on SSH"; exit 1; }
log "ssh up in $((SECONDS-T0))s"
g 'test ! -e /workspace && test ! -e /results && echo "[guest] fresh: no /workspace, no /results"'

# 2. Clone and scan, inside the guest. The clone is the job's only network call.
log "clone ..."
g "git clone --quiet $URL /workspace && cd /workspace && git checkout --quiet $REF" || { log "clone failed"; exit 1; }
g "mkdir -p /results && cd /opt/agents && GIT_URL=$URL REF=$REF timeout $TIMEOUT docker compose up 2>&1" > $JOB/compose.log
g "cd /opt/agents && docker compose ps -a --format '{{.Service}} {{.ExitCode}}'" > $JOB/exit-codes.txt
if [ -s $JOB/exit-codes.txt ]; then
  while read -r a c; do log "$(printf '%-8s exit %s' $a $c)"; done < $JOB/exit-codes.txt
else
  log "compose did not start the agents: $(tail -1 $JOB/compose.log)"
fi

# 3. Collect. The host only ever reads these files; it never runs anything from the repository.
scp -q "root@$GUEST:/results/*.json" $JOB/results/ 2>/dev/null
exit 0
