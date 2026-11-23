#!/bin/bash
# The Part 5 check, run by hand on the host (./check-parallel.sh): two jobs at once, each on its own TAP and guest
# address, a third job turned away while they run, and nothing left behind afterwards.
source "$(dirname "$0")/common.sh"
set +e
pass=0; fail=0
ok() { if eval "$2" >/dev/null 2>&1; then echo "PASS  $1"; pass=$((pass+1)); else echo "FAIL  $1"; fail=$((fail+1)); fi; }
SAMPLE=https://github.com/elevy99927/fc-agents-sample; SAMPLE_SHA=c48a39a82205ff3b828d21393aa0e295da54f5e9
CLEAN=https://github.com/octocat/Hello-World;        CLEAN_SHA=7fd1a60b01f91b314f59955a4e4d4e80d8edf11d

step "Two jobs, three seconds apart"
./run-job.sh $SAMPLE $SAMPLE_SHA > par-1.log 2>&1 &
P1=$!; sleep 3
./run-job.sh $CLEAN $CLEAN_SHA > par-2.log 2>&1 &
P2=$!
for _ in $(seq 1 60); do [ "$(pgrep -cx firecracker)" -ge 2 ] && break; sleep 2; done
run 'pgrep -a firecracker'

step "A third job while two run"
./run-job.sh $CLEAN $CLEAN_SHA > par-3.log 2>&1; R3=$?
run 'cat par-3.log'

step "Guest isolation, from the guest on tap0"
O="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -o ConnectTimeout=5"
for _ in $(seq 1 60); do ssh $O root@172.16.0.2 true 2>/dev/null && ssh $O root@172.16.0.6 true 2>/dev/null && break; sleep 2; done
ssh $O root@172.16.0.2 'ping -c1 -W2 172.16.0.6' > iso-guest.log 2>&1; ISO_GUEST=$?
ssh $O root@172.16.0.2 'curl -sS -m3 http://169.254.169.254/' > iso-meta.log 2>&1; ISO_META=$?
ssh $O root@172.16.0.2 'curl -sS -m5 -o /dev/null -w "%{http_code}" https://github.com' > iso-net.log 2>&1

wait $P1 $P2
run 'grep -h "slot\|scan started\|scan done\|vm destroyed" par-1.log par-2.log | sort -k3'
t() { date -d "$(grep -m1 "$2" "$1" | awk '{print $3}')" +%s; }

step "The checks"
ok "job 1 on tap0, guest 172.16.0.2"         "grep -q 'slot 0: tap0, guest 172.16.0.2' par-1.log"
ok "job 2 on tap1, guest 172.16.0.6"         "grep -q 'slot 1: tap1, guest 172.16.0.6' par-2.log"
ok "the scans overlapped"                    "[ \$(t par-2.log 'scan started') -lt \$(t par-1.log 'scan done') ]"
ok "job 1: verdict findings"                 "grep -q 'summary: findings' par-1.log"
ok "job 2: verdict clean"                    "grep -q 'summary: clean' par-2.log"
ok "job 3 turned away, no third microVM"     "[ $R3 -ne 0 ] && grep -q 'no free slot' par-3.log"
ok "guest 1 can't reach guest 2"             "[ $ISO_GUEST -ne 0 ]"
ok "guest 1 can't reach the metadata"        "[ $ISO_META -ne 0 ]"
ok "guest 1 reaches GitHub"                  "grep -q 200 iso-net.log"
ok "no Firecracker process"                  "! pgrep -x firecracker"
ok "no disk copies or mounts left"           "! ls jobs/*/rootfs.ext4 && ! findmnt -rn | grep -q /fc/jobs/"
ok "both slots free"                         "flock -n jobs/.tap0.lock true && flock -n jobs/.tap1.lock true"
echo; echo "check-parallel.sh: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
