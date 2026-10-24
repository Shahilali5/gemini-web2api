import httpx
import json

def test_api():
    base_url = "http://127.0.0.1:8081/v1"
    headers = {
        "Authorization": "Bearer sk-gemini",
        "Content-Type": "application/json"
    }
    
    print("Testing connection to gemini-web2api...")
    try:
        # Check models
        models_resp = httpx.get(f"{base_url}/models", headers=headers, timeout=10.0)
        if models_resp.status_code == 200:
            print("Successfully retrieved models:")
            for m in models_resp.json().get("data", []):
                print(f"  - {m['id']}: {m.get('description', '')}")
        else:
            print(f"Failed to fetch models: HTTP {models_resp.status_code}")
            return

        # Check chat completions
        payload = {
            "model": "gemini-3.6-flash",
            "messages": [
                {"role": "user", "content": "Explain quantum computing in one sentence."}
            ]
        }
        print("\nSending test completion prompt...")
        chat_resp = httpx.post(f"{base_url}/chat/completions", headers=headers, json=payload, timeout=60.0)
        if chat_resp.status_code == 200:
            data = chat_resp.json()
            content = data["choices"][0]["message"]["content"]
            print(f"\nResponse:\n{content}")
            print("\nSetup test passed successfully!")
        else:
            print(f"Chat completion failed: HTTP {chat_resp.status_code} - {chat_resp.text}")
    except httpx.ConnectError:
        print("Could not connect to server. Make sure the server is running on port 8081 (run start.bat)!")
    except Exception as e:
        print(f"Error during test: {e}")

if __name__ == "__main__":
    test_api()
