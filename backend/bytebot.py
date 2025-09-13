import os
import json
import requests
from datetime import datetime, timezone, timedelta
from groq import Groq

class ByteBot:
    """
    A class to encapsulate the AI recommendation logic for the ByteEat app.
    """
    def __init__(self, supabase_url: str, supabase_headers: dict):
        """
        Initializes the ByteBot service.

        Args:
            supabase_url: The base URL for the Supabase project.
            supabase_headers: The required headers for Supabase REST API calls.
        """
        self.supabase_url = supabase_url
        self.supabase_headers = supabase_headers
        self.model = self._configure_model()

    def _configure_model(self):
        """Configures and returns the Groq AI model client."""
        try:
            # CHANGE: Look for GROQ_API_KEY now
            api_key = os.environ.get("GROQ_API_KEY")
            if not api_key:
                print("✗ ERROR: GROQ_API_KEY environment variable not set.")
                return None
            # CHANGE: Initialize the Groq client
            client = Groq(api_key=api_key)
            print("✓ ByteBot: Groq AI Model configured successfully.")
            return client
        except Exception as e:
            print(f"✗ ERROR: ByteBot Groq AI Model configuration failed: {e}")
            return None

    def get_recommendation(self):
        """
        Generates a dish recommendation by querying the Gemini AI model.

        Returns:
            A dictionary containing the recommended dish and the reason,
            or an error dictionary.
        """
        if not self.model:
            # Graceful fallback: return a simple deterministic recommendation
            try:
                menu_response = requests.get(
                    f"{self.supabase_url}/rest/v1/menu_items?select=name,description,tags,image_url",
                    headers=self.supabase_headers
                )
                menu_response.raise_for_status()
                menu_items = menu_response.json()
                if not menu_items:
                    return {"error": "Menu is empty."}, 503
                fallback_dish = menu_items[0]
                return {
                    "dish": fallback_dish,
                    "reason": "Showing a recommendation while AI initializes."
                }, 200
            except Exception as e:
                # Last-resort placeholder so the UI can render
                return {
                    "dish": {
                        "name": "Chef's Special",
                        "description": "A delightful seasonal pick while ByteBot warms up.",
                        "image_url": "https://via.placeholder.com/600x400.png?text=Chef%27s%20Special",
                        "tags": ["popular", "seasonal"]
                    },
                    "reason": "Temporary recommendation shown while AI initializes."
                }, 200

        try:
            # 1. Fetch the entire menu from Supabase to give the AI context
            menu_response = requests.get(
                f"{self.supabase_url}/rest/v1/menu_items?select=name,description,tags,image_url",
                headers=self.supabase_headers
            )
            menu_response.raise_for_status()
            menu_items = menu_response.json()

            # Format the menu for the AI prompt
            menu_for_prompt = ", ".join([f"'{item['name']}'" for item in menu_items])

            # 2. Engineer the prompt with real-time context
            # Using IST for Bengaluru
            current_time = datetime.now(timezone.utc) + timedelta(hours=5, minutes=30)
            prompt = f"""
            You are ByteBot, the intelligent culinary curator for a restaurant named "ByteEat" in Bengaluru, India.
            Your goal is to provide a single, perfect dish recommendation based on the current context.

            **Current Context:**
            - Time: {current_time.strftime('%I:%M %p')}
            - Day: {current_time.strftime('%A')}
            - Location: Bengaluru, India

            **Available Menu Items:**
            [{menu_for_prompt}]

            **Your Task:**
            1. Analyze the context (e.g., a weekday morning is for a light breakfast, a Friday night is for a celebratory meal).
            2. Select the ONE most suitable dish from the provided menu list.
            3. Generate a compelling, one-sentence reason for your choice, mentioning the context.
            4. Return your response ONLY in the following JSON format, with no other text or markdown:
            {{
              "dishName": "Name of the Chosen Dish",
              "reason": "Your generated reason."
            }}
            """

            # 3. Call the Groq API
            chat_completion = self.model.chat.completions.create(
                messages=[{"role": "user", "content": prompt}],
                model="llama-3.1-8b-instant", # Using a fast model from Groq
                temperature=0.7,
                response_format={"type": "json_object"},
            )
            
            # Get the JSON response directly from the new response format
            response_content = chat_completion.choices[0].message.content
            ai_data = json.loads(response_content)
            
            # 4. Find the full dish details from the menu
            recommended_dish_name = ai_data.get("dishName")
            full_dish_details = next((item for item in menu_items if item['name'] == recommended_dish_name), None)

            if not full_dish_details:
                return {"error": "AI recommended a dish not found in the menu."}, 500

            # 5. Return the complete recommendation
            return {
                "dish": full_dish_details,
                "reason": ai_data.get("reason")
            }, 200

        except Exception as e:
            print(f"An error occurred in ByteBot's get_recommendation: {e}")
            return {"error": str(e)}, 500
