import httpx
import json

base_url = "http://127.0.0.1:8081/v1"
headers = {
    "x-api-key": "sk-gemini",
    "anthropic-version": "2023-06-01",
    "content-type": "application/json"
}

def test_tools():
    print("Testing Anthropic tool calling...")
    tools = [
        {
            "name": "get_current_weather",
            "description": "Get the current weather for a city",
            "input_schema": {
                "type": "object",
                "properties": {
                    "city": {"type": "string", "description": "The city name"}
                },
                "required": ["city"]
            }
        }
    ]
    payload = {
        "model": "claude-3-7-sonnet-20250219",
        "messages": [{"role": "user", "content": "What is the weather in Paris? Please call the tool."}],
        "tools": tools,
        "stream": True
    }
    with httpx.stream("POST", f"{base_url}/messages", headers=headers, json=payload, timeout=60.0) as sresp:
        print(f"Tool stream status: {sresp.status_code}")
        for line in sresp.iter_lines():
            if line:
                print(f"  {line}")

if __name__ == "__main__":
    test_tools()
