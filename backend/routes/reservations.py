from flask import Blueprint, request, jsonify
from datetime import datetime, timedelta, timezone

# Import from config
from config import supabase

reservations_bp = Blueprint('reservations', __name__)

@reservations_bp.route('/api/available-tables', methods=['GET'])
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
        return jsonify({"error": str(e)}), 500

@reservations_bp.route('/api/reservations', methods=['POST'])
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

        # If no table_id provided or it's not a valid UUID, create/use a default table
        if not table_id or table_id in ['1', 'default']:
            # Try to find an existing table with table_number = 1
            existing_table = supabase.table('tables').select('id').eq('table_number', 1).execute()
            if existing_table.data:
                table_id = existing_table.data[0]['id']
            else:
                # Create a default table
                default_table = supabase.table('tables').insert({
                    'table_number': 1,
                    'capacity': 4,
                    'location_preference': 'Main Dining'
                }).execute()
                if default_table.data:
                    table_id = default_table.data[0]['id']
                else:
                    return jsonify({"error": "Failed to create default table"}), 500

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
        
        if not insert_response.data:
            return jsonify({"error": "Failed to create reservation"}), 500
        
        return jsonify(insert_response.data[0]), 201

    except Exception as e:
        return jsonify({"error": str(e)}), 500

@reservations_bp.route('/api/reservations/simple', methods=['POST'])
def create_simple_reservation():
    """
    Creates a simple reservation for the logged-in user.
    This is used by the simplified reservation flow.
    """
    try:
        # Get user authentication
        auth_header = request.headers.get('Authorization')
        if not auth_header:
            return jsonify({"error": "Authorization header is required"}), 401
        token = auth_header.split(" ")[1]
        user_response = supabase.auth.get_user(token)
        user_id = user_response.user.id

        data = request.get_json()
        table_number = data.get('table_number')
        date = data.get('date')  # YYYY-MM-DD format
        time = data.get('time')  # HH:MM format
        party_size = data.get('party_size')
        special_occasion = data.get('special_occasion', 'None')

        if not all([table_number, date, time, party_size]):
            return jsonify({"error": "Missing required fields"}), 400

        # Find or create table with the specified table number
        existing_table = supabase.table('tables').select('id').eq('table_number', int(table_number)).execute()
        if existing_table.data:
            table_id = existing_table.data[0]['id']
        else:
            # Create a new table with the specified number
            new_table = supabase.table('tables').insert({
                'table_number': int(table_number),
                'capacity': max(party_size, 4),  # At least 4 capacity
                'location_preference': 'Main Dining'
            }).execute()
            if new_table.data:
                table_id = new_table.data[0]['id']
            else:
                return jsonify({"error": "Failed to create table"}), 500

        # Parse the reservation datetime
        reservation_datetime = datetime.strptime(f"{date} {time}", "%Y-%m-%d %H:%M")
        
        new_reservation = {
            "user_id": user_id,
            "table_id": table_id,
            "reservation_time": reservation_datetime.isoformat(),
            "party_size": party_size,
            "special_occasion": special_occasion,
            "status": "confirmed"
        }

        insert_response = supabase.table('reservations').insert(new_reservation).execute()
        
        if not insert_response.data:
            return jsonify({"error": "Failed to create reservation"}), 500
        
        return jsonify({
            "success": True,
            "reservation": insert_response.data[0],
            "message": "Reservation created successfully"
        }), 201

    except Exception as e:
        return jsonify({"error": str(e)}), 500

@reservations_bp.route('/api/reservations/<reservation_id>/complete', methods=['POST'])
def complete_reservation(reservation_id):
    """
    Marks a reservation as completed when the customer finishes dining.
    """
    try:
        # Get user authentication
        auth_header = request.headers.get('Authorization')
        if not auth_header:
            return jsonify({"error": "Authorization header is required"}), 401
        token = auth_header.split(" ")[1]
        user_response = supabase.auth.get_user(token)
        user_id = user_response.user.id

        # Verify the reservation belongs to the authenticated user
        reservation_response = supabase.table('reservations').select('*').eq('id', reservation_id).eq('user_id', user_id).execute()
        
        if not reservation_response.data:
            return jsonify({"error": "Reservation not found or not authorized"}), 404

        reservation = reservation_response.data[0]
        
        # Check if reservation is already completed
        if reservation.get('status') == 'completed':
            return jsonify({"error": "Reservation is already completed"}), 400

        # Update reservation status to completed
        update_response = supabase.table('reservations').update({
            'status': 'completed',
            'completed_at': datetime.now(timezone.utc).isoformat()
        }).eq('id', reservation_id).execute()

        if not update_response.data:
            return jsonify({"error": "Failed to update reservation"}), 500

        return jsonify({
            "success": True,
            "message": "Reservation completed successfully",
            "reservation": update_response.data[0]
        }), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500

@reservations_bp.route('/api/tables/availability', methods=['POST'])
def check_table_availability():
    """
    Check table availability for a specific date and time.
    """
    try:
        data = request.get_json()
        if not data:
            return jsonify({"error": "Request body is required"}), 400
            
        reservation_date = data.get('date')  # YYYY-MM-DD format
        reservation_time = data.get('time')  # HH:MM format
        party_size = data.get('party_size', 2)

        if not all([reservation_date, reservation_time]):
            return jsonify({"error": "Date and time are required"}), 400
        
        # Parse the reservation datetime
        reservation_datetime = datetime.strptime(f"{reservation_date} {reservation_time}", "%Y-%m-%d %H:%M")
        
        # Define time window (2 hours before and after)
        window_start = reservation_datetime - timedelta(hours=1, minutes=59)
        window_end = reservation_datetime + timedelta(hours=1, minutes=59)
        
        # Get all tables
        tables_response = supabase.table('tables').select('*').order('table_number').execute()
        all_tables = tables_response.data or []
        
        # Get booked tables in the time window
        booked_tables_response = supabase.table('reservations').select('table_id').eq('status', 'confirmed').gte('reservation_time', window_start.isoformat()).lte('reservation_time', window_end.isoformat()).execute()
        booked_table_ids = [res['table_id'] for res in booked_tables_response.data or []]
        
        # Filter available tables
        available_tables = []
        for table in all_tables:
            if table['id'] not in booked_table_ids and table['capacity'] >= party_size:
                available_tables.append({
                    'id': table['id'],
                    'table_number': table['table_number'],
                    'capacity': table['capacity'],
                    'location_preference': table['location_preference'],
                    'code': table.get('code', f"TBL{table['table_number']:03d}")
                })

        return jsonify({
            'available_tables': available_tables,
            'total_available': len(available_tables),
            'requested_party_size': party_size,
            'reservation_datetime': reservation_datetime.isoformat()
        }), 200
        
    except Exception as e:
        import traceback
        traceback.print_exc()
        return jsonify({"error": str(e)}), 500

@reservations_bp.route('/api/reservations', methods=['GET'])
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

@reservations_bp.route('/api/reservations/<uuid:reservation_id>/cancel', methods=['PUT'])
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

@reservations_bp.route('/api/tables', methods=['POST'])
def create_table():
    """
    Creates a new table. Optionally accepts a session_code to create an active
    table session for that table immediately (useful when pre-printing QR codes).

    Body:
    {
      "table_number": 12,               // required
      "capacity": 4,                    // optional (defaults 4)
      "location_preference": "Patio",  // optional
      "session_code": "TBL012"         // optional, creates active session
    }
    """
    try:
        data = request.get_json() or {}
        table_number = data.get('table_number')
        capacity = data.get('capacity', 4)
        location_preference = data.get('location_preference')
        session_code = data.get('session_code')

        if not table_number:
            return jsonify({"error": "table_number is required"}), 400

        # Create table row
        table_payload = {
            'table_number': table_number,
            'capacity': capacity,
        }
        if location_preference is not None:
            table_payload['location_preference'] = location_preference

        table_resp = supabase.table('tables').insert(table_payload).execute()
        if not table_resp.data:
            return jsonify({"error": "Failed to create table"}), 500

        table_row = table_resp.data[0]
        result = { 'table': table_row }

        # Optionally create an active session with provided code
        if session_code:
            # If a session with the same code is already active, return conflict
            existing = supabase.table('table_sessions').select('id') \
                .eq('session_code', session_code.upper()) \
                .eq('status', 'active').execute()
            if existing.data:
                return jsonify({
                    'error': 'An active session already exists with this session_code'
                }), 409

            create_session = supabase.table('table_sessions').insert({
                'table_id': table_row['id'],
                'session_code': session_code.upper(),
                'status': 'active',
                'started_at': datetime.now(timezone.utc).isoformat(),
            }).execute()

            if not create_session.data:
                return jsonify({"error": "Table created but failed to create session"}), 500

            result['session'] = create_session.data[0]

        return jsonify(result), 201

    except Exception as e:
        return jsonify({"error": str(e)}), 500

