#!/usr/bin/env python3
"""
Script to create tables 1-20 and their active sessions.
This ensures all table codes from TBL001 to TBL020 are available.
"""

import requests
import json

# Backend API URL
BASE_URL = "http://localhost:5000"

def create_table_if_not_exists(table_number, capacity=4, location="standard"):
    """Create a table if it doesn't exist"""
    try:
        # First check if table exists
        response = requests.get(f"{BASE_URL}/api/tables")
        if response.status_code == 200:
            tables = response.json()
            existing_table = next((t for t in tables if t['table_number'] == table_number), None)
            if existing_table:
                print(f"Table {table_number} already exists")
                return existing_table['id']
        
        # Create the table
        table_data = {
            "table_number": table_number,
            "capacity": capacity,
            "location_preference": location,
            "session_code": f"TBL{table_number:03d}"
        }
        
        response = requests.post(
            f"{BASE_URL}/api/tables",
            headers={'Content-Type': 'application/json'},
            data=json.dumps(table_data)
        )
        
        if response.status_code == 201:
            result = response.json()
            print(f"SUCCESS: Created table {table_number} with session TBL{table_number:03d}")
            return result['table']['id']
        else:
            print(f"FAILED: Could not create table {table_number}: {response.text}")
            return None
            
    except Exception as e:
        print(f"ERROR creating table {table_number}: {e}")
        return None

def ensure_active_session(table_id, table_number):
    """Ensure there's an active session for the table"""
    try:
        session_code = f"TBL{table_number:03d}"
        
        # Toggle the table to create/activate session
        response = requests.post(
            f"{BASE_URL}/api/tables/{table_id}/toggle",
            headers={'Content-Type': 'application/json'},
            data=json.dumps({'session_code': session_code})
        )
        
        if response.status_code == 200:
            result = response.json()
            if result.get('occupied'):
                print(f"SUCCESS: Activated session {session_code}")
            else:
                print(f"INFO: Session {session_code} was already active")
        else:
            print(f"FAILED: Could not activate session for table {table_number}: {response.text}")
            
    except Exception as e:
        print(f"ERROR activating session for table {table_number}: {e}")

def main():
    """Create tables 1-20 and their active sessions"""
    print("Creating tables 1-20 and their active sessions...")
    
    for table_number in range(1, 21):  # 1 to 20 inclusive
        print(f"\nProcessing table {table_number}...")
        
        # Create table if it doesn't exist
        table_id = create_table_if_not_exists(table_number)
        
        if table_id:
            # Ensure active session
            ensure_active_session(table_id, table_number)
        else:
            print(f"SKIPPED: Could not process table {table_number}")
    
    print("\nDone! All tables TBL001 to TBL020 should now be available.")

if __name__ == "__main__":
    main()
