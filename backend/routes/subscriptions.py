from flask import Blueprint, request, jsonify
import requests
from datetime import datetime, timedelta

# Import from config
from config import SUPABASE_URL, SUPABASE_KEY

subscriptions_bp = Blueprint('subscriptions', __name__)

@subscriptions_bp.route('/subscription-plans', methods=['GET'])
def get_subscription_plans():
    """Fetch all available subscription plans."""
    try:
        headers = {
            'apikey': SUPABASE_KEY,
            'Authorization': f'Bearer {SUPABASE_KEY}',
            'Content-Type': 'application/json'
        }
        
        response = requests.get(f"{SUPABASE_URL}/rest/v1/subscription_plans?select=*&is_active=eq.true", headers=headers)
        response.raise_for_status()
        
        plans = response.json()
        return jsonify(plans), 200
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@subscriptions_bp.route('/subscription-plans/<int:plan_id>', methods=['GET'])
def get_subscription_plan(plan_id):
    """Fetch a specific subscription plan by ID."""
    try:
        headers = {
            'apikey': SUPABASE_KEY,
            'Authorization': f'Bearer {SUPABASE_KEY}',
            'Content-Type': 'application/json'
        }
        
        response = requests.get(f"{SUPABASE_URL}/rest/v1/subscription_plans?select=*&id=eq.{plan_id}", headers=headers)
        response.raise_for_status()
        
        plans = response.json()
        if not plans:
            return jsonify({"error": "Subscription plan not found"}), 404
            
        return jsonify(plans[0]), 200
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@subscriptions_bp.route('/users/<string:user_id>/subscription', methods=['GET'])
def get_current_subscription(user_id):
    """Get user's current active subscription."""
    try:
        headers = {
            'apikey': SUPABASE_KEY,
            'Authorization': f'Bearer {SUPABASE_KEY}',
            'Content-Type': 'application/json'
        }
        
        # Get active subscription with plan details
        response = requests.get(
            f"{SUPABASE_URL}/rest/v1/user_subscriptions?select=*,subscription_plans(*)&user_id=eq.{user_id}&status=eq.active",
            headers=headers
        )
        response.raise_for_status()
        
        subscriptions = response.json()
        if not subscriptions:
            return jsonify({"error": "No active subscription found"}), 404
            
        return jsonify(subscriptions[0]), 200
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@subscriptions_bp.route('/users/<string:user_id>/subscriptions', methods=['GET'])
def get_subscription_history(user_id):
    """Get user's subscription history."""
    try:
        headers = {
            'apikey': SUPABASE_KEY,
            'Authorization': f'Bearer {SUPABASE_KEY}',
            'Content-Type': 'application/json'
        }
        
        response = requests.get(
            f"{SUPABASE_URL}/rest/v1/user_subscriptions?select=*,subscription_plans(*)&user_id=eq.{user_id}&order=created_at.desc",
            headers=headers
        )
        response.raise_for_status()
        
        subscriptions = response.json()
        return jsonify(subscriptions), 200
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@subscriptions_bp.route('/subscriptions', methods=['POST'])
def create_subscription():
    """Create a new subscription for a user."""
    try:
        data = request.get_json()
        user_id = data.get('user_id')
        plan_id = data.get('plan_id')
        payment_id = data.get('payment_id')
        payment_order_id = data.get('payment_order_id')
        
        if not all([user_id, plan_id, payment_id, payment_order_id]):
            return jsonify({"error": "Missing required fields"}), 400
        
        headers = {
            'apikey': SUPABASE_KEY,
            'Authorization': f'Bearer {SUPABASE_KEY}',
            'Content-Type': 'application/json',
            'Prefer': 'return=minimal'
        }
        
        # First, get the plan details
        plan_response = requests.get(f"{SUPABASE_URL}/rest/v1/subscription_plans?select=*&id=eq.{plan_id}", headers=headers)
        plan_response.raise_for_status()
        plans = plan_response.json()
        
        if not plans:
            return jsonify({"error": "Subscription plan not found"}), 404
            
        plan = plans[0]
        
        # Calculate subscription dates
        start_date = datetime.now().date()
        end_date = start_date + timedelta(days=plan['duration_days'])
        
        # Create subscription
        subscription_data = {
            'user_id': user_id,
            'plan_id': plan_id,
            'start_date': start_date.isoformat(),
            'end_date': end_date.isoformat(),
            'status': 'active',
            'remaining_credits': plan['credits'],
            'total_credits': plan['credits'],
            'auto_renew': True
        }
        
        subscription_response = requests.post(
            f"{SUPABASE_URL}/rest/v1/user_subscriptions",
            json=subscription_data,
            headers=headers
        )
        subscription_response.raise_for_status()
        
        # Get the created subscription ID
        subscription_id_response = requests.get(
            f"{SUPABASE_URL}/rest/v1/user_subscriptions?select=id&user_id=eq.{user_id}&order=created_at.desc&limit=1",
            headers=headers
        )
        subscription_id_response.raise_for_status()
        subscription_id = subscription_id_response.json()[0]['id']
        
        # Create payment record
        payment_data = {
            'subscription_id': subscription_id,
            'amount': plan['price'],
            'payment_method': 'razorpay',
            'payment_status': 'completed',
            'razorpay_payment_id': payment_id,
            'razorpay_order_id': payment_order_id
        }

        payment_response = requests.post(
            f"{SUPABASE_URL}/rest/v1/subscription_payments",
            json=payment_data,
            headers=headers
        )
        payment_response.raise_for_status()
        
        # Create initial credit transaction
        credit_transaction_data = {
            'subscription_id': subscription_id,
            'credits_used': 0,  # 0 because it's a purchase, not usage
            'transaction_type': 'purchased',
            'description': f'Subscription purchase: {plan["name"]}'
        }
        
        credit_response = requests.post(
            f"{SUPABASE_URL}/rest/v1/credit_transactions",
            json=credit_transaction_data,
            headers=headers
        )
        credit_response.raise_for_status()
        
        return jsonify({
            "message": "Subscription created successfully",
            "subscription_id": subscription_id,
            "plan": plan
        }), 201
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@subscriptions_bp.route('/subscriptions/<int:subscription_id>/cancel', methods=['PATCH'])
def cancel_subscription(subscription_id):
    """Cancel a subscription."""
    try:
        headers = {
            'apikey': SUPABASE_KEY,
            'Authorization': f'Bearer {SUPABASE_KEY}',
            'Content-Type': 'application/json',
            'Prefer': 'return=minimal'
        }
        
        update_data = {
            'status': 'cancelled',
            'auto_renew': False
        }
        
        response = requests.patch(
            f"{SUPABASE_URL}/rest/v1/user_subscriptions?id=eq.{subscription_id}",
            json=update_data,
            headers=headers
        )
        response.raise_for_status()
        
        return jsonify({"message": "Subscription cancelled successfully"}), 200
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@subscriptions_bp.route('/subscriptions/<int:subscription_id>/credits', methods=['GET'])
def get_credit_history(subscription_id):
    """Get credit transaction history for a subscription."""
    try:
        headers = {
            'apikey': SUPABASE_KEY,
            'Authorization': f'Bearer {SUPABASE_KEY}',
            'Content-Type': 'application/json'
        }
        
        response = requests.get(
            f"{SUPABASE_URL}/rest/v1/credit_transactions?select=*&subscription_id=eq.{subscription_id}&order=created_at.desc",
            headers=headers
        )
        response.raise_for_status()
        
        transactions = response.json()
        return jsonify(transactions), 200
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@subscriptions_bp.route('/subscriptions/<int:subscription_id>/use-credits', methods=['POST'])
def use_credits(subscription_id):
    """Use credits for an order."""
    try:
        data = request.get_json()
        order_id = data.get('order_id')
        credits_to_use = data.get('credits_used')
        
        if not all([order_id, credits_to_use]):
            return jsonify({"error": "Missing required fields"}), 400
        
        headers = {
            'apikey': SUPABASE_KEY,
            'Authorization': f'Bearer {SUPABASE_KEY}',
            'Content-Type': 'application/json',
            'Prefer': 'return=minimal'
        }
        
        # Get current subscription
        subscription_response = requests.get(
            f"{SUPABASE_URL}/rest/v1/user_subscriptions?select=*&id=eq.{subscription_id}",
            headers=headers
        )
        subscription_response.raise_for_status()
        subscriptions = subscription_response.json()
        
        if not subscriptions:
            return jsonify({"error": "Subscription not found"}), 404
            
        subscription = subscriptions[0]
        
        if subscription['remaining_credits'] < credits_to_use:
            return jsonify({"error": "Insufficient credits"}), 400
        
        # Update remaining credits
        new_remaining = subscription['remaining_credits'] - credits_to_use
        update_data = {
            'remaining_credits': new_remaining
        }
        
        update_response = requests.patch(
            f"{SUPABASE_URL}/rest/v1/user_subscriptions?id=eq.{subscription_id}",
            json=update_data,
            headers=headers
        )
        update_response.raise_for_status()
        
        # Create credit transaction record
        transaction_data = {
            'subscription_id': subscription_id,
            'order_id': order_id,
            'credits_used': credits_to_use,
            'transaction_type': 'used',
            'description': f'Used {credits_to_use} credits for order #{order_id}'
        }
        
        transaction_response = requests.post(
            f"{SUPABASE_URL}/rest/v1/credit_transactions",
            json=transaction_data,
            headers=headers
        )
        transaction_response.raise_for_status()
        
        return jsonify({
            "message": "Credits used successfully",
            "remaining_credits": new_remaining
        }), 200
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@subscriptions_bp.route('/subscriptions/<int:subscription_id>/check-credits', methods=['POST'])
def check_credits(subscription_id):
    """Check if user has enough credits for an order."""
    try:
        data = request.get_json()
        order_amount = data.get('order_amount')
        
        if not order_amount:
            return jsonify({"error": "Missing order_amount"}), 400
        
        headers = {
            'apikey': SUPABASE_KEY,
            'Authorization': f'Bearer {SUPABASE_KEY}',
            'Content-Type': 'application/json'
        }
        
        # Get subscription with plan details
        response = requests.get(
            f"{SUPABASE_URL}/rest/v1/user_subscriptions?select=*,subscription_plans(*)&id=eq.{subscription_id}",
            headers=headers
        )
        response.raise_for_status()
        subscriptions = response.json()
        
        if not subscriptions:
            return jsonify({"error": "Subscription not found"}), 404
            
        subscription = subscriptions[0]
        plan = subscription['subscription_plans']
        
        # Calculate credits needed (1 credit per ₹1, up to max meal price)
        credits_needed = min(int(order_amount), plan['max_meal_price'])
        has_enough_credits = subscription['remaining_credits'] >= credits_needed
        
        return jsonify({
            "has_enough_credits": has_enough_credits,
            "credits_needed": credits_needed,
            "remaining_credits": subscription['remaining_credits'],
            "max_meal_price": plan['max_meal_price']
        }), 200
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500
