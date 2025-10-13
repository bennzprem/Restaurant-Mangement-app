from flask import Flask, request, jsonify
from flask_cors import CORS
from supabase import create_client, Client
import bcrypt
import os
import requests
from datetime import datetime, timedelta, timezone
import re
import secrets
from flask_mail import Mail, Message
from twilio.rest import Client as TwilioClient
from twilio.base.exceptions import TwilioRestException
from werkzeug.utils import secure_filename
import mimetypes
import razorpay
from urllib.parse import quote

from dotenv import load_dotenv  # <-- ADD THIS LINE
# Import your existing VoiceAssistant class
import json
import random
from voice_assistant import VoiceAssistant
load_dotenv()  
# Import your existing ByteBot class and the new VoiceAssistant class
from bytebot import ByteBot

# Set GROQ_API_KEY if not already set
if not os.environ.get('GROQ_API_KEY'):
    os.environ['GROQ_API_KEY'] = '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'

# --- CONFIGURATION: FILL IN YOUR CREDENTIALS HERE ---

# Supabase Credentials
SUPABASE_URL = "https://hjvxiamgvcmwjejsmvho.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhqdnhpYW1ndmNtd2planNtdmhvIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MzYwOTU5NywiZXhwIjoyMDY5MTg1NTk3fQ.fwLqVAXZH00BSn-496hJH4LWdMGveQzELch2dgC_PM8"

# Twilio Credentials (for phone OTP)
TWILIO_ACCOUNT_SID = os.environ.get('TWILIO_ACCOUNT_SID')
TWILIO_AUTH_TOKEN = os.environ.get('TWILIO_AUTH_TOKEN')
TWILIO_VERIFY_SERVICE_SID = os.environ.get('TWILIO_VERIFY_SERVICE_SID')

# Email Credentials (for password reset)
# Prefer environment variables for security. Falls back to placeholders.
EMAIL_USER = os.environ.get('EMAIL_USER', "benzprem165@gmail.com")
EMAIL_PASS = os.environ.get('EMAIL_PASS', "fisd ztcu jkkz gucz")

# Where your Flutter web is served (used in email links)
FRONTEND_BASE_URL = os.environ.get('FRONTEND_BASE_URL', 'http://localhost:60611')

# ----------------------------------------------------



# --- INITIALIZATION ---
# app = Flask(__name__)
# CORS(app, resources={r"/*": {"origins": "*"}}, supports_credentials=True)
# --- INITIALIZATION ---
app = Flask(__name__)
CORS(app)

# Register recommendation blueprint
from recommendation.routes import recommendation_bp
app.register_blueprint(recommendation_bp)

# Define Headers for all Supabase REST API calls
SUPABASE_HEADERS = {
    "apikey": SUPABASE_KEY,
    "Authorization": f"Bearer {SUPABASE_KEY}",
    "Content-Type": "application/json",
    "Prefer": "return=representation",
}

# Initialize Supabase client (for auth routes using the python library)
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

# Initialize AI Services
byte_bot_service = ByteBot(supabase_url=SUPABASE_URL, supabase_headers=SUPABASE_HEADERS)
voice_assistant_service = VoiceAssistant(supabase_url=SUPABASE_URL, supabase_headers=SUPABASE_HEADERS)
# Initialize all AI Services


# Initialize Twilio client
twilio_client = TwilioClient(TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN) if TWILIO_ACCOUNT_SID else None

"""Flask-Mail configuration
For Gmail: use an App Password. Set env vars EMAIL_USER and EMAIL_PASS.
You can adapt MAIL_SERVER/PORT for other providers.
"""
app.config['MAIL_SERVER'] = os.environ.get('MAIL_SERVER', 'smtp.gmail.com')
app.config['MAIL_PORT'] = int(os.environ.get('MAIL_PORT', '587'))
app.config['MAIL_USE_TLS'] = os.environ.get('MAIL_USE_TLS', 'true').lower() == 'true'
app.config['MAIL_USE_SSL'] = os.environ.get('MAIL_USE_SSL', 'false').lower() == 'true'
app.config['MAIL_USERNAME'] = EMAIL_USER
app.config['MAIL_PASSWORD'] = EMAIL_PASS
app.config['MAIL_DEFAULT_SENDER'] = os.environ.get('MAIL_DEFAULT_SENDER', EMAIL_USER)
app.config['MAIL_SUPPRESS_SEND'] = os.environ.get('MAIL_SUPPRESS_SEND', 'false').lower() == 'true'
mail = Mail(app)

def _is_mail_configured() -> bool:
    return bool(app.config.get('MAIL_USERNAME') and app.config.get('MAIL_PASSWORD'))

def _send_password_reset_email(recipient_email: str, token: str) -> tuple[bool, str]:
    """Sends password reset email. Returns (sent, link_used).

    sent: True if mail sent without exception
    link_used: The reset link included in the email (for logging/debug)
    """
    reset_link = f"{FRONTEND_BASE_URL.rstrip('/')}/reset-password.html?token={token}"
    if not _is_mail_configured():
        print("Flask-Mail not configured: EMAIL_USER/EMAIL_PASS missing.")
        return False, reset_link
    try:
        msg = Message('Password Reset Request', recipients=[recipient_email])
        msg.body = (
            "Hello,\n\nPlease use the following link to reset your password:\n"
            f"{reset_link}\n\nThis link will expire in one hour."
        )
        mail.send(msg)
        return True, reset_link
    except Exception as e:
        print(f"Mail send failed: {e}")
        return False, reset_link
# Initialize Razorpay client with your keys
client = razorpay.Client(auth=("rzp_test_R9IWhVRyO9Ga0k", "QKfOOhOaSDh5kVloa5XCeSL6"))
# Headers for REST API calls (for menu routes)
headers = {
    "apikey": SUPABASE_KEY,
    "Authorization": f"Bearer {SUPABASE_KEY}",
    "Content-Type": "application/json",
    "Prefer": "return=representation"
}



'''# --- HELPER FUNCTIONS ---
def hash_password(password):
    salt = bcrypt.gensalt()
    return bcrypt.hashpw(password.encode('utf-8'), salt).decode('utf-8')

def verify_password(password, hashed):
    return bcrypt.checkpw(password.encode('utf-8'), hashed.encode('utf-8'))'''

def validate_email(email):
    pattern = r'^[\w\.-]+@[\w\.-]+\.\w+$'
    return re.match(pattern, email) is not None

# --- HELPER FUNCTIONS ---
def hash_password(password):
    return bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')

def verify_password(password, hashed):
    return bcrypt.checkpw(password.encode('utf-8'), hashed.encode('utf-8'))

# --- AUTHENTICATION ROUTES ---
@app.route('/create-razorpay-order', methods=['POST'])
def create_razorpay_order():
    try:
        data = request.get_json()
        amount_in_rupees = data.get('amount')
        
        order_data = {
            "amount": int(amount_in_rupees * 100),  # Amount in the smallest currency unit (paise)
            "currency": "INR",
            "receipt": "order_rcptid_11" # A unique receipt ID
        }
        razorpay_order = client.order.create(data=order_data)
        
        # Return the order_id created by Razorpay
        return jsonify({"order_id": razorpay_order['id']})
    except Exception as e:
        print(f"Error creating Razorpay order: {e}")
        return jsonify({"error": str(e)}), 500
# In app.py, replace the entire signup function
@app.route('/signup', methods=['POST'])
def signup():
    try:
        data = request.get_json()
        name = data.get('name')
        email = data.get('email')
        password = data.get('password')

        if not all([name, email, password]):
            return jsonify({'error': 'Name, email, and password are required'}), 400

        # This securely signs up the user and provides the 'name'
        # to your database trigger via the metadata.
        auth_response = supabase.auth.sign_up({
            "email": email,
            "password": password,
            "options": {
                "data": {
                    'name': name
                }
            }
        })

        if auth_response.user is None:
            return jsonify({'error': 'User may already exist or another error occurred.'}), 409

        return jsonify({'message': 'Signup successful! Please check your email for confirmation.'}), 201

    except Exception as e:
        print(f"Error during signup: {e}")
        return jsonify({'error': str(e)}), 500

# In app.py, replace the entire login function

@app.route('/login', methods=['POST'])
def login():
    try:
        data = request.get_json()
        email = data.get('email', '').strip().lower()
        password = data.get('password', '').strip()
        if not email or not password: 
            return jsonify({'error': 'Email and password are required'}), 400

        # This signs the user in and creates a session
        auth_response = supabase.auth.sign_in_with_password({
            "email": email,
            "password": password
        })
        
        session = auth_response.session
        user = auth_response.user

        # Fetch the user's public profile from your 'users' table
        profile_response = supabase.table('users').select('*').eq('id', user.id).single().execute()
        
        # IMPORTANT: Return the session tokens along with the user data
        return jsonify({
            'message': 'Login successful', 
            'user': profile_response.data,
            'access_token': session.access_token,
            'refresh_token': session.refresh_token,
        }), 200
        
    except Exception as e:
        print(f"Error during login: {str(e)}")
        return jsonify({'error': 'Invalid credentials'}), 401
    
@app.route('/forgot-password', methods=['POST'])
def forgot_password():
    data = request.get_json()
    email = data.get('email', '').strip().lower()
    if not email:
        return jsonify({'message': 'Email is required.'}), 400
    try:
        user_result = supabase.table('users').select('id').eq('email', email).execute()
        # Respond the same regardless of user existence for privacy
        generic_msg = 'If an account with that email exists, a reset link has been sent.'
        if not user_result.data:
            return jsonify({'message': generic_msg}), 200

        user_id = user_result.data[0]['id']
        token = secrets.token_urlsafe(32)
        expires_at = datetime.now(timezone.utc) + timedelta(hours=1)
        supabase.table('password_reset_tokens').insert({
            'user_id': user_id,
            'token': token,
            'expires_at': expires_at.isoformat()
        }).execute()

        # Attempt to send email only if credentials are configured
        sent, reset_link = _send_password_reset_email(email, token)
        response_payload = {'message': generic_msg, 'email_sent': sent}
        # In dev, include the link so you can proceed even if email didn't send
        if not sent:
            response_payload['reset_link'] = reset_link
        return jsonify(response_payload), 200
    except Exception as e:
        print(f"Error during forgot password: {str(e)}")
        # Still respond generically to avoid leaking details to the client
        return jsonify({'message': 'If an account with that email exists, a reset link has been sent.'}), 200

@app.route('/reset-password', methods=['POST'])
def reset_password():
    data = request.get_json()
    token = data.get('token')
    new_password = data.get('password')
    if not token or not new_password:
        return jsonify({'error': 'Token and new password are required.'}), 400
    try:
        token_res = supabase.table('password_reset_tokens').select('*').eq('token', token).execute()
        if not token_res.data:
            return jsonify({'error': 'Invalid or expired token.'}), 400
        token_data = token_res.data[0]
        expires_at = datetime.fromisoformat(token_data['expires_at'].replace('Z', '+00:00'))
        if expires_at < datetime.now(timezone.utc):
            return jsonify({'error': 'Token has expired.'}), 400
        user_id = token_data['user_id']

        # Update the password in Supabase Auth using Admin API
        supabase.auth.admin.update_user_by_id(user_id, { 'password': new_password })
        supabase.table('password_reset_tokens').delete().eq('id', token_data['id']).execute()
        return jsonify({'message': 'Password has been reset successfully.'}), 200
    except Exception as e:
        print(f"Error during password reset: {str(e)}")
        return jsonify({'error': 'An internal server error occurred.'}), 500

@app.route('/verify/start', methods=['POST'])
def verify_start():
    if not twilio_client or not TWILIO_VERIFY_SERVICE_SID:
        return jsonify({'error': 'Twilio Verify service is not configured.'}), 503
    data = request.get_json()
    phone_number = data.get('phone_number', '').strip()
    if not phone_number: return jsonify({'error': 'Phone number is required'}), 400
    try:
        verification = twilio_client.verify.v2.services(TWILIO_VERIFY_SERVICE_SID).verifications.create(to=phone_number, channel='sms')
        return jsonify({'message': 'Verification code sent successfully.'}), 200
    except TwilioRestException as e:
        print(f"Twilio error: {e}")
        return jsonify({'error': 'Failed to send verification code. Please check the phone number.'}), 400
    except Exception as e:
        print(f"Error starting verification: {str(e)}")
        return jsonify({'error': 'An internal server error occurred.'}), 500

@app.route('/verify/check-and-signup', methods=['POST'])
def verify_check_and_signup():
    if not twilio_client or not TWILIO_VERIFY_SERVICE_SID:
        return jsonify({'error': 'Twilio Verify service is not configured.'}), 503
    data = request.get_json()
    phone_number = data.get('phone_number', '').strip()
    otp_code = data.get('otp', '').strip()
    name = data.get('name', '').strip()
    password = data.get('password', '').strip()
    if not all([phone_number, otp_code, name, password]): return jsonify({'error': 'All fields are required'}), 400
    try:
        existing_user = supabase.table('users').select('id').eq('phone_number', phone_number).execute()
        if existing_user.data: return jsonify({'error': 'A user with this phone number already exists.'}), 409
        verification_check = twilio_client.verify.v2.services(TWILIO_VERIFY_SERVICE_SID).verification_checks.create(to=phone_number, code=otp_code)
        if verification_check.status != 'approved': return jsonify({'error': 'Invalid or expired verification code.'}), 400
        hashed_password = hash_password(password)
        user_data = {'name': name, 'phone_number': phone_number, 'password': hashed_password, 'created_at': datetime.now(timezone.utc).isoformat()}
        result = supabase.table('users').insert(user_data).execute()
        if result.data: return jsonify({'message': 'Account created successfully!'}), 201
        else: return jsonify({'error': 'Failed to create user account after verification.'}), 500
    except TwilioRestException as e:
        print(f"Twilio check error: {e}")
        return jsonify({'error': 'Invalid verification code.'}), 400
    except Exception as e:
        print(f"Error during verification check: {str(e)}")
        return jsonify({'error': 'An internal server error occurred.'}), 500

@app.route('/login-with-phone', methods=['POST'])
def login_with_phone():
    try:
        data = request.get_json()
        if not data: return jsonify({'error': 'No data provided'}), 400
        phone_number = data.get('phone_number', '').strip()
        password = data.get('password', '').strip()
        if not phone_number or not password: return jsonify({'error': 'Phone number and password are required'}), 400
        user_result = supabase.table('users').select('*').eq('phone_number', phone_number).execute()
        if not user_result.data: return jsonify({'error': 'Invalid credentials'}), 401
        user = user_result.data[0]
        if not verify_password(password, user['password']): return jsonify({'error': 'Invalid credentials'}), 401
        user_response = {'id': user.get('id'), 'name': user['name'], 'phone_number': user.get('phone_number'), 'email': user.get('email'), 'created_at': user['created_at']}
        return jsonify({'message': 'Login successful', 'user': user_response}), 200
    except Exception as e:
        print(f"Error during phone login: {str(e)}")
        return jsonify({'error': 'An internal server error occurred.'}), 500


# --- MENU & ORDER ROUTES ---

# In app.py, replace the get_menu function

# In app.py, replace the entire get_menu function

@app.route('/menu', methods=['GET'])
def get_menu():
    """Fetches all menu items, with optional dynamic filters."""
    try:
        select_query = "select=id,name,menu_items!inner(*)"
        filters = []

        # THIS IS THE FIX: Explicitly check for 'veg_only' from the frontend
        if request.args.get('veg_only', 'false').lower() == 'true':
            filters.append("menu_items.is_veg=eq.true")

        # Handle the other dynamic filters
        if request.args.get('is_vegan', 'false').lower() == 'true':
            filters.append("menu_items.is_vegan=eq.true")
        if request.args.get('is_gluten_free', 'false').lower() == 'true':
            filters.append("menu_items.is_gluten_free=eq.true")
        if request.args.get('nuts_free', 'false').lower() == 'true':
             filters.append("menu_items.contains_nuts=eq.false")
        
        # Handle the new boolean filters
        if request.args.get('is_bestseller', 'false').lower() == 'true':
            filters.append("menu_items.is_bestseller=eq.true")
        if request.args.get('is_chef_spl', 'false').lower() == 'true':
            filters.append("menu_items.is_chef_spl=eq.true")
        if request.args.get('is_seasonal', 'false').lower() == 'true':
            filters.append("menu_items.is_seasonal=eq.true")

        # Handle search query
        search_term = request.args.get('search')
        if search_term:
            filters.append(f"menu_items.name=ilike.%{search_term}%")

        # NEW: meal_time filtering (e.g., breakfast, lunch, snacks, dinner)
        meal_time = request.args.get('meal_time')
        if meal_time:
            filters.append(f"menu_items.meal_time=eq.{meal_time}")

        # NEW: fitness filters
        if request.args.get('is_high_protein', 'false').lower() == 'true':
            filters.append("menu_items.is_high_protein=eq.true")
        if request.args.get('is_low_carb', 'false').lower() == 'true':
            filters.append("menu_items.is_low_carb=eq.true")
        if request.args.get('is_balanced', 'false').lower() == 'true':
            filters.append("menu_items.is_balanced=eq.true")
        if request.args.get('is_bulk_up', 'false').lower() == 'true':
            filters.append("menu_items.is_bulk_up=eq.true")

        # NEW: subscription/combo filter (column: subscription_type)
        subscription_type = request.args.get('subscription_type')
        if subscription_type:
            filters.append(f"menu_items.subscription_type=eq.{subscription_type}")
        
        api_url = f"{SUPABASE_URL}/rest/v1/categories?{select_query}"
        if filters:
            api_url += "&" + "&".join(filters)
            
        response = requests.get(api_url, headers=headers)
        response.raise_for_status()
        data_from_supabase = response.json()
        
        menu_data = [
            {"category_id": c['id'], "category_name": c['name'], "items": c['menu_items']}
            for c in data_from_supabase if c.get('menu_items')
        ]
        return jsonify(menu_data)
    except Exception as e:
        print(f"An error occurred in get_menu: {e}")
        return jsonify({"error": "An internal server error occurred."}), 500

@app.route('/menu/<int:item_id>', methods=['DELETE'])
def delete_menu_item(item_id):
    """Deletes a specific menu item by ID."""
    try:
        print(f"DELETE request received for menu item ID: {item_id}")
        
        # Delete the menu item from Supabase
        api_url = f"{SUPABASE_URL}/rest/v1/menu_items?id=eq.{item_id}"
        print(f"Calling Supabase API: {api_url}")
        
        response = requests.delete(api_url, headers=headers)
        print(f"Supabase response status: {response.status_code}")
        print(f"Supabase response body: {response.text}")
        
        if response.status_code == 204:  # Success, no content
            print("Item deleted successfully (204)")
            response = jsonify({"message": "Menu item deleted successfully"})
            response.headers.add('Access-Control-Allow-Origin', '*')
            return response, 200
        elif response.status_code == 404:
            print("Item not found (404)")
            response = jsonify({"error": "Menu item not found"})
            response.headers.add('Access-Control-Allow-Origin', '*')
            return response, 404
        else:
            print(f"Unexpected status code: {response.status_code}")
            response.raise_for_status()
            # Add return statement for successful response.raise_for_status()
            response = jsonify({"message": "Menu item deleted successfully"})
            response.headers.add('Access-Control-Allow-Origin', '*')
            return response, 200
            
    except Exception as e:
        print(f"An error occurred in delete_menu_item: {e}")
        response = jsonify({"error": "An internal server error occurred."})
        response.headers.add('Access-Control-Allow-Origin', '*')
        return response, 500


@app.route('/menu/<int:item_id>/availability', methods=['PATCH'])
def update_menu_item_availability(item_id):
    """Updates the availability of a specific menu item."""
    try:
        data = request.get_json()
        is_available = data.get('is_available')
        
        if is_available is None:
            response = jsonify({"error": "is_available field is required"})
            response.headers.add('Access-Control-Allow-Origin', '*')
            return response, 400
        
        # Update the menu item availability in Supabase
        api_url = f"{SUPABASE_URL}/rest/v1/menu_items?id=eq.{item_id}"
        update_payload = {"is_available": is_available}
        
        response = requests.patch(api_url, json=update_payload, headers=headers)
        
        if response.status_code == 204:  # Success, no content
            response = jsonify({"message": "Availability updated successfully"})
            response.headers.add('Access-Control-Allow-Origin', '*')
            return response, 200
        elif response.status_code == 404:
            response = jsonify({"error": "Menu item not found"})
            response.headers.add('Access-Control-Origin', '*')
            return response, 404
        else:
            response.raise_for_status()
            # Add return statement for successful response.raise_for_status()
            response = jsonify({"message": "Availability updated successfully"})
            response.headers.add('Access-Control-Allow-Origin', '*')
            return response, 200
            
    except Exception as e:
        print(f"An error occurred in update_menu_item_availability: {e}")
        response = jsonify({"error": "An internal server error occurred."})
        response.headers.add('Access-Control-Allow-Origin', '*')
        return response, 500

# In app.py...

@app.route('/order', methods=['POST'])
def place_order():
    try:
        data = request.get_json()
        cart_items = data.get('items')
        total_amount = data.get('total')
        user_id = data.get('user_id')
        delivery_address = data.get('address') # <-- Receive the address

        if not all([cart_items, total_amount, user_id, delivery_address]):
            return jsonify({"error": "Missing required order data including address"}), 400

        # Extract pickup code from delivery address for takeaway orders
        pickup_code = None
        if delivery_address and delivery_address.upper().startswith('TAKEAWAY'):
            import re
            code_match = re.search(r'Code:\s*(\d{4})', delivery_address)
            if code_match:
                pickup_code = code_match.group(1)

        order_payload = {
            "total_amount": total_amount,
            "status": "Preparing",
            "user_id": user_id,
            "delivery_address": delivery_address, # <-- Save the address to the database
        }
        
        # Only add pickup_code if it exists (for takeaway orders)
        if pickup_code:
            order_payload["pickup_code"] = pickup_code
            
        print(f"Order payload: {order_payload}")  # Debug log
        print(f"Supabase URL: {SUPABASE_URL}")  # Debug log
        print(f"Headers: {headers}")  # Debug log
        
        order_response = requests.post(f"{SUPABASE_URL}/rest/v1/orders", json=order_payload, headers=headers)
        
        print(f"Order response status: {order_response.status_code}")  # Debug log
        print(f"Order response text: {order_response.text}")  # Debug log
        
        if order_response.status_code != 201:
            print(f"Order creation failed: {order_response.status_code} - {order_response.text}")
            return jsonify({"error": f"Failed to create order: {order_response.text}"}), 500
            
        order_response.raise_for_status()
        new_order = order_response.json()[0]
        order_id = new_order['id']
        print(f"Order created successfully with ID: {order_id}")  # Debug log

        
        order_items_payload = [
            {
                "order_id": order_id, 
                "menu_item_id": item['menu_item_id'],  # Use 'menu_item_id' from Flutter
                "quantity": item['quantity'], 
                "price_at_order": item['price_at_order'] # Use 'price_at_order' from Flutter and for the column name
            } for item in cart_items
        ]
        
        
        print(f"Order items payload: {order_items_payload}")  # Debug log
        
        items_response = requests.post(f"{SUPABASE_URL}/rest/v1/order_items", json=order_items_payload, headers=headers)
        
        if items_response.status_code != 201:
            print(f"Order items creation failed: {items_response.status_code} - {items_response.text}")
            return jsonify({"error": f"Failed to create order items: {items_response.text}"}), 500
            
        items_response.raise_for_status()

        return jsonify({"message": "Order placed successfully!", "order_id": order_id}), 201
    except Exception as e:
        print(f"An error occurred in place_order: {e}")
        import traceback
        print(f"Full traceback: {traceback.format_exc()}")
        return jsonify({"error": str(e)}), 500
    
@app.route('/users/<string:user_id>/orders', methods=['GET'])
def get_order_history(user_id):
    """Fetches all past orders for a specific user."""
    try:
        # Query the 'orders' table and filter by the user_id
        # Order by creation date to show the most recent first
        api_url = f"{SUPABASE_URL}/rest/v1/orders?user_id=eq.{user_id}&select=*&order=created_at.desc"
        response = requests.get(api_url, headers=headers)
        response.raise_for_status()
        
        orders = response.json()
        return jsonify(orders)
    except Exception as e:
        print(f"An error occurred in get_order_history: {e}")
        return jsonify({"error": "An internal server error occurred."}), 500
    
@app.route('/order/<int:order_id>', methods=['GET'])
def get_order_status(order_id):
    """Fetches the status of a specific order using the Supabase REST API."""
    try:
        api_url = f"{SUPABASE_URL}/rest/v1/orders?select=status&id=eq.{order_id}"
        response = requests.get(api_url, headers=headers)
        response.raise_for_status()
        data = response.json()
        if data:
            return jsonify({"order_id": order_id, "status": data[0]['status']})
        else:
            return jsonify({"error": "Order not found"}), 404
    except Exception as e:
        print(f"An error occurred in get_order_status: {e}")
        return jsonify({"error": str(e)}), 500

@app.route('/orders/count', methods=['GET'])
def get_orders_count():
    try:
        api_url = f"{SUPABASE_URL}/rest/v1/orders?select=id"
        response = requests.get(api_url, headers=headers)
        response.raise_for_status()
        data = response.json()
        return jsonify({"count": len(data)}), 200
    except Exception as e:
        print(f"Error fetching orders count: {e}")
        return jsonify({"error": str(e)}), 500

# --- Kitchen and Delivery Order Feeds ---
@app.route('/api/kitchen/orders', methods=['GET'])
def api_kitchen_orders():
    """Returns orders that need preparation for delivery with user and item details."""
    try:
        # Fetch orders marked as Preparing
        orders_res = requests.get(
            f"{SUPABASE_URL}/rest/v1/orders?select=*&status=eq.Preparing&order=created_at.desc",
            headers=SUPABASE_HEADERS,
        )
        orders_res.raise_for_status()
        orders = orders_res.json() or []

        result = []
        for order in orders:
            order_id = order.get('id')

            # Get user info
            user_name = None
            if order.get('user_id'):
                u_res = requests.get(
                    f"{SUPABASE_URL}/rest/v1/users?select=name&id=eq.{order['user_id']}",
                    headers=SUPABASE_HEADERS,
                )
                if u_res.ok and u_res.json():
                    user_name = (u_res.json()[0] or {}).get('name')

            # Get items for the order joined to menu_items
            items_res = requests.get(
                f"{SUPABASE_URL}/rest/v1/order_items?select=quantity,price_at_order,menu_items(name,description,image_url)&order_id=eq.{order_id}",
                headers=SUPABASE_HEADERS,
            )
            items_res.raise_for_status()
            raw_items = items_res.json() or []
            items = []
            for it in raw_items:
                mi = it.get('menu_items') or {}
                items.append({
                    'name': mi.get('name'),
                    'description': mi.get('description'),
                    'image_url': mi.get('image_url'),
                    'quantity': it.get('quantity', 1),
                    'price': it.get('price_at_order', 0),
                })

            result.append({
                'order_id': order_id,
                'status': order.get('status'),
                'waiter_name': user_name or 'User',
                'table_info': order.get('delivery_address') or 'Delivery order',
                'total_amount': order.get('total_amount') or order.get('total') or 0,
                'items': items,
            })

        return cors_json_response(result, 200)
    except Exception as e:
        print(f"Error building kitchen orders feed: {e}")
        return cors_json_response({"error": str(e)}, 500)


@app.route('/api/delivery/orders', methods=['GET'])
def api_delivery_orders():
    """Returns orders that are ready for delivery (status = Ready)."""
    try:
        print("Fetching ready orders for delivery")
        
        # First, let's check what order statuses exist
        all_orders_res = requests.get(
            f"{SUPABASE_URL}/rest/v1/orders?select=id,status&order=created_at.desc&limit=10",
            headers=SUPABASE_HEADERS,
        )
        if all_orders_res.ok:
            all_orders = all_orders_res.json() or []
            print(f"Recent order statuses: {[order.get('status') for order in all_orders]}")
        
        orders_res = requests.get(
            f"{SUPABASE_URL}/rest/v1/orders?select=*&status=eq.Ready&order=created_at.desc",
            headers=SUPABASE_HEADERS,
        )
        print(f"Ready orders response status: {orders_res.status_code}")
        print(f"Ready orders response body: {orders_res.text}")
        
        orders_res.raise_for_status()
        orders = orders_res.json() or []
        print(f"Found {len(orders)} ready orders")
        
        # If no ready orders, let's also check preparing orders for debugging
        if len(orders) == 0:
            preparing_res = requests.get(
                f"{SUPABASE_URL}/rest/v1/orders?select=*&status=eq.Preparing&order=created_at.desc",
                headers=SUPABASE_HEADERS,
            )
            if preparing_res.ok:
                preparing_orders = preparing_res.json() or []
                print(f"Found {len(preparing_orders)} preparing orders (these need to be marked ready by kitchen)")

        result = []
        for order in orders:
            order_id = order.get('id')
            user_name = None
            if order.get('user_id'):
                u_res = requests.get(
                    f"{SUPABASE_URL}/rest/v1/users?select=name&id=eq.{order['user_id']}",
                    headers=SUPABASE_HEADERS,
                )
                if u_res.ok and u_res.json():
                    user_name = (u_res.json()[0] or {}).get('name')

            result.append({
                'order_id': order_id,
                'status': order.get('status'),
                'customer_name': user_name or 'User',
                'delivery_address': order.get('delivery_address'),
                'total_amount': order.get('total_amount') or order.get('total') or 0,
            })

        print(f"Returning {len(result)} ready orders")
        return cors_json_response(result, 200)
    except Exception as e:
        print(f"Error building delivery orders feed: {e}")
        import traceback
        traceback.print_exc()
        return cors_json_response({"error": str(e)}, 500)


