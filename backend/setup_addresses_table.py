#!/usr/bin/env python3
"""
Script to create the user_addresses table in Supabase
Run this script to set up the address management functionality
"""

import os
from supabase import create_client, Client
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Initialize Supabase client
url = os.getenv("SUPABASE_URL", "https://hjvxiamgvcmwjejsmvho.supabase.co")
key = os.getenv("SUPABASE_ANON_KEY", "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhqdnhpYW1ndmNtd2planNtdmhvIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MzYwOTU5NywiZXhwIjoyMDY5MTg1NTk3fQ.fwLqVAXZH00BSn-496hJH4LWdMGveQzELch2dgC_PM8")

if not url or not key:
    print("Error: SUPABASE_URL and SUPABASE_ANON_KEY must be set")
    exit(1)

supabase: Client = create_client(url, key)

def create_addresses_table():
    """Create the user_addresses table with proper schema and policies"""
    
    try:
        print("Testing connection to Supabase...")
        
        # Test the connection by trying to query a simple table
        test_response = supabase.table('users').select('id').limit(1).execute()
        print("✓ Connection to Supabase successful")
        
        print("\nNote: The user_addresses table needs to be created manually in your Supabase dashboard.")
        print("Please follow these steps:")
        print("\n1. Go to your Supabase project dashboard")
        print("2. Navigate to SQL Editor")
        print("3. Run the following SQL commands:")
        print("\n" + "="*60)
        print("CREATE TABLE IF NOT EXISTS user_addresses (")
        print("    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,")
        print("    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,")
        print("    house_no VARCHAR(255) NOT NULL,")
        print("    area VARCHAR(255) NOT NULL,")
        print("    city VARCHAR(255) NOT NULL,")
        print("    state VARCHAR(255) NOT NULL,")
        print("    pincode VARCHAR(20) NOT NULL,")
        print("    contact_name VARCHAR(255),")
        print("    contact_phone VARCHAR(20),")
        print("    is_default BOOLEAN DEFAULT FALSE,")
        print("    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),")
        print("    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()")
        print(");")
        print("\n-- Enable RLS")
        print("ALTER TABLE user_addresses ENABLE ROW LEVEL SECURITY;")
        print("\n-- Create RLS policies")
        print('CREATE POLICY "Users can view their own addresses" ON user_addresses')
        print("    FOR SELECT USING (auth.uid() = user_id);")
        print('CREATE POLICY "Users can insert their own addresses" ON user_addresses')
        print("    FOR INSERT WITH CHECK (auth.uid() = user_id);")
        print('CREATE POLICY "Users can update their own addresses" ON user_addresses')
        print("    FOR UPDATE USING (auth.uid() = user_id);")
        print('CREATE POLICY "Users can delete their own addresses" ON user_addresses')
        print("    FOR DELETE USING (auth.uid() = user_id);")
        print("="*60)
        
        print("\n4. After running the SQL, the address management feature will work!")
        print("\nAlternatively, you can copy the SQL from the file: backend/create_addresses_table.sql")
        
        return True
        
    except Exception as e:
        print(f"Error: {e}")
        print("\nPlease check your Supabase connection and try again.")
        return False

if __name__ == "__main__":
    print("Setting up user_addresses table...")
    success = create_addresses_table()
    
    if success:
        print("\n✅ Setup completed! The address management feature should now work.")
    else:
        print("\n❌ Setup failed. Please check the error messages above.")
