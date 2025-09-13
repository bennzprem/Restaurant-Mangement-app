import os
import json
import requests
from groq import Groq

class VoiceAssistant:
    def __init__(self, supabase_url: str, supabase_headers: dict):
        self.supabase_url = supabase_url
        self.supabase_headers = supabase_headers
        self.model = self._configure_model()

    def _configure_model(self):
        try:
            api_key = os.environ.get("GROQ_API_KEY")
            if not api_key: raise ValueError("GROQ_API_KEY environment variable not set.")
            client = Groq(api_key=api_key)
            print("✓ VoiceAssistant: Groq AI Model configured successfully.")
            return client
        except Exception as e:
            print(f"✗ ERROR: VoiceAssistant Groq AI Model configuration failed: {e}")
            return None

    def get_intent_and_entities(self, user_text: str, menu_list: list, conversation_context: dict = None):
        """
        AI Pass 1: Simple and fast. Just identifies the user's goal (intent) and the item they're talking about (entity).
        """
        if not self.model: return {"error": "AI model not available."}

        menu_for_prompt = ", ".join([f"'{item['name']}'" for item in menu_list])
        conversation_history_for_prompt = json.dumps(conversation_context) if conversation_context else "None"

        prompt = f"""
        You are a system that analyzes user text. Your ONLY job is to identify the user's intent and the main entity they mention.

        **Conversation Context (what was just mentioned):** {conversation_history_for_prompt}
        **User's Current Command:** "{user_text}"

        **CRITICAL RULES (Follow in this order):**
        1.  First, check if the **User's Current Command** mentions a specific menu item from the list below. If it does, you MUST use THAT as the `entity_name`.
        2.  ONLY if the User's Current Command is ambiguous (e.g., "order it", "how much is it?", "add one to my cart") should you use the `last_mentioned_item` from the Conversation Context as the `entity_name`.
        3.  Determine the most likely intent from the possible intents list. A simple greeting like "hi" or "good evening" should have an intent of "unknown".

        **Possible Intents:** place_order, clear_cart, check_availability, get_recommendation, ask_about_dish, ask_price, request_waiter, request_bill, unknown.
        **Menu Items:** {menu_for_prompt}

        Return ONLY a JSON object with "intent" and "entity_name".

        Example 1 (Specific Item Mentioned):
        - Context: {{"last_mentioned_item": "Cold Coffee"}}
        - Command: "how much is the chilly chicken"
        - Output: {{"intent": "ask_price", "entity_name": "Chilly Chicken"}}

        Example 2 (Ambiguous Command):
        - Context: {{"last_mentioned_item": "Cold Coffee"}}
        - Command: "order it"
        - Output: {{"intent": "place_order", "entity_name": "Cold Coffee"}}
        """
        try:
            chat_completion = self.model.chat.completions.create(
                messages=[{"role": "user", "content": prompt}],
                model="llama-3.1-8b-instant",
                response_format={"type": "json_object"},
            )
            return json.loads(chat_completion.choices[0].message.content)
        except Exception as e:
            print(f"Error during AI intent analysis: {e}")
            return {"intent": "unknown", "entity_name": None}

    def formulate_response(self, user_text: str, intent: str, context_data: dict):
        """
        AI Pass 2: Takes verified facts from our database and turns them into a natural, human-friendly sentence.
        """
        if not self.model: return {"error": "AI model not available."}

        facts_for_prompt = json.dumps(context_data, indent=2)

        prompt = f"""
        You are ByteBot, a friendly and precise restaurant voice assistant.
        Your job is to create a helpful, conversational response based ONLY on the verified facts provided to you.

        **User's original command:** "{user_text}"
        **The user's intent was:** "{intent}"
        **Verified facts from our database and system:**
        {facts_for_prompt}

        **Your Task & Rules:**
        1.  **Formulate a `confirmation_message`** based on the intent and the verified facts.
        2.  **Determine the `new_context`**. The `item_name` from the facts should become the `last_mentioned_item`.
        3.  Return your entire response as a single JSON object.

        --- CRITICAL INSTRUCTIONS FOR SPECIFIC INTENTS ---

        **If intent is `clear_cart`:**
        - If the facts contain `"cart_cleared": true`, your `confirmation_message` must be a simple confirmation like "Okay, I've cleared your cart."

        **If intent is `place_order`:**
        - If facts contain `"login_required": true`, your ONLY message must be "You need to log in or sign up to place an order."
        - If facts contain an `"item_added"` key, the order was successful. Your message MUST state which item was added, its individual `price`, and the new `total_cart_price`.
            - *Example:* "Okay, I've added one Classic Cold Coffee for ₹150 to your cart. Your new total is ₹450."

        **If intent is `ask_price`:**
        - Your message MUST state the item's name and its `price`.
            - *Example:* "The Classic Cold Coffee costs ₹150."

        **If intent is `unknown` or a simple greeting:**
        -   Provide a friendly, welcoming response. Do NOT mention logging in unless the facts explicitly say so.
            - *Example:* "Good evening! How can I help you today?"
        """
        try:
            chat_completion = self.model.chat.completions.create(
                messages=[{"role": "user", "content": prompt}],
                model="llama-3.1-8b-instant",
                temperature=0.5,
                response_format={"type": "json_object"},
            )
            return json.loads(chat_completion.choices[0].message.content)
        except Exception as e:
            print(f"Error during AI response formulation: {e}")
            return {"confirmation_message": "I'm sorry, I had a little trouble with that request."}

