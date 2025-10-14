#!/usr/bin/env python3
"""
Workaround for Groq API SSL issues
This can be used as a temporary solution
"""
import requests
import ssl
import urllib3
from urllib3.util.ssl_ import create_urllib3_context

# Disable SSL warnings
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

def create_groq_session():
    """Create a requests session with SSL workaround"""
    session = requests.Session()
    
    # Create custom SSL context
    ctx = create_urllib3_context()
    ctx.set_ciphers('DEFAULT@SECLEVEL=1')
    
    # Create custom adapter
    from requests.adapters import HTTPAdapter
    from urllib3.util.retry import Retry
    
    retry_strategy = Retry(
        total=3,
        backoff_factor=1,
        status_forcelist=[429, 500, 502, 503, 504],
    )
    
    adapter = HTTPAdapter(max_retries=retry_strategy)
    session.mount("https://", adapter)
    
    return session

def test_groq_with_workaround():
    """Test Groq API with SSL workaround"""
    api_key = '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'
    
    try:
        session = create_groq_session()
        
        response = session.post(
            "https://api.groq.ai/chat/completions",
            headers={
                "Authorization": f"Bearer {api_key}",
                "Content-Type": "application/json",
                "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
            },
            json={
                "model": "gpt-3.5-mini",
                "messages": [{"role": "user", "content": "Hello"}],
                "max_tokens": 10
            },
            timeout=15,
            verify=False  # Temporary workaround
        )
        
        if response.status_code == 200:

            return True
        else:

            return False
            
    except Exception as e:

        return False

if __name__ == "__main__":
    test_groq_with_workaround()
