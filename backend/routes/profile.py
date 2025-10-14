from flask import Blueprint, request, jsonify

# Import from config
from config import supabase
# Import utilities
from utils.cors_utils import _build_cors_preflight_response

profile_bp = Blueprint('profile', __name__)

@profile_bp.route('/users/<string:user_id>', methods=['PUT'])
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
        response = jsonify({"error": str(e)})                      # UPDATE THIS
        response.headers.add('Access-Control-Allow-Origin', '*')  # ADD THIS
        return response, 500

@profile_bp.route('/users/change-password', methods=['POST'])
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
        return jsonify({"error": str(e)}), 500

@profile_bp.route('/users/<user_id>/profile-picture', methods=['POST'])
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
        return jsonify({"error": str(e)}), 500

@profile_bp.route('/users/<string:user_id>/profile', methods=['PUT'])
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
        return jsonify({"error": str(e)}), 500

# OPTIONS handlers for CORS
@profile_bp.route('/users/<string:user_id>', methods=['OPTIONS'])
def handle_user_preflight(user_id):
    return _build_cors_preflight_response()

@profile_bp.route('/users/change-password', methods=['OPTIONS'])
def handle_password_preflight():
    return _build_cors_preflight_response()

@profile_bp.route('/users/<string:user_id>/profile-picture', methods=['OPTIONS'])
def handle_pfp_preflight(user_id):
    return _build_cors_preflight_response()

