#!/usr/bin/env python3
import os
import requests
import json

# Set environment variables
os.environ['GROQ_API_KEY'] = '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'

# Get API key
api_key = os.getenv('GROQ_API_KEY')

# Test 1: Check API key format

if api_key and api_key.startswith('gsk_'):

else:

# Test 2: Test basic connectivity

try:
    response = requests.get("https://api.groq.ai", timeout=10)

except Exception as e:

# Test 3: Test with minimal request

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

    if response.status_code == 200:
        data = response.json()

    else:

except requests.exceptions.ConnectionError as e:

except requests.exceptions.Timeout as e:

except Exception as e:

# Test 4: Check DNS resolution

import socket
try:
    ip = socket.gethostbyname('api.groq.ai')

except Exception as e:

# Test 5: Check if it's a rate limit issue

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
    elif response.status_code == 401:
    elif response.status_code == 400:
    else:

except Exception as e:
