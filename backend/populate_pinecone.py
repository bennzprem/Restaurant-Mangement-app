import os
import requests
from dotenv import load_dotenv
from pinecone import Pinecone
from sentence_transformers import SentenceTransformer # <-- NEW: Import SentenceTransformer

# Load environment variables from .env file
load_dotenv()

# --- Configuration ---
SUPABASE_URL = "https://hjvxiamgvcmwjejsmvho.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhqdnhpYW1ndmNtd2planNtdmhvIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MzYwOTU5NywiZXhwIjoyMDY5MTg1NTk3fQ.fwLqVAXZH00BSn-496hJH4LWdMGveQzELch2dgC_PM8"
PINECONE_INDEX_NAME = "menu-items"

# --- Initialize Clients ---
print("Initializing clients...")
# Supabase
supabase_headers = {
    "apikey": SUPABASE_KEY,
    "Authorization": f"Bearer {SUPABASE_KEY}"
}

# Pinecone
try:
    pc = Pinecone(api_key=os.environ.get("PINECONE_API_KEY"))
    index = pc.Index(PINECONE_INDEX_NAME)
    print(f"✅ Successfully connected to Pinecone index '{PINECONE_INDEX_NAME}'.")
except Exception as e:
    print(f"❌ Error connecting to Pinecone: {e}.")
    exit()

# NEW: Load the local sentence transformer model
print("Loading local embedding model (this may take a moment on first run)...")
embedding_model = SentenceTransformer('all-MiniLM-L6-v2')
print("✅ Embedding model loaded.")


def fetch_all_menu_items():
    """Fetches all categories and their menu items from Supabase."""
    print("\nFetching menu items from Supabase...")
    try:
        api_url = f"{SUPABASE_URL}/rest/v1/categories?select=name,menu_items(*)"
        response = requests.get(api_url, headers=supabase_headers)
        response.raise_for_status()
        
        structured_menu = response.json()
        all_items = []
        for category in structured_menu:
            category_name = category.get('name', 'Uncategorized')
            for item in category.get('menu_items', []):
                if isinstance(item, dict) and item.get('id') is not None:
                    item['category_name'] = category_name
                    all_items.append(item)
        print(f"✅ Successfully fetched {len(all_items)} menu items.")
        return all_items
    except Exception as e:
        print(f"❌ Error fetching menu from Supabase: {e}")
        return []

# NEW: Updated function using the local model
def create_embedding(text):
    """Creates an embedding for a given text using the local model."""
    return embedding_model.encode(text).tolist()

def main():
    menu_items = fetch_all_menu_items()
    if not menu_items:
        return

    print("\nPreparing items for Pinecone upsert...")
    vectors_to_upsert = []
    for item in menu_items:
        description_for_embedding = f"Dish Name: {item.get('name', '')}. Description: {item.get('description', '')}. Category: {item.get('category_name', '')}."
        vector = create_embedding(description_for_embedding)
        
        try:
            price = float(item.get('price', 0.0))
        except (ValueError, TypeError):
            price = 0.0

        metadata = {
            "name": str(item.get('name', '')),
            "description": str(item.get('description', '')),
            "price": price,
            "image_url": str(item.get('image_url', '')),
            "category_name": str(item.get('category_name', '')),
            "is_veg": bool(item.get('is_veg', False))
        }
        
        vectors_to_upsert.append({
            "id": str(item['id']),
            "values": vector,
            "metadata": metadata
        })

    print(f"\nUploading {len(vectors_to_upsert)} vectors to Pinecone...")
    batch_size = 100 
    for i in range(0, len(vectors_to_upsert), batch_size):
        batch = vectors_to_upsert[i:i + batch_size]
        print(f"Uploading batch {i//batch_size + 1}...")
        try:
            index.upsert(vectors=batch)
        except Exception as e:
            print(f"❌ An error occurred during upsert: {e}")
    
    print("\n--- ✅ Population Complete! ---")
    final_stats = index.describe_index_stats()
    print(f"Final Record Count: {final_stats.get('total_record_count', 'N/A')}")
    print("\nYou can now run 'python app.py'.")

if __name__ == "__main__":
    main()