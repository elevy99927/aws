#!/bin/bash
# run-job.sh <git-url> [ref]
# One job: a fresh microVM from the base image, the repository cloned inside it, the three agents on it, the
# results copied to jobs/<id>/ on the host, and the VM destroyed. summary.json is written on every path: success,
# a failed scanner, a timeout, or a guest that never booted.
# Part 5: up to two jobs at once. A TAP can be attached to one microVM only, so each job takes a free slot
# (tapN, with its own guest address) and holds that slot's lock until its VM and disk copy are gone.
# ponytail: MAX_VMS=2 because this host (2 vCPUs, 8 GiB) fits two guests of 2 vCPUs and 2 GiB; tap2 and tap3 are
# made by host-net.sh for a bigger host. A third job finds both slots taken and stops; a queue (SQS) comes later.
set -uo pipefail
cd "$HOME/fc" || exit 1
URL=${1:?usage: run-job.sh <git-url> [ref]}; REF=${2:-HEAD}
BASE=ubuntu-agents-base.ext4; TIMEOUT=900; MAX_VMS=2
SSH_OPTS=(-o ConnectTimeout=5 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR)
mkdir -p jobs

# 1. A free slot. flock -n gives a lock file to one process only; the lock stays held while fd 9 is open (this
# script, and the Firecracker it starts), and the kernel drops it when they're gone, even after a crash.
SLOT=
for N in $(seq 0 $((MAX_VMS-1))); do
  exec 9>jobs/.tap$N.lock
  flock -n 9 && { SLOT=$N; break; }
  exec 9>&-
done
[ -n "$SLOT" ] || { echo "no free slot: $MAX_VMS microVMs are already running"; exit 1; }
TAP=tap$SLOT; GW=172.16.0.$((4*SLOT+1)); GUEST=172.16.0.$((4*SLOT+2))

ID=$(date +%Y%m%d-%H%M%S); JOB=jobs/$ID
mkdir -p $JOB/results; echo $SLOT > $JOB/slot
log() { echo "[job $ID] $(date +%T) $*"; }
g()   { ssh "${SSH_OPTS[@]}" root@$GUEST "$@"; }
log "slot $SLOT: $TAP, guest $GUEST"

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
  [ -n "${FC:-}" ] && { kill $FC 2>/dev/null; wait $FC 2>/dev/null; }
  mountpoint -q $JOB/mnt && sudo umount $JOB/mnt
  rm -f "$JOB/rootfs.ext4" "$JOB/fc.sock"; rmdir "$JOB/mnt" 2>/dev/null
  log "vm destroyed"
}

# 2. A fresh VM for this job, on its own TAP and address
./host-net.sh >/dev/null
trap finish EXIT
log "copy base image ..."
cp --sparse=always $BASE $JOB/rootfs.ext4
# The base image has 172.16.0.2 baked in. Before boot, write this slot's address into the job's own copy (still the
# clean base: nothing from the repository is on it yet).
mkdir -p $JOB/mnt && sudo mount -o loop $JOB/rootfs.ext4 $JOB/mnt
printf '[Match]\nName=eth0\n\n[Network]\nAddress=%s/30\nGateway=%s\nDNS=1.1.1.1\nDHCP=no\n' $GUEST $GW |
  sudo tee $JOB/mnt/etc/systemd/network/eth0.network >/dev/null
sudo umount $JOB/mnt
sed -e "s|\"ubuntu.ext4\"|\"$JOB/rootfs.ext4\"|" -e "s|\"tap0\"|\"$TAP\"|" vm.json > $JOB/vm.json
log "boot ..."
./firecracker --api-sock $JOB/fc.sock --config-file $JOB/vm.json > $JOB/console.log 2>&1 &
FC=$!
T0=$SECONDS
for _ in $(seq 1 60); do g true 2>/dev/null && break; sleep 1; done
g true 2>/dev/null || { log "the guest did not answer on SSH"; exit 1; }
log "ssh up in $((SECONDS-T0))s"
g 'test ! -e /workspace && test ! -e /results && echo "[guest] fresh: no /workspace, no /results"'

# 3. Clone and scan, inside the guest. The clone is the job's only network call.
log "clone ..."
g "git clone --quiet $URL /workspace && cd /workspace && git checkout --quiet $REF" || { log "clone failed"; exit 1; }
log "scan started"
g "mkdir -p /results && cd /opt/agents && GIT_URL=$URL REF=$REF timeout $TIMEOUT docker compose up 2>&1" > $JOB/compose.log
log "scan done"
g "cd /opt/agents && docker compose ps -a --format '{{.Service}} {{.ExitCode}}'" > $JOB/exit-codes.txt
if [ -s $JOB/exit-codes.txt ]; then
  while read -r a c; do log "$(printf '%-8s exit %s' $a $c)"; done < $JOB/exit-codes.txt
else
  log "compose did not start the agents: $(tail -1 $JOB/compose.log)"
fi

# 4. Collect. The host only ever reads these files; it never runs anything from the repository.
scp -q "${SSH_OPTS[@]}" "root@$GUEST:/results/*.json" $JOB/results/ 2>/dev/null
exit 0
