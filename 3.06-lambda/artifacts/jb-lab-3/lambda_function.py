import hashlib
import time


def lambda_handler(event, context):
    rounds = int(event.get("rounds", 100000))   # CPU work: repeated SHA-256 hashing
    sleep_s = float(event.get("sleep", 0))      # waiting (no CPU), e.g. a slow API call

    start = time.time()
    digest = b"jb-lab-3"
    for _ in range(rounds):
        digest = hashlib.sha256(digest).digest()
    time.sleep(sleep_s)
    took_ms = round((time.time() - start) * 1000)

    print(f"rounds={rounds} sleep={sleep_s}s took_ms={took_ms} memory={context.memory_limit_in_mb}MB")
    return {"rounds": rounds, "sleep": sleep_s, "took_ms": took_ms, "memory_mb": int(context.memory_limit_in_mb)}
