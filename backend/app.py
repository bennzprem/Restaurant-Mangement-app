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

# --- CONFIGURATION: FILL IN YOUR CREDENTIALS HERE ---

# Supabase Credentials
SUPABASE_URL = "https://hjvxiamgvcmwjejsmvho.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhqdnhpYW1ndmNtd2planNtdmhvIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MzYwOTU5NywiZXhwIjoyMDY5MTg1NTk3fQ.fwLqVAXZH00BSn-496hJH4LWdMGveQzELch2dgC_PM8"

# Twilio Credentials (for phone OTP)
TWILIO_ACCOUNT_SID = os.environ.get('TWILIO_ACCOUNT_SID')
TWILIO_AUTH_TOKEN = os.environ.get('TWILIO_AUTH_TOKEN')
TWILIO_VERIFY_SERVICE_SID = os.environ.get('TWILIO_VERIFY_SERVICE_SID')

# Email Credentials (for password reset)
EMAIL_USER = "your-email@gmail.com"
EMAIL_PASS = "your-gmail-app-password"

# ----------------------------------------------------



# --- INITIALIZATION ---
# app = Flask(__name__)
# CORS(app, resources={r"/*": {"origins": "*"}}, supports_credentials=True)
app = Flask(__name__)
CORS(app)
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
headers = {
    "apikey": SUPABASE_KEY, "Authorization": f"Bearer {SUPABASE_KEY}",
    "Content-Type": "application/json", "Prefer": "return=representation"
}

# Initialize Supabase client (for auth routes using the python library)
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

# Initialize Twilio client
twilio_client = TwilioClient(TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN) if TWILIO_ACCOUNT_SID else None

# Initialize Flask-Mail
app.config['MAIL_SERVER'] = 'smtp.gmail.com'
app.config['MAIL_PORT'] = 587
app.config['MAIL_USE_TLS'] = True
app.config['MAIL_USERNAME'] = EMAIL_USER
app.config['MAIL_PASSWORD'] = EMAIL_PASS
app.config['MAIL_DEFAULT_SENDER'] = EMAIL_USER
mail = Mail(app)

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

# In app.py, replace the entire signup function

@app.route('/signup', methods=['POST'])
def signup():
    try:
        data = request.get_json()
        name = data.get('name', '').strip()
        email = data.get('email', '').strip().lower()
        password = data.get('password', '')

        if not all([name, email, password]): return jsonify({'error': 'All fields are required'}), 400
        if len(password) < 6: return jsonify({'error': 'Password must be at least 6 characters'}), 400

        # Step 1: Create the user in Supabase Auth
        auth_response = supabase.auth.sign_up({
            "email": email,
            "password": password,
        })
        
        new_user = auth_response.user
        if not new_user:
            return jsonify({'error': 'Failed to create user in authentication system.'}), 500

        # Step 2: Hash the password and create the public profile
        hashed_password = hash_password(password) # <-- Hash the password
        profile_data = {
            'id': new_user.id,
            'name': name,
            'email': email,
            'password': hashed_password # <-- Save the hashed password
        }
        result = supabase.table('users').insert(profile_data).execute()

        return jsonify({'message': 'User created successfully! Please check your email to verify your account.'}), 201

    except Exception as e:
        if 'User already registered' in str(e):
            return jsonify({'error': 'A user with this email already exists.'}), 409
        print(f"Error during signup: {str(e)}")
        return jsonify({'error': 'Internal server error'}), 500
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
    if not email: return jsonify({'message': 'Email is required.'}), 400
    try:
        user_result = supabase.table('users').select('id').eq('email', email).execute()
        if not user_result.data:
            return jsonify({'message': 'If an account with that email exists, a reset link has been sent.'}), 200
        user_id = user_result.data[0]['id']
        token = secrets.token_urlsafe(32)
        expires_at = datetime.now(timezone.utc) + timedelta(hours=1)
        supabase.table('password_reset_tokens').insert({'user_id': user_id, 'token': token, 'expires_at': expires_at.isoformat()}).execute()
        
        reset_link = f"http://localhost:3000/reset-password.html?token={token}"
        msg = Message('Password Reset Request', recipients=[email])
        msg.body = f"Hello,\n\nPlease use the following link to reset your password:\n{reset_link}\n\nThis link will expire in one hour."
        mail.send(msg)
        return jsonify({'message': 'If an account with that email exists, a reset link has been sent.'}), 200
    except Exception as e:
        print(f"Error during forgot password: {str(e)}")
        return jsonify({'error': 'An internal server error occurred.'}), 500

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
        hashed_password = hash_password(new_password)
        supabase.table('users').update({'password': hashed_password}).eq('id', user_id).execute()
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

        # Handle search query
        search_term = request.args.get('search')
        if search_term:
            filters.append(f"menu_items.name=ilike.%{search_term}%")
        
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

        order_payload = {
            "total_amount": total_amount,
            "status": "Preparing",
            "user_id": user_id,
            "delivery_address": delivery_address # <-- Save the address to the database
        }
        order_response = requests.post(f"{SUPABASE_URL}/rest/v1/orders", json=order_payload, headers=headers)
        order_response.raise_for_status()
        new_order = order_response.json()[0]
        order_id = new_order['id']

        order_items_payload = [
            {
                "order_id": order_id, "menu_item_id": item['id'],
                "quantity": item['quantity'], "price_per_item": item['price']
            } for item in cart_items
        ]
        items_response = requests.post(f"{SUPABASE_URL}/rest/v1/order_items", json=order_items_payload, headers=headers)
        items_response.raise_for_status()

        return jsonify({"message": "Order placed successfully!", "order_id": order_id}), 201
    except Exception as e:
        print(f"An error occurred in place_order: {e}")
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

        return jsonify({"message": "Profile picture uploaded successfully", "url": public_url_response}), 200

    except Exception as e:
        print(f"An error occurred in upload_profile_picture: {e}", flush=True)
        return jsonify({"error": str(e)}), 500


# --- CORS PREFLIGHT HANDLERS (Very Important) ---

@app.route('/users/<string:user_id>', methods=['OPTIONS'])
def handle_user_preflight(user_id):
    return _build_cors_preflight_response()

@app.route('/users/change-password', methods=['OPTIONS'])
def handle_password_preflight():
    return _build_cors_preflight_response()

@app.route('/users/<string:user_id>/profile-picture', methods=['OPTIONS'])
def handle_pfp_preflight(user_id):
    return _build_cors_preflight_response()

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
if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)

