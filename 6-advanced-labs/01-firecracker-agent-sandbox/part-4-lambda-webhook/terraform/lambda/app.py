"""The GitHub webhook: verify the signature, keep pull_request opened (new pull requests only), hand the job to SSM, answer 202.

Environment: HOST (instance id), DOCUMENT (fc-run-pr-job), REPOS (comma-separated owner/name allowlist),
SECRET_PARAM (/fc/webhook-secret).
"""
import base64
import hashlib
import hmac
import json
import os
import re

import boto3

ssm = boto3.client("ssm")
REPOS = set(os.environ.get("REPOS", "").split(","))
SHA = re.compile(r"[0-9a-f]{40}")
CLONE = re.compile(r"https://github\.com/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+\.git")
_secret = None  # read once per cold start


def reply(code, result, **log):
    print(json.dumps({"status": code, "result": result, **log}))  # one line per delivery, nothing from a rejected body
    return {"statusCode": code, "headers": {"content-type": "application/json"}, "body": json.dumps(result)}


def handler(event, context):
    global _secret
    headers = {k.lower(): v for k, v in (event.get("headers") or {}).items()}
    body = event.get("body") or ""
    raw = base64.b64decode(body) if event.get("isBase64Encoded") else body.encode()
    delivery = headers.get("x-github-delivery", "-")

    # 1. The signature, over the exact bytes received, before anything is parsed.
    signature = headers.get("x-hub-signature-256")
    if not signature:
        return reply(401, "missing signature", delivery=delivery)
    if _secret is None:
        _secret = ssm.get_parameter(Name=os.environ["SECRET_PARAM"], WithDecryption=True)["Parameter"]["Value"].encode()
    expected = "sha256=" + hmac.new(_secret, raw, hashlib.sha256).hexdigest()
    if not hmac.compare_digest(expected, signature):
        return reply(401, "bad signature", delivery=delivery)

    # 2. Which events, which fields.
    kind = headers.get("x-github-event")
    if kind == "ping":
        return reply(200, "pong", delivery=delivery)
    payload = json.loads(raw)
    action = payload.get("action")
    if kind != "pull_request" or action != "opened":
        return reply(200, "ignored", delivery=delivery, event=kind, action=action)
    pr = payload["pull_request"]
    repo = payload["repository"]["full_name"]
    number = payload["number"]
    sha = pr["head"]["sha"]
    url = (pr["head"].get("repo") or {}).get("clone_url", "")
    if repo not in REPOS or not SHA.fullmatch(sha) or not isinstance(number, int) or not CLONE.fullmatch(url):
        return reply(400, "rejected", delivery=delivery, repo=repo)

    # 3. Hand the job to the host and answer now: GitHub waits 10 seconds, the scan takes minutes.
    command = ssm.send_command(
        InstanceIds=[os.environ["HOST"]],
        DocumentName=os.environ["DOCUMENT"],
        Comment=f"pr-{number} {sha[:7]}",
        Parameters={"url": [url], "sha": [sha], "pr": [str(number)], "repo": [repo]},
    )["Command"]["CommandId"]
    return reply(202, {"command_id": command}, delivery=delivery, action=action, pr=number, sha=sha[:7])