@reservations_bp.route('/api/tables', methods=['GET'])
def list_tables():
    """Returns all tables with active occupancy/session info."""
    try:
        tables_resp = supabase.table('tables').select('*').order('table_number').execute()
        tables = tables_resp.data or []

        # Fetch active sessions to determine occupancy and codes
        sessions_resp = supabase.table('table_sessions') \
            .select('table_id, session_code, status') \
            .eq('status', 'active').execute()
        active_by_table = {}
        if sessions_resp.data:
            for s in sessions_resp.data:
                active_by_table[s['table_id']] = {
                    'session_code': s.get('session_code'),
                    'status': s.get('status', 'active')
                }

        result = []
        for t in tables:
            info = {
                'id': t.get('id'),
                'table_number': t.get('table_number'),
                'capacity': t.get('capacity'),
                'location_preference': t.get('location_preference'),
                'occupied': t.get('id') in active_by_table,
                'active_session_code': active_by_table.get(t.get('id'), {}).get('session_code')
            }
            result.append(info)

        return jsonify(result), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@reservations_bp.route('/api/tables/<table_id>/toggle', methods=['POST'])
def toggle_table_occupancy(table_id):
    """
    Toggles a table between occupied and available.
    - If an active session exists for this table, close it (set available).
    - Otherwise create a new active session (set occupied). Optional body:
      { "session_code": "TBL007" }
    Returns: { occupied: bool, active_session_code: str|null }
    """
    try:
        data = request.get_json(silent=True) or {}
        desired_code = (data.get('session_code') or '').strip().upper() or None

        # Check table exists and get number for default code
        # table_id may arrive as string UUID or integer; compare via eq works for both
        table_row = supabase.table('tables').select('*').eq('id', table_id).maybe_single().execute()
        if not table_row or not table_row.data:
            return jsonify({"error": "Table not found"}), 404

        # Check for active session for this table
        active = supabase.table('table_sessions').select('*') \
            .eq('table_id', table_id).eq('status', 'active').maybe_single().execute()

        # If active exists, close it
        if active and active.data:
            supabase.table('table_sessions').update({
                'status': 'closed',
                'ended_at': datetime.now(timezone.utc).isoformat(),
            }).eq('id', active.data['id']).execute()
            return jsonify({
                'occupied': False,
                'active_session_code': None,
            }), 200

        # Else create a new active session
        session_code = desired_code
        if not session_code:
            # Default code: TBL{table_number:03d}
            tbl_num = table_row.data.get('table_number')
            try:
                session_code = f"TBL{int(tbl_num):03d}"
            except Exception:
                session_code = f"TBL{table_id}"

        # Ensure no conflicting active session with same code
        conflict = supabase.table('table_sessions').select('id').eq('session_code', session_code).eq('status', 'active').execute()
        if conflict and conflict.data:
            return jsonify({"error": "An active session already uses this code"}), 409

        created = supabase.table('table_sessions').insert({
            'table_id': table_id,
            'session_code': session_code,
            'status': 'active',
            'started_at': datetime.now(timezone.utc).isoformat(),
        }).execute()

        if not created or not created.data:
            return jsonify({"error": "Failed to create session"}), 500

        return jsonify({
            'occupied': True,
            'active_session_code': session_code,
        }), 200
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@reservations_bp.route('/api/table-sessions/start', methods=['POST'])
def start_table_session():
    """
    Validates a table code and returns the active session for that table.
    """
    try:
        data = request.get_json()
        session_code = data.get('session_code')

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
            return jsonify({"error": "Invalid table code. Please check the code and try again."}), 404

        # If we get here, the code was found
        session = session_response.data
        
        return jsonify({
            "sessionId": session['id'],
            "tableId": session['table_id'],
            "tableNumber": session['tables']['table_number']
        }), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500
