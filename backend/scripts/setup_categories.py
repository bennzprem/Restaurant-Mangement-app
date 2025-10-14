import os
import requests

# Use the same credentials as in app.py
SUPABASE_URL = "https://hjvxiamgvcmwjejsmvho.supabase.co"
SUPABASE_SERVICE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhqdnhpYW1ndmNtd2planNtdmhvIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MzYwOTU5NywiZXhwIjoyMDY5MTg1NTk3fQ.fwLqVAXZH00BSn-496hJH4LWdMGveQzELch2dgC_PM8"

headers = {
    'apikey': SUPABASE_SERVICE_KEY,
    'Authorization': f'Bearer {SUPABASE_SERVICE_KEY}',
    'Content-Type': 'application/json',
    'Prefer': 'return=minimal'
}

def setup_categories():
    """Set up the categories table with the correct category data."""
    
    # Define the categories that match the frontend menu screen
    categories = [
        {"id": 1, "name": "Appetizers"},
        {"id": 2, "name": "Soups & Salads"},
        {"id": 3, "name": "Pizzas (11-inch)"},
        {"id": 4, "name": "Pasta"},
        {"id": 5, "name": "Sandwiches & Wraps"},
        {"id": 6, "name": "Main Course - Indian"},
        {"id": 7, "name": "Main Course - Global"},
        {"id": 8, "name": "Desserts"},
        {"id": 9, "name": "Beverages"},
    ]
    
    try:
        # First, check if categories table exists and has data
        response = requests.get(f"{SUPABASE_URL}/rest/v1/categories", headers=headers)
        
        if response.status_code == 200:
            existing_categories = response.json()
            
            if len(existing_categories) == 0:
                # Insert all categories

                for category in categories:
                    response = requests.post(
                        f"{SUPABASE_URL}/rest/v1/categories",
                        headers=headers,
                        json=category
                    )
                    if response.status_code == 201:

                    else:

            else:

        else:

    except Exception as e:

if __name__ == "__main__":
    setup_categories()
