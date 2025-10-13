import os
import json
import requests
from groq import Groq
import re

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
            print("VoiceAssistant: Groq AI Model configured successfully.")
            return client
        except Exception as e:
            print(f"ERROR: VoiceAssistant Groq AI Model configuration failed: {e}")
            return None

    def get_intent_and_entities(self, user_text: str, menu_list: list, category_list: list, conversation_context: dict = None):
        """
        AI Pass 1: Identifies the user's goal (intent) and extracts key details (entities)
        like item names, ingredients, categories, or prices.
        """
        if not self.model: return {"intent": "unknown", "entity_name": None}

        menu_for_prompt = ", ".join([f"'{item['name']}'" for item in menu_list])
        categories_for_prompt = ", ".join(f"'{cat}'" for cat in category_list)
        conversation_history_for_prompt = json.dumps(conversation_context) if conversation_context else "None"

        prompt = f"""
        You are an expert system for a restaurant voice assistant. Your ONLY job is to analyze the user's text and extract their intent and relevant entities.

        **Conversation Context (what was just mentioned):** {conversation_history_for_prompt}
        **User's Current Command:** "{user_text}"

        **CRITICAL RULES:**
        1.  **Fuzzy Matching:** Be smart. If the user says "cold coffee" and the menu has "Classic Cold Coffee", you MUST match the entity to "Classic Cold Coffee". If they mention an ingredient like "chicken" or "mushroom", your intent must be `list_by_ingredient`.
        2.  **Entity Extraction:** Extract numbers for prices. Extract names for categories, items, and ingredients.
        3.  **Context Usage:** ONLY if the User's Current Command is ambiguous (e.g., "how much is it?") should you use the `last_mentioned_item` from the Conversation Context as the `entity_name`.
        4.  **Prioritize Intent:** Your primary goal is to determine the intent. A simple greeting like "hi" has an intent of "unknown".

        **Possible Intents:**
        - `place_order`: User wants to add an item to their cart.
        - `clear_cart`: User wants to empty their cart.
        - `ask_about_dish`: User asks for details about a specific dish (e.g., "what is in the...").
        - `ask_price`: User asks for the price of a specific dish.
        - `list_by_category`: User asks for all items in a category (e.g., "what's in appetizers?").
        - `list_by_ingredient`: User asks for dishes containing a specific ingredient (e.g., "show me something with mushroom").
        - `list_by_price_under`: User asks for items below a certain price (e.g., "what's under 200?").
        - `unknown`: The intent is unclear or is a simple greeting.

        **Available Menu Items:** {menu_for_prompt}
        **Available Categories:** {categories_for_prompt}

        **Your Output MUST be a single JSON object.**

        --- EXAMPLES ---
        User Command: "how much is the Spicy Prawn Aglio Olio"
        Output: {{"intent": "ask_price", "entity_name": "Spicy Prawn Aglio Olio"}}

        User Command: "add a cold coffee to my order"
        Output: {{"intent": "place_order", "entity_name": "Classic Cold Coffee"}}

        User Command: "what do you have in soups and salads"
        Output: {{"intent": "list_by_category", "category_name": "Soups & Salads"}}

        User Command: "list all chicken items"
        Output: {{"intent": "list_by_ingredient", "ingredient": "chicken"}}

        User Command: "what can I get for less than 300 rupees"
        Output: {{"intent": "list_by_price_under", "price_limit": 300}}

        User Command: "tell me about the paneer tikka"
        Output: {{"intent": "ask_about_dish", "entity_name": "Paneer Tikka Skewers"}}
        """
        try:
            # Simple regex to find numbers for the price intent
            price_match = re.search(r'\b(\d{2,4})\b', user_text)
            if price_match and ("under" in user_text or "less than" in user_text or "for" in user_text):
                 return {"intent": "list_by_price_under", "price_limit": int(price_match.group(1))}

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
        AI Pass 2: Takes verified facts from our database and system and turns them into a
        natural, human-friendly sentence.
        """
        if not self.model: 
            return {"confirmation_message": "I'm currently having trouble connecting to my AI brain. Please try again in a moment.", "new_context": {}}

        facts_for_prompt = json.dumps(context_data, indent=2)

        prompt = f"""
        You are ByteBot, a friendly and helpful restaurant voice assistant.
        Your job is to create a conversational response based ONLY on the verified facts provided.

        **User's original command:** "{user_text}"
        **The user's intent was:** "{intent}"
        **Verified facts from our database and system:**
        {facts_for_prompt}

        **Your Task & Rules:**
        1.  Formulate a single `confirmation_message` based on the intent and verified facts.
        2.  Determine the `new_context`. If a specific dish was discussed (e.g., from an `ask_price` or `place_order` intent), its name should become the `last_mentioned_item` in the new context.
        3.  Return your entire response as a single JSON object containing `confirmation_message` and `new_context`.

        --- CRITICAL INSTRUCTIONS FOR SPECIFIC INTENTS ---

        **If intent is `place_order`:**
        - If facts contain `"login_required": true`, your ONLY message is "You need to log in or sign up to place an order."
        - If an `"item_added"` key exists, the order was successful. Your message MUST state which item was added and the new `total_cart_price`.
            - Example: "Okay, I've added one Classic Cold Coffee to your cart. Your new total is ₹450."

        **If intent is `ask_price` or `ask_about_dish`:**
        - If an error is present, just say "Sorry, I couldn't find that item."
        - Otherwise, state the item's name and the requested info (price or description).
            - Price Example: "The Classic Cold Coffee costs ₹150."
            - Description Example: "Paneer Tikka Skewers are tender cubes of fresh paneer marinated and grilled to perfection."

        **If intent is `list_by_category`, `list_by_ingredient`, or `list_by_price_under`:**
        - The facts will contain a list named `matching_items`.
        - If `matching_items` is empty, say "Sorry, I couldn't find any items that match your request."
        - If `matching_items` is not empty, list the items in a natural sentence.
            - Category Example: "In Appetizers, we have Paneer Tikka Skewers and Crispy Chilli Baby Corn."
            - Ingredient Example: "The dishes with mushroom are Mushroom & Truffle Oil Pizza and Forest Risotto."
            - Price Example: "Items under ₹300 include the Classic Cold Coffee and Paneer Tikka Skewers."
        - After listing, you can optionally add a follow-up question like "Would you like to know more about any of these?"

        **If intent is `clear_cart`:**
        - If `"cart_cleared": true`, simply say "Okay, I've cleared your cart."

        **If intent is `unknown` or a simple greeting:**
        - Provide a friendly, welcoming response.
            - Example: "Good evening! How can I help you today?"
        """
        try:
            chat_completion = self.model.chat.completions.create(
                messages=[{"role": "user", "content": prompt}],
                model="llama-3.1-8b-instant",
                temperature=0.6,
                response_format={"type": "json_object"},
            )
            return json.loads(chat_completion.choices[0].message.content)
        except Exception as e:
            print(f"Error during AI response formulation: {e}")
            return {"confirmation_message": "I'm sorry, I had a little trouble with that request. Please try again.", "new_context": {}}