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

    exit(1)

supabase: Client = create_client(url, key)

def create_addresses_table():
    """Create the user_addresses table with proper schema and policies"""
    
    try:

        # Test the connection by trying to query a simple table
        test_response = supabase.table('users').select('id').limit(1).execute()

        return True
        
    except Exception as e:

        return False

if __name__ == "__main__":

    success = create_addresses_table()
    
    if success:

    else:
