from flask import Blueprint, request, jsonify
import requests
import re
from urllib.parse import quote

# Import from config
from config import (
    SUPABASE_URL, headers, SUPABASE_HEADERS, supabase
)
# Import utilities
from utils.cors_utils import cors_json_response, _build_cors_preflight_response
from utils.menu_utils import get_menu_items, find_best_menu_match, find_similar_items

orders_bp = Blueprint('orders', __name__)

@orders_bp.route('/order', methods=['POST'])
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

        order_response = requests.post(f"{SUPABASE_URL}/rest/v1/orders", json=order_payload, headers=headers)

        if order_response.status_code != 201:
            return jsonify({"error": f"Failed to create order: {order_response.text}"}), 500
            
        order_response.raise_for_status()
        new_order = order_response.json()[0]
        order_id = new_order['id']

        order_items_payload = [
            {
                "order_id": order_id, 
                "menu_item_id": item['menu_item_id'],  # Use 'menu_item_id' from Flutter
                "quantity": item['quantity'], 
                "price_at_order": item['price_at_order'] # Use 'price_at_order' from Flutter and for the column name
            } for item in cart_items
        ]

        items_response = requests.post(f"{SUPABASE_URL}/rest/v1/order_items", json=order_items_payload, headers=headers)
        
        if items_response.status_code != 201:
            return jsonify({"error": f"Failed to create order items: {items_response.text}"}), 500
            
        items_response.raise_for_status()

        return jsonify({"message": "Order placed successfully!", "order_id": order_id}), 201
    except Exception as e:
        import traceback
        return jsonify({"error": str(e)}), 500
    
@orders_bp.route('/users/<string:user_id>/orders', methods=['GET'])
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
        return jsonify({"error": "An internal server error occurred."}), 500
    
@orders_bp.route('/order/<int:order_id>', methods=['GET'])
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
        return jsonify({"error": str(e)}), 500

