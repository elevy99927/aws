"""Local check of app.py, no AWS: python3 test_app.py"""
import base64, hashlib, hmac, json, os, sys, types

calls = []
fake = types.SimpleNamespace(
    get_parameter=lambda **kw: {"Parameter": {"Value": "s3cret"}},
    send_command=lambda **kw: calls.append(kw) or {"Command": {"CommandId": "cmd-1"}},
)
sys.modules["boto3"] = types.SimpleNamespace(client=lambda name: fake)
os.environ.update(HOST="i-0abc", DOCUMENT="fc-run-pr-job", REPOS="elevy99927/fc-agents-sample", SECRET_PARAM="/fc/webhook-secret")
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import app  # noqa: E402

SHA = "c48a39a82205ff3b828d21393aa0e295da54f5e9"


def event(kind, payload, secret=b"s3cret", sig=None, b64=False):
    body = json.dumps(payload).encode()
    headers = {"X-GitHub-Event": kind, "X-GitHub-Delivery": "d-1"}
    if sig is not False:
        headers["X-Hub-Signature-256"] = sig or "sha256=" + hmac.new(secret, body, hashlib.sha256).hexdigest()
    return {"headers": headers, "isBase64Encoded": b64, "body": base64.b64encode(body).decode() if b64 else body.decode()}


def pr(action="opened", repo="elevy99927/fc-agents-sample", sha=SHA):
    return {"action": action, "number": 1, "repository": {"full_name": repo},
            "pull_request": {"head": {"sha": sha, "repo": {"clone_url": f"https://github.com/{repo}.git"}}}}


def code(e):
    return app.handler(e, None)["statusCode"]


assert code(event("ping", {"zen": "hi"})) == 200
assert code(event("ping", {}, sig=False)) == 401
assert code(event("ping", {}, secret=b"wrong")) == 401
assert code(event("pull_request", pr("closed"))) == 200 and not calls
assert code(event("pull_request", pr(repo="someone/else"))) == 400 and not calls
assert code(event("pull_request", pr(sha="c48a39a; rm -rf /"))) == 400 and not calls
assert code(event("pull_request", pr("synchronize"))) == 200 and not calls  # a push to an open PR: ignored
r = app.handler(event("pull_request", pr("opened"), b64=True), None)
assert r["statusCode"] == 202 and json.loads(r["body"]) == {"command_id": "cmd-1"}
assert calls == [{"InstanceIds": ["i-0abc"], "DocumentName": "fc-run-pr-job", "Comment": "pr-1 c48a39a",
                  "Parameters": {"url": ["https://github.com/elevy99927/fc-agents-sample.git"], "sha": [SHA],
                                 "pr": ["1"], "repo": ["elevy99927/fc-agents-sample"]}}]
print("app.py: all checks passed")
