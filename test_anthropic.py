import httpx
import json

base_url = "http://127.0.0.1:8081/v1"
headers = {
    "x-api-key": "sk-gemini",
    "anthropic-version": "2023-06-01",
    "content-type": "application/json"
}

def test_anthropic():
    print("1. Testing count_tokens...")
    payload = {
        "model": "claude-3-7-sonnet-20250219",
        "messages": [{"role": "user", "content": "Hello Claude!"}]
    }
    resp = httpx.post(f"{base_url}/messages/count_tokens", headers=headers, json=payload, timeout=10.0)
    print(f"Status: {resp.status_code}, Body: {resp.text}")

    print("\n2. Testing /v1/messages (non-streaming)...")
    payload = {
        "model": "claude-3-7-sonnet-20250219",
        "messages": [{"role": "user", "content": "Respond with exactly: 'Gemini to Claude test passed'."}],
        "stream": False
    }
    resp = httpx.post(f"{base_url}/messages", headers=headers, json=payload, timeout=60.0)
    print(f"Status: {resp.status_code}")
    if resp.status_code == 200:
        data = resp.json()
        print("Response structure:")
        print(f"  id: {data.get('id')}")
        print(f"  model: {data.get('model')}")
        print(f"  role: {data.get('role')}")
        print(f"  content: {data.get('content')}")
        print(f"  stop_reason: {data.get('stop_reason')}")
    else:
        print(f"Error: {resp.text}")

    print("\n3. Testing /v1/messages (streaming SSE)...")
    payload = {
        "model": "claude-3-5-sonnet-20241022",
        "messages": [{"role": "user", "content": "Count from 1 to 5."}],
        "stream": True
    }
    with httpx.stream("POST", f"{base_url}/messages", headers=headers, json=payload, timeout=60.0) as sresp:
        print(f"Stream status: {sresp.status_code}")
        for line in sresp.iter_lines():
            if line:
                print(f"  {line}")

if __name__ == "__main__":
    test_anthropic()
