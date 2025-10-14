from flask import Blueprint, request, jsonify
import requests

# Import from config
from config import SUPABASE_URL, headers
# Import utilities
from utils.menu_utils import get_menu_items, get_full_menu_with_categories
from utils.cors_utils import _build_cors_preflight_response

menu_bp = Blueprint('menu', __name__)

@menu_bp.route('/menu', methods=['GET'])
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
        return jsonify({"error": "An internal server error occurred."}), 500

@menu_bp.route('/menu/<int:item_id>', methods=['DELETE'])
def delete_menu_item(item_id):
    """Deletes a specific menu item by ID."""
    try:
        
        # Delete the menu item from Supabase
        api_url = f"{SUPABASE_URL}/rest/v1/menu_items?id=eq.{item_id}"
        
        response = requests.delete(api_url, headers=headers)
        
        if response.status_code == 204:  # Success, no content
            response = jsonify({"message": "Menu item deleted successfully"})
            response.headers.add('Access-Control-Allow-Origin', '*')
            return response, 200
        elif response.status_code == 404:
            response = jsonify({"error": "Menu item not found"})
            response.headers.add('Access-Control-Allow-Origin', '*')
            return response, 404
        else:
            response.raise_for_status()
            # Add return statement for successful response.raise_for_status()
            response = jsonify({"message": "Menu item deleted successfully"})
            response.headers.add('Access-Control-Allow-Origin', '*')
            return response, 200
            
    except Exception as e:
        response = jsonify({"error": "An internal server error occurred."})
        response.headers.add('Access-Control-Allow-Origin', '*')
        return response, 500

@menu_bp.route('/menu/<int:item_id>/availability', methods=['PATCH'])
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
        response = jsonify({"error": "An internal server error occurred."})
        response.headers.add('Access-Control-Allow-Origin', '*')
        return response, 500

@menu_bp.route('/menu', methods=['POST'])
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
        
        # Create the menu item - using correct column names from database
        menu_item_data = {
            'name': data['name'],
            'description': data['description'],
            'price': data['price'],
            'image_url': data['image_url'],
            'category_id': category_id,
            'is_available': data.get('is_available', True),
            'is_veg': data.get('is_veg', True),
            'is_bestseller': data.get('is_bestseller', False),
            'is_chef_spl': data.get('is_chef_spl', False),
            'is_seasonal': data.get('is_seasonal', False),
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
        response = jsonify({"error": str(e)})
        response.headers.add('Access-Control-Allow-Origin', '*')
        return response, 500

@menu_bp.route('/menu/<int:item_id>', methods=['PUT'])
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
        
        # Update the menu item - using correct column names from database
        menu_item_data = {
            'name': data['name'],
            'description': data['description'],
            'price': data['price'],
            'image_url': data['image_url'],
            'category_id': category_id,
            'is_available': data.get('is_available', True),
            'is_veg': data.get('is_veg', True),
            'is_bestseller': data.get('is_bestseller', False),
            'is_chef_spl': data.get('is_chef_spl', False),
            'is_seasonal': data.get('is_seasonal', False),
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
        response = jsonify({"error": str(e)})
        response.headers.add('Access-Control-Allow-Origin', '*')
        return response, 500

@menu_bp.route('/categories', methods=['GET'])
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
        response = jsonify({"error": "An internal server error occurred."})
        response.headers.add('Access-Control-Allow-Origin', '*')
        return response, 500

@menu_bp.route('/categories', methods=['POST'])
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
            return jsonify({"error": "Failed to create category"}), 500
        
    except Exception as e:
        import traceback
        traceback.print_exc()
        response = jsonify({"error": f"Failed to create category: {str(e)}"})
        response.headers.add('Access-Control-Allow-Origin', '*')
        return response, 500

@menu_bp.route('/categories/<int:category_id>', methods=['DELETE'])
def delete_category(category_id):
    """Deletes a category and all its menu items."""
    try:
        
        # First, delete all menu items in this category
        menu_items_response = requests.get(
            f"{SUPABASE_URL}/rest/v1/menu_items?category_id=eq.{category_id}",
            headers=headers
        )
        menu_items_response.raise_for_status()
        menu_items = menu_items_response.json()
        
        if menu_items:
            # Delete all menu items in this category
            for item in menu_items:
                item_id = item['id']
                delete_item_response = requests.delete(
                    f"{SUPABASE_URL}/rest/v1/menu_items?id=eq.{item_id}",
                    headers=headers
                )
                if delete_item_response.status_code not in [204, 200]:
                    # Log error but continue with category deletion
                    pass
        
        # Now delete the category
        api_url = f"{SUPABASE_URL}/rest/v1/categories?id=eq.{category_id}"
        response = requests.delete(api_url, headers=headers)

        # Supabase can return 200 or 204 for successful deletes
        if response.status_code in [200, 204]:
            response = jsonify({"message": "Category and all its items deleted successfully"})
            response.headers.add('Access-Control-Allow-Origin', '*')
            return response, 200
        else:
            return jsonify({"error": "Failed to delete category"}), 500
            
    except Exception as e:
        import traceback
        traceback.print_exc()
        response = jsonify({"error": f"Failed to delete category: {str(e)}"})
        response.headers.add('Access-Control-Allow-Origin', '*')
        return response, 500

# OPTIONS handlers for CORS
@menu_bp.route('/menu/<int:item_id>', methods=['OPTIONS'])
def handle_menu_item_preflight(item_id):
    return _build_cors_preflight_response()

@menu_bp.route('/menu/<int:item_id>/availability', methods=['OPTIONS'])
def handle_menu_availability_preflight(item_id):
    return _build_cors_preflight_response()

