import requests
import json
import re
import os

def parse_craving_with_groq(user_query):
    """Parse user craving query using Groq LLM into structured JSON"""
    prompt = f"""You are a restaurant menu assistant. Convert any free-text craving into structured JSON.
Rules:
- Normalize slang, typos, punctuation, emojis.
- Extract positive/negative keywords (what user wants/avoids).
- Detect hints: diet (veg/non-veg/vegan), course_type (drink/starter/main/dessert/snack/combo), budget (numeric INR), portion_size (single/share_2/share_4), mood/context.
- Map adjectives to logical categories: "refreshing" → course_type: drink, taste_profile: refreshing; "warming" → soup/hot drink.
- Detect intent: surprise, popular, trending, chef_reco, history_reference.

Output only JSON, use empty strings/arrays if unknown:

{{
  "normalized_query": "",
  "positive_keywords": [],
  "negative_keywords": [],
  "hints": {{
    "diet": "",
    "course_type": "",
    "budget": "",
    "portion_size": "",
    "mood": ""
  }},
  "intent": ""
}}

User query: "{user_query}"

Examples:
"🥶 need something hot n spicy" → "positive_keywords": ["hot","spicy"], "hints": {{"course_type":"drink"}}
"give me a non-veg starter" → "hints": {{"diet":"non-veg","course_type":"starter"}}
"Idk maybe something sweet" → "positive_keywords":["sweet"]
"Anything without onions pls" → "negative_keywords":["onion"]
"meal under ₹150" → "hints": {{"budget":150}}
"refreshing drink" → "hints": {{"course_type":"drink"}}, "positive_keywords":["refreshing"]
"warming soup" → "hints": {{"course_type":"soup"}}, "positive_keywords":["warming"]
"something cheesy" → "positive_keywords":["cheesy"]
"spicy but not too hot" → "positive_keywords":["spicy"], "negative_keywords":["hot"]
"vegetarian main course" → "hints": {{"diet":"veg","course_type":"main"}}
"""
    
    try:
        response = requests.post(
            "https://api.groq.com/openai/v1/chat/completions",
            headers={
                "Authorization": f"Bearer {os.getenv('GROQ_API_KEY')}",
                "Content-Type": "application/json",
            },
            json={
                "model": "llama-3.1-8b-instant",
                "messages": [{"role": "user", "content": prompt}]
            },
            timeout=15,
        )
        
        if response.status_code == 200:
            data = response.json()
            content = data['choices'][0]['message']['content'].strip()
            
            # Extract JSON from response
            match = re.search(r"\{.*\}", content, re.DOTALL)
            if match:
                return json.loads(match.group())
            else:
                return {}
        else:

            return {}
            
    except Exception as e:

        return {}

# Example usage and test
if __name__ == "__main__":
    # Test with example query
    test_query = "🥶 need something hot n spicy"
    result = parse_craving_with_groq(test_query)
