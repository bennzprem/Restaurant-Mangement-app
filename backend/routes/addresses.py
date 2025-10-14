from flask import Blueprint, request, jsonify
from datetime import datetime, timezone

# Import from config
from config import supabase
# Import utilities
from utils.cors_utils import _build_cors_preflight_response

addresses_bp = Blueprint('addresses', __name__)

@addresses_bp.route('/users/<string:user_id>/addresses', methods=['GET'])
def get_user_addresses(user_id):
    try:
        # Get all addresses for the user
        response = supabase.table('user_addresses').select('*').eq('user_id', user_id).order('created_at', desc=True).execute()
        
        result = jsonify(response.data)
        result.headers.add('Access-Control-Allow-Origin', '*')
        return result, 200
    except Exception as e:
        result = jsonify({"error": str(e)})
        result.headers.add('Access-Control-Allow-Origin', '*')
        return result, 500

@addresses_bp.route('/users/<string:user_id>/addresses', methods=['POST'])
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
        result = jsonify({"error": str(e)})
        result.headers.add('Access-Control-Allow-Origin', '*')
        return result, 500

@addresses_bp.route('/users/<string:user_id>/addresses/<string:address_id>', methods=['PUT'])
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
        result = jsonify({"error": str(e)})
        result.headers.add('Access-Control-Allow-Origin', '*')
        return result, 500

@addresses_bp.route('/users/<string:user_id>/addresses/<string:address_id>', methods=['DELETE'])
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
        result = jsonify({"error": str(e)})
        result.headers.add('Access-Control-Allow-Origin', '*')
        return result, 500

@addresses_bp.route('/users/<string:user_id>/addresses/<string:address_id>/set-default', methods=['POST'])
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
        result = jsonify({"error": str(e)})
        result.headers.add('Access-Control-Allow-Origin', '*')
        return result, 500

@addresses_bp.route('/users/<string:user_id>/addresses/default', methods=['GET'])
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
        result = jsonify({"error": str(e)})
        result.headers.add('Access-Control-Allow-Origin', '*')
        return result, 500

# OPTIONS handlers for CORS
@addresses_bp.route('/users/<string:user_id>/addresses', methods=['OPTIONS'])
def handle_addresses_preflight(user_id):
    return _build_cors_preflight_response()

@addresses_bp.route('/users/<string:user_id>/addresses/<string:address_id>', methods=['OPTIONS'])
def handle_address_preflight(user_id, address_id):
    return _build_cors_preflight_response()

@addresses_bp.route('/users/<string:user_id>/addresses/<string:address_id>/set-default', methods=['OPTIONS'])
def handle_set_default_address_preflight(user_id, address_id):
    return _build_cors_preflight_response()

@addresses_bp.route('/users/<string:user_id>/addresses/default', methods=['OPTIONS'])
def handle_default_address_preflight(user_id):
    return _build_cors_preflight_response()

