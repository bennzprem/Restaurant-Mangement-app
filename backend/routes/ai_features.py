from flask import Blueprint, request, jsonify
from datetime import datetime, timedelta

# Import from config
from config import (
    supabase, voice_assistant_service, byte_bot_service, SUPABASE_URL, SUPABASE_HEADERS
)
# Import utilities
from utils.menu_utils import get_full_menu_with_categories, find_best_menu_match, find_similar_items

ai_features_bp = Blueprint('ai_features', __name__)

@ai_features_bp.route('/voice-command', methods=['POST'])
def handle_voice_command():
    try:
        # Step 1: Get data from request
        data = request.get_json()
        user_text = data.get('text', '').lower()
        conversation_context = data.get('context') 
        auth_header = request.headers.get('Authorization')
        if not user_text: return jsonify({"error": "No text provided."}), 400

        # Get the full menu and list of categories for context
        from app import SUPABASE_URL, SUPABASE_HEADERS
        menu_list, category_list = get_full_menu_with_categories(SUPABASE_URL, SUPABASE_HEADERS)
        if not menu_list: return jsonify({"error": "Could not retrieve menu."}), 500

        # Step 2: Check login status
        is_logged_in = False
        user_id = None
        if auth_header and "Bearer " in auth_header:
            token = auth_header.split(" ")[1]
            try:
                user_response = supabase.auth.get_user(token)
                user_id = user_response.user.id
                is_logged_in = True
            except Exception: is_logged_in = False

        # Step 3: AI Pass 1 - Get user's intent and entities
        intent_result = voice_assistant_service.get_intent_and_entities(user_text, menu_list, category_list, conversation_context or {})
        intent = intent_result.get("intent")
        
        # Debug logging
        
        # Step 4: Python Logic - Perform actions based on intent
        context_for_ai = {"is_logged_in": is_logged_in}
        updated_cart_items = []
        action_required = ""

        # --- NEW LOGIC FOR MENU QUERIES ---
        if intent == "list_by_category":
            category_name = intent_result.get("category_name")
            matching_items = [item['name'] for item in menu_list if item.get('category_name', '').lower() == category_name.lower()]
            context_for_ai['matching_items'] = matching_items
            context_for_ai['category_name'] = category_name

        elif intent == "list_by_ingredient":
            ingredient = intent_result.get("ingredient", "").lower()
            matching_items = [item['name'] for item in menu_list if ingredient in item['name'].lower() or ingredient in item['description'].lower()]
            context_for_ai['matching_items'] = matching_items
            context_for_ai['ingredient'] = ingredient

        elif intent == "list_by_price_under":
            price_limit = intent_result.get("price_limit")
            if price_limit:
                matching_items = [item['name'] for item in menu_list if item.get('price', 9999) <= price_limit]
                context_for_ai['matching_items'] = matching_items
                context_for_ai['price_limit'] = price_limit

        elif intent == "list_by_specific_type":
            specific_type = intent_result.get("specific_type", "").lower()
            if specific_type:
                # Filter items based on specific type (ice cream, dessert, beverage, etc.)
                matching_items = []
                for item in menu_list:
                    item_name = item['name'].lower()
                    item_desc = item.get('description', '').lower()
                    item_category = item.get('category_name', '').lower()
                    
                    # Check if the specific type matches the item
                    if specific_type in item_name or specific_type in item_desc or specific_type in item_category:
                        matching_items.append(item['name'])
                
                # If no exact matches found, find similar items
                if not matching_items:
                    similar_items = find_similar_items(menu_list, specific_type, max_results=5)
                    context_for_ai['similar_items'] = similar_items
                    context_for_ai['no_exact_match'] = True
                else:
                    context_for_ai['similar_items'] = []
                    context_for_ai['no_exact_match'] = False
                
                context_for_ai['matching_items'] = matching_items
                context_for_ai['specific_type'] = specific_type

        # --- NEW LOGIC FOR ENHANCED QUERIES ---
        elif intent == "show_menu":
            # Show all menu items organized by category
            menu_by_category = {}
            for item in menu_list:
                category = item.get('category_name', 'Other')
                if category not in menu_by_category:
                    menu_by_category[category] = []
                menu_by_category[category].append(item['name'])
            context_for_ai['menu_by_category'] = menu_by_category
            context_for_ai['total_items'] = len(menu_list)

        elif intent == "show_specials":
            # Show seasonal, chef special, and new items
            special_items = []
            for item in menu_list:
                if item.get('is_seasonal') or item.get('is_chef_special') or item.get('is_new'):
                    special_items.append(item['name'])
            context_for_ai['special_items'] = special_items
            context_for_ai['has_specials'] = len(special_items) > 0

        elif intent == "show_popular":
            # Show bestsellers and popular items
            popular_items = []
            for item in menu_list:
                if item.get('is_bestseller') or item.get('is_popular'):
                    popular_items.append(item['name'])
            context_for_ai['popular_items'] = popular_items
            context_for_ai['has_popular'] = len(popular_items) > 0

        elif intent == "show_dietary_options":
            dietary_type = intent_result.get("dietary_type", "").lower()
            dietary_items = []
            for item in menu_list:
                if dietary_type == "vegan" and item.get('is_vegan'):
                    dietary_items.append(item['name'])
                elif dietary_type == "vegetarian" and item.get('is_vegetarian'):
                    dietary_items.append(item['name'])
                elif dietary_type == "gluten-free" and item.get('is_gluten_free'):
                    dietary_items.append(item['name'])
            context_for_ai['dietary_items'] = dietary_items
            context_for_ai['dietary_type'] = dietary_type
            context_for_ai['has_dietary_options'] = len(dietary_items) > 0

        elif intent == "show_drinks":
            # Show beverages and drinks
            drink_items = []
            for item in menu_list:
                category = item.get('category_name', '').lower()
                if 'beverage' in category or 'drink' in category or 'coffee' in category or 'tea' in category:
                    drink_items.append(item['name'])
            context_for_ai['drink_items'] = drink_items
            context_for_ai['has_drinks'] = len(drink_items) > 0

        elif intent == "show_healthy_options":
            # Show healthy, organic, and nutritional options
            healthy_items = []
            for item in menu_list:
                if item.get('is_organic') or item.get('is_healthy') or 'salad' in item['name'].lower():
                    healthy_items.append(item['name'])
            context_for_ai['healthy_items'] = healthy_items
            context_for_ai['has_healthy_options'] = len(healthy_items) > 0

        elif intent == "ask_ingredients":
            entity_name = intent_result.get("entity_name")
            if entity_name:
                dish_details = find_best_menu_match(menu_list, entity_name)
                if dish_details:
                    context_for_ai['ingredients_info'] = dish_details.get('description', '')
                    context_for_ai['item_name'] = dish_details['name']

        elif intent == "ask_spice_level":
            entity_name = intent_result.get("entity_name")
            if entity_name:
                dish_details = find_best_menu_match(menu_list, entity_name)
                if dish_details:
                    # Analyze description for spice indicators
                    description = dish_details.get('description', '').lower()
                    spice_level = "mild"
                    if any(word in description for word in ['spicy', 'hot', 'chili', 'pepper']):
                        spice_level = "spicy"
                    elif any(word in description for word in ['very spicy', 'extra hot', 'fiery']):
                        spice_level = "very spicy"
                    context_for_ai['spice_level'] = spice_level
                    context_for_ai['item_name'] = dish_details['name']

        elif intent == "ask_customization":
            context_for_ai['customization_available'] = True

        elif intent == "ask_combos":
            # Look for combo or meal deal items
            combo_items = []
            for item in menu_list:
                if 'combo' in item['name'].lower() or 'meal' in item['name'].lower() or 'deal' in item['name'].lower():
                    combo_items.append(item['name'])
            context_for_ai['combo_items'] = combo_items
            context_for_ai['has_combos'] = len(combo_items) > 0

        elif intent == "ask_pricing_info":
            # Provide general pricing information
            prices = [item.get('price', 0) for item in menu_list if item.get('price')]
            if prices:
                min_price = min(prices)
                max_price = max(prices)
                avg_price = sum(prices) / len(prices)
                context_for_ai['price_range'] = f"₹{min_price:.0f} - ₹{max_price:.0f}"
                context_for_ai['average_price'] = f"₹{avg_price:.0f}"

            # Special handling for discount questions
            if any(word in user_text.lower() for word in ['discount', 'offer', 'promotion', 'deal']):
                context_for_ai['discount_question'] = True

        # --- NEW LOGIC FOR ORDERING INTENT ---
        elif intent == "want_to_order":
            # User wants to order food but hasn't specified what
            if not is_logged_in:
                action_required = "NAVIGATE_TO_LOGIN"
                context_for_ai['login_required'] = True
                context_for_ai['previous_intent'] = 'want_to_order'  # Store intent for post-login continuation
            else:
                action_required = "NAVIGATE_TO_MENU"
                context_for_ai['is_logged_in'] = True

        # --- NEW LOGIC FOR ORDER PROCESS QUESTIONS ---
        elif intent == "ask_takeaway":
            # User asking about takeaway process
            if not is_logged_in:
                action_required = "NAVIGATE_TO_LOGIN"
                context_for_ai['login_required'] = True
                context_for_ai['previous_intent'] = 'ask_takeaway'  # Store intent for post-login continuation
            else:
                action_required = "NAVIGATE_TO_MENU"
                context_for_ai['is_logged_in'] = True

        elif intent == "ask_online_ordering":
            # User asking about online ordering process
            if not is_logged_in:
                action_required = "NAVIGATE_TO_LOGIN"
                context_for_ai['login_required'] = True
                context_for_ai['previous_intent'] = 'ask_online_ordering'  # Store intent for post-login continuation
            else:
                action_required = "NAVIGATE_TO_MENU"
                context_for_ai['is_logged_in'] = True

        elif intent == "ask_order_tracking":
            # User asking about order tracking
            if not is_logged_in:
                action_required = "NAVIGATE_TO_LOGIN"
                context_for_ai['login_required'] = True
                context_for_ai['previous_intent'] = 'ask_order_tracking'  # Store intent for post-login continuation
            else:
                action_required = "NAVIGATE_TO_ORDER_HISTORY"
                context_for_ai['is_logged_in'] = True

        elif intent == "ask_order_cancellation":
            # User asking about order cancellation
            if not is_logged_in:
                action_required = "NAVIGATE_TO_LOGIN"
                context_for_ai['login_required'] = True
                context_for_ai['previous_intent'] = 'ask_order_cancellation'  # Store intent for post-login continuation
            else:
                action_required = "NAVIGATE_TO_ORDER_HISTORY"
                context_for_ai['is_logged_in'] = True

        elif intent == "ask_order_status":
            # User asking about order status
            if not is_logged_in:
                action_required = "NAVIGATE_TO_LOGIN"
                context_for_ai['login_required'] = True
                context_for_ai['previous_intent'] = 'ask_order_status'  # Store intent for post-login continuation
            else:
                action_required = "NAVIGATE_TO_ORDER_HISTORY"
                context_for_ai['is_logged_in'] = True

        elif intent == "ask_delivery_info":
            # User asking about delivery information
            context_for_ai['delivery_available'] = True
            context_for_ai['delivery_radius'] = "5km"
            context_for_ai['min_order_amount'] = "₹200"
            context_for_ai['delivery_fee'] = "₹30"
            context_for_ai['delivery_time'] = "30-45 minutes"

        elif intent == "ask_table_booking":
            # User asking about table booking process
            if not is_logged_in:
                action_required = "NAVIGATE_TO_LOGIN"
                context_for_ai['login_required'] = True
                context_for_ai['previous_intent'] = 'ask_table_booking'  # Store intent for post-login continuation
            else:
                # No navigation - handle entirely through voice
                context_for_ai['is_logged_in'] = True
                context_for_ai['booking_flow_step'] = "ask_guests"
            context_for_ai['table_booking_available'] = True
            context_for_ai['max_guests'] = 10
            context_for_ai['booking_steps'] = ["Select guests", "Choose date", "Select time", "Confirm"]

        elif intent == "book_table":
            # User wants to make a table reservation
            if not is_logged_in:
                action_required = "NAVIGATE_TO_LOGIN"
                context_for_ai['login_required'] = True
                context_for_ai['previous_intent'] = 'book_table'  # Store intent for post-login continuation
            else:
                # No navigation - handle entirely through voice
                context_for_ai['is_logged_in'] = True
                context_for_ai['reservation_flow'] = True
                context_for_ai['booking_flow_step'] = "ask_guests"

        elif intent == "ask_group_reservations":
            # User asking about group reservations
            context_for_ai['group_reservations_available'] = True
            context_for_ai['max_group_size'] = 20
            context_for_ai['recommended_advance_notice'] = "24 hours"

        elif intent == "ask_walk_ins":
            # User asking about walk-ins
            context_for_ai['walk_ins_welcome'] = True
            context_for_ai['peak_hours'] = "7-9 PM"
            context_for_ai['recommendation'] = "Make reservation for guaranteed table"

        elif intent == "modify_reservation":
            # User wants to modify existing reservation
            if not is_logged_in:
                action_required = "NAVIGATE_TO_LOGIN"
                context_for_ai['login_required'] = True
                context_for_ai['previous_intent'] = 'modify_reservation'
            else:
                action_required = "NAVIGATE_TO_RESERVATION_HISTORY"
                context_for_ai['is_logged_in'] = True

        elif intent == "ask_booking_fees":
            # User asking about booking fees
            context_for_ai['booking_fee'] = "Free"
            context_for_ai['cancellation_policy'] = "2 hours advance notice"

        elif intent == "continue_booking_flow":
            # User said "yes" to continue booking flow
            booking_step = conversation_context.get('booking_flow_step', 'initial_offer') if conversation_context else 'initial_offer'
            context_for_ai['booking_flow_step'] = booking_step
            context_for_ai['is_logged_in'] = is_logged_in
            if not is_logged_in:
                action_required = "NAVIGATE_TO_LOGIN"
                context_for_ai['login_required'] = True
            
            # If user is confirming booking, trigger the booking creation
            if booking_step == "confirm_booking" and is_logged_in:
                # This will be handled by the confirm_booking intent logic
                intent = "confirm_booking"  # Override intent to trigger booking creation
                # Set the context for booking creation
                context_for_ai['booking_flow_step'] = "confirm_booking"
                context_for_ai['guest_count'] = conversation_context.get('guest_count', 2) if conversation_context else 2
                context_for_ai['date'] = conversation_context.get('date', 'tomorrow') if conversation_context else 'tomorrow'
                context_for_ai['time'] = conversation_context.get('time', '8:00 PM') if conversation_context else '8:00 PM'

        elif intent == "booking_guests":
            # User specified number of guests
            guest_count = intent_result.get("guest_count", 2)
            context_for_ai['booking_flow_step'] = "ask_date"
            context_for_ai['guest_count'] = guest_count
            context_for_ai['is_logged_in'] = is_logged_in

        elif intent == "booking_date":
            # User specified date
            date = intent_result.get("date", "tomorrow")
            guest_count = conversation_context.get('guest_count', 2) if conversation_context else 2
            context_for_ai['booking_flow_step'] = "ask_meal_period"
            context_for_ai['guest_count'] = guest_count
            context_for_ai['date'] = date
            context_for_ai['is_logged_in'] = is_logged_in

        elif intent == "booking_meal_period":
            # User specified meal period
            meal_period = intent_result.get("meal_period", "Dinner")
            guest_count = conversation_context.get('guest_count', 2) if conversation_context else 2
            date = conversation_context.get('date', "tomorrow") if conversation_context else "tomorrow"
            context_for_ai['booking_flow_step'] = "ask_time"
            context_for_ai['guest_count'] = guest_count
            context_for_ai['date'] = date
            context_for_ai['meal_period'] = meal_period
            context_for_ai['is_logged_in'] = is_logged_in

        elif intent == "booking_time":
            # User specified time - ready for special occasion
            time = intent_result.get("time", "8:00 PM")
            guest_count = conversation_context.get('guest_count', 2) if conversation_context else 2
            date = conversation_context.get('date', "tomorrow") if conversation_context else "tomorrow"
            meal_period = conversation_context.get('meal_period', "Dinner") if conversation_context else "Dinner"
            context_for_ai['booking_flow_step'] = "ask_special_occasion"
            context_for_ai['guest_count'] = guest_count
            context_for_ai['date'] = date
            context_for_ai['meal_period'] = meal_period
            context_for_ai['time'] = time
            context_for_ai['is_logged_in'] = is_logged_in

        elif intent == "booking_special_occasion":
            # User specified special occasion - ready for confirmation
            special_occasion = intent_result.get("special_occasion", "None")
            guest_count = conversation_context.get('guest_count', 2) if conversation_context else 2
            date = conversation_context.get('date', "tomorrow") if conversation_context else "tomorrow"
            meal_period = conversation_context.get('meal_period', "Dinner") if conversation_context else "Dinner"
            time = conversation_context.get('time', "8:00 PM") if conversation_context else "8:00 PM"
            context_for_ai['booking_flow_step'] = "confirm_booking"
            context_for_ai['guest_count'] = guest_count
            context_for_ai['date'] = date
            context_for_ai['meal_period'] = meal_period
            context_for_ai['time'] = time
            context_for_ai['special_occasion'] = special_occasion
            context_for_ai['is_logged_in'] = is_logged_in

        elif intent == "confirm_booking":
            # User confirmed the booking - create reservation in database
            if is_logged_in:
                time = conversation_context.get('time', "8:00 PM") if conversation_context else "8:00 PM"
                guest_count = conversation_context.get('guest_count', 2) if conversation_context else 2
                date = conversation_context.get('date', "tomorrow") if conversation_context else "tomorrow"
                
                # Convert date and time to proper format
                if date == "today":
                    booking_date = datetime.now().date()
                elif date == "tomorrow":
                    booking_date = (datetime.now() + timedelta(days=1)).date()
                else:
                    # Try to parse specific date
                    try:
                        booking_date = datetime.strptime(date, "%Y-%m-%d").date()
                    except:
                        booking_date = (datetime.now() + timedelta(days=1)).date()
                
                # Convert time to 24-hour format
                try:
                    time_obj = datetime.strptime(time.replace("PM", " PM").replace("AM", " AM"), "%I:%M %p")
                    booking_time = time_obj.strftime("%H:%M")
                except:
                    booking_time = "20:00"  # Default to 8 PM
                
                # Create reservation in database
                try:
                    special_occasion = conversation_context.get('special_occasion', 'None') if conversation_context else 'None'
                    special_requests = f"Booked via ByteBot voice assistant. Special occasion: {special_occasion}"
                    
                    reservation_data = {
                        'user_id': user_id,
                        'party_size': guest_count,
                        'reservation_date': booking_date.isoformat(),
                        'reservation_time': booking_time,
                        'status': 'confirmed',
                        'special_requests': special_requests
                    }
                    
                    result = supabase.table('reservations').insert(reservation_data).execute()
                    context_for_ai['booking_success'] = True
                    context_for_ai['reservation_id'] = result.data[0]['id'] if result.data else None
                    context_for_ai['booking_flow_step'] = "completed"
                except Exception as e:
                    context_for_ai['booking_error'] = str(e)
                    context_for_ai['booking_flow_step'] = "error"
            else:
                context_for_ai['login_required'] = True
                context_for_ai['booking_flow_step'] = "login_required"

        elif intent == "post_login_continuation":
            # User has logged in and wants to continue with their previous request
            # Get the previous intent from conversation context
            previous_intent = conversation_context.get('previous_intent') if conversation_context else None
            context_for_ai['previous_intent'] = previous_intent
            context_for_ai['is_logged_in'] = True
            # No specific action required - just provide guidance based on previous intent

        # --- EXISTING LOGIC FOR OTHER ACTIONS ---
        elif intent == "clear_cart":
            if is_logged_in:
                order_response = supabase.table('orders').select('id').eq('user_id', user_id).eq('status', 'active').maybe_single().execute()
                if order_response and order_response.data:
                    order_id = order_response.data['id']
                    supabase.table('order_items').delete().eq('order_id', order_id).execute()
                    supabase.table('orders').update({'total_amount': 0}).eq('id', order_id).execute()
                    context_for_ai['cart_cleared'] = True
                    updated_cart_items = []
            else:
                action_required = "NAVIGATE_TO_LOGIN"
                context_for_ai['login_required'] = True
        
        else: # Handles place_order, ask_price, ask_about_dish, etc.
            entity_name = intent_result.get("entity_name")
            dish_details = None
            if entity_name:
                # Fuzzy match against menu to be resilient to slight name mismatches
                dish_details = find_best_menu_match(menu_list, entity_name)
            
            if dish_details:
                context_for_ai.update(dish_details)
                
                # Only require login for placing orders, not for asking questions
                if intent == "place_order":
                    if not is_logged_in:
                        action_required = "NAVIGATE_TO_LOGIN"
                        context_for_ai['login_required'] = True
                    else:
                        order_id = None
                        order_response = supabase.table('orders').select('id').eq('user_id', user_id).eq('status', 'active').maybe_single().execute()
                        if order_response and order_response.data: order_id = order_response.data['id']
                        else:
                            new_order = supabase.table('orders').insert({'user_id': user_id, 'status': 'active', 'total_amount': 0}).execute()
                            if new_order.data: order_id = new_order.data[0]['id']
                        
                        if order_id:
                            supabase.table('order_items').upsert({ "order_id": order_id, "menu_item_id": dish_details['id'], "quantity": 1, "price_at_order": dish_details['price'] }).execute()
                            cart_response = supabase.table('order_items').select('*, menu_items(*)').eq('order_id', order_id).execute()
                            if cart_response.data:
                                total_price = sum((item.get('price_at_order', 0) or 0) * (item.get('quantity', 0) or 0) for item in cart_response.data)
                                supabase.table('orders').update({'total_amount': total_price}).eq('id', order_id).execute()
                                updated_cart_items = cart_response.data
                                context_for_ai['total_cart_price'] = round(total_price, 2)
                                context_for_ai['item_added'] = entity_name
                
                # For ask_price and ask_about_dish, no login required - just provide the information
                elif intent in ["ask_price", "ask_about_dish"]:
                    # No login required for these intents - just provide menu information
                    context_for_ai['item_found'] = True
                    context_for_ai['item_name'] = dish_details['name']
                    context_for_ai['item_price'] = dish_details['price']
                    context_for_ai['item_description'] = dish_details.get('description', '')
                
                # For any other intent that finds a dish, provide basic info without login
                else:
                    context_for_ai['item_found'] = True
                    context_for_ai['item_name'] = dish_details['name']
                    context_for_ai['item_price'] = dish_details['price']
                    context_for_ai['item_description'] = dish_details.get('description', '')
                    
            elif entity_name:
                # When no exact match found, suggest similar items
                similar_items = find_similar_items(menu_list, entity_name, max_results=5)
                if similar_items:
                    context_for_ai['similar_items'] = similar_items
                    context_for_ai['no_exact_match'] = True
                    context_for_ai['query_item'] = entity_name
                else:
                    context_for_ai['error'] = f"Could not find an item named '{entity_name}'."
        
        # Step 5: AI Pass 2 - Formulate the final response based on verified facts
        try:
            # Merge conversation context with context_for_ai
            merged_context = {**(conversation_context or {}), **context_for_ai}
            final_ai_response = voice_assistant_service.formulate_response(user_text, intent, merged_context)
        except Exception as e:
            final_ai_response = {"confirmation_message": "I'm having trouble processing that request. Please try again.", "new_context": {}}
        
        # Better error handling for AI responses
        if not final_ai_response or "error" in final_ai_response:
            # Provide fallback responses based on intent
            if intent == "want_to_order":
                if not is_logged_in:
                    final_message = "Great! I'd love to help you order food. First, please log in or sign up to start ordering."
                else:
                    final_message = "Perfect! You're all set to order. You can browse our menu, ask me about specific dishes, or tell me what you'd like to order."
            elif intent == "ask_takeaway":
                final_message = "Yes, you can definitely place an order for takeaway! Here's how: 1) Log in to your account, 2) Browse our menu and add items to your cart, 3) Select 'Takeaway' as your order type, 4) Choose your pickup time, 5) Complete payment, and 6) Come to our restaurant at the scheduled time. Would you like me to help you start ordering?"
            elif intent == "ask_online_ordering":
                final_message = "Absolutely! Here's how to order online: 1) Log in to your ByteEat account, 2) Browse our menu or ask me about specific dishes, 3) Add items to your cart, 4) Choose delivery or takeaway, 5) Enter your address (for delivery) or pickup time, 6) Review your order and complete payment, 7) Track your order status. Would you like me to help you get started?"
            elif intent == "ask_order_tracking":
                if not is_logged_in:
                    final_message = "To track your orders, you'll need to log in first. Once logged in, you can view your order history and track current orders in real-time."
                else:
                    final_message = "Yes, you can track your order! Here's how: 1) Go to your order history in the app, 2) Find your current order, 3) You'll see real-time updates: 'Order Placed' → 'Preparing' → 'Ready for Pickup/Delivery' → 'Completed'. You can also ask me 'What's my order status?' anytime!"
            elif intent == "ask_order_cancellation":
                if not is_logged_in:
                    final_message = "To cancel an order, you'll need to log in first. Once logged in, you can manage your orders from your order history."
                else:
                    final_message = "Yes, you can cancel your order! Here's how: 1) Go to your order history, 2) Find the order you want to cancel, 3) Click 'Cancel Order' if it's still being prepared, 4) Orders that are already being prepared or ready cannot be cancelled. For immediate assistance, you can also call our restaurant directly."
            elif intent == "ask_order_status":
                if not is_logged_in:
                    final_message = "To check your order status, please log in first. Then I can help you track your orders!"
                else:
                    final_message = "I can help you check your order status! You can: 1) Check your order history in the app, 2) Ask me 'What's my order status?' and I'll look it up, 3) Look for status updates: 'Order Placed' → 'Preparing' → 'Ready' → 'Completed'. What would you like to know about your order?"
            elif intent == "ask_delivery_info":
                final_message = "Yes, we offer delivery! Here's what you need to know: 1) We deliver within a 5km radius, 2) Minimum order amount is ₹200, 3) Delivery fee is ₹30, 4) Estimated delivery time is 30-45 minutes, 5) You can track your delivery in real-time. For takeaway, there's no minimum order and no delivery fee. Would you like to place an order?"
            elif intent == "ask_table_booking":
                final_message = "Yes, you can book a table! We offer table reservations for dine-in. Here's how: 1) Log in to your account, 2) Go to the 'Reserve Table' section, 3) Select the number of guests (1-10), 4) Choose your preferred date, 5) Select your preferred time slot, 6) Confirm your reservation. Would you like me to help you book a table?"
            elif intent == "book_table":
                if not is_logged_in:
                    final_message = "I'd love to help you book a table! First, please log in to your account, then I'll guide you through the reservation process step by step."
                else:
                    final_message = "Perfect! Let's book your table. I'll guide you through each step: 1) How many guests? (1-10), 2) What date would you like? (Today, Tomorrow, or specific date), 3) What time would you prefer? (Lunch: 12-3 PM, Dinner: 6-10 PM). Let's start - how many guests will be joining you?"
            elif intent == "ask_group_reservations":
                final_message = "Yes, we take group reservations! For parties of 6 or more, we recommend making a reservation in advance. For very large groups (10+ people), please call us directly at least 24 hours in advance. We can accommodate groups up to 20 people. Would you like to make a group reservation?"
            elif intent == "ask_walk_ins":
                final_message = "Yes, we welcome walk-ins! However, we recommend making a reservation to guarantee your table, especially during peak hours (7-9 PM) and weekends. Walk-ins are subject to availability. Would you like to make a reservation to secure your table?"
            elif intent == "modify_reservation":
                if not is_logged_in:
                    final_message = "To modify your reservation, please log in first. Then I can help you make changes to your booking."
                else:
                    final_message = "I can help you modify your reservation! Go to your reservation history in the app, find your booking, and click 'Modify'. You can change the date, time, or number of guests. For immediate changes, you can also call us directly. What would you like to change?"
            elif intent == "ask_booking_fees":
                final_message = "No, we don't charge any fees for table bookings! Reservations are completely free. We only ask that you arrive on time for your reservation. If you need to cancel, please let us know at least 2 hours in advance. Would you like to make a reservation?"
            elif intent == "post_login_continuation":
                previous_intent = context_for_ai.get('previous_intent')
                if previous_intent == "want_to_order":
                    final_message = "Perfect! Now that you're logged in, let's get you started with ordering. You can browse our menu, ask me about specific dishes, or tell me what you'd like to order. What would you like to try today?"
                elif previous_intent == "ask_takeaway":
                    final_message = "Great! Now that you're logged in, here's how to place a takeaway order: 1) Browse our menu and add items to your cart, 2) Select 'Takeaway' as your order type, 3) Choose your pickup time, 4) Complete payment, and 5) Come to our restaurant at the scheduled time. Would you like me to help you start ordering?"
                elif previous_intent == "ask_online_ordering":
                    final_message = "Excellent! Now that you're logged in, here's how to order online: 1) Browse our menu or ask me about specific dishes, 2) Add items to your cart, 3) Choose delivery or takeaway, 4) Enter your address (for delivery) or pickup time, 5) Review your order and complete payment, 6) Track your order status. What would you like to order?"
                elif previous_intent == "ask_order_tracking":
                    final_message = "Perfect! Now that you're logged in, you can track your orders! Go to your order history in the app to see real-time updates: 'Order Placed' → 'Preparing' → 'Ready for Pickup/Delivery' → 'Completed'. You can also ask me 'What's my order status?' anytime!"
                elif previous_intent == "ask_order_cancellation":
                    final_message = "Great! Now that you're logged in, you can manage your orders. Go to your order history to cancel orders that are still being prepared. Orders already being prepared or ready cannot be cancelled. What would you like to do?"
                else:
                    final_message = "Welcome back! You're now logged in and ready to order. How can I help you today?"
            elif intent == "ask_pricing_info" and any(word in user_text.lower() for word in ['discount', 'offer', 'promotion', 'deal']):
                final_message = "I'd be happy to help with discount information! We don't have current discount details in our system, but please ask our staff about any ongoing promotions, student discounts, or loyalty programs when you visit."
            elif intent == "ask_price":
                final_message = "I'm sorry, I couldn't find that item in our menu. Please try asking about a specific dish by name."
            elif intent == "ask_about_dish":
                final_message = "I'm sorry, I couldn't find information about that dish. Please try asking about a specific item from our menu."
            elif intent == "show_menu":
                final_message = "I'm having trouble loading our menu right now. Please try again in a moment or check our website."
            else:
                final_message = "I'm having trouble processing that request. Please try again."
        else:
            final_message = final_ai_response.get("confirmation_message", "I'm not sure how to answer that.")
        
        new_context = final_ai_response.get("new_context", {})
        
        # Debug logging for action

        return jsonify({ "message": final_message, "action": action_required, "updated_cart": updated_cart_items, "new_context": new_context }), 200

    except Exception as e:
        import traceback
        traceback.print_exc()
        return jsonify({"error": "A major server error occurred. Check the logs."}), 500

@ai_features_bp.route('/bytebot-recommendation', methods=['GET'])
def get_bytebot_recommendation():
    """Endpoint to get a real-time AI dish recommendation."""
    try:
        response_data, status_code = byte_bot_service.get_recommendation()
        # Ensure UI always loads by downgrading unexpected errors to 200 with placeholder
        if status_code != 200:
            return jsonify({
                "dish": {
                    "name": "Chef's Special",
                    "description": "A delightful seasonal pick while ByteBot warms up.",
                    "image_url": "https://via.placeholder.com/600x400.png?text=Chef%27s%20Special",
                    "tags": ["popular", "seasonal"]
                },
                "reason": "Temporary recommendation shown while AI initializes."
            }), 200
        return jsonify(response_data), 200
    except Exception as e:
        return jsonify({
            "dish": {
                "name": "Chef's Special",
                "description": "A delightful seasonal pick while ByteBot warms up.",
                "image_url": "https://via.placeholder.com/600x400.png?text=Chef%27s%20Special",
                "tags": ["popular", "seasonal"]
            },
            "reason": "Temporary recommendation shown while AI initializes.",
            "note": f"server note: {str(e)}"
        }), 200
