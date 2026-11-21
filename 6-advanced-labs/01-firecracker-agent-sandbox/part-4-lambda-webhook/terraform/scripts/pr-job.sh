#!/bin/bash
# pr-job.sh <clone-url> <sha> <pr> <owner/repo>
# One pull request scan: tell GitHub we started, run Part 3's run-job.sh (unchanged) on that commit, put the
# results in S3, tell GitHub how it ended (a status on the commit, a comment on the pull request). Runs as ubuntu on the host; SSM starts it through the fc-run-pr-job
# document. The GitHub token stays on the host, in a variable, for the length of this script; the guest never sees it.
set -uo pipefail
cd "$HOME/fc" || exit 1
source ./pr-job.env   # BUCKET and AWS_REGION, written by user data (or by hand in the CLI path)
URL=${1:-} SHA=${2:-} PR=${3:-} REPO=${4:-}

# The values came from the internet. The Lambda and the SSM document checked them already; check again, because
# run-job.sh puts them into commands in the guest.
NAME='[A-Za-z0-9_.-]+'
[[ $URL =~ ^https://github\.com/$NAME/$NAME\.git$ && $SHA =~ ^[0-9a-f]{40}$ && $PR =~ ^[0-9]{1,7}$ && $REPO =~ ^$NAME/$NAME$ ]] ||
  { echo "usage: pr-job.sh <https://github.com/o/r.git> <40-hex sha> <pr number> <owner/repo>"; exit 2; }

KEY=$REPO/pr-$PR/$SHA
TARGET="https://s3.console.aws.amazon.com/s3/buckets/$BUCKET?prefix=$KEY/"
TOKEN=$(aws ssm get-parameter --name /fc/github-token --with-decryption --query Parameter.Value --output text) ||
  echo "warning: no GitHub token, the scan runs without statuses"

# A failed post is a warning: an expired token must not stop the scan or the upload.
status() {
  [ -n "${TOKEN:-}" ] || return 0
  jq -n --arg s "$1" --arg d "$2" --arg u "$TARGET" '{state: $s, description: $d, context: "fc-agents/scan", target_url: $u}' |
    curl -fsS -o /dev/null -X POST "https://api.github.com/repos/$REPO/statuses/$SHA" \
      -H @<(printf 'Authorization: Bearer %s' "$TOKEN") -H "Accept: application/vnd.github+json" --data @- &&
    echo "status: $1 ($2)" || echo "warning: status '$1' not posted"
}

# The same verdict as a comment on the pull request, with the link to the reports. PR 0 = a run by hand: no comment.
comment() {
  [ -n "${TOKEN:-}" ] && [ "$PR" -gt 0 ] || return 0
  jq -n --arg b "$1" '{body: $b}' |
    curl -fsS -o /dev/null -X POST "https://api.github.com/repos/$REPO/issues/$PR/comments" \
      -H @<(printf 'Authorization: Bearer %s' "$TOKEN") -H "Accept: application/vnd.github+json" --data @- &&
    echo "comment posted" || echo "warning: comment not posted"
}

# Busy: if this commit is the one already running (a redelivery), leave its status alone; otherwise say so on this commit.
# ponytail: this check and run-job.sh's lock are two steps; a command that lands in between gets "did not start" below.
mkdir -p jobs
if ! flock -n jobs/.lock true; then
  pgrep -f "run-job.sh .* $SHA" >/dev/null && { echo "this commit is already being scanned"; exit 0; }
  status error "host busy, push again"; exit 1
fi

status pending "scanning ${SHA:0:7}"
LOG=$(mktemp)
./run-job.sh "$URL" "$SHA" 2>&1 | tee "$LOG"
# This job's id, from run-job.sh's own "[job <id>]" lines; never "the newest folder".
ID=$(grep -m1 -o '^\[job [0-9-]*\]' "$LOG" | tr -d '[]' | cut -d' ' -f2); rm -f "$LOG"
[ -n "$ID" ] && [ -s "jobs/$ID/summary.json" ] || { status error "the job did not start"; exit 1; }
echo "$REPO $PR $SHA" > "jobs/$ID/pr.txt"

up=0 all=0
for f in jobs/$ID/results/*.json jobs/$ID/summary.json jobs/$ID/compose.log; do
  [ -e "$f" ] || continue
  all=$((all+1)); aws s3 cp --only-show-errors "$f" "s3://$BUCKET/$KEY/$(basename "$f")" && up=$((up+1))
done
echo "uploaded $up of $all files to s3://$BUCKET/$KEY/"

DESC=$(jq -r '"\(.verdict): deps \(.agents.deps), code \(.agents.code), secrets \(.agents.secrets)"' "jobs/$ID/summary.json")
case $(jq -r .verdict "jobs/$ID/summary.json") in
  clean) state=success ;; findings) state=failure ;; *) state=error ;;
esac
status $state "$DESC"
comment "fc-agents scan of ${SHA:0:7}: $DESC"$'\n\n'"Reports: $TARGET"
[ "$up" -eq "$all" ]   # SSM shows Success only if every file reached S3; the verdict lives in the status, not here