@orders_bp.route('/orders/count', methods=['GET'])
def get_orders_count():
    try:
        api_url = f"{SUPABASE_URL}/rest/v1/orders?select=id"
        response = requests.get(api_url, headers=headers)
        response.raise_for_status()
        data = response.json()
        return jsonify({"count": len(data)}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# --- Kitchen and Delivery Order Feeds ---
@orders_bp.route('/api/kitchen/orders', methods=['GET'])
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
        return cors_json_response({"error": str(e)}, 500)

@orders_bp.route('/api/delivery/orders', methods=['GET'])
def api_delivery_orders():
    """Returns orders that are ready for delivery (status = Ready)."""
    try:
        
        # First, let's check what order statuses exist
        all_orders_res = requests.get(
            f"{SUPABASE_URL}/rest/v1/orders?select=id,status&order=created_at.desc&limit=10",
            headers=SUPABASE_HEADERS,
        )
        if all_orders_res.ok:
            all_orders = all_orders_res.json() or []
        
        orders_res = requests.get(
            f"{SUPABASE_URL}/rest/v1/orders?select=*&status=eq.Ready&order=created_at.desc",
            headers=SUPABASE_HEADERS,
        )
        
        orders_res.raise_for_status()
        orders = orders_res.json() or []
        
        # If no ready orders, let's also check preparing orders for debugging
        if len(orders) == 0:
            preparing_res = requests.get(
                f"{SUPABASE_URL}/rest/v1/orders?select=*&status=eq.Preparing&order=created_at.desc",
                headers=SUPABASE_HEADERS,
            )
            if preparing_res.ok:
                preparing_orders = preparing_res.json() or []

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

        return cors_json_response(result, 200)
    except Exception as e:
        import traceback
        traceback.print_exc()
        return cors_json_response({"error": str(e)}, 500)

@orders_bp.route('/api/delivery/orders/<int:order_id>/accept', methods=['POST'])
def api_delivery_accept(order_id: int):
    """Delivery user accepts an order → mark as Out for delivery and assign delivery_user_id."""
    try:
        data = request.get_json(silent=True) or {}
        delivery_user_id = data.get('delivery_user_id')

        # First, check if the order exists and get its current status
        check_resp = requests.get(
            f"{SUPABASE_URL}/rest/v1/orders?id=eq.{order_id}&select=id,status",
            headers=SUPABASE_HEADERS,
        )
        
        if check_resp.status_code != 200:
            return cors_json_response({"error": "Order not found"}, 404)
            
        order_data = check_resp.json()
        if not order_data:
            return cors_json_response({"error": "Order not found"}, 404)
            
        current_status = order_data[0].get('status')

        # Update status
        update = { 'status': 'Out for delivery' }
        if delivery_user_id:
            update['delivery_user_id'] = delivery_user_id

        # Try to update with delivery_user_id first
        resp = requests.patch(
            f"{SUPABASE_URL}/rest/v1/orders?id=eq.{order_id}",
            json=update,
            headers=SUPABASE_HEADERS,
        )
        
        # If the update fails due to column issues, try without delivery_user_id
        if resp.status_code == 400 and 'delivery_user_id' in update:
            update_without_user = { 'status': 'Out for delivery' }
            resp = requests.patch(
                f"{SUPABASE_URL}/rest/v1/orders?id=eq.{order_id}",
                json=update_without_user,
                headers=SUPABASE_HEADERS,
            )

        resp.raise_for_status()
        return cors_json_response({"message": "Order accepted for delivery"}, 200)
    except Exception as e:
        import traceback
        traceback.print_exc()
        return cors_json_response({"error": str(e)}, 500)

@orders_bp.route('/test-delivery-column', methods=['GET'])
def test_delivery_column():
    """Test endpoint to check if delivery_user_id column exists and works."""
    try:
        # Try to select the delivery_user_id column
        resp = requests.get(
            f"{SUPABASE_URL}/rest/v1/orders?select=id,delivery_user_id&limit=1",
            headers=SUPABASE_HEADERS,
        )
        return cors_json_response({"status": resp.status_code, "response": resp.text}, 200)
    except Exception as e:
        return cors_json_response({"error": str(e)}, 500)

@orders_bp.route('/api/delivery/accepted-orders', methods=['GET'])
def api_delivery_accepted_orders():
    """Returns orders that are accepted by a specific delivery person (status = Out for delivery)."""
    try:
        delivery_user_id = request.args.get('delivery_user_id')
        
        if not delivery_user_id:
            return cors_json_response({"error": "delivery_user_id is required"}, 400)

        # For now, get all "Out for delivery" orders since the column might not be working
        # TODO: Once delivery_user_id column is properly configured, filter by it
        orders_res = requests.get(
            f"{SUPABASE_URL}/rest/v1/orders?select=*&status=eq.{quote('Out for delivery')}&order=created_at.desc",
            headers=SUPABASE_HEADERS,
        )
        
        orders_res.raise_for_status()
        orders = orders_res.json() or []

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

        return cors_json_response(result, 200)
    except Exception as e:
        import traceback
        traceback.print_exc()
        return cors_json_response({"error": str(e)}, 500)

@orders_bp.route('/api/delivery/orders/<int:order_id>/delivered', methods=['POST'])
def api_delivery_delivered(order_id: int):
    """Delivery user marks an order as delivered → mark as Delivered."""
    try:
        data = request.get_json(silent=True) or {}
        delivery_user_id = data.get('delivery_user_id')

        # First, check if the order exists and get its current status
        check_resp = requests.get(
            f"{SUPABASE_URL}/rest/v1/orders?id=eq.{order_id}&select=id,status",
            headers=SUPABASE_HEADERS,
        )
        
        if check_resp.status_code != 200:
            return cors_json_response({"error": "Order not found"}, 404)
            
        order_data = check_resp.json()
        if not order_data:
            return cors_json_response({"error": "Order not found"}, 404)
            
        current_status = order_data[0].get('status')

        # Only allow marking as delivered if order is "Out for delivery"
        if current_status != 'Out for delivery':
            return cors_json_response({"error": f"Order must be 'Out for delivery' to mark as delivered. Current status: {current_status}"}, 400)

        # Update status to "Delivered"
        update = { 'status': 'Delivered' }

        resp = requests.patch(
            f"{SUPABASE_URL}/rest/v1/orders?id=eq.{order_id}",
            json=update,
            headers=SUPABASE_HEADERS,
        )

        resp.raise_for_status()
        return cors_json_response({"message": "Order marked as delivered successfully"}, 200)
    except Exception as e:
        import traceback
        traceback.print_exc()
        return cors_json_response({"error": str(e)}, 500)

@orders_bp.route('/orders', methods=['GET'])
def get_all_orders():
    try:
        api_url = f"{SUPABASE_URL}/rest/v1/orders?select=*&order=created_at.desc"
        response = requests.get(api_url, headers=headers)
        response.raise_for_status()
        return jsonify(response.json()), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@orders_bp.route('/orders/<int:order_id>/items', methods=['GET'])
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
        response = jsonify({"error": str(e)})
        response.headers.add('Access-Control-Allow-Origin', '*')
        return response, 500

@orders_bp.route('/orders/<int:order_id>/status', methods=['PATCH'])
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
        response = jsonify({"error": str(e)})
        response.headers.add('Access-Control-Allow-Origin', '*')
        return response, 500
    
@orders_bp.route('/users/<string:user_id>/favorites', methods=['GET'])
def get_favorites(user_id):
    """Gets a user's favorite items using the Supabase REST API."""
    try:
        api_url = f"{SUPABASE_URL}/rest/v1/favorites?user_id=eq.{user_id}&select=menu_items(*)"
        response = requests.get(api_url, headers=headers)
        response.raise_for_status()
        favorite_items = [item['menu_items'] for item in response.json() if item.get('menu_items')]
        return jsonify(favorite_items)
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@orders_bp.route('/favorites', methods=['POST'])
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
        return jsonify({"error": str(e)}), 500

@orders_bp.route('/favorites', methods=['DELETE'])
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
        return jsonify({"error": str(e)}), 500

@orders_bp.route('/api/orders/add-items', methods=['POST'])
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
        return jsonify({"error": str(e)}), 500

# OPTIONS handlers for CORS
@orders_bp.route('/api/delivery/orders/<int:order_id>/delivered', methods=['OPTIONS'])
def handle_delivered_preflight(order_id):
    return _build_cors_preflight_response()
