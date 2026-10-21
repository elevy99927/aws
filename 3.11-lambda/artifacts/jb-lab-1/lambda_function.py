import json


def lambda_handler(event, context):
    # 1. The event: the JSON document that describes "what happened"
    print("event received:", json.dumps(event))

    # 2. The context: information about this invocation
    print(
        f"function={context.function_name} "
        f"memory={context.memory_limit_in_mb}MB "
        f"request_id={context.aws_request_id}"
    )

    # 3. The function's work, driven by the event
    action = event.get("action", "hello")
    if action == "add":
        result = sum(event.get("numbers", []))
    elif action == "upper":
        result = event.get("text", "").upper()
    else:
        result = "Hello from jb-lab-1!"

    print(f"action={action} result={result} remaining_ms={context.get_remaining_time_in_millis()}")

    # 4. The return value is the response to a synchronous caller
    return {"action": action, "result": result}
