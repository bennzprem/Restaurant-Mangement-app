import random
from supabase import create_client
from sklearn.metrics.pairwise import cosine_similarity
from sklearn.feature_extraction.text import TfidfVectorizer
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Supabase init - use the same credentials as main app
SUPABASE_URL = "https://hjvxiamgvcmwjejsmvho.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhqdnhpYW1ndmNtd2planNtdmhvIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MzYwOTU5NywiZXhwIjoyMDY5MTg1NTk3fQ.fwLqVAXZH00BSn-496hJH4LWdMGveQzELch2dgC_PM8"
supabase = create_client(SUPABASE_URL, SUPABASE_KEY)


def fetch_menu_items():
    """Fetch all menu items from Supabase"""
    response = supabase.table("menu_items").select("*").execute()
    return response.data if response.data else []


def fetch_order_history(user_id: str):
    """Fetch past order history items for a given user"""
    # First get all orders for the user
    orders_response = supabase.table("orders").select("id").eq("user_id", user_id).execute()
    if not orders_response.data:
        return []
    
    order_ids = [order["id"] for order in orders_response.data]
    
    # Then get all menu_item_ids from order_items for those orders
    order_items_response = supabase.table("order_items").select("menu_item_id").in_("order_id", order_ids).execute()
    return [row["menu_item_id"] for row in order_items_response.data] if order_items_response.data else []


def recommend_items(user_id: str, top_n=3):
    """Generate recommendations for a user - always returns exactly 3 items"""

    # 1. Fetch menu + history
    menu_items = fetch_menu_items()
    if not menu_items:
        return []

    order_history = fetch_order_history(user_id)

    # If no history → fallback to bestsellers with randomization
    if not order_history:
        bestseller_items = [item for item in menu_items if item["is_bestseller"]]
        if len(bestseller_items) >= top_n:
            # Shuffle and take exactly top_n items
            random.shuffle(bestseller_items)
            return bestseller_items[:top_n]
        else:
            # If not enough bestsellers, fill with random items
            random.shuffle(menu_items)
            return menu_items[:top_n]

    # 2. Build content matrix using description + tags
    corpus = []
    id_map = {}

    for i, item in enumerate(menu_items):
        text = f"{item['name']} {item.get('description','')} {' '.join(item.get('tags', [])) if item.get('tags') else ''}"
        corpus.append(text)
        id_map[i] = item["id"]

    vectorizer = TfidfVectorizer(stop_words="english")
    tfidf_matrix = vectorizer.fit_transform(corpus)

    # 3. Build profile vector (avg of user's ordered items)
    ordered_indices = [idx for idx, mid in id_map.items() if mid in order_history]
    if not ordered_indices:
        # Fallback to bestsellers if no ordered items found
        bestseller_items = [item for item in menu_items if item["is_bestseller"]]
        if len(bestseller_items) >= top_n:
            random.shuffle(bestseller_items)
            return bestseller_items[:top_n]
        else:
            random.shuffle(menu_items)
            return menu_items[:top_n]

    user_profile = tfidf_matrix[ordered_indices].mean(axis=0)

    # 4. Compute similarity
    sims = cosine_similarity(user_profile, tfidf_matrix).flatten()

    # 5. Sort by score and filter already ordered
    ranked_indices = sims.argsort()[::-1]
    recommendations = []

    for idx in ranked_indices:
        mid = id_map[idx]
        if mid not in order_history:
            recommendations.append(next(item for item in menu_items if item["id"] == mid))
        if len(recommendations) >= top_n:
            break

    # 6. If we don't have enough recommendations, fill with random bestsellers
    if len(recommendations) < top_n:
        remaining_needed = top_n - len(recommendations)
        bestseller_items = [item for item in menu_items if item["is_bestseller"] and item["id"] not in [r["id"] for r in recommendations]]
        if bestseller_items:
            random.shuffle(bestseller_items)
            recommendations.extend(bestseller_items[:remaining_needed])
        
        # If still not enough, fill with any random items
        if len(recommendations) < top_n:
            remaining_needed = top_n - len(recommendations)
            available_items = [item for item in menu_items if item["id"] not in [r["id"] for r in recommendations]]
            if available_items:
                random.shuffle(available_items)
                recommendations.extend(available_items[:remaining_needed])

    # 7. Shuffle the final recommendations for variety
    random.shuffle(recommendations)
    
    # 8. Ensure we return exactly top_n items
    return recommendations[:top_n]
