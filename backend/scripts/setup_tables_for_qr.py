#!/usr/bin/env python3
"""
Setup script to create 20 tables in the database for QR code generation.
This script will create tables with numbers 1-20 if they don't already exist.
"""

import os
import sys

# Add the current directory to Python path to import from app.py
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

try:
    from app_refactored import supabase
except ImportError:

    sys.exit(1)

def create_tables():
    """
    Create 20 tables in the database if they don't exist.
    """

    created_count = 0
    existing_count = 0
    
    for table_num in range(1, 21):  # Tables 1-20
        try:
            # Check if table already exists
            existing = supabase.table('tables').select('id').eq('table_number', table_num).execute()
            
            if existing.data:

                existing_count += 1
                continue
            
            # Create new table
            table_data = {
                'table_number': table_num,
                'capacity': 4,  # Default capacity
                'location_preference': 'Main Dining'
            }
            
            result = supabase.table('tables').insert(table_data).execute()
            
            if result.data:

                created_count += 1
            else:

        except Exception as e:

    if created_count + existing_count == 20:

    else:

def main():
    """
    Main function to setup tables.
    """

    try:
        create_tables()
    except Exception as e:

if __name__ == "__main__":
    main()