@app.route('/api/delivery/orders/<int:order_id>/accept', methods=['POST'])
def api_delivery_accept(order_id: int):
    """Delivery user accepts an order → mark as Out for delivery and assign delivery_user_id."""
    try:
        data = request.get_json(silent=True) or {}
        delivery_user_id = data.get('delivery_user_id')
        
        print(f"Accepting order {order_id} for delivery_user_id: {delivery_user_id}")

        # First, check if the order exists and get its current status
        check_resp = requests.get(
            f"{SUPABASE_URL}/rest/v1/orders?id=eq.{order_id}&select=id,status",
            headers=SUPABASE_HEADERS,
        )
        print(f"Order check response: {check_resp.status_code} - {check_resp.text}")
        
        if check_resp.status_code != 200:
            return cors_json_response({"error": "Order not found"}, 404)
            
        order_data = check_resp.json()
        if not order_data:
            return cors_json_response({"error": "Order not found"}, 404)
            
        current_status = order_data[0].get('status')
        print(f"Current order status: {current_status}")

        # Update status
        update = { 'status': 'Out for delivery' }
        if delivery_user_id:
            update['delivery_user_id'] = delivery_user_id

        print(f"Updating order with data: {update}")
        
        # Try to update with delivery_user_id first
        resp = requests.patch(
            f"{SUPABASE_URL}/rest/v1/orders?id=eq.{order_id}",
            json=update,
            headers=SUPABASE_HEADERS,
        )
        
        # If the update fails due to column issues, try without delivery_user_id
        if resp.status_code == 400 and 'delivery_user_id' in update:
            print("Failed to update with delivery_user_id, trying without it")
            print(f"Error response: {resp.text}")
            update_without_user = { 'status': 'Out for delivery' }
            resp = requests.patch(
                f"{SUPABASE_URL}/rest/v1/orders?id=eq.{order_id}",
                json=update_without_user,
                headers=SUPABASE_HEADERS,
            )
            print(f"Fallback update response: {resp.status_code} - {resp.text}")
        
        print(f"Supabase response status: {resp.status_code}")
        print(f"Supabase response body: {resp.text}")
        
        resp.raise_for_status()
        return cors_json_response({"message": "Order accepted for delivery"}, 200)
    except Exception as e:
        print(f"Error accepting delivery order: {e}")
        import traceback
        traceback.print_exc()
        return cors_json_response({"error": str(e)}, 500)

@app.route('/test-delivery-column', methods=['GET'])
def test_delivery_column():
    """Test endpoint to check if delivery_user_id column exists and works."""
    try:
        # Try to select the delivery_user_id column
        resp = requests.get(
            f"{SUPABASE_URL}/rest/v1/orders?select=id,delivery_user_id&limit=1",
            headers=SUPABASE_HEADERS,
        )
        print(f"Column test response: {resp.status_code} - {resp.text}")
        return cors_json_response({"status": resp.status_code, "response": resp.text}, 200)
    except Exception as e:
        print(f"Column test error: {e}")
        return cors_json_response({"error": str(e)}, 500)

@app.route('/api/delivery/accepted-orders', methods=['GET'])
def api_delivery_accepted_orders():
    """Returns orders that are accepted by a specific delivery person (status = Out for delivery)."""
    try:
        delivery_user_id = request.args.get('delivery_user_id')
        print(f"Fetching accepted orders for delivery_user_id: {delivery_user_id}")
        
        if not delivery_user_id:
            return cors_json_response({"error": "delivery_user_id is required"}, 400)

        # For now, get all "Out for delivery" orders since the column might not be working
        # TODO: Once delivery_user_id column is properly configured, filter by it
        orders_res = requests.get(
            f"{SUPABASE_URL}/rest/v1/orders?select=*&status=eq.{quote('Out for delivery')}&order=created_at.desc",
            headers=SUPABASE_HEADERS,
        )
        print(f"Supabase response status: {orders_res.status_code}")
        print(f"Supabase response body: {orders_res.text}")
        
        orders_res.raise_for_status()
        orders = orders_res.json() or []
        print(f"Found {len(orders)} accepted orders")

        # Orders are already filtered by delivery_user_id in the query
        filtered_orders = orders

        result = []
        for order in filtered_orders:
            order_id = order.get('id')
            user_name = None
            if order.get('user_id'):
                u_res = requests.get(
                    f"{SUPABASE_URL}/rest/v1/users?select=name&id=eq.{order['user_id']}",
                    headers=SUPABASE_HEADERS,
                )
                if u_res.ok and u_res.json():
                    user_name = (u_res.json()[0] or {}).get('name')

            result.append({
                'order_id': order_id,
                'status': order.get('status'),
                'customer_name': user_name or 'User',
                'delivery_address': order.get('delivery_address'),
                'total_amount': order.get('total_amount') or order.get('total') or 0,
            })

        print(f"Returning {len(result)} accepted orders")
        return cors_json_response(result, 200)
    except Exception as e:
        print(f"Error building accepted orders feed: {e}")
        import traceback
        traceback.print_exc()
        return cors_json_response({"error": str(e)}, 500)

@app.route('/api/delivery/orders/<int:order_id>/delivered', methods=['POST'])
def api_delivery_delivered(order_id: int):
    """Delivery user marks an order as delivered → mark as Delivered."""
    try:
        data = request.get_json(silent=True) or {}
        delivery_user_id = data.get('delivery_user_id')
        
        print(f"Marking order {order_id} as delivered by delivery_user_id: {delivery_user_id}")

        # First, check if the order exists and get its current status
        check_resp = requests.get(
            f"{SUPABASE_URL}/rest/v1/orders?id=eq.{order_id}&select=id,status",
            headers=SUPABASE_HEADERS,
        )
        print(f"Order check response: {check_resp.status_code} - {check_resp.text}")
        
        if check_resp.status_code != 200:
            return cors_json_response({"error": "Order not found"}, 404)
            
        order_data = check_resp.json()
        if not order_data:
            return cors_json_response({"error": "Order not found"}, 404)
            
        current_status = order_data[0].get('status')
        print(f"Current order status: {current_status}")

        # Only allow marking as delivered if order is "Out for delivery"
        if current_status != 'Out for delivery':
            return cors_json_response({"error": f"Order must be 'Out for delivery' to mark as delivered. Current status: {current_status}"}, 400)

        # Update status to "Delivered"
        update = { 'status': 'Delivered' }

        print(f"Updating order with data: {update}")
        
        resp = requests.patch(
            f"{SUPABASE_URL}/rest/v1/orders?id=eq.{order_id}",
            json=update,
            headers=SUPABASE_HEADERS,
        )
        
        print(f"Supabase response status: {resp.status_code}")
        print(f"Supabase response body: {resp.text}")
        
        resp.raise_for_status()
        return cors_json_response({"message": "Order marked as delivered successfully"}, 200)
    except Exception as e:
        print(f"Error marking order as delivered: {e}")
        import traceback
        traceback.print_exc()
        return cors_json_response({"error": str(e)}, 500)

@app.route('/orders', methods=['GET'])
def get_all_orders():
    try:
        api_url = f"{SUPABASE_URL}/rest/v1/orders?select=*&order=created_at.desc"
        response = requests.get(api_url, headers=headers)
        response.raise_for_status()
        return jsonify(response.json()), 200
    except Exception as e:
        print(f"Error fetching all orders: {e}")
        return jsonify({"error": str(e)}), 500

@app.route('/orders/<int:order_id>/items', methods=['GET'])
def get_order_items(order_id):
    """Returns all items for a specific order with menu item details."""
    try:
        # Join order_items with menu_items to get the actual food names and details
        api_url = f"{SUPABASE_URL}/rest/v1/order_items?select=quantity,price_at_order,menu_items(name,description,image_url,price)&order_id=eq.{order_id}"
        response = requests.get(api_url, headers=headers)
        response.raise_for_status()
        
        raw_items = response.json() or []
        items = []
        
        for item in raw_items:
            menu_item = item.get('menu_items') or {}
            items.append({
                'quantity': item.get('quantity', 1),
                'price': item.get('price_at_order', 0),
                'name': menu_item.get('name', 'Unknown Item'),
                'description': menu_item.get('description', ''),
                'image_url': menu_item.get('image_url', ''),
                'original_price': menu_item.get('price', 0)
            })
        
        response_data = jsonify(items)
        response_data.headers.add('Access-Control-Allow-Origin', '*')
        return response_data, 200
    except Exception as e:
        print(f"Error fetching order items: {e}")
        response = jsonify({"error": str(e)})
        response.headers.add('Access-Control-Allow-Origin', '*')
        return response, 500

@app.route('/orders/<int:order_id>/status', methods=['PATCH'])
def update_order_status(order_id):
    """Updates the status of a specific order."""
    try:
        data = request.get_json()
        new_status = data.get('status')
        
        if not new_status:
            return jsonify({"error": "Status is required"}), 400
        
        # Update the order status
        api_url = f"{SUPABASE_URL}/rest/v1/orders?id=eq.{order_id}"
        update_data = {"status": new_status}
        
        response = requests.patch(api_url, json=update_data, headers=headers)
        response.raise_for_status()
        
        response_data = jsonify({"message": "Order status updated successfully"})
        response_data.headers.add('Access-Control-Allow-Origin', '*')
        return response_data, 200
    except Exception as e:
        print(f"Error updating order status: {e}")
        response = jsonify({"error": str(e)})
        response.headers.add('Access-Control-Allow-Origin', '*')
        return response, 500
    
@app.route('/users/<string:user_id>/favorites', methods=['GET'])
def get_favorites(user_id):
    """Gets a user's favorite items using the Supabase REST API."""
    try:
        api_url = f"{SUPABASE_URL}/rest/v1/favorites?user_id=eq.{user_id}&select=menu_items(*)"
        response = requests.get(api_url, headers=headers)
        response.raise_for_status()
        favorite_items = [item['menu_items'] for item in response.json() if item.get('menu_items')]
        return jsonify(favorite_items)
    except Exception as e:
        print(f"An error occurred in get_favorites: {e}")
        return jsonify({"error": str(e)}), 500

@app.route('/favorites', methods=['POST'])
def add_favorite():
    """Adds an item to a user's favorites."""
    try:
        data = request.get_json()
        payload = {"user_id": data['user_id'], "menu_item_id": data['menu_item_id']}
        response = requests.post(f"{SUPABASE_URL}/rest/v1/favorites", json=payload, headers=headers)
        response.raise_for_status()
        return jsonify(response.json()), 201
    except Exception as e:
        if "violates unique constraint" in str(e):
             return jsonify({"message": "Favorite already exists."}), 200
        print(f"An error occurred in add_favorite: {e}")
        return jsonify({"error": str(e)}), 500

@app.route('/favorites', methods=['DELETE'])
def remove_favorite():
    """Removes an item from a user's favorites."""
    try:
        data = request.get_json()
        user_id = data['user_id']
        menu_item_id = data['menu_item_id']
        api_url = f"{SUPABASE_URL}/rest/v1/favorites?user_id=eq.{user_id}&menu_item_id=eq.{menu_item_id}"
        response = requests.delete(api_url, headers=headers)
        response.raise_for_status()
        return jsonify({"message": "Favorite removed successfully."}), 200
    except Exception as e:
        print(f"An error occurred in remove_favorite: {e}")
        return jsonify({"error": str(e)}), 500


# --- Health Check ---
@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({'status': 'healthy', 'timestamp': datetime.now(timezone.utc).isoformat()}), 200

# --- PROFILE MANAGEMENT ROUTES ---

@app.route('/users/<string:user_id>', methods=['PUT'])
def update_user_profile(user_id):
    try:
        data = request.get_json()
        name = data.get('name')
        if not name:
            return jsonify({'error': 'Name is required'}), 400

        supabase.auth.admin.update_user_by_id(
            user_id, {'user_metadata': {'name': name}}
        )
        profile_response = supabase.table('users').update({'name': name}).eq('id', user_id).execute()
        
        response = jsonify(profile_response.data[0])
        response.headers.add('Access-Control-Allow-Origin', '*')  # ADD THIS
        return response, 200
    except Exception as e:
        print(f"An error occurred in update_user_profile: {e}")
        response = jsonify({"error": str(e)})                      # UPDATE THIS
        response.headers.add('Access-Control-Allow-Origin', '*')  # ADD THIS
        return response, 500


@app.route('/users/change-password', methods=['POST'])
def change_password():
    try:
        jwt = request.headers.get('Authorization').split(' ')[1]
        data = request.get_json()
        new_password = data.get('new_password')
        if not new_password or len(new_password) < 6:
            return jsonify({'error': 'Password must be at least 6 characters'}), 400

        user_response = supabase.auth.get_user(jwt)
        user_id = user_response.user.id

        supabase.auth.admin.update_user_by_id(
            user_id, {'password': new_password}
        )
        return jsonify({'message': 'Password updated successfully'}), 200
    except Exception as e:
        print(f"An error occurred in change_password: {e}")
        return jsonify({"error": str(e)}), 500


# In app.py, find your upload function (e.g., upload_avatar or upload_profile_picture)

@app.route('/users/<user_id>/profile-picture', methods=['POST'])
def upload_profile_picture(user_id):
    try:
        if 'avatar' not in request.files:
            return jsonify({"error": "No file part"}), 400
            
        file = request.files['avatar']

        if file.filename == '':
            return jsonify({"error": "No selected file"}), 400

        # Construct a unique path for the file in Supabase Storage
        file_path = f"{user_id}/{file.filename}"

        # --- THIS IS THE FIX ---
        # Instead of passing the 'file' object directly, we pass 'file.read()'
        # to get the raw bytes of the image.
        upload_response = supabase.storage.from_("profile-pictures").upload(
            path=file_path,
            file=file.read(), # Use .read() to get the file content
            file_options={"content-type": file.mimetype, "upsert": "true"}
        )
        
        # After successful upload, get the public URL
        public_url_response = supabase.storage.from_('profile-pictures').get_public_url(file_path)
        
        # Update the user's metadata with the new avatar URL
        supabase.auth.admin.update_user_by_id(
            user_id,
            {'user_metadata': {'avatar_url': public_url_response}}
        )
        
        # ALSO update the avatar_Url column in the users table
        supabase.table('users').update({'avatar_Url': public_url_response}).eq('id', user_id).execute()

        return jsonify({"message": "Profile picture uploaded successfully", "url": public_url_response}), 200

    except Exception as e:
        print(f"An error occurred in upload_profile_picture: {e}", flush=True)
        return jsonify({"error": str(e)}), 500


@app.route('/users/<string:user_id>/profile', methods=['PUT'])
def update_user_profile_info(user_id):
    try:
        data = request.get_json()
        
        # Extract the additional profile fields
        profile_data = {}
        if 'nickname' in data:
            profile_data['nickname'] = data['nickname']
        if 'gender' in data:
            profile_data['gender'] = data['gender']
        if 'country' in data:
            profile_data['country'] = data['country']
        if 'language' in data:
            profile_data['language'] = data['language']
        if 'timezone' in data:
            profile_data['timezone'] = data['timezone']
        
        if not profile_data:
            return jsonify({"error": "No profile data provided"}), 400
        
        # Update the user's profile information
        result = supabase.table('users').update(profile_data).eq('id', user_id).execute()
        
        if result.data:
            return jsonify({"message": "Profile updated successfully", "data": result.data[0]}), 200
        else:
            return jsonify({"error": "Failed to update profile"}), 500
            
    except Exception as e:
        print(f"An error occurred in update_user_profile_info: {e}", flush=True)
        return jsonify({"error": str(e)}), 500


# --- ADDRESS MANAGEMENT ROUTES ---

@app.route('/users/<string:user_id>/addresses', methods=['GET'])
def get_user_addresses(user_id):
    try:
        # Get all addresses for the user
        response = supabase.table('user_addresses').select('*').eq('user_id', user_id).order('created_at', desc=True).execute()
        
        result = jsonify(response.data)
        result.headers.add('Access-Control-Allow-Origin', '*')
        return result, 200
    except Exception as e:
        print(f"Error fetching addresses: {e}")
        result = jsonify({"error": str(e)})
        result.headers.add('Access-Control-Allow-Origin', '*')
        return result, 500

@app.route('/users/<string:user_id>/addresses', methods=['POST'])
def save_user_address(user_id):
    try:
        data = request.get_json()
        
        # Validate required fields
        required_fields = ['house_no', 'area', 'city', 'state', 'pincode']
        for field in required_fields:
            if not data.get(field):
                return jsonify({'error': f'{field} is required'}), 400
        
        # If this is set as default, unset other default addresses first
        if data.get('is_default', False):
            supabase.table('user_addresses').update({'is_default': False}).eq('user_id', user_id).execute()
        
        # Prepare address data
        address_data = {
            'user_id': user_id,
            'house_no': data['house_no'],
            'area': data['area'],
            'city': data['city'],
            'state': data['state'],
            'pincode': data['pincode'],
            'contact_name': data.get('contact_name'),
            'contact_phone': data.get('contact_phone'),
            'is_default': data.get('is_default', False),
            'created_at': datetime.now(timezone.utc).isoformat(),
            'updated_at': datetime.now(timezone.utc).isoformat()
        }
        
        # Insert the address
        response = supabase.table('user_addresses').insert(address_data).execute()
        
        result = jsonify(response.data[0])
        result.headers.add('Access-Control-Allow-Origin', '*')
        return result, 201
    except Exception as e:
        print(f"Error saving address: {e}")
        result = jsonify({"error": str(e)})
        result.headers.add('Access-Control-Allow-Origin', '*')
        return result, 500

@app.route('/users/<string:user_id>/addresses/<string:address_id>', methods=['PUT'])
def update_user_address(user_id, address_id):
    try:
        data = request.get_json()
        
        # If this is set as default, unset other default addresses first
        if data.get('is_default', False):
            supabase.table('user_addresses').update({'is_default': False}).eq('user_id', user_id).execute()
        
        # Prepare update data
        update_data = {
            'updated_at': datetime.now(timezone.utc).isoformat()
        }
        
        # Add fields that are provided
        if 'house_no' in data:
            update_data['house_no'] = data['house_no']
        if 'area' in data:
            update_data['area'] = data['area']
        if 'city' in data:
            update_data['city'] = data['city']
        if 'state' in data:
            update_data['state'] = data['state']
        if 'pincode' in data:
            update_data['pincode'] = data['pincode']
        if 'contact_name' in data:
            update_data['contact_name'] = data['contact_name']
        if 'contact_phone' in data:
            update_data['contact_phone'] = data['contact_phone']
        if 'is_default' in data:
            update_data['is_default'] = data['is_default']
        
        # Update the address
        response = supabase.table('user_addresses').update(update_data).eq('id', address_id).eq('user_id', user_id).execute()
        
        if not response.data:
            return jsonify({'error': 'Address not found'}), 404
        
        result = jsonify(response.data[0])
        result.headers.add('Access-Control-Allow-Origin', '*')
        return result, 200
    except Exception as e:
        print(f"Error updating address: {e}")
        result = jsonify({"error": str(e)})
        result.headers.add('Access-Control-Allow-Origin', '*')
        return result, 500

@app.route('/users/<string:user_id>/addresses/<string:address_id>', methods=['DELETE'])
def delete_user_address(user_id, address_id):
    try:
        # Delete the address
        response = supabase.table('user_addresses').delete().eq('id', address_id).eq('user_id', user_id).execute()
        
        if not response.data:
            return jsonify({'error': 'Address not found'}), 404
        
        result = jsonify({'message': 'Address deleted successfully'})
        result.headers.add('Access-Control-Allow-Origin', '*')
        return result, 200
    except Exception as e:
        print(f"Error deleting address: {e}")
        result = jsonify({"error": str(e)})
        result.headers.add('Access-Control-Allow-Origin', '*')
        return result, 500

