from flask import Blueprint, request, jsonify, Response
from supabase import create_client, Client
import bcrypt
import os
import secrets
from datetime import datetime, timedelta, timezone
import re
from twilio.rest import Client as TwilioClient
from twilio.base.exceptions import TwilioRestException
from flask_mail import Mail, Message

# Import from config
from config import (
    supabase, twilio_client, TWILIO_VERIFY_SERVICE_SID, FRONTEND_BASE_URL, mail
)
# Import utilities
from utils.auth_utils import hash_password, verify_password, validate_email
from utils.email_utils import _is_mail_configured, _send_password_reset_email

auth_bp = Blueprint('auth', __name__)

@auth_bp.route('/signup', methods=['POST'])
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
        return jsonify({'error': str(e)}), 500

@auth_bp.route('/login', methods=['POST'])
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
        return jsonify({'error': 'Invalid credentials'}), 401

@auth_bp.route('/forgot-password', methods=['POST'])
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
        sent, reset_link = _send_password_reset_email(email, token, mail, FRONTEND_BASE_URL)
        response_payload = {'message': generic_msg, 'email_sent': sent}
        # In dev, include the link so you can proceed even if email didn't send
        if not sent:
            response_payload['reset_link'] = reset_link
        return jsonify(response_payload), 200
    except Exception as e:
        # Still respond generically to avoid leaking details to the client
        return jsonify({'message': 'If an account with that email exists, a reset link has been sent.'}), 200

@auth_bp.route('/reset-password.html')
def reset_password_page():
    """Serve the password reset HTML page"""
    try:
        with open('../frontend/web/reset-password.html', 'r') as f:
            return Response(f.read(), mimetype='text/html')
    except FileNotFoundError:
        return "Password reset page not found", 404

@auth_bp.route('/reset-password', methods=['POST'])
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
        return jsonify({'error': 'An internal server error occurred.'}), 500

@auth_bp.route('/verify/start', methods=['POST'])
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
        return jsonify({'error': 'Failed to send verification code. Please check the phone number.'}), 400
    except Exception as e:
        return jsonify({'error': 'An internal server error occurred.'}), 500

@auth_bp.route('/verify/check-and-signup', methods=['POST'])
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
        return jsonify({'error': 'Invalid verification code.'}), 400
    except Exception as e:
        return jsonify({'error': 'An internal server error occurred.'}), 500

@auth_bp.route('/login-with-phone', methods=['POST'])
def login_with_phone():
    try:
        data = request.get_json()
        if not data: return jsonify({'error': 'No data provided'}), 400
        phone_number = data.get('phone_number', '').strip()
        password = data.get('password', '').strip()
        if not phone_number or not password: return jsonify({'error': 'Phone number and password are required'}), 400
        
        # First, find the user by phone number
        user_result = supabase.table('users').select('*').eq('phone_number', phone_number).execute()
        if not user_result.data: return jsonify({'error': 'Invalid credentials'}), 401
        user = user_result.data[0]
        
        # Verify password
        if not verify_password(password, user['password']): return jsonify({'error': 'Invalid credentials'}), 401
        
        # If user has an email, try to sign in with Supabase auth
        if user.get('email'):
            try:
                auth_response = supabase.auth.sign_in_with_password({
                    "email": user['email'],
                    "password": password
                })
                
                session = auth_response.session
                if session:
                    return jsonify({
                        'message': 'Login successful', 
                        'user': user,
                        'access_token': session.access_token,
                        'refresh_token': session.refresh_token,
                    }), 200
            except:
                # If Supabase auth fails, continue with manual auth
                pass
        
        # Fallback: return user data without Supabase session
        # This means the user won't have full Supabase auth features
        user_response = {'id': user.get('id'), 'name': user['name'], 'phone_number': user.get('phone_number'), 'email': user.get('email'), 'created_at': user['created_at']}
        return jsonify({
            'message': 'Login successful', 
            'user': user_response,
            'access_token': 'manual_phone_login',  # Indicates manual phone login
            'refresh_token': 'manual_phone_login'
        }), 200
    except Exception as e:
        return jsonify({'error': 'An internal server error occurred.'}), 500
