from flask import Flask, request, jsonify
from flask_cors import CORS
from datetime import datetime, timezone

# Import configuration
from config import (
    supabase, headers, SUPABASE_HEADERS, SUPABASE_URL, SUPABASE_KEY,
    twilio_client, TWILIO_VERIFY_SERVICE_SID, FRONTEND_BASE_URL,
    razorpay_client, voice_assistant_service, byte_bot_service, mail
)

# --- INITIALIZATION ---
app = Flask(__name__)
CORS(app)

# --- UTILITY IMPORTS ---
from utils.email_utils import _is_mail_configured, _send_password_reset_email
from utils.auth_utils import validate_email, hash_password, verify_password
from utils.menu_utils import get_menu_items, get_full_menu_with_categories, find_best_menu_match, find_similar_items
from utils.cors_utils import _build_cors_preflight_response, cors_json_response

# --- BLUEPRINT IMPORTS (moved to end to avoid circular imports) ---
from routes.recommendations import recommendation_bp
from routes.auth import auth_bp
from routes.menu import menu_bp
from routes.orders import orders_bp
from routes.profile import profile_bp
from routes.addresses import addresses_bp
from routes.reservations import reservations_bp
from routes.ai_features import ai_features_bp
from routes.subscriptions import subscriptions_bp
from routes.payments import payments_bp

# --- BLUEPRINT REGISTRATION ---
app.register_blueprint(recommendation_bp, url_prefix='/recommendation')
app.register_blueprint(auth_bp)
app.register_blueprint(menu_bp)
app.register_blueprint(orders_bp)
app.register_blueprint(profile_bp, url_prefix='/users')
app.register_blueprint(addresses_bp, url_prefix='/users')
app.register_blueprint(reservations_bp, url_prefix='/api')
app.register_blueprint(ai_features_bp)
app.register_blueprint(subscriptions_bp)
app.register_blueprint(payments_bp)

# --- MAIN ROUTES ---
@app.route('/')
def index():
    return "ByteEat AI Backend is running!"

@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({'status': 'healthy', 'timestamp': datetime.now(timezone.utc).isoformat()}), 200

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)