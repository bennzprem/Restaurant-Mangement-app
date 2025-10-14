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

            return client
        except Exception as e:

            return None

    def extract_number_from_text(self, text: str):
        """Extract number from text, handling both digits and words"""
        import re
        
        # Number word mapping
        number_words = {
            'zero': 0, 'one': 1, 'two': 2, 'three': 3, 'four': 4, 'five': 5,
            'six': 6, 'seven': 7, 'eight': 8, 'nine': 9, 'ten': 10
        }
        
        text_lower = text.lower().strip()
        
        # First try to find digit
        digit_match = re.search(r'\b(\d+)\b', text)
        if digit_match:
            return int(digit_match.group(1))
        
        # Then try number words
        for word, num in number_words.items():
            if word in text_lower:
                return num
                
        return None

    def get_intent_and_entities(self, user_text: str, menu_list: list, category_list: list, conversation_context: dict = None):
        """
        AI Pass 1: Identifies the user's goal (intent) and extracts key details (entities)
        like item names, ingredients, categories, or prices.
        """
        if not self.model: 

            return {"intent": "unknown", "entity_name": None}

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
        - `place_order`: User wants to add an item to their cart (e.g., "add pizza", "order chicken", "I want to buy...").
        - `want_to_order`: User wants to start ordering food but hasn't specified a particular item (e.g., "I want to order food", "I want to order something", "I want to buy food").
        - `ask_takeaway`: User asks about takeaway ordering process (e.g., "can I place an order for takeaway", "how do I order for pickup").
        - `ask_online_ordering`: User asks about online ordering process (e.g., "how do I order online", "how to order through the app").
        - `ask_order_tracking`: User asks about order tracking (e.g., "can I track my order", "how to track my order").
        - `ask_order_cancellation`: User asks about canceling orders (e.g., "can I cancel my order", "how to cancel my order").
        - `ask_order_status`: User asks about order status or delivery status.
        - `ask_delivery_info`: User asks about delivery options, fees, or timing.
        - `ask_table_booking`: User asks about table booking/reservation (e.g., "can I book a table", "how do I reserve a table", "is table booking required").
        - `book_table`: User wants to make a table reservation (e.g., "I want a table for 4 at 8 PM", "book a table for tomorrow").
        - `ask_group_reservations`: User asks about group reservations or large party bookings.
        - `ask_walk_ins`: User asks about walk-in availability.
        - `modify_reservation`: User wants to change or modify existing reservation.
        - `ask_booking_fees`: User asks about table booking charges or fees.
        - `post_login_continuation`: User has logged in and wants to continue with their previous request.
        - `clear_cart`: User wants to empty their cart.
        - `ask_about_dish`: User asks for details about a specific dish (e.g., "what is in the...", "do you have...", "is there...", "tell me about...").
        - `ask_price`: User asks for the price of a specific dish.
        - `list_by_category`: User asks for all items in a category (e.g., "what's in appetizers?").
        - `list_by_ingredient`: User asks for dishes containing a specific ingredient (e.g., "show me something with mushroom").
        - `list_by_price_under`: User asks for items below a certain price (e.g., "what's under 200?").
        - `list_by_specific_type`: User asks for specific types like "ice creams", "desserts", "beverages", "pizzas" (e.g., "what ice creams do you have?").
        - `show_menu`: User wants to see the full menu or browse items.
        - `show_specials`: User asks about specials, new items, or recommendations.
        - `show_popular`: User asks about popular dishes, bestsellers, or recommendations.
        - `show_dietary_options`: User asks about dietary restrictions (vegan, gluten-free, vegetarian, etc.).
        - `show_drinks`: User asks about beverages, drinks, coffee, tea, etc.
        - `show_healthy_options`: User asks about healthy, organic, or nutritional options.
        - `ask_ingredients`: User asks about ingredients in a specific dish.
        - `ask_spice_level`: User asks about spice level or heat of a dish.
        - `ask_customization`: User asks about customizing orders or modifications.
        - `ask_combos`: User asks about combo deals, meal deals, or special offers.
        - `ask_pricing_info`: User asks about general pricing, discounts, delivery fees, etc.
        - `unknown`: The intent is unclear or is a simple greeting.

        **CRITICAL INTENT DISTINCTION:**
        - Use `ask_about_dish` for questions like "do you have...", "is there...", "tell me about...", "what is...", "do you serve...", "is [item] available"
        - Use `place_order` ONLY when user explicitly wants to add/order/buy something (e.g., "add to cart", "order", "buy", "I want to order...", "add [item] to my order")
        
        **IMPORTANT:** Questions about availability or asking for information should NEVER be classified as `place_order`.

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

        User Command: "what ice creams do you have"
        Output: {{"intent": "list_by_specific_type", "specific_type": "ice cream"}}

        User Command: "show me desserts"
        Output: {{"intent": "list_by_specific_type", "specific_type": "dessert"}}

        User Command: "what can I get for less than 300 rupees"
        Output: {{"intent": "list_by_price_under", "price_limit": 300}}

        User Command: "tell me about the paneer tikka"
        Output: {{"intent": "ask_about_dish", "entity_name": "Paneer Tikka Skewers"}}

        User Command: "do you have pizza"
        Output: {{"intent": "ask_about_dish", "entity_name": "pizza"}}

        User Command: "do you serve chicken biryani"
        Output: {{"intent": "ask_about_dish", "entity_name": "chicken biryani"}}

        User Command: "is there any pasta available"
        Output: {{"intent": "ask_about_dish", "entity_name": "pasta"}}

        User Command: "do you have cold coffee"
        Output: {{"intent": "ask_about_dish", "entity_name": "cold coffee"}}

        User Command: "add pizza to my order"
        Output: {{"intent": "place_order", "entity_name": "pizza"}}

        User Command: "I want to order chicken biryani"
        Output: {{"intent": "place_order", "entity_name": "chicken biryani"}}

        User Command: "buy me a cold coffee"
        Output: {{"intent": "place_order", "entity_name": "cold coffee"}}

        User Command: "I want to order food"
        Output: {{"intent": "want_to_order"}}

        User Command: "I want to order something"
        Output: {{"intent": "want_to_order"}}

        User Command: "I want to buy food"
        Output: {{"intent": "want_to_order"}}

        User Command: "I want to order"
        Output: {{"intent": "want_to_order"}}

        User Command: "can I place an order for takeaway"
        Output: {{"intent": "ask_takeaway"}}

        User Command: "how do I order online"
        Output: {{"intent": "ask_online_ordering"}}

        User Command: "can I track my order"
        Output: {{"intent": "ask_order_tracking"}}

        User Command: "can I cancel my order"
        Output: {{"intent": "ask_order_cancellation"}}

        User Command: "how to order for pickup"
        Output: {{"intent": "ask_takeaway"}}

        User Command: "how to order through the app"
        Output: {{"intent": "ask_online_ordering"}}

        User Command: "how to track my order"
        Output: {{"intent": "ask_order_tracking"}}

        User Command: "how to cancel my order"
        Output: {{"intent": "ask_order_cancellation"}}

        User Command: "what's my order status"
        Output: {{"intent": "ask_order_status"}}

        User Command: "is my order ready"
        Output: {{"intent": "ask_order_status"}}

        User Command: "do you deliver"
        Output: {{"intent": "ask_delivery_info"}}

        User Command: "what are your delivery options"
        Output: {{"intent": "ask_delivery_info"}}

        User Command: "I'm back after logging in"
        Output: {{"intent": "post_login_continuation"}}

        User Command: "I just logged in"
        Output: {{"intent": "post_login_continuation"}}

        User Command: "I'm logged in now"
        Output: {{"intent": "post_login_continuation"}}

        User Command: "can I book a table"
        Output: {{"intent": "ask_table_booking"}}

        User Command: "how do I reserve a table"
        Output: {{"intent": "ask_table_booking"}}

        User Command: "is table booking required"
        Output: {{"intent": "ask_table_booking"}}

        User Command: "I want a table for 4 at 8 PM"
        Output: {{"intent": "book_table", "guest_count": 4, "time": "8 PM"}}

        User Command: "book a table for tomorrow"
        Output: {{"intent": "book_table", "date": "tomorrow"}}

        User Command: "reserve a table for 6 people"
        Output: {{"intent": "book_table", "guest_count": 6}}

        User Command: "do you take group reservations"
        Output: {{"intent": "ask_group_reservations"}}

        User Command: "do you allow walk-ins"
        Output: {{"intent": "ask_walk_ins"}}

        User Command: "can I change my reservation time"
        Output: {{"intent": "modify_reservation"}}

        User Command: "do you charge for table booking"
        Output: {{"intent": "ask_booking_fees"}}

        User Command: "yes please help me"
        Output: {{"intent": "continue_booking_flow"}}

        User Command: "yes"
        Output: {{"intent": "continue_booking_flow"}}

        User Command: "sure"
        Output: {{"intent": "continue_booking_flow"}}

        User Command: "okay"
        Output: {{"intent": "continue_booking_flow"}}

        User Command: "4 people"
        Output: {{"intent": "booking_guests", "guest_count": 4}}

        User Command: "2 guests"
        Output: {{"intent": "booking_guests", "guest_count": 2}}

        User Command: "6 people"
        Output: {{"intent": "booking_guests", "guest_count": 6}}

        User Command: "tomorrow"
        Output: {{"intent": "booking_date", "date": "tomorrow"}}

        User Command: "today"
        Output: {{"intent": "booking_date", "date": "today"}}

        User Command: "8 PM"
        Output: {{"intent": "booking_time", "time": "8 PM"}}

        User Command: "7:30 PM"
        Output: {{"intent": "booking_time", "time": "7:30 PM"}}

        User Command: "dinner"
        Output: {{"intent": "booking_meal_period", "meal_period": "dinner"}}

        User Command: "lunch"
        Output: {{"intent": "booking_meal_period", "meal_period": "lunch"}}

        User Command: "breakfast"
        Output: {{"intent": "booking_meal_period", "meal_period": "breakfast"}}

        User Command: "yes confirm"
        Output: {{"intent": "confirm_booking"}}

        User Command: "confirm"
        Output: {{"intent": "confirm_booking"}}

        User Command: "yes"
        Output: {{"intent": "confirm_booking"}}

        User Command: "book it"
        Output: {{"intent": "confirm_booking"}}

        User Command: "show me the menu"
        Output: {{"intent": "show_menu"}}

        User Command: "what are today's specials"
        Output: {{"intent": "show_specials"}}

        User Command: "do you have any new items"
        Output: {{"intent": "show_specials"}}

        User Command: "what is your most popular dish"
        Output: {{"intent": "show_popular"}}

        User Command: "what do you recommend for first-timers"
        Output: {{"intent": "show_popular"}}

        User Command: "do you serve desserts"
        Output: {{"intent": "list_by_specific_type", "specific_type": "dessert"}}

        User Command: "do you have vegan options"
        Output: {{"intent": "show_dietary_options", "dietary_type": "vegan"}}

        User Command: "what are your best sellers"
        Output: {{"intent": "show_popular"}}

        User Command: "what drinks do you offer"
        Output: {{"intent": "show_drinks"}}

        User Command: "do you serve coffee or tea"
        Output: {{"intent": "show_drinks"}}

        User Command: "can you suggest something spicy"
        Output: {{"intent": "list_by_ingredient", "ingredient": "spicy"}}

        User Command: "what's ByteEat's signature dish"
        Output: {{"intent": "show_popular"}}

        User Command: "what are your healthy options"
        Output: {{"intent": "show_healthy_options"}}

        User Command: "tell me the ingredients of the chicken biryani"
        Output: {{"intent": "ask_ingredients", "entity_name": "chicken biryani"}}

        User Command: "how spicy is the paneer tikka"
        Output: {{"intent": "ask_spice_level", "entity_name": "paneer tikka"}}

        User Command: "do you use organic ingredients"
        Output: {{"intent": "show_healthy_options"}}

        User Command: "can I customize my order"
        Output: {{"intent": "ask_customization"}}

        User Command: "is chicken biryani vegetarian"
        Output: {{"intent": "ask_about_dish", "entity_name": "chicken biryani"}}

        User Command: "do you have combos or meal deals"
        Output: {{"intent": "ask_combos"}}

        User Command: "how much does pizza cost"
        Output: {{"intent": "ask_price", "entity_name": "pizza"}}

        User Command: "what's the price range here"
        Output: {{"intent": "ask_pricing_info"}}

        User Command: "do you have any discounts right now"
        Output: {{"intent": "ask_pricing_info"}}

        User Command: "is there a student discount"
        Output: {{"intent": "ask_pricing_info"}}

        User Command: "do you have a loyalty program"
        Output: {{"intent": "ask_pricing_info"}}

        User Command: "are there any combo offers"
        Output: {{"intent": "ask_combos"}}

        User Command: "how much is delivery"
        Output: {{"intent": "ask_pricing_info"}}

        User Command: "what's the minimum order for delivery"
        Output: {{"intent": "ask_pricing_info"}}
        """
        try:
            # Quick fallback for common questions to avoid API calls
            user_lower = user_text.lower()
            if any(phrase in user_lower for phrase in ["how do i order", "how to order", "i want to order food", "i want to order something"]):
                return {"intent": "want_to_order"}
            elif any(phrase in user_lower for phrase in ["can i place an order for takeaway", "how do i order for pickup", "takeaway"]):
                return {"intent": "ask_takeaway"}
            elif any(phrase in user_lower for phrase in ["how do i order online", "online ordering", "order through the app"]):
                return {"intent": "ask_online_ordering"}
            elif any(phrase in user_lower for phrase in ["can i track my order", "how to track my order", "track order"]):
                return {"intent": "ask_order_tracking"}
            elif any(phrase in user_lower for phrase in ["can i cancel my order", "how to cancel my order", "cancel order"]):
                return {"intent": "ask_order_cancellation"}
            elif any(phrase in user_lower for phrase in ["what's my order status", "is my order ready", "order status"]):
                return {"intent": "ask_order_status"}
            elif any(phrase in user_lower for phrase in ["do you deliver", "delivery options", "delivery info"]):
                return {"intent": "ask_delivery_info"}
            elif any(phrase in user_lower for phrase in ["discount", "offer", "promotion", "deal"]):
                return {"intent": "ask_pricing_info"}
            elif any(phrase in user_lower for phrase in ["i'm back after logging in", "i just logged in", "i'm logged in now", "logged in", "back after login"]):
                return {"intent": "post_login_continuation"}
            elif any(phrase in user_lower for phrase in ["can i book a table", "how do i reserve a table", "is table booking required", "table booking", "reserve table"]):
                return {"intent": "ask_table_booking"}
            elif any(phrase in user_lower for phrase in ["i want a table", "book a table", "reserve a table", "table for", "book table"]):
                return {"intent": "book_table"}
            elif any(phrase in user_lower for phrase in ["group reservations", "large party", "big group", "group booking"]):
                return {"intent": "ask_group_reservations"}
            elif any(phrase in user_lower for phrase in ["walk-ins", "walk in", "walkin", "without reservation"]):
                return {"intent": "ask_walk_ins"}
            elif any(phrase in user_lower for phrase in ["change reservation", "modify reservation", "reschedule", "change time"]):
                return {"intent": "modify_reservation"}
            elif any(phrase in user_lower for phrase in ["charge for booking", "booking fee", "reservation fee", "table charge"]):
                return {"intent": "ask_booking_fees"}

            # Simple regex to find numbers for the price intent
            price_match = re.search(r'\b(\d{2,4})\b', user_text)
            if price_match and ("under" in user_text or "less than" in user_text or "for" in user_text):
                 return {"intent": "list_by_price_under", "price_limit": int(price_match.group(1))}

            chat_completion = self.model.chat.completions.create(
                messages=[{"role": "user", "content": prompt}],
                model="llama-3.1-8b-instant",
                response_format={"type": "json_object"},
                timeout=5  # 5 second timeout
            )
            
            response_content = chat_completion.choices[0].message.content

            if not response_content:

                return {"intent": "unknown", "entity_name": None}
                
            return json.loads(response_content)
        except json.JSONDecodeError as e:

            return {"intent": "unknown", "entity_name": None}
        except Exception as e:

            return {"intent": "unknown", "entity_name": None}

    def formulate_response(self, user_text: str, intent: str, context_data: dict):
        """
        AI Pass 2: Takes verified facts from our database and system and turns them into a
        natural, human-friendly sentence.
        """
        if not self.model: 
            return {"confirmation_message": "I'm currently having trouble connecting to my AI brain. Please try again in a moment.", "new_context": {}}

        # PRIORITY: Handle booking flow inputs first to prevent conflicts
        user_text_lower = user_text.lower().strip()
        
        # Handle date inputs during booking flow (check both 'ask_date' step AND if context has guest_count without meal_period)
        if context_data:
            booking_step = context_data.get('booking_flow_step')
            has_guest_count = context_data.get('guest_count') is not None
            has_meal_period = context_data.get('meal_period') is not None
            
            # If we have guest_count but no meal_period, and user says a date word, ask for meal period
            if has_guest_count and not has_meal_period and any(word in user_text_lower for word in ['today', 'tomorrow', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday']):
                guest_count = context_data.get('guest_count', 2)
                date = 'tomorrow' if 'tomorrow' in user_text_lower else ('today' if 'today' in user_text_lower else user_text_lower)
                return {"confirmation_message": f"Perfect! {date} for {guest_count} guests. What meal period would you prefer? You can choose from Breakfast, Lunch, or Dinner.", "new_context": {"booking_flow_step": "ask_meal_period", "guest_count": guest_count, "date": date}}
        
        # Handle meal period inputs during booking flow
        if context_data and context_data.get('booking_flow_step') == 'ask_meal_period':
            guest_count = context_data.get('guest_count', 2)
            date = context_data.get('date', 'tomorrow')
            if any(word in user_text_lower for word in ['breakfast', 'lunch', 'dinner']):
                meal_period = 'Breakfast' if 'breakfast' in user_text_lower else ('Lunch' if 'lunch' in user_text_lower else 'Dinner')
                return {"confirmation_message": f"Great! {meal_period} on {date} for {guest_count} guests. Let me check available time slots for you. What time would you prefer? We have slots available from 7:00 PM to 10:00 PM in 30-minute intervals.", "new_context": {"booking_flow_step": "ask_time", "guest_count": guest_count, "date": date, "meal_period": meal_period}}
        
        # Handle time inputs during booking flow
        if any(word in user_text_lower for word in ['pm', 'am', ':', '7', '8', '9', '10']):
            if context_data and context_data.get('booking_flow_step') == 'ask_time':
                guest_count = context_data.get('guest_count', 2)
                date = context_data.get('date', 'tomorrow')
                meal_period = context_data.get('meal_period', 'Dinner')
                time = user_text_lower
                return {"confirmation_message": f"Excellent! I have your reservation for {guest_count} guests on {date} at {time} for {meal_period}. Is there any special occasion or special requests for your reservation?", "new_context": {"booking_flow_step": "ask_special_occasion", "guest_count": guest_count, "date": date, "meal_period": meal_period, "time": time}}

        # Immediate fallback for table booking requests - works even if API fails
        if any(phrase in user_text_lower for phrase in ['reserve a table', 'book a table', 'table reservation', 'reserve table', 'i want a table', 'book table']):
            if context_data.get("login_required"):
                return {"confirmation_message": "I'd love to help you book a table! First, please log in to your account, then I'll guide you through the reservation process step by step.", "new_context": {"booking_flow_step": "login_required"}}
            elif context_data.get("is_logged_in"):
                return {"confirmation_message": "Perfect! Let's start booking your table. How many guests will be joining you?", "new_context": {"booking_flow_step": "ask_guests"}}
            else:
                return {"confirmation_message": "I'd love to help you book a table! Please log in first, then I'll guide you through the reservation process step by step.", "new_context": {"booking_flow_step": "login_required"}}

        # Universal time recognition fallback - catches time input (MUST come before number recognition)
        user_text_lower = user_text.lower().strip()
        if any(word in user_text_lower for word in ['pm', 'am', ':', '7', '8', '9', '10']):
            if context_data and context_data.get('booking_flow_step') == 'ask_time':
                guest_count = context_data.get('guest_count', 2)
                date = context_data.get('date', 'tomorrow')
                meal_period = context_data.get('meal_period', 'Dinner')
                time = user_text_lower
                return {"confirmation_message": f"Excellent! I have your reservation for {guest_count} guests on {date} at {time} for {meal_period}. Is there any special occasion or special requests for your reservation?", "new_context": {"booking_flow_step": "ask_special_occasion", "guest_count": guest_count, "date": date, "meal_period": meal_period, "time": time}}

        # Universal number recognition fallback - catches any number input
        number = self.extract_number_from_text(user_text)
        if number and 1 <= number <= 8:
            # Check if we're in a booking flow or if this could be a guest count
            if context_data and context_data.get('booking_flow_step') == 'ask_guests':
                return {"confirmation_message": f"Great! A table for {number} guests. What date would you like to book for? You can say 'today', 'tomorrow', or a specific date.", "new_context": {"booking_flow_step": "ask_date", "guest_count": number}}
            # If we're asking for time, meal period, or special occasion, don't treat numbers as guest count
            elif context_data and context_data.get('booking_flow_step') in ['ask_time', 'ask_meal_period', 'ask_special_occasion']:
                # Let the specific step logic handle this
                pass
            # If no booking flow context but user is logged in, assume they want to start booking
            elif context_data and context_data.get('is_logged_in'):
                return {"confirmation_message": f"Great! A table for {number} guests. What date would you like to book for? You can say 'today', 'tomorrow', or a specific date.", "new_context": {"booking_flow_step": "ask_date", "guest_count": number}}
            # If no context at all, but user said a number, assume they want to start booking
            else:
                return {"confirmation_message": f"Great! A table for {number} guests. What date would you like to book for? You can say 'today', 'tomorrow', or a specific date.", "new_context": {"booking_flow_step": "ask_date", "guest_count": number}}

        # Universal date recognition fallback - catches any date input
        if any(word in user_text_lower for word in ['today', 'tomorrow', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday']):
            if context_data and context_data.get('booking_flow_step') == 'ask_date':
                guest_count = context_data.get('guest_count', 2)
                date = 'tomorrow' if 'tomorrow' in user_text_lower else ('today' if 'today' in user_text_lower else user_text_lower)
                return {"confirmation_message": f"Perfect! {date} for {guest_count} guests. What meal period would you prefer? You can choose from Breakfast, Lunch, or Dinner.", "new_context": {"booking_flow_step": "ask_meal_period", "guest_count": guest_count, "date": date}}

        # Universal meal period recognition fallback - catches meal period input
        if any(word in user_text_lower for word in ['breakfast', 'lunch', 'dinner']):
            if context_data and context_data.get('booking_flow_step') == 'ask_meal_period':
                guest_count = context_data.get('guest_count', 2)
                date = context_data.get('date', 'tomorrow')
                meal_period = 'Breakfast' if 'breakfast' in user_text_lower else ('Lunch' if 'lunch' in user_text_lower else 'Dinner')
                return {"confirmation_message": f"Great! {meal_period} on {date} for {guest_count} guests. Let me check available time slots for you. What time would you prefer? We have slots available from 7:00 PM to 10:00 PM in 30-minute intervals.", "new_context": {"booking_flow_step": "ask_time", "guest_count": guest_count, "date": date, "meal_period": meal_period}}

        # Universal special occasion recognition fallback - catches any text input for special occasion
        if context_data and context_data.get('booking_flow_step') == 'ask_special_occasion':
            guest_count = context_data.get('guest_count', 2)
            date = context_data.get('date', 'tomorrow')
            meal_period = context_data.get('meal_period', 'Dinner')
            time = context_data.get('time', '8:00 PM')
            special_occasion = user_text.strip() if user_text.strip() else "None"
            return {"confirmation_message": f"Perfect! I have your reservation for {guest_count} guests on {date} at {time} for {meal_period}. Special occasion: {special_occasion}. Would you like me to confirm this booking for you?", "new_context": {"booking_flow_step": "confirm_booking", "guest_count": guest_count, "date": date, "meal_period": meal_period, "time": time, "special_occasion": special_occasion}}

        # Fallback for unknown intents or errors
        if intent == "unknown" or not intent:
            if any(phrase in user_text_lower for phrase in ['reserve a table', 'book a table', 'table reservation', 'reserve table', 'i want a table', 'book table']):
                if context_data.get("login_required"):
                    return {"confirmation_message": "I'd love to help you book a table! First, please log in to your account, then I'll guide you through the reservation process step by step.", "new_context": {"booking_flow_step": "login_required"}}
                elif context_data.get("is_logged_in"):
                    return {"confirmation_message": "Perfect! Let's start booking your table. How many guests will be joining you?", "new_context": {"booking_flow_step": "ask_guests"}}
                else:
                    return {"confirmation_message": "I'd love to help you book a table! Please log in first, then I'll guide you through the reservation process step by step.", "new_context": {"booking_flow_step": "login_required"}}
            else:
                return {"confirmation_message": "I'm having trouble understanding that. Could you please try again or ask me about our menu, table reservations, or delivery options?", "new_context": {}}

        # Additional fallback for number inputs during booking flow
        if context_data and context_data.get('booking_flow_step') == 'ask_guests':
            number = self.extract_number_from_text(user_text)
            if number and 1 <= number <= 8:
                return {"confirmation_message": f"Great! A table for {number} guests. What date would you like to book for? You can say 'today', 'tomorrow', or a specific date.", "new_context": {"booking_flow_step": "ask_date", "guest_count": number}}

        # Additional fallback for date inputs during booking flow
        if context_data and context_data.get('booking_flow_step') == 'ask_date':
            user_text_lower = user_text.lower().strip()
            guest_count = context_data.get('guest_count', 2)
            if any(word in user_text_lower for word in ['today', 'tomorrow', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday']):
                date = 'tomorrow' if 'tomorrow' in user_text_lower else ('today' if 'today' in user_text_lower else user_text_lower)
                return {"confirmation_message": f"Perfect! {date} for {guest_count} guests. What meal period would you prefer? You can choose from Breakfast, Lunch, or Dinner.", "new_context": {"booking_flow_step": "ask_meal_period", "guest_count": guest_count, "date": date}}
            else:
                # Default to tomorrow if unclear
                return {"confirmation_message": f"Perfect! tomorrow for {guest_count} guests. What meal period would you prefer? You can choose from Breakfast, Lunch, or Dinner.", "new_context": {"booking_flow_step": "ask_meal_period", "guest_count": guest_count, "date": "tomorrow"}}

        # Additional fallback for meal period inputs during booking flow
        if context_data and context_data.get('booking_flow_step') == 'ask_meal_period':
            user_text_lower = user_text.lower().strip()
            guest_count = context_data.get('guest_count', 2)
            date = context_data.get('date', 'tomorrow')
            if any(word in user_text_lower for word in ['breakfast', 'lunch', 'dinner']):
                meal_period = 'Breakfast' if 'breakfast' in user_text_lower else ('Lunch' if 'lunch' in user_text_lower else 'Dinner')
                return {"confirmation_message": f"Great! {meal_period} on {date} for {guest_count} guests. Let me check available time slots for you. What time would you prefer? We have slots available from 7:00 PM to 10:00 PM in 30-minute intervals.", "new_context": {"booking_flow_step": "ask_time", "guest_count": guest_count, "date": date, "meal_period": meal_period}}
            else:
                # Default to Dinner if unclear
                return {"confirmation_message": f"Great! Dinner on {date} for {guest_count} guests. Let me check available time slots for you. What time would you prefer? We have slots available from 7:00 PM to 10:00 PM in 30-minute intervals.", "new_context": {"booking_flow_step": "ask_time", "guest_count": guest_count, "date": date, "meal_period": "Dinner"}}

        # Additional fallback for time inputs during booking flow
        if context_data and context_data.get('booking_flow_step') == 'ask_time':
            user_text_lower = user_text.lower().strip()
            guest_count = context_data.get('guest_count', 2)
            date = context_data.get('date', 'tomorrow')
            meal_period = context_data.get('meal_period', 'Dinner')
            if any(word in user_text_lower for word in ['pm', 'am', ':', '7', '8', '9', '10']):
                time = user_text_lower
                return {"confirmation_message": f"Excellent! I have your reservation for {guest_count} guests on {date} at {time} for {meal_period}. Is there any special occasion or special requests for your reservation?", "new_context": {"booking_flow_step": "ask_special_occasion", "guest_count": guest_count, "date": date, "meal_period": meal_period, "time": time}}
            else:
                # Default to 8 PM if unclear
                return {"confirmation_message": f"Excellent! I have your reservation for {guest_count} guests on {date} at 8:00 PM for {meal_period}. Is there any special occasion or special requests for your reservation?", "new_context": {"booking_flow_step": "ask_special_occasion", "guest_count": guest_count, "date": date, "meal_period": meal_period, "time": "8:00 PM"}}

        # Additional fallback for special occasion inputs during booking flow
        if context_data and context_data.get('booking_flow_step') == 'ask_special_occasion':
            guest_count = context_data.get('guest_count', 2)
            date = context_data.get('date', 'tomorrow')
            meal_period = context_data.get('meal_period', 'Dinner')
            time = context_data.get('time', '8:00 PM')
            special_occasion = user_text.strip() if user_text.strip() else "None"
            return {"confirmation_message": f"Perfect! I have your reservation for {guest_count} guests on {date} at {time} for {meal_period}. Special occasion: {special_occasion}. Would you like me to confirm this booking for you?", "new_context": {"booking_flow_step": "confirm_booking", "guest_count": guest_count, "date": date, "meal_period": meal_period, "time": time, "special_occasion": special_occasion}}

        # Universal fallback for booking flow - works regardless of intent or API failure
        if context_data and context_data.get('booking_flow_step'):
            booking_step = context_data.get('booking_flow_step')
            user_text_lower = user_text.lower().strip()
            
            if booking_step == 'ask_guests':
                # Check if user provided a number
                number = self.extract_number_from_text(user_text)
                if number and 1 <= number <= 8:
                    return {"confirmation_message": f"Great! A table for {number} guests. What date would you like to book for? You can say 'today', 'tomorrow', or a specific date.", "new_context": {"booking_flow_step": "ask_date", "guest_count": number}}
                else:
                    return {"confirmation_message": "How many guests will be joining you? Please say a number between 1 and 8.", "new_context": {"booking_flow_step": "ask_guests"}}
            
            elif booking_step == 'ask_date':
                guest_count = context_data.get('guest_count', 2)
                # Check if user provided a date
                if any(word in user_text_lower for word in ['today', 'tomorrow', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday']):
                    date = 'tomorrow' if 'tomorrow' in user_text_lower else ('today' if 'today' in user_text_lower else user_text_lower)
                    return {"confirmation_message": f"Perfect! {date} for {guest_count} guests. What meal period would you prefer? You can choose from Breakfast, Lunch, or Dinner.", "new_context": {"booking_flow_step": "ask_meal_period", "guest_count": guest_count, "date": date}}
                else:
                    # Default to tomorrow if unclear
                    return {"confirmation_message": f"Perfect! tomorrow for {guest_count} guests. What meal period would you prefer? You can choose from Breakfast, Lunch, or Dinner.", "new_context": {"booking_flow_step": "ask_meal_period", "guest_count": guest_count, "date": "tomorrow"}}
            
            elif booking_step == 'ask_meal_period':
                guest_count = context_data.get('guest_count', 2)
                date = context_data.get('date', 'tomorrow')
                if any(word in user_text_lower for word in ['breakfast', 'lunch', 'dinner']):
                    meal_period = 'Breakfast' if 'breakfast' in user_text_lower else ('Lunch' if 'lunch' in user_text_lower else 'Dinner')
                    return {"confirmation_message": f"Great! {meal_period} on {date} for {guest_count} guests. Let me check available time slots for you. What time would you prefer? We have slots available from 7:00 PM to 10:00 PM in 30-minute intervals.", "new_context": {"booking_flow_step": "ask_time", "guest_count": guest_count, "date": date, "meal_period": meal_period}}
                else:
                    # Default to Dinner if unclear
                    return {"confirmation_message": f"Great! Dinner on {date} for {guest_count} guests. Let me check available time slots for you. What time would you prefer? We have slots available from 7:00 PM to 10:00 PM in 30-minute intervals.", "new_context": {"booking_flow_step": "ask_time", "guest_count": guest_count, "date": date, "meal_period": "Dinner"}}
            
            elif booking_step == 'ask_time':
                guest_count = context_data.get('guest_count', 2)
                date = context_data.get('date', 'tomorrow')
                meal_period = context_data.get('meal_period', 'Dinner')
                # Check if user provided a time
                if any(word in user_text_lower for word in ['pm', 'am', ':', '7', '8', '9', '10']):
                    time = user_text_lower
                    return {"confirmation_message": f"Excellent! I have your reservation for {guest_count} guests on {date} at {time} for {meal_period}. Is there any special occasion or special requests for your reservation?", "new_context": {"booking_flow_step": "ask_special_occasion", "guest_count": guest_count, "date": date, "meal_period": meal_period, "time": time}}
                else:
                    # Default to 8 PM if unclear
                    return {"confirmation_message": f"Excellent! I have your reservation for {guest_count} guests on {date} at 8:00 PM for {meal_period}. Is there any special occasion or special requests for your reservation?", "new_context": {"booking_flow_step": "ask_special_occasion", "guest_count": guest_count, "date": date, "meal_period": meal_period, "time": "8:00 PM"}}
            
            elif booking_step == 'ask_special_occasion':
                guest_count = context_data.get('guest_count', 2)
                date = context_data.get('date', 'tomorrow')
                meal_period = context_data.get('meal_period', 'Dinner')
                time = context_data.get('time', '8:00 PM')
                special_occasion = user_text.strip() if user_text.strip() else "None"
                return {"confirmation_message": f"Perfect! I have your reservation for {guest_count} guests on {date} at {time} for {meal_period}. Special occasion: {special_occasion}. Would you like me to confirm this booking for you?", "new_context": {"booking_flow_step": "confirm_booking", "guest_count": guest_count, "date": date, "meal_period": meal_period, "time": time, "special_occasion": special_occasion}}
            
            elif booking_step == 'confirm_booking':
                # User is confirming the booking
                if any(word in user_text_lower for word in ['yes', 'confirm', 'book', 'ok', 'okay', 'sure']):
                    return {"confirmation_message": "I'm processing your booking confirmation. Please wait a moment...", "new_context": {"booking_flow_step": "processing"}}
                else:
                    guest_count = context_data.get('guest_count', 2)
                    date = context_data.get('date', 'tomorrow')
                    time = context_data.get('time', '8:00 PM')
                    return {"confirmation_message": f"Would you like me to confirm your reservation for {guest_count} guests on {date} at {time}? Please say 'yes' to confirm.", "new_context": {"booking_flow_step": "confirm_booking", "guest_count": guest_count, "date": date, "time": time}}

        # Quick fallback responses for common intents to avoid API calls
        if intent == "want_to_order":
            if context_data.get("login_required"):
                return {"confirmation_message": "Great! I'd love to help you order food. First, please log in or sign up to start ordering.", "new_context": {}}
            elif context_data.get("is_logged_in"):
                return {"confirmation_message": "Perfect! You're all set to order. What would you like to try today?", "new_context": {}}
            else:
                return {"confirmation_message": "Great! I'd love to help you order food. What would you like to try today?", "new_context": {}}
        elif intent == "ask_takeaway":
            return {"confirmation_message": "Yes, you can definitely place an order for takeaway! Would you like me to help you start ordering?", "new_context": {}}
        elif intent == "ask_online_ordering":
            return {"confirmation_message": "Absolutely! You can order online through our app. Would you like me to help you get started?", "new_context": {}}
        elif intent == "ask_order_tracking":
            if context_data.get("login_required"):
                return {"confirmation_message": "To track your orders, you'll need to log in first. Once logged in, you can view your order history and track current orders in real-time.", "new_context": {}}
            else:
                return {"confirmation_message": "Yes, you can track your order! You can check your order history in the app or ask me 'What's my order status?' anytime!", "new_context": {}}
        elif intent == "ask_order_cancellation":
            if context_data.get("login_required"):
                return {"confirmation_message": "To cancel an order, you'll need to log in first. Once logged in, you can manage your orders from your order history.", "new_context": {}}
            else:
                return {"confirmation_message": "Yes, you can cancel your order! Go to your order history and click 'Cancel Order' if it's still being prepared. Orders already being prepared cannot be cancelled.", "new_context": {}}
        elif intent == "ask_order_status":
            if context_data.get("login_required"):
                return {"confirmation_message": "To check your order status, please log in first. Then I can help you track your orders!", "new_context": {}}
            else:
                return {"confirmation_message": "I can help you check your order status! What would you like to know about your order?", "new_context": {}}
        elif intent == "ask_delivery_info":
            return {"confirmation_message": "Yes, we offer delivery! We deliver within a 5km radius with a ₹30 delivery fee and 30-45 minute delivery time. Would you like to place an order?", "new_context": {}}
        elif intent == "ask_table_booking":
            return {"confirmation_message": "Yes, you can book a table! We offer table reservations for dine-in. Would you like me to help you book a table?", "new_context": {"booking_flow_step": "initial_offer"}}
        elif intent == "book_table":
            if context_data.get("login_required"):
                return {"confirmation_message": "I'd love to help you book a table! First, please log in to your account, then I'll guide you through the reservation process.", "new_context": {"booking_flow_step": "login_required"}}
            elif context_data.get("is_logged_in"):
                return {"confirmation_message": "Perfect! Let's book your table. How many guests will be joining you?", "new_context": {"booking_flow_step": "ask_guests"}}
            else:
                return {"confirmation_message": "I'd love to help you book a table! Please log in first, then I'll guide you through the reservation process.", "new_context": {"booking_flow_step": "login_required"}}
        elif intent == "ask_group_reservations":
            return {"confirmation_message": "Yes, we take group reservations! For parties of 6 or more, we recommend making a reservation in advance. For very large groups (10+ people), please call us directly at least 24 hours in advance. We can accommodate groups up to 20 people. Would you like to make a group reservation?", "new_context": {}}
        elif intent == "ask_walk_ins":
            return {"confirmation_message": "Yes, we welcome walk-ins! However, we recommend making a reservation to guarantee your table, especially during peak hours (7-9 PM) and weekends. Walk-ins are subject to availability. Would you like to make a reservation to secure your table?", "new_context": {}}
        elif intent == "modify_reservation":
            if context_data.get("login_required"):
                return {"confirmation_message": "To modify your reservation, please log in first. Then I can help you make changes to your booking.", "new_context": {}}
            else:
                return {"confirmation_message": "I can help you modify your reservation! Go to your reservation history in the app, find your booking, and click 'Modify'. You can change the date, time, or number of guests. For immediate changes, you can also call us directly. What would you like to change?", "new_context": {}}
        elif intent == "ask_booking_fees":
            return {"confirmation_message": "No, we don't charge any fees for table bookings! Reservations are completely free. We only ask that you arrive on time for your reservation. If you need to cancel, please let us know at least 2 hours in advance. Would you like to make a reservation?", "new_context": {}}
        elif intent == "ask_pricing_info" and any(word in user_text.lower() for word in ['discount', 'offer', 'promotion', 'deal']):
            return {"confirmation_message": "I'd be happy to help with discount information! We don't have current discount details in our system, but please ask our staff about any ongoing promotions, student discounts, or loyalty programs when you visit.", "new_context": {}}
        elif intent == "continue_booking_flow":
            # Handle "yes" responses to continue booking flow
            booking_step = context_data.get("booking_flow_step", "initial_offer")
            if booking_step == "initial_offer":
                if context_data.get("login_required"):
                    return {"confirmation_message": "Great! To book a table, please log in first. Once you're logged in, I'll guide you through the reservation process step by step.", "new_context": {"booking_flow_step": "login_required"}}
                elif context_data.get("is_logged_in"):
                    return {"confirmation_message": "Perfect! Let's start booking your table. How many guests will be joining you?", "new_context": {"booking_flow_step": "ask_guests"}}
                else:
                    return {"confirmation_message": "Great! To book a table, please log in first. Once you're logged in, I'll guide you through the reservation process step by step.", "new_context": {"booking_flow_step": "login_required"}}
            elif booking_step == "ask_guests":
                return {"confirmation_message": "How many guests will be joining you?", "new_context": {"booking_flow_step": "ask_guests"}}
            elif booking_step == "ask_date":
                return {"confirmation_message": "What date would you like to book for? You can say 'today', 'tomorrow', or a specific date.", "new_context": {"booking_flow_step": "ask_date"}}
            elif booking_step == "ask_time":
                return {"confirmation_message": "What time would you like to book for? We have slots available from 7:00 PM to 10:00 PM.", "new_context": {"booking_flow_step": "ask_time"}}
            elif booking_step == "confirm_booking":
                # User said "yes" to confirm booking - this should trigger confirm_booking intent
                return {"confirmation_message": "I'm processing your booking confirmation. Please wait a moment...", "new_context": {"booking_flow_step": "processing"}}
            else:
                return {"confirmation_message": "Let's start booking your table. How many guests will be joining you?", "new_context": {"booking_flow_step": "ask_guests"}}
        
        elif intent == "booking_guests":
            guest_count = intent_result.get("guest_count", 2)
            return {"confirmation_message": f"Great! A table for {guest_count} guests. What date would you like to book for? You can say 'today', 'tomorrow', or a specific date.", "new_context": {"booking_flow_step": "ask_date", "guest_count": guest_count}}
        
        elif intent == "booking_date":
            date = intent_result.get("date", "tomorrow")
            guest_count = context_data.get("guest_count", 2)
            return {"confirmation_message": f"Perfect! {date} for {guest_count} guests. What meal period would you prefer? You can choose from Breakfast, Lunch, or Dinner.", "new_context": {"booking_flow_step": "ask_meal_period", "guest_count": guest_count, "date": date}}
        
        elif intent == "booking_meal_period":
            meal_period = intent_result.get("meal_period", "Dinner")
            guest_count = context_data.get("guest_count", 2)
            date = context_data.get("date", "tomorrow")
            return {"confirmation_message": f"Great! {meal_period} on {date} for {guest_count} guests. Let me check available time slots for you. What time would you prefer? We have slots available from 7:00 PM to 10:00 PM in 30-minute intervals.", "new_context": {"booking_flow_step": "ask_time", "guest_count": guest_count, "date": date, "meal_period": meal_period}}
        
        elif intent == "booking_time":
            time = intent_result.get("time", "8:00 PM")
            guest_count = context_data.get("guest_count", 2)
            date = context_data.get("date", "tomorrow")
            return {"confirmation_message": f"Excellent! I have your reservation for {guest_count} guests on {date} at {time}. Would you like me to confirm this booking for you?", "new_context": {"booking_flow_step": "confirm_booking", "guest_count": guest_count, "date": date, "time": time}}
        
        elif intent == "confirm_booking":
            # Handle booking confirmation
            if context_data.get("booking_success"):
                guest_count = context_data.get("guest_count", 2)
                date = context_data.get("date", "tomorrow")
                time = context_data.get("time", "8:00 PM")
                reservation_id = context_data.get("reservation_id", "")
                return {"confirmation_message": f"🎉 Perfect! Your table reservation is confirmed! You have a table for {guest_count} guests on {date} at {time}. Your reservation ID is {reservation_id}. We look forward to seeing you!", "new_context": {"booking_flow_step": "completed"}}
            elif context_data.get("booking_error"):
                return {"confirmation_message": f"I'm sorry, there was an issue creating your reservation: {context_data.get('booking_error')}. Please try again or contact us directly.", "new_context": {"booking_flow_step": "error"}}
            elif context_data.get("login_required"):
                return {"confirmation_message": "To confirm your booking, please log in first. Once you're logged in, I'll complete your reservation.", "new_context": {"booking_flow_step": "login_required"}}
            else:
                return {"confirmation_message": "I'm processing your booking confirmation. Please wait a moment...", "new_context": {"booking_flow_step": "processing"}}

        elif intent == "post_login_continuation":
            # This will be handled by the main AI response generation
            pass

        facts_for_prompt = json.dumps(context_data, indent=2)

        prompt = f"""
        You are ByteBot, a friendly restaurant voice assistant. Create a conversational response based on verified facts.

        **User:** "{user_text}"
        **Intent:** "{intent}"
        **Facts:** {facts_for_prompt}

        **Rules:**
        1. Be concise and specific
        2. Only mention items that match the request exactly
        3. For ice creams, only list actual ice cream items
        4. Return JSON: {{"confirmation_message": "your response", "new_context": {{}}}}

        --- CRITICAL INSTRUCTIONS FOR SPECIFIC INTENTS ---

        **If intent is `place_order`:**
        - If facts contain `"login_required": true`, your ONLY message is "You need to log in or sign up to place an order."
        - If an `"item_added"` key exists, the order was successful. Your message MUST state which item was added and the new `total_cart_price`.
            - Example: "Okay, I've added one Classic Cold Coffee to your cart. Your new total is ₹450."

        **If intent is `want_to_order`:**
        - If facts contain `"login_required": true`, your message is "Great! I'd love to help you order food. First, please log in or sign up to start ordering. Once you're logged in, I'll guide you through the ordering process step by step."
        - If facts contain `"is_logged_in": true`, your message is "Perfect! You're all set to order. You can browse our menu, ask me about specific dishes, or tell me what you'd like to order."
        - If no login status is provided, your message is "Great! I'd love to help you order food. You can browse our menu, ask me about specific dishes, or tell me what you'd like to order."

        **If intent is `ask_takeaway`:**
        - Your message is "Yes, you can definitely place an order for takeaway! Here's how: 1) Log in to your account, 2) Browse our menu and add items to your cart, 3) Select 'Takeaway' as your order type, 4) Choose your pickup time, 5) Complete payment, and 6) Come to our restaurant at the scheduled time. Would you like me to help you start ordering?"

        **If intent is `ask_online_ordering`:**
        - Your message is "Absolutely! Here's how to order online: 1) Log in to your ByteEat account, 2) Browse our menu or ask me about specific dishes, 3) Add items to your cart, 4) Choose delivery or takeaway, 5) Enter your address (for delivery) or pickup time, 6) Review your order and complete payment, 7) Track your order status. Would you like me to help you get started?"

        **If intent is `ask_order_tracking`:**
        - If facts contain `"is_logged_in": true`, your message is "Yes, you can track your order! Here's how: 1) Go to your order history in the app, 2) Find your current order, 3) You'll see real-time updates: 'Order Placed' → 'Preparing' → 'Ready for Pickup/Delivery' → 'Completed'. You can also ask me 'What's my order status?' anytime!"
        - If facts contain `"login_required": true`, your message is "To track your orders, you'll need to log in first. Once logged in, you can view your order history and track current orders in real-time."

        **If intent is `ask_order_cancellation`:**
        - If facts contain `"is_logged_in": true`, your message is "Yes, you can cancel your order! Here's how: 1) Go to your order history, 2) Find the order you want to cancel, 3) Click 'Cancel Order' if it's still being prepared, 4) Orders that are already being prepared or ready cannot be cancelled. For immediate assistance, you can also call our restaurant directly."
        - If facts contain `"login_required": true`, your message is "To cancel an order, you'll need to log in first. Once logged in, you can manage your orders from your order history."

        **If intent is `ask_order_status`:**
        - If facts contain `"is_logged_in": true`, your message is "I can help you check your order status! You can: 1) Check your order history in the app, 2) Ask me 'What's my order status?' and I'll look it up, 3) Look for status updates: 'Order Placed' → 'Preparing' → 'Ready' → 'Completed'. What would you like to know about your order?"
        - If facts contain `"login_required": true`, your message is "To check your order status, please log in first. Then I can help you track your orders!"

        **If intent is `ask_delivery_info`:**
        - Your message is "Yes, we offer delivery! Here's what you need to know: 1) We deliver within a 5km radius, 2) Minimum order amount is ₹200, 3) Delivery fee is ₹30, 4) Estimated delivery time is 30-45 minutes, 5) You can track your delivery in real-time. For takeaway, there's no minimum order and no delivery fee. Would you like to place an order?"

        **If intent is `ask_table_booking`:**
        - Your message is "Yes, you can book a table! We offer table reservations for dine-in. Here's how: 1) Log in to your account, 2) Go to the 'Reserve Table' section, 3) Select the number of guests (1-10), 4) Choose your preferred date, 5) Select your preferred time slot, 6) Confirm your reservation. Would you like me to help you book a table?"

        **If intent is `book_table`:**
        - If facts contain `"login_required": true`, your message is "I'd love to help you book a table! First, please log in to your account, then I'll guide you through the reservation process step by step."
        - If facts contain `"is_logged_in": true`, your message is "Perfect! Let's book your table. I'll guide you through each step: 1) How many guests? (1-10), 2) What date would you like? (Today, Tomorrow, or specific date), 3) What time would you prefer? (Lunch: 12-3 PM, Dinner: 6-10 PM). Let's start - how many guests will be joining you?"
        - If no login status is provided, your message is "I'd love to help you book a table! Please log in first, then I'll guide you through the reservation process."

        **If intent is `ask_group_reservations`:**
        - Your message is "Yes, we take group reservations! For parties of 6 or more, we recommend making a reservation in advance. For very large groups (10+ people), please call us directly at least 24 hours in advance. We can accommodate groups up to 20 people. Would you like to make a group reservation?"

        **If intent is `ask_walk_ins`:**
        - Your message is "Yes, we welcome walk-ins! However, we recommend making a reservation to guarantee your table, especially during peak hours (7-9 PM) and weekends. Walk-ins are subject to availability. Would you like to make a reservation to secure your table?"

        **If intent is `modify_reservation`:**
        - If facts contain `"is_logged_in": true`, your message is "I can help you modify your reservation! Go to your reservation history in the app, find your booking, and click 'Modify'. You can change the date, time, or number of guests. For immediate changes, you can also call us directly. What would you like to change?"
        - If facts contain `"login_required": true`, your message is "To modify your reservation, please log in first. Then I can help you make changes to your booking."

        **If intent is `ask_booking_fees`:**
        - Your message is "No, we don't charge any fees for table bookings! Reservations are completely free. We only ask that you arrive on time for your reservation. If you need to cancel, please let us know at least 2 hours in advance. Would you like to make a reservation?"

        **If intent is `post_login_continuation`:**
        - If facts contain `"previous_intent"`, provide guidance based on the previous intent:
          - If `previous_intent` is "want_to_order", your message is "Perfect! Now that you're logged in, let's get you started with ordering. You can browse our menu, ask me about specific dishes, or tell me what you'd like to order. What would you like to try today?"
          - If `previous_intent` is "ask_takeaway", your message is "Great! Now that you're logged in, here's how to place a takeaway order: 1) Browse our menu and add items to your cart, 2) Select 'Takeaway' as your order type, 3) Choose your pickup time, 4) Complete payment, and 5) Come to our restaurant at the scheduled time. Would you like me to help you start ordering?"
          - If `previous_intent` is "ask_online_ordering", your message is "Excellent! Now that you're logged in, here's how to order online: 1) Browse our menu or ask me about specific dishes, 2) Add items to your cart, 3) Choose delivery or takeaway, 4) Enter your address (for delivery) or pickup time, 5) Review your order and complete payment, 6) Track your order status. What would you like to order?"
          - If `previous_intent` is "ask_order_tracking", your message is "Perfect! Now that you're logged in, you can track your orders! Go to your order history in the app to see real-time updates: 'Order Placed' → 'Preparing' → 'Ready for Pickup/Delivery' → 'Completed'. You can also ask me 'What's my order status?' anytime!"
          - If `previous_intent` is "ask_order_cancellation", your message is "Great! Now that you're logged in, you can manage your orders. Go to your order history to cancel orders that are still being prepared. Orders already being prepared or ready cannot be cancelled. What would you like to do?"
        - If no `previous_intent` is provided, your message is "Welcome back! You're now logged in and ready to order. How can I help you today?"

        **If intent is `ask_price` or `ask_about_dish`:**
        - If an error is present, just say "Sorry, I couldn't find that item."
        - Otherwise, state the item's name and the requested info (price or description).
            - Price Example: "The Classic Cold Coffee costs ₹150."
            - Description Example: "Paneer Tikka Skewers are tender cubes of fresh paneer marinated and grilled to perfection."

        **If intent is `list_by_category`, `list_by_ingredient`, `list_by_price_under`, or `list_by_specific_type`:**
        - The facts will contain a list named `matching_items`.
        - If `matching_items` is empty, say "Sorry, I couldn't find any items that match your request."
        - If `matching_items` is not empty, list ONLY the items that match the specific request.
        - For `list_by_specific_type` (like "ice creams"), be VERY specific and only list items that actually contain that type.
            - Example: "We have the following ice creams: Panna Cotta, Mousse (Dark Chocolate), Brownie Sundae, Cheesecake (New York Style), Ice Cream Scoop Trio."
            - Do NOT include other desserts that are not ice creams.
        - After listing, you can optionally add a follow-up question like "Would you like to know more about any of these?"

        **If no exact matches found but similar items exist:**
        - Say "I couldn't find exactly what you're looking for, but here are some similar items: [list similar items]"
        - This applies to all query types (ask_price, ask_about_dish, list_by_specific_type, etc.)
        - Use the `similar_items` list from facts to suggest alternatives

        **If intent is `clear_cart`:**
        - If `"cart_cleared": true`, simply say "Okay, I've cleared your cart."

        **If intent is `show_menu`:**
        - If facts contain `menu_by_category`, organize and present the menu by categories.
        - Example: "Here's our menu: [list items by category]. We have [total_items] items available."

        **If intent is `show_specials`:**
        - If facts contain `has_specials: false` or empty `special_items`, say "We don't have any special items listed right now, but all our regular menu items are available."
        - If facts contain `special_items`, list the special items.
        - Example: "Our specials today include: [list special items]."

        **If intent is `show_popular`:**
        - If facts contain `has_popular: false` or empty `popular_items`, say "We don't have specific popular items marked, but I'd recommend trying our signature dishes or asking our staff for recommendations."
        - If facts contain `popular_items`, list the popular/bestseller items.
        - Example: "Our most popular dishes are: [list popular items]."

        **If intent is `show_dietary_options`:**
        - If facts contain `has_dietary_options: false` or empty `dietary_items`, say "We don't have specific [dietary_type] items marked in our database, but please ask our staff about dietary accommodations when you visit."
        - If facts contain `dietary_items`, list items matching the dietary requirement.
        - Example: "Our [dietary_type] options include: [list dietary items]."

        **If intent is `show_drinks`:**
        - If facts contain `has_drinks: false` or empty `drink_items`, say "We don't have specific beverage items listed in our database, but we do serve drinks. Please check our full menu or ask our staff about our beverage options."
        - If facts contain `drink_items`, list the beverage options.
        - Example: "We offer: [list drink items]."

        **If intent is `show_healthy_options`:**
        - If facts contain `has_healthy_options: false` or empty `healthy_items`, say "We don't have specific healthy items marked in our database, but we focus on fresh ingredients. Please ask our staff about our healthiest options when you visit."
        - If facts contain `healthy_items`, list the healthy options.
        - Example: "Our healthy options include: [list healthy items]."

        **If intent is `ask_ingredients`:**
        - If facts contain `ingredients_info`, provide the ingredient information.
        - Example: "The [item_name] contains: [ingredients_info]."

        **If intent is `ask_spice_level`:**
        - If facts contain `spice_level`, provide the spice level information.
        - Example: "The [item_name] has a [spice_level] spice level."

        **If intent is `ask_customization`:**
        - If facts contain `customization_available`, confirm customization options.
        - Example: "Yes, you can customize your order. Please let me know what modifications you'd like."
        - For general customization questions: "Yes, we're happy to accommodate customizations when possible. Please let our staff know about any dietary preferences or modifications you need."

        **If intent is `ask_combos`:**
        - If facts contain `has_combos: false` or empty `combo_items`, say "We don't have specific combo deals listed in our database, but we may offer special combinations. Please ask our staff about any current deals or meal combinations."
        - If facts contain `combo_items`, list the combo/meal deal options.
        - Example: "We have these combo deals: [list combo items]."

        **If intent is `ask_pricing_info`:**
        - If facts contain `price_range`, provide pricing information.
        - Example: "Our prices range from [price_range]. The average price is around [average_price]."
        - For general pricing questions without specific data, provide helpful responses:
          - "Do you have any discounts?" → "We don't have current discount information in our database, but please ask our staff about any ongoing promotions."
          - "Is there a student discount?" → "Please check with our staff about student discounts when you visit."
          - "Do you have a loyalty program?" → "Please ask our staff about our loyalty program and membership benefits."
          - "How much is delivery?" → "Please contact us directly for current delivery charges and minimum order requirements."
          - "I am asking for discounts" → "I'd be happy to help with discount information! We don't have current discount details in our system, but please ask our staff about any ongoing promotions, student discounts, or loyalty programs when you visit."

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
                timeout=5  # 5 second timeout
            )
            
            response_content = chat_completion.choices[0].message.content

            if not response_content:

                return {"confirmation_message": "I'm sorry, I had a little trouble with that request. Please try again.", "new_context": {}}
                
            return json.loads(response_content)
        except json.JSONDecodeError as e:

            return {"confirmation_message": "I'm sorry, I had a little trouble with that request. Please try again.", "new_context": {}}
        except Exception as e:

            return {"confirmation_message": "I'm sorry, I had a little trouble with that request. Please try again.", "new_context": {}}