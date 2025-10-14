from flask import Blueprint, request, jsonify
import razorpay

# Import from config
from config import razorpay_client as client

payments_bp = Blueprint('payments', __name__)

@payments_bp.route('/create-razorpay-order', methods=['POST'])
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
        return jsonify({"error": str(e)}), 500