@app.route('/users/<string:user_id>/addresses/<string:address_id>/set-default', methods=['POST'])
def set_default_address(user_id, address_id):
    try:
        # First, unset all default addresses for this user
        supabase.table('user_addresses').update({'is_default': False}).eq('user_id', user_id).execute()
        
        # Then set the specified address as default
        response = supabase.table('user_addresses').update({'is_default': True}).eq('id', address_id).eq('user_id', user_id).execute()
        
        if not response.data:
            return jsonify({'error': 'Address not found'}), 404
        
        result = jsonify({'message': 'Default address updated successfully'})
        result.headers.add('Access-Control-Allow-Origin', '*')
        return result, 200
    except Exception as e:
        print(f"Error setting default address: {e}")
        result = jsonify({"error": str(e)})
        result.headers.add('Access-Control-Allow-Origin', '*')
        return result, 500

@app.route('/users/<string:user_id>/addresses/default', methods=['GET'])
def get_default_address(user_id):
    try:
        # Get the default address for the user
        response = supabase.table('user_addresses').select('*').eq('user_id', user_id).eq('is_default', True).single().execute()
        
        if not response.data:
            return jsonify({'error': 'No default address found'}), 404
        
        result = jsonify(response.data)
        result.headers.add('Access-Control-Allow-Origin', '*')
        return result, 200
    except Exception as e:
        print(f"Error fetching default address: {e}")
        result = jsonify({"error": str(e)})
        result.headers.add('Access-Control-Allow-Origin', '*')
        return result, 500


# --- CORS PREFLIGHT HANDLERS (Very Important) ---

# --- CORS PREFLIGHT HANDLERS (Very Important) ---

@app.route('/users/<string:user_id>', methods=['OPTIONS'])
def handle_user_preflight(user_id):
    return _build_cors_preflight_response()

@app.route('/users/change-password', methods=['OPTIONS'])
def handle_password_preflight():
    return _build_cors_preflight_response()

@app.route('/users/<string:user_id>/addresses', methods=['OPTIONS'])
def handle_addresses_preflight(user_id):
    return _build_cors_preflight_response()

@app.route('/users/<string:user_id>/addresses/<string:address_id>', methods=['OPTIONS'])
def handle_address_preflight(user_id, address_id):
    return _build_cors_preflight_response()

@app.route('/users/<string:user_id>/addresses/<string:address_id>/set-default', methods=['OPTIONS'])
def handle_set_default_address_preflight(user_id, address_id):
    return _build_cors_preflight_response()

@app.route('/users/<string:user_id>/addresses/default', methods=['OPTIONS'])
def handle_default_address_preflight(user_id):
    return _build_cors_preflight_response()

@app.route('/users/<string:user_id>/profile-picture', methods=['OPTIONS'])
def handle_pfp_preflight(user_id):
    return _build_cors_preflight_response()

@app.route('/api/delivery/orders/<int:order_id>/delivered', methods=['OPTIONS'])
def handle_delivered_preflight(order_id):
    return _build_cors_preflight_response()

@app.route('/menu/<int:item_id>', methods=['OPTIONS'])
def handle_menu_item_preflight(item_id):
    return _build_cors_preflight_response()

@app.route('/menu/<int:item_id>/availability', methods=['OPTIONS'])
def handle_menu_availability_preflight(item_id):
    return _build_cors_preflight_response()

# Recommendation preflight handler - REMOVED
# This feature has been removed as requested

def _build_cors_preflight_response():
    response = jsonify({'message': 'CORS preflight successful'})
    response.headers.add('Access-Control-Allow-Origin', '*')
    response.headers.add('Access-Control-Allow-Headers', 'Content-Type,Authorization')
    response.headers.add('Access-Control-Allow-Methods', 'GET,PUT,POST,DELETE,OPTIONS')
    return response, 200

def cors_json_response(payload, status=200):
    response = jsonify(payload)
    response.headers.add('Access-Control-Allow-Origin', '*')
    return response, status


# In your app.py

@app.route('/api/available-tables', methods=['GET'])
def get_available_tables():
    """
    Finds available tables based on date, time, and party size using a more robust
    2-step filtering method in Python to avoid database query builder errors.
    """
    try:
        # --- Step 1: Get input from the request ---
        date_str = request.args.get('date')
        time_str = request.args.get('time')
        party_size = request.args.get('party_size')

        if not all([date_str, time_str, party_size]):
            return jsonify({"error": "Missing required query parameters"}), 400

        party_size = int(party_size)
        reservation_datetime = datetime.strptime(f"{date_str} {time_str}", "%Y-%m-%d %I:%M %p")
        
        window_start = reservation_datetime - timedelta(hours=1, minutes=59)
        window_end = reservation_datetime + timedelta(hours=1, minutes=59)

        # --- Step 2: Get IDs of all tables that are ALREADY BOOKED ---
        booked_tables_response = supabase.table('reservations').select('table_id').eq('status', 'confirmed').gte('reservation_time', window_start.isoformat()).lte('reservation_time', window_end.isoformat()).execute()
        
        # Use a Set for efficient lookups
        booked_table_ids = set()
        if booked_tables_response.data:
            booked_table_ids = {booking['table_id'] for booking in booked_tables_response.data}

        # --- Step 3: Get ALL tables that are big enough for the party ---
        potential_tables_response = supabase.table('tables').select('*').gte('capacity', party_size).execute()

        if not potential_tables_response.data:
            return jsonify([]), 200 # No tables are big enough, return empty list

        potential_tables = potential_tables_response.data
        
        # --- Step 4: Manually filter out the booked tables in Python ---
        # This is the new logic that replaces the problematic query.
        available_tables = [
            table for table in potential_tables if table['id'] not in booked_table_ids
        ]

        return jsonify(available_tables), 200

    except Exception as e:
        print(f"An error occurred in get_available_tables: {e}", flush=True)
        return jsonify({"error": str(e)}), 500

# In your app.py, find the create_reservation function and update it

@app.route('/api/reservations', methods=['POST'])
def create_reservation():
    """
    Creates a new reservation for the logged-in user.
    """
    try:
        # ... (get user_id logic remains the same) ...
        auth_header = request.headers.get('Authorization')
        if not auth_header:
            return jsonify({"error": "Authorization header is required"}), 401
        token = auth_header.split(" ")[1]
        user_response = supabase.auth.get_user(token)
        user_id = user_response.user.id

        data = request.get_json()
        table_id = data.get('table_id')
        reservation_time = data.get('reservation_time')
        party_size = data.get('party_size')
        special_occasion = data.get('special_occasion')
        
        # --- NEW FIELD ---
        add_ons_requested = data.get('add_ons_requested', False) # Default to false

        if not all([table_id, reservation_time, party_size]):
            return jsonify({"error": "Missing required fields"}), 400
            
        new_reservation = {
            "user_id": user_id,
            "table_id": table_id,
            "reservation_time": reservation_time,
            "party_size": party_size,
            "special_occasion": special_occasion,
            "add_ons_requested": add_ons_requested, # <-- Add new field here
            "status": "confirmed"
        }
        
        insert_response = supabase.table('reservations').insert(new_reservation).execute()

        return jsonify(insert_response.data[0]), 201

    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route('/api/reservations', methods=['GET'])
def get_user_reservations():
    """
    Gets the booking history for the logged-in user.
    """
    try:
        # 1. Get user from auth token
        auth_header = request.headers.get('Authorization')
        if not auth_header:
            return jsonify({"error": "Authorization header is required"}), 401
        token = auth_header.split(" ")[1]
        user_response = supabase.auth.get_user(token)
        user_id = user_response.user.id

        # 2. Fetch all reservations for that user, joining with table details
        # The 'tables(*)' part tells Supabase to fetch all columns from the related table.
        reservations_response = supabase.table('reservations').select('*, tables(*)').eq('user_id', user_id).order('reservation_time', desc=True).execute()

        return jsonify(reservations_response.data), 200
            
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route('/api/reservations/<uuid:reservation_id>/cancel', methods=['PUT'])
def cancel_reservation(reservation_id):
    """
    Cancels a specific reservation for the logged-in user.
    """
    try:
        # 1. Get user from auth token
        auth_header = request.headers.get('Authorization')
        if not auth_header:
            return jsonify({"error": "Authorization header is required"}), 401
        token = auth_header.split(" ")[1]
        user_response = supabase.auth.get_user(token)
        user_id = user_response.user.id

        # 2. Update the reservation status to 'cancelled'
        # We match on both reservation_id and user_id for security.
        update_response = supabase.table('reservations').update({'status': 'cancelled'}).eq('id', str(reservation_id)).eq('user_id', user_id).execute()

        # Check if a row was actually updated
        if not update_response.data:
            return jsonify({"error": "Reservation not found or you do not have permission to cancel it"}), 404

        return jsonify({"message": "Reservation cancelled successfully"}), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500


# In your app.py file

# In your app.py

@app.route('/menu', methods=['POST'])
def create_menu_item():
    """Creates a new menu item."""
    try:
        data = request.get_json()
        
        # Validate required fields
        required_fields = ['name', 'description', 'price', 'image_url', 'category_id']
        for field in required_fields:
            if field not in data:
                return jsonify({"error": f"Missing required field: {field}"}), 400
        
        # Validate category_id exists
        category_id = data['category_id']
        category_response = requests.get(
            f"{SUPABASE_URL}/rest/v1/categories?id=eq.{category_id}",
            headers=headers
        )
        if not category_response.json():
            return jsonify({"error": "Invalid category_id"}), 400
        
        # Create the menu item
        menu_item_data = {
            'name': data['name'],
            'description': data['description'],
            'price': data['price'],
            'image_url': data['image_url'],
            'category_id': category_id,
            'is_available': data.get('is_available', True),
            'is_vegan': data.get('is_vegan', False),
            'is_gluten_free': data.get('is_gluten_free', False),
            'contains_nuts': data.get('contains_nuts', False),
        }
        
        api_url = f"{SUPABASE_URL}/rest/v1/menu_items"
        response = requests.post(api_url, json=menu_item_data, headers=headers)
        
        if response.status_code == 201:
            created_item = response.json()[0]
            response = jsonify({
                "message": "Menu item created successfully",
                "item": created_item
            })
            response.headers.add('Access-Control-Allow-Origin', '*')
            return response, 201
        else:
            return jsonify({"error": "Failed to create menu item"}), 500
            
    except Exception as e:
        print(f"Error creating menu item: {e}")
        response = jsonify({"error": str(e)})
        response.headers.add('Access-Control-Allow-Origin', '*')
        return response, 500

