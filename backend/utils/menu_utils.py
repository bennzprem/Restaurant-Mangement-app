"""
Menu utility functions for the ByteEat application.
"""
import requests
import re

def get_menu_items(supabase_url: str, supabase_headers: dict):
    """Fetches all menu items from Supabase."""
    try:
        response = requests.get(
            f"{supabase_url}/rest/v1/menu_items?select=*",
            headers=supabase_headers
        )
        response.raise_for_status()
        return response.json()
    except Exception as e:
        return []

def get_full_menu_with_categories(supabase_url: str, supabase_headers: dict):
    """Fetches all categories and their associated menu items."""
    try:
        api_url = f"{supabase_url}/rest/v1/categories?select=name,menu_items(*)"
        response = requests.get(api_url, headers=supabase_headers)
        response.raise_for_status()
        
        structured_menu = response.json()
        
        # Flatten the structure for easier processing by the AI
        all_items = []
        category_names = []
        for category in structured_menu:
            category_name = category.get('name')
            if category_name:
                category_names.append(category_name)
            for item in category.get('menu_items', []):
                item['category_name'] = category_name  # Add category name to each item
                all_items.append(item)
                
        return all_items, category_names
    except Exception as e:
        return [], []

def _normalize_text(value: str) -> str:
    """Normalize text for fuzzy matching by removing special characters and converting to lowercase."""
    try:
        return re.sub(r"[^a-z0-9 ]+", "", (value or "").lower()).strip()
    except Exception:
        return (value or "").lower().strip()

def find_best_menu_match(menu_list: list, query_name: str):
    """Return the best matching menu item dict for the given query_name.
    Prefers exact (case-insensitive) match; otherwise tries startswith, contains,
    and simple token overlap scoring. Returns None if nothing reasonable found.
    """
    if not query_name:
        return None
    q_norm = _normalize_text(query_name)
    if not q_norm:
        return None

    # 1) Exact (case-insensitive)
    for item in menu_list:
        if _normalize_text(item.get('name', '')) == q_norm:
            return item

    # 2) Startswith
    starts = [it for it in menu_list if _normalize_text(it.get('name', '')).startswith(q_norm)]
    if starts:
        return starts[0]

    # 3) Contains
    contains = [it for it in menu_list if q_norm in _normalize_text(it.get('name', ''))]
    if contains:
        return contains[0]

    # 4) Token overlap (simple score)
    q_tokens = set(q_norm.split())
    best = None
    best_score = 0
    for it in menu_list:
        name_tokens = set(_normalize_text(it.get('name', '')).split())
        score = len(q_tokens.intersection(name_tokens))
        if score > best_score:
            best_score = score
            best = it
    # Require at least 1 token overlap to avoid bad guesses
    return best if best_score > 0 else None

def find_similar_items(menu_list: list, query: str, max_results: int = 5):
    """Find similar items when no exact matches are found"""
    if not query:
        return []
    
    normalized_query = _normalize_text(query)
    if not normalized_query:
        return []
    
    similar_items = []
    
    for item in menu_list:
        item_name = _normalize_text(item.get('name', ''))
        item_desc = _normalize_text(item.get('description', ''))
        item_category = _normalize_text(item.get('category_name', ''))
        
        score = 0
        
        # Check for partial matches in name
        if normalized_query in item_name:
            score += 10
        
        # Check for partial matches in description
        if normalized_query in item_desc:
            score += 5
            
        # Check for partial matches in category
        if normalized_query in item_category:
            score += 3
            
        # Check for word overlap
        query_words = set(normalized_query.split())
        item_words = set(item_name.split())
        overlap = len(query_words.intersection(item_words))
        score += overlap * 2
        
        if score > 0:
            similar_items.append((item['name'], score))
    
    # Sort by score and return top matches
    similar_items.sort(key=lambda x: x[1], reverse=True)
    return [item[0] for item in similar_items[:max_results]]
