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
    from app import supabase
except ImportError:
    print("Error: Could not import Supabase configuration from app.py")
    print("Make sure app.py is in the same directory and has the correct Supabase setup")
    sys.exit(1)

def create_tables():
    """
    Create 20 tables in the database if they don't exist.
    """
    print("🔧 Setting up 20 tables for QR code generation...")
    
    created_count = 0
    existing_count = 0
    
    for table_num in range(1, 21):  # Tables 1-20
        try:
            # Check if table already exists
            existing = supabase.table('tables').select('id').eq('table_number', table_num).execute()
            
            if existing.data:
                print(f"📋 Table {table_num} already exists")
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
                print(f"✅ Created Table {table_num}")
                created_count += 1
            else:
                print(f"❌ Failed to create Table {table_num}")
                
        except Exception as e:
            print(f"❌ Error creating Table {table_num}: {e}")
    
    print(f"\n📊 Summary:")
    print(f"   Created: {created_count} tables")
    print(f"   Already existed: {existing_count} tables")
    print(f"   Total: {created_count + existing_count} tables")
    
    if created_count + existing_count == 20:
        print("✅ All 20 tables are ready for QR code generation!")
    else:
        print("⚠️  Some tables may be missing. Please check your database.")

def main():
    """
    Main function to setup tables.
    """
    print("🚀 ByteEat Table Setup")
    print("=" * 40)
    
    try:
        create_tables()
    except Exception as e:
        print(f"❌ Error setting up tables: {e}")

if __name__ == "__main__":
    main()