@app.route('/menu/<int:item_id>', methods=['PUT'])
def update_menu_item(item_id):
    """Updates an existing menu item."""
    try:
        data = request.get_json()
        
        # Validate required fields
        required_fields = ['name', 'description', 'price', 'image_url', 'category_id']
        for field in required_fields:
            if field not in data:
                return jsonify({"error": f"Missing required field: {field}"}), 400
        
        # Validate category_id exists
        category_id = data['category_id']
        category_response = requests.get(
            f"{SUPABASE_URL}/rest/v1/categories?id=eq.{category_id}",
            headers=headers
        )
        if not category_response.json():
            return jsonify({"error": "Invalid category_id"}), 400
        
        # Update the menu item
        menu_item_data = {
            'name': data['name'],
            'description': data['description'],
            'price': data['price'],
            'image_url': data['image_url'],
            'category_id': category_id,
            'is_available': data.get('is_available', True),
            'is_vegan': data.get('is_vegan', False),
            'is_gluten_free': data.get('is_gluten_free', False),
            'contains_nuts': data.get('contains_nuts', False),
        }
        
        api_url = f"{SUPABASE_URL}/rest/v1/menu_items?id=eq.{item_id}"
        response = requests.patch(api_url, json=menu_item_data, headers=headers)
        
        if response.status_code == 204:
            response = jsonify({"message": "Menu item updated successfully"})
            response.headers.add('Access-Control-Allow-Origin', '*')
            return response, 200
        elif response.status_code == 404:
            response = jsonify({"error": "Menu item not found"})
            response.headers.add('Access-Control-Allow-Origin', '*')
            return response, 404
        else:
            return jsonify({"error": "Failed to update menu item"}), 500
            
    except Exception as e:
        print(f"Error updating menu item: {e}")
        response = jsonify({"error": str(e)})
        response.headers.add('Access-Control-Allow-Origin', '*')
        return response, 500

@app.route('/categories', methods=['GET'])
def get_categories():
    """Returns all available menu categories."""
    try:
        # Get categories from Supabase instead of hardcoded list
        api_url = f"{SUPABASE_URL}/rest/v1/categories"
        response = requests.get(api_url, headers=headers)
        response.raise_for_status()
        categories = response.json()
        
        response = jsonify(categories)
        response.headers.add('Access-Control-Allow-Origin', '*')
        return response, 200
    except Exception as e:
        print(f"Error fetching categories: {e}")
        response = jsonify({"error": str(e)})
        response.headers.add('Access-Control-Allow-Origin', '*')
        return response, 500

@app.route('/categories', methods=['POST'])
def create_category():
    """Creates a new menu category."""
    try:
        data = request.get_json()
        
        # Validate required fields
        if 'name' not in data or not data['name'].strip():
            return jsonify({"error": "Category name is required"}), 400
        
        # Check if category name already exists
        existing_response = requests.get(
            f"{SUPABASE_URL}/rest/v1/categories?name=eq.{data['name'].strip()}",
            headers=headers
        )
        existing_response.raise_for_status()
        
        if existing_response.json():
            return jsonify({"error": "Category with this name already exists"}), 409
        
        # Create the category
        category_data = {
            'name': data['name'].strip(),
        }
        
        api_url = f"{SUPABASE_URL}/rest/v1/categories"
        post_headers = headers.copy()
        post_headers['Prefer'] = 'return=representation'
        response = requests.post(api_url, json=category_data, headers=post_headers)
        
        if response.status_code == 201:
            created_category = response.json()[0]
            response = jsonify({
                "message": "Category created successfully",
                "category": created_category
            })
            response.headers.add('Access-Control-Allow-Origin', '*')
            return response, 201
        else:
            print(f"Supabase response: {response.status_code} - {response.text}")
            return jsonify({"error": "Failed to create category"}), 500
        
    except Exception as e:
        print(f"Error creating category: {e}")
        import traceback
        traceback.print_exc()
        response = jsonify({"error": f"Failed to create category: {str(e)}"})
        response.headers.add('Access-Control-Allow-Origin', '*')
        return response, 500

@app.route('/categories/<int:category_id>', methods=['DELETE'])
def delete_category(category_id):
    """Deletes a category and all its menu items."""
    try:
        print(f"DELETE request received for category ID: {category_id}")
        
        # First, delete all menu items in this category
        menu_items_response = requests.get(
            f"{SUPABASE_URL}/rest/v1/menu_items?category_id=eq.{category_id}",
            headers=headers
        )
        menu_items_response.raise_for_status()
        menu_items = menu_items_response.json()
        
        if menu_items:
            print(f"Found {len(menu_items)} menu items to delete")
            # Delete all menu items in this category
            for item in menu_items:
                item_id = item['id']
                print(f"Deleting menu item ID: {item_id}")
                delete_item_response = requests.delete(
                    f"{SUPABASE_URL}/rest/v1/menu_items?id=eq.{item_id}",
                    headers=headers
                )
                if delete_item_response.status_code not in [204, 200]:
                    print(f"Warning: Failed to delete menu item {item_id}: {delete_item_response.status_code}")
        
        # Now delete the category
        print(f"Deleting category ID: {category_id}")
        api_url = f"{SUPABASE_URL}/rest/v1/categories?id=eq.{category_id}"
        response = requests.delete(api_url, headers=headers)
        
        print(f"Category delete response: {response.status_code}")
        print(f"Category delete response body: {response.text}")
        
        # Supabase can return 200 or 204 for successful deletes
        if response.status_code in [200, 204]:
            response = jsonify({"message": "Category and all its items deleted successfully"})
            response.headers.add('Access-Control-Allow-Origin', '*')
            return response, 200
        else:
            print(f"Unexpected response from Supabase: {response.status_code} - {response.text}")
            return jsonify({"error": "Failed to delete category"}), 500
            
    except Exception as e:
        print(f"Error deleting category: {e}")
        import traceback
        traceback.print_exc()
        response = jsonify({"error": f"Failed to delete category: {str(e)}"})
        response.headers.add('Access-Control-Allow-Origin', '*')
        return response, 500

@app.route('/api/table-sessions/start', methods=['POST'])
def start_table_session():
    """
    Validates a table code and returns the active session for that table.
    """
    try:
        data = request.get_json()
        session_code = data.get('session_code')

        print(f"Received request to start session for code: {session_code}", flush=True)

        if not session_code:
            return jsonify({"error": "session_code is required"}), 400

        session_response = supabase.table('table_sessions').select('*, tables(*)') \
            .eq('session_code', session_code.upper()) \
            .eq('status', 'active') \
            .maybe_single().execute()

        # --- THIS IS THE FINAL, ULTRA-DEFENSIVE FIX ---
        # We now check if the response object ITSELF is None OR if its data is empty.
        # This will prevent the 'NoneType' has no attribute 'data' crash.
        if session_response is None or not session_response.data:
            print(f"Code '{session_code.upper()}' not found or the database query failed.", flush=True)
            return jsonify({"error": "Invalid table code. Please check the code and try again."}), 404

        # If we get here, the code was found
        session = session_response.data
        print(f"Successfully found session for table number: {session['tables']['table_number']}", flush=True)
        
        return jsonify({
            "sessionId": session['id'],
            "tableId": session['table_id'],
            "tableNumber": session['tables']['table_number']
        }), 200

    except Exception as e:
        print(f"An error CRASHED the function: {e}", flush=True)
        return jsonify({"error": str(e)}), 500
@app.route('/api/orders/add-items', methods=['POST'])
def add_items_to_order():
    """
    Adds items to a table's current active order.
    If no active order exists for the session, it creates one.
    """
    try:
        data = request.get_json()
        session_id = data.get('session_id')
        items = data.get('items') # Expecting a list of {'menu_item_id': id, 'quantity': qty}

        if not all([session_id, items]):
            return jsonify({"error": "session_id and items are required"}), 400

        # Find an existing 'active' order for this table session
        order_response = supabase.table('orders').select('id').eq('table_session_id', session_id).eq('status', 'active').maybe_single().execute()
        
        order_id = None
        if order_response.data:
            # An active order already exists
            order_id = order_response.data['id']
        else:
            # No active order found, so create a new one
            auth_header = request.headers.get('Authorization')
            token = auth_header.split(" ")[1]
            user = supabase.auth.get_user(token).user
            
            new_order_response = supabase.table('orders').insert({
                'table_session_id': session_id,
                'user_id': user.id,
                'status': 'active'
                # Other fields like total_price can be updated later
            }).execute()
            order_id = new_order_response.data[0]['id']

        # Prepare items to be inserted into order_items
        items_to_insert = []
        for item in items:
            # In a real app, you'd fetch the current price from menu_items table
            # For now, we'll assume price is passed from client or fetched here
            items_to_insert.append({
                'order_id': order_id,
                'menu_item_id': item['menu_item_id'],
                'quantity': item['quantity'],
                'price_at_order': item['price'] 
            })

        supabase.table('order_items').insert(items_to_insert).execute()

        return jsonify({"message": "Items added to order successfully", "order_id": order_id}), 200

    except Exception as e:
        print(f"Error in add_items_to_order: {e}", flush=True)
        return jsonify({"error": str(e)}), 500

def get_menu_items():
    """Fetches all menu items from Supabase."""
    try:
        response = requests.get(
            f"{SUPABASE_URL}/rest/v1/menu_items?select=*",
            headers=SUPABASE_HEADERS
        )
        response.raise_for_status()
        return response.json()
    except Exception as e:
        print(f"Error fetching menu: {e}")
        return []

def get_full_menu_with_categories():
    """Fetches all categories and their associated menu items."""
    try:
        api_url = f"{SUPABASE_URL}/rest/v1/categories?select=name,menu_items(*)"
        response = requests.get(api_url, headers=SUPABASE_HEADERS)
        response.raise_for_status()
        
        structured_menu = response.json()
        
        # Flatten the structure for easier processing by the AI
        all_items = []
        category_names = []
        for category in structured_menu:
            category_name = category.get('name')
            if category_name:
                category_names.append(category_name)
            for item in category.get('menu_items', []):
                item['category_name'] = category_name  # Add category name to each item
                all_items.append(item)
                
        return all_items, category_names
    except Exception as e:
        print(f"Error fetching full menu: {e}")
        return [], []


