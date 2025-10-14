from supabase import create_client, Client
import os
import requests
from flask import Flask
from flask_mail import Mail
from twilio.rest import Client as TwilioClient
import razorpay
from services.voice_assistant import VoiceAssistant
from services.bytebot import ByteBot
from dotenv import load_dotenv

load_dotenv()

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
FRONTEND_BASE_URL = os.environ.get('FRONTEND_BASE_URL', 'http://localhost:5000')

# ----------------------------------------------------

# Initialize Supabase client
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

# Headers for Supabase REST API calls
headers = {
    "apikey": SUPABASE_KEY,
    "Authorization": f"Bearer {SUPABASE_KEY}",
    "Content-Type": "application/json",
    "Prefer": "return=minimal"
}

SUPABASE_HEADERS = {
    "apikey": SUPABASE_KEY,
    "Authorization": f"Bearer {SUPABASE_KEY}",
    "Content-Type": "application/json",
    "Prefer": "return=minimal"
}

# Initialize Twilio client
twilio_client = None
if TWILIO_ACCOUNT_SID and TWILIO_AUTH_TOKEN:
    try:
        twilio_client = TwilioClient(TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN)
    except Exception as e:
        print(f"Warning: Failed to initialize Twilio client: {e}")

# Initialize Razorpay client
RAZORPAY_KEY_ID = os.environ.get('RAZORPAY_KEY_ID', 'rzp_test_1DP5mmOlF5G5ag')
RAZORPAY_KEY_SECRET = os.environ.get('RAZORPAY_KEY_SECRET', 'thisisasecret')
razorpay_client = razorpay.Client(auth=(RAZORPAY_KEY_ID, RAZORPAY_KEY_SECRET))

# Initialize Flask app for mail
app = Flask(__name__)
app.config.update({
    'MAIL_SERVER': 'smtp.gmail.com',
    'MAIL_PORT': 587,
    'MAIL_USE_TLS': True,
    'MAIL_USERNAME': EMAIL_USER,
    'MAIL_PASSWORD': EMAIL_PASS,
    'MAIL_DEFAULT_SENDER': EMAIL_USER,
})
mail = Mail(app)

# Initialize AI services
voice_assistant_service = VoiceAssistant(supabase_url=SUPABASE_URL, supabase_headers=SUPABASE_HEADERS, supabase_client=supabase)
byte_bot_service = ByteBot(supabase_url=SUPABASE_URL, supabase_headers=SUPABASE_HEADERS)
