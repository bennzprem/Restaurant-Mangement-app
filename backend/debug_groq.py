#!/usr/bin/env python3
import os
import requests
import json

# Set environment variables
os.environ['GROQ_API_KEY'] = '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'

# Get API key
api_key = os.getenv('GROQ_API_KEY')
print(f"API Key loaded: {bool(api_key)}")
print(f"API Key length: {len(api_key) if api_key else 0}")
print(f"API Key starts with: {api_key[:10] if api_key else 'None'}...")

# Test 1: Check API key format
print("\n=== API Key Verification ===")
if api_key and api_key.startswith('gsk_'):
    print("API key format looks correct")
else:
    print("API key format incorrect - should start with 'gsk_'")

# Test 2: Test basic connectivity
print("\n=== Basic Connectivity Test ===")
try:
    response = requests.get("https://api.groq.ai", timeout=10)
    print(f"Groq API endpoint reachable: {response.status_code}")
except Exception as e:
    print(f"Cannot reach Groq API: {e}")

# Test 3: Test with minimal request
print("\n=== Minimal Request Test ===")
try:
    response = requests.post(
        "https://api.groq.ai/chat/completions",
        headers={
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json"
        },
        json={
            "model": "gpt-3.5-mini",
            "messages": [{"role": "user", "content": "Hello"}],
            "max_tokens": 10
        },
        timeout=15
    )
    
    print(f"Response Status Code: {response.status_code}")
    print(f"Response Headers: {dict(response.headers)}")
    
    if response.status_code == 200:
        data = response.json()
        print("API request successful!")
        print(f"Response: {data}")
    else:
        print(f"API request failed")
        print(f"Response body: {response.text}")
        
except requests.exceptions.ConnectionError as e:
    print(f"Connection Error: {e}")
    print("This suggests network/firewall issues")
except requests.exceptions.Timeout as e:
    print(f"Timeout Error: {e}")
    print("Request took too long")
except Exception as e:
    print(f"Other Error: {e}")

# Test 4: Check DNS resolution
print("\n=== DNS Resolution Test ===")
import socket
try:
    ip = socket.gethostbyname('api.groq.ai')
    print(f"DNS resolution successful: api.groq.ai -> {ip}")
except Exception as e:
    print(f"DNS resolution failed: {e}")

# Test 5: Check if it's a rate limit issue
print("\n=== Rate Limit Check ===")
try:
    response = requests.post(
        "https://api.groq.ai/chat/completions",
        headers={
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json"
        },
        json={
            "model": "gpt-3.5-mini",
            "messages": [{"role": "user", "content": "test"}],
            "max_tokens": 1
        },
        timeout=10
    )
    
    if response.status_code == 429:
        print("Rate limit exceeded (429)")
        print(f"Rate limit headers: {dict(response.headers)}")
    elif response.status_code == 401:
        print("Unauthorized (401) - API key issue")
    elif response.status_code == 400:
        print("Bad request (400) - check request format")
    else:
        print(f"Status code: {response.status_code}")
        
except Exception as e:
    print(f"Error during rate limit check: {e}")