# --- Helper: fuzzy match a user-provided dish name to the closest menu item ---
def _normalize_text(value: str) -> str:
    try:
        return re.sub(r"[^a-z0-9 ]+", "", (value or "").lower()).strip()
    except Exception:
        return (value or "").lower().strip()

def find_best_menu_match(menu_list: list, query_name: str):
    """Return the best matching menu item dict for the given query_name.
    Prefers exact (case-insensitive) match; otherwise tries startswith, contains,
    and simple token overlap scoring. Returns None if nothing reasonable found.
    """
    if not query_name:
        return None
    q_norm = _normalize_text(query_name)
    if not q_norm:
        return None

    # 1) Exact (case-insensitive)
    for item in menu_list:
        if _normalize_text(item.get('name', '')) == q_norm:
            return item

    # 2) Startswith
    starts = [it for it in menu_list if _normalize_text(it.get('name', '')).startswith(q_norm)]
    if starts:
        return starts[0]

    # 3) Contains
    contains = [it for it in menu_list if q_norm in _normalize_text(it.get('name', ''))]
    if contains:
        return contains[0]

    # 4) Token overlap (simple score)
    q_tokens = set(q_norm.split())
    best = None
    best_score = 0
    for it in menu_list:
        name_tokens = set(_normalize_text(it.get('name', '')).split())
        score = len(q_tokens.intersection(name_tokens))
        if score > best_score:
            best_score = score
            best = it
    # Require at least 1 token overlap to avoid bad guesses
    return best if best_score > 0 else None

def find_similar_items(menu_list: list, query: str, max_results: int = 5):
    """Find similar items when no exact matches are found"""
    if not query:
        return []
    
    normalized_query = _normalize_text(query)
    if not normalized_query:
        return []
    
    similar_items = []
    
    for item in menu_list:
        item_name = _normalize_text(item.get('name', ''))
        item_desc = _normalize_text(item.get('description', ''))
        item_category = _normalize_text(item.get('category_name', ''))
        
        score = 0
        
        # Check for partial matches in name
        if normalized_query in item_name:
            score += 10
        
        # Check for partial matches in description
        if normalized_query in item_desc:
            score += 5
            
        # Check for partial matches in category
        if normalized_query in item_category:
            score += 3
            
        # Check for word overlap
        query_words = set(normalized_query.split())
        item_words = set(item_name.split())
        overlap = len(query_words.intersection(item_words))
        score += overlap * 2
        
        if score > 0:
            similar_items.append((item['name'], score))
    
    # Sort by score and return top matches
    similar_items.sort(key=lambda x: x[1], reverse=True)
    return [item[0] for item in similar_items[:max_results]]


@app.route('/')
def index():
    return "ByteEat AI Backend is running!"



@app.route('/voice-command', methods=['POST'])
def handle_voice_command():
    try:
        # Step 1: Get data from request
        data = request.get_json()
        user_text = data.get('text', '').lower()
        conversation_context = data.get('context') 
        auth_header = request.headers.get('Authorization')
        if not user_text: return jsonify({"error": "No text provided."}), 400

        # Get the full menu and list of categories for context
        menu_list, category_list = get_full_menu_with_categories()
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
        intent_result = voice_assistant_service.get_intent_and_entities(user_text, menu_list, category_list, conversation_context)
        intent = intent_result.get("intent")
        
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
        final_ai_response = voice_assistant_service.formulate_response(user_text, intent, context_for_ai)
        
        # Better error handling for AI responses
        if "error" in final_ai_response:
            print(f"AI response error: {final_ai_response['error']}")
            final_message = "I'm having trouble processing that request. Please try again."
        else:
            final_message = final_ai_response.get("confirmation_message", "I'm not sure how to answer that.")
        
        new_context = final_ai_response.get("new_context", {})

        return jsonify({ "message": final_message, "action": action_required, "updated_cart": updated_cart_items, "new_context": new_context }), 200

    except Exception as e:
        import traceback
        print("--- A FATAL ERROR OCCURRED ---")
        traceback.print_exc()
        return jsonify({"error": "A major server error occurred. Check the logs."}), 500

@app.route('/bytebot-recommendation', methods=['GET'])
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

# --- CREATE TABLE (OPTIONAL SESSION CODE) ---

@app.route('/api/tables', methods=['POST'])
def create_table():
    """
    Creates a new table. Optionally accepts a session_code to create an active
    table session for that table immediately (useful when pre-printing QR codes).

    Body:
    {
      "table_number": 12,               // required
      "capacity": 4,                    // optional (defaults 4)
      "location_preference": "Patio",  // optional
      "session_code": "TBL012"         // optional, creates active session
    }
    """
    try:
        data = request.get_json() or {}
        table_number = data.get('table_number')
        capacity = data.get('capacity', 4)
        location_preference = data.get('location_preference')
        session_code = data.get('session_code')

        if not table_number:
            return jsonify({"error": "table_number is required"}), 400

        # Create table row
        table_payload = {
            'table_number': table_number,
            'capacity': capacity,
        }
        if location_preference is not None:
            table_payload['location_preference'] = location_preference

        table_resp = supabase.table('tables').insert(table_payload).execute()
        if not table_resp.data:
            return jsonify({"error": "Failed to create table"}), 500

        table_row = table_resp.data[0]
        result = { 'table': table_row }

        # Optionally create an active session with provided code
        if session_code:
            # If a session with the same code is already active, return conflict
            existing = supabase.table('table_sessions').select('id') \
                .eq('session_code', session_code.upper()) \
                .eq('status', 'active').execute()
            if existing.data:
                return jsonify({
                    'error': 'An active session already exists with this session_code'
                }), 409

            create_session = supabase.table('table_sessions').insert({
                'table_id': table_row['id'],
                'session_code': session_code.upper(),
                'status': 'active',
                'started_at': datetime.now(timezone.utc).isoformat(),
            }).execute()

            if not create_session.data:
                return jsonify({"error": "Table created but failed to create session"}), 500

            result['session'] = create_session.data[0]

        return jsonify(result), 201

    except Exception as e:
        print(f"Error creating table: {e}", flush=True)
        return jsonify({"error": str(e)}), 500

@app.route('/api/tables', methods=['GET'])
def list_tables():
    """Returns all tables with active occupancy/session info."""
    try:
        tables_resp = supabase.table('tables').select('*').order('table_number').execute()
        tables = tables_resp.data or []

        # Fetch active sessions to determine occupancy and codes
        sessions_resp = supabase.table('table_sessions') \
            .select('table_id, session_code, status') \
            .eq('status', 'active').execute()
        active_by_table = {}
        if sessions_resp.data:
            for s in sessions_resp.data:
                active_by_table[s['table_id']] = {
                    'session_code': s.get('session_code'),
                    'status': s.get('status', 'active')
                }

        result = []
        for t in tables:
            info = {
                'id': t.get('id'),
                'table_number': t.get('table_number'),
                'capacity': t.get('capacity'),
                'location_preference': t.get('location_preference'),
                'occupied': t.get('id') in active_by_table,
                'active_session_code': active_by_table.get(t.get('id'), {}).get('session_code')
            }
            result.append(info)

        return jsonify(result), 200
    except Exception as e:
        print(f"Error listing tables: {e}", flush=True)
        return jsonify({"error": str(e)}), 500

@app.route('/api/tables/<table_id>/toggle', methods=['POST'])
def toggle_table_occupancy(table_id):
    """
    Toggles a table between occupied and available.
    - If an active session exists for this table, close it (set available).
    - Otherwise create a new active session (set occupied). Optional body:
      { "session_code": "TBL007" }
    Returns: { occupied: bool, active_session_code: str|null }
    """
    try:
        data = request.get_json(silent=True) or {}
        desired_code = (data.get('session_code') or '').strip().upper() or None

        # Check table exists and get number for default code
        # table_id may arrive as string UUID or integer; compare via eq works for both
        table_row = supabase.table('tables').select('*').eq('id', table_id).maybe_single().execute()
        if not table_row or not table_row.data:
            return jsonify({"error": "Table not found"}), 404

        # Check for active session for this table
        active = supabase.table('table_sessions').select('*') \
            .eq('table_id', table_id).eq('status', 'active').maybe_single().execute()

        # If active exists, close it
        if active and active.data:
            supabase.table('table_sessions').update({
                'status': 'closed',
                'ended_at': datetime.now(timezone.utc).isoformat(),
            }).eq('id', active.data['id']).execute()
            return jsonify({
                'occupied': False,
                'active_session_code': None,
            }), 200

        # Else create a new active session
        session_code = desired_code
        if not session_code:
            # Default code: TBL{table_number:03d}
            tbl_num = table_row.data.get('table_number')
            try:
                session_code = f"TBL{int(tbl_num):03d}"
            except Exception:
                session_code = f"TBL{table_id}"

        # Ensure no conflicting active session with same code
        conflict = supabase.table('table_sessions').select('id').eq('session_code', session_code).eq('status', 'active').execute()
        if conflict and conflict.data:
            return jsonify({"error": "An active session already uses this code"}), 409

        created = supabase.table('table_sessions').insert({
            'table_id': table_id,
            'session_code': session_code,
            'status': 'active',
            'started_at': datetime.now(timezone.utc).isoformat(),
        }).execute()

        if not created or not created.data:
            return jsonify({"error": "Failed to create session"}), 500

        return jsonify({
            'occupied': True,
            'active_session_code': session_code,
        }), 200
        
    except Exception as e:
        print(f"Error toggling table occupancy: {e}", flush=True)
        return jsonify({"error": str(e)}), 500

# app.py

# REPLACE your existing _get_structured_filters_from_groq and get_ai_recommendation functions
# with this single, updated block of code.
# app.py

# Groq structured filters function - REMOVED
# This feature has been removed as requested
# AI recommendation endpoint - REMOVED
# This feature has been removed as requested

# app.py

# ADD THIS ENTIRE NEW ENDPOINT
# History recommendation endpoint - REMOVED
# This feature has been removed as requested

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)

