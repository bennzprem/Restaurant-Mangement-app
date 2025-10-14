import os
import time
import requests
import json
from pinecone import Pinecone
from services.query_parser import parse_craving_with_groq

_pc = None
_index = None
_cache = {
    # structure: { query_lower: {"ts": epoch_seconds, "matches": [...] } }
}

_CACHE_TTL_SECONDS = 600  # 10 minutes

def _get_pinecone_index():
    """Lazily initialize Pinecone to avoid startup failures when offline.

    Returns None if Pinecone cannot be initialized or index not reachable.
    """
    global _pc, _index
    if _index is not None:
        return _index
    try:
        api_key = os.getenv("PINECONE_API_KEY")
        if not api_key:
            return None
        if _pc is None:
            _pc = Pinecone(api_key=api_key)
        _index = _pc.Index("menu-items")
        # Light-touch call to validate connectivity could be added here if needed
        return _index
    except Exception as _e:
        # Swallow errors and fall back to simple search
        return None

def get_embedding(text):
    """Call Groq embedding API (OpenAI-compatible)."""
    url = "https://api.groq.com/openai/v1/embeddings"
    model = os.getenv("EMBEDDING_MODEL", "nomic-embed-text-v1.5")  # 768 dims
    headers = {
        "Authorization": f"Bearer {os.getenv('GROQ_API_KEY')}",
        "Content-Type": "application/json",
    }
    payload = {"input": text, "model": model}
    # Simple retry loop for transient SSL issues
    last_err = None
    for _ in range(3):
        try:
            resp = requests.post(url, headers=headers, json=payload, timeout=12)
            if resp.ok:
                data = resp.json()
                # OpenAI-compatible shape: { data: [ { embedding: [...] } ] }
                if isinstance(data, dict) and data.get("data"):
                    return data["data"][0]["embedding"]
            last_err = resp.text
        except Exception as e:
            last_err = str(e)
    raise RuntimeError(f"Groq embeddings failed: {last_err}")

def find_craving(user_query):
    """Understand query with Groq, then Pinecone vector search + re-rank + hydrate.

    Returns a list of up to 6 matches with `metadata` for the frontend UI.
    """
    try:
        # Check cache first
        query_key = (user_query or "").strip().lower()
        if query_key:
            cached = _cache.get(query_key)
            now = time.time()
            if cached and now - cached.get("ts", 0) < _CACHE_TTL_SECONDS:
                return cached.get("matches", [])

        # Step 1: Parse query with Groq LLM (best-effort)
        parsed = parse_craving_with_groq(user_query) or {}

        # Step 2: Vector search on Pinecone and re-rank
        matches = _vector_search_and_rerank(user_query, parsed)

        # Cache result
        if query_key and matches is not None:
            _cache[query_key] = {"ts": time.time(), "matches": matches}

        return matches
        
    except Exception as e:

        # Fallback to simple keyword search
        return _simple_keyword_search(user_query)

def _simple_keyword_search(user_query):
    """Enhanced fallback keyword search using Supabase with intelligent filtering"""
    try:
        from supabase import create_client
        
        # Initialize Supabase
        SUPABASE_URL = "https://hjvxiamgvcmwjejsmvho.supabase.co"
        SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhqdnhpYW1ndmNtd2planNtdmhvIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MzYwOTU5NywiZXhwIjoyMDY5MTg1NTk3fQ.fwLqVAXZH00BSn-496hJH4LWdMGveQzELch2dgC_PM8"
        supabase = create_client(SUPABASE_URL, SUPABASE_KEY)
        
        # Get all menu items
        response = supabase.table("menu_items").select("*").execute()
        menu_items = response.data if response.data else []
        
        if not menu_items:
            return []
        
        # Enhanced keyword matching with intelligent filtering
        query_lower = user_query.lower()
        matches = []
        
        # Define keyword synonyms and categories
        synonyms = {
            'cold': ['chilled', 'ice', 'frozen', 'refreshing', 'iced', 'cool'],
            'hot': ['spicy', 'warm', 'heated', 'fiery', 'burning'],
            'sweet': ['dessert', 'sugar', 'honey', 'chocolate', 'sugary', 'candy'],
            'spicy': ['hot', 'chili', 'pepper', 'fiery', 'pungent', 'tangy'],
            'sour': ['tangy', 'tart', 'acidic', 'bitter'],
            'refreshing': ['cool', 'cold', 'chilled', 'fresh'],
            'drink': ['beverage', 'juice', 'smoothie', 'coffee', 'tea', 'soda'],
            'soup': ['broth', 'stew', 'bisque'],
            'starter': ['appetizer', 'snack'],
            'main': ['course', 'meal', 'dish'],
            'dessert': ['sweet', 'cake', 'ice cream'],
            'vegetarian': ['veg', 'veggie'],
            'non-veg': ['non-vegetarian', 'meat', 'chicken', 'fish']
        }
        
        for item in menu_items:
            name = item.get('name', '').lower()
            description = item.get('description', '').lower()
            text_blob = f"{name} {description}"
            
            # Check if query keywords match
            score = 0
            query_words = query_lower.split()
            matched_requirements = 0
            total_requirements = len(query_words)
            
            # Check each query word
            for word in query_words:
                word_matched = False
                
                # Direct matches
                if word in name:
                    score += 5  # Highest score for name matches
                    word_matched = True
                if word in description:
                    score += 3  # High score for description matches
                    word_matched = True
                
                # Synonym matches
                if word in synonyms:
                    for synonym in synonyms[word]:
                        if synonym in name:
                            score += 4
                            word_matched = True
                        if synonym in description:
                            score += 2
                            word_matched = True
                
                if word_matched:
                    matched_requirements += 1
            
            # Special handling for common patterns
            if 'refreshing' in query_lower and 'drink' in query_lower:
                if any(term in text_blob for term in ['refreshing', 'cool', 'cold', 'chilled']) and item.get('category_id') == 12:
                    score += 5
                    matched_requirements += 1
            elif 'hot' in query_lower and 'spicy' in query_lower:
                if any(term in text_blob for term in ['hot', 'spicy', 'chili', 'pepper']) and not any(term in text_blob for term in ['sweet', 'chocolate']):
                    score += 5
                    matched_requirements += 1
            elif 'cold' in query_lower and 'sweet' in query_lower:
                if any(term in text_blob for term in ['cold', 'chilled', 'refreshing']) and any(term in text_blob for term in ['sweet', 'sugar', 'honey', 'chocolate']):
                    score += 5
                    matched_requirements += 1
            elif 'vegetarian' in query_lower and 'main' in query_lower:
                if item.get('is_veg', False) and item.get('category_id') in [4, 5, 6, 7, 8, 9, 10]:
                    score += 5
                    matched_requirements += 1
            
            # Apply penalties for contradictory items
            if 'cold' in query_lower and any(term in text_blob for term in ['hot', 'warm', 'heated']):
                score -= 3
            if 'hot' in query_lower and any(term in text_blob for term in ['cold', 'iced', 'chilled']):
                score -= 3
            if 'sweet' in query_lower and any(term in text_blob for term in ['sour', 'tangy', 'bitter']):
                score -= 2
            if 'spicy' in query_lower and any(term in text_blob for term in ['sweet', 'chocolate', 'sugar']):
                score -= 2
            
            # Only include items that match at least 50% of the requirements
            if score > 0 and matched_requirements >= max(1, total_requirements * 0.5):
                # Generate tags for metadata
                tags = []
                if item.get('is_veg', False):
                    tags.append('veg')
                else:
                    tags.append('non-veg')
                if item.get('is_bestseller', False):
                    tags.append('popular')
                if item.get('price', 0) < 100:
                    tags.append('budget')
                elif item.get('price', 0) > 300:
                    tags.append('premium')
                
                # Add course type based on category
                category_id = item.get('category_id', 1)
                if category_id in [12]:  # Drinks
                    tags.append('drink')
                elif category_id in [2]:  # Soups
                    tags.append('soup')
                elif category_id in [1]:  # Starters
                    tags.append('starter')
                elif category_id in [11]:  # Desserts
                    tags.append('dessert')
                elif category_id in [4, 5, 6, 7, 8, 9, 10]:  # Main courses
                    tags.append('main')
                
                # Add taste profile
                if any(word in text_blob for word in ['spicy', 'hot', 'chili', 'pepper']):
                    tags.append('spicy')
                if any(word in text_blob for word in ['sweet', 'sugar', 'honey', 'chocolate']):
                    tags.append('sweet')
                if any(word in text_blob for word in ['sour', 'tangy', 'lemon']):
                    tags.append('sour')
                if any(word in text_blob for word in ['cold', 'iced', 'chilled', 'refreshing']):
                    tags.append('cold')
                if any(word in text_blob for word in ['hot', 'warm', 'heated']):
                    tags.append('hot')
                if any(word in text_blob for word in ['cheesy', 'cheese']):
                    tags.append('cheesy')
                if any(word in text_blob for word in ['crispy', 'fried']):
                    tags.append('crispy')
                
                # Calculate popularity score
                popularity = 5.0
                if item.get('is_bestseller', False):
                    popularity += 3.0
                if item.get('price', 0) < 150:
                    popularity += 1.0
                if item.get('is_veg', False):
                    popularity += 0.5
                
                matches.append({
                    'id': item['id'],
                    'name': item['name'],
                    'description': item.get('description', ''),
                    'score': score,
                    'final_score': score,
                    'metadata': {
                        'id': item['id'],
                        'name': item['name'],
                        'description': item.get('description', ''),
                        'image_url': item.get('image_url', ''),
                        'price': item.get('price', 0.0),
                        'is_veg': item.get('is_veg', False),
                        'is_bestseller': item.get('is_bestseller', False),
                        'is_available': item.get('is_available', True),
                        'category_id': item.get('category_id', 1),
                        'tags': tags,
                        'diet_info': "veg" if item.get('is_veg', False) else "non-veg",
                        'popularity': popularity
                    }
                })
        
        # Sort by score and return up to top 3
        matches.sort(key=lambda x: x['final_score'], reverse=True)
        return matches[:3]
        
    except Exception as e:

        return []

def _db_search_with_hints(user_query, parsed):
    """Search Supabase items using parsed hints/keywords and return top 3.

    Output shape matches previous vector search: list of matches with 'metadata'.
    """
    try:
        from supabase import create_client

        SUPABASE_URL = "https://hjvxiamgvcmwjejsmvho.supabase.co"
        SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhqdnhpYW1ndmNtd2planNtdmhvIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MzYwOTU5NywiZXhwIjoyMDY5MTg1NTk3fQ.fwLqVAXZH00BSn-496hJH4LWdMGveQzELch2dgC_PM8"
        supabase = create_client(SUPABASE_URL, SUPABASE_KEY)

        response = supabase.table("menu_items").select("*").execute()
        menu_items = response.data if response.data else []
        if not menu_items:
            return []

        hints = parsed.get("hints", {})
        positive_keywords = [kw.lower() for kw in parsed.get("positive_keywords", [])]
        negative_keywords = [kw.lower() for kw in parsed.get("negative_keywords", [])]
        normalized_query = parsed.get("normalized_query", user_query).lower()

        results = []
        for item in menu_items:
            name = (item.get('name') or '').lower()
            description = (item.get('description') or '').lower()
            text_blob = f"{name} {description}"

            # Hard filters first
            if any(neg in text_blob for neg in negative_keywords):
                continue

            if hints.get("diet"):
                diet = str(hints["diet"]).lower()
                if diet == "veg" and not item.get('is_veg', False):
                    continue
                if diet == "non-veg" and item.get('is_veg', False):
                    continue

            if hints.get("budget"):
                try:
                    budget = float(hints["budget"])
                    if item.get('price', 0) > budget:
                        continue
                except (ValueError, TypeError):
                    pass

            # Score based on matches
            score = 0.0
            # Query words
            for word in normalized_query.split():
                if word and word in name:
                    score += 4.0
                if word and word in description:
                    score += 2.0

            # Positive keywords from Groq
            for kw in positive_keywords:
                if kw in name:
                    score += 3.0
                if kw in description:
                    score += 1.5

            # Course type preference using heuristic tags
            course_bonus = 0.0
            course = str(hints.get("course_type", "")).lower()
            if course:
                category_id = item.get('category_id', 1)
                tag = None
                if category_id in [12]:
                    tag = 'drink'
                elif category_id in [2]:
                    tag = 'soup'
                elif category_id in [1]:
                    tag = 'starter'
                elif category_id in [11]:
                    tag = 'dessert'
                elif category_id in [4,5,6,7,8,9,10]:
                    tag = 'main'
                if tag == course:
                    course_bonus = 2.0
            score += course_bonus

            # Popularity boost
            if item.get('is_bestseller', False):
                score += 1.0

            if score <= 0:
                continue

            # Build match structure
            results.append({
                'id': item['id'],
                'name': item['name'],
                'description': item.get('description', ''),
                'score': score,
                'final_score': score,
                'metadata': {
                    'id': item['id'],
                    'name': item['name'],
                    'description': item.get('description', ''),
                    'image_url': item.get('image_url', ''),
                    'price': item.get('price', 0.0),
                    'is_veg': item.get('is_veg', False),
                    'is_bestseller': item.get('is_bestseller', False),
                    'is_available': item.get('is_available', True),
                    'category_id': item.get('category_id', 1),
                }
            })

        results.sort(key=lambda x: x['final_score'], reverse=True)
        return results[:3]
    except Exception as e:

        return _simple_keyword_search(user_query)

def search_craving(user_query):
    """Main search function - wrapper for find_craving"""
    return find_craving(user_query)

def _vector_search_and_rerank(user_query: str, parsed: dict):
    """Perform Pinecone vector search, then re-rank using attributes and hydrate from Supabase.

    Returns top 6 items in the same shape as fallback functions: list of dicts with 'metadata'.
    """
    index = _get_pinecone_index()
    if index is None:
        # Pinecone not available, fall back
        return _db_search_with_hints(user_query, parsed)

    query_text = (parsed.get("normalized_query") or user_query or "").strip()
    if not query_text:
        return []

    # Query expansion (simple synonyms)
    synonyms = {
        "hot": ["warm", "spicy"],
        "sweet": ["sugary", "dessert"],
        "cheesy": ["cheese", "mozzarella"],
        "refreshing": ["cool", "cold", "chilled"],
        "spicy": ["hot", "fiery", "chili"],
    }
    expanded_terms = []
    for term in (parsed.get("positive_keywords") or []):
        term_l = str(term).lower()
        expanded_terms.append(term_l)
        expanded_terms.extend(synonyms.get(term_l, []))
    expansion_suffix = (" " + " ".join(expanded_terms)) if expanded_terms else ""
    embed_text = f"{query_text}{expansion_suffix}".strip()

    # Create embedding
    vector = get_embedding(embed_text)

    # Query Pinecone
    try:
        res = index.query(
            vector=vector,
            top_k=20,
            include_values=False,
            include_metadata=True,
        )
        matches = res.get("matches", [])
    except Exception as e:

        return _db_search_with_hints(user_query, parsed)

    if not matches:
        return _db_search_with_hints(user_query, parsed)

    # Build re-ranking inputs
    positive_keywords = set([str(x).lower() for x in (parsed.get("positive_keywords") or [])])
    negative_keywords = set([str(x).lower() for x in (parsed.get("negative_keywords") or [])])
    hints = parsed.get("hints", {})
    course_pref = str(hints.get("course_type", "")).lower()
    budget = hints.get("budget")

    # Base attributes we care strongly about for combined queries
    strong_attrs = {"hot", "sweet", "spicy", "cheesy", "sour", "cold", "refreshing"}
    requested_attrs = [kw for kw in positive_keywords if kw in strong_attrs]

    def category_to_course_tag(category_id: int):
        if category_id in [12]:
            return "drink"
        if category_id in [2]:
            return "soup"
        if category_id in [1]:
            return "starter"
        if category_id in [11]:
            return "dessert"
        if category_id in [4, 5, 6, 7, 8, 9, 10]:
            return "main"
        return ""

    scored = []
    for m in matches:
        meta = m.get("metadata", {}) or {}
        base_score = float(m.get("score", 0.0))  # vector similarity

        # Tag-based bonuses
        item_tags = set([str(t).lower() for t in (meta.get("tags") or [])])
        tag_bonus = 0.0
        for pk in positive_keywords:
            if pk in item_tags:
                tag_bonus += 0.3

        # Negative penalties
        neg_penalty = 0.0
        for nk in negative_keywords:
            if nk in item_tags:
                neg_penalty += 0.5

        # Course preference bonus
        course_bonus = 0.0
        if course_pref:
            course_tag = category_to_course_tag(int(meta.get("category_id", 0)))
            if course_tag and course_tag == course_pref:
                course_bonus += 0.5

        # Popularity bonus
        popularity_bonus = 0.3 if meta.get("is_bestseller", False) else 0.0

        # Attribute coverage enforcement for combined queries
        # Count distinct requested attrs matched in tags or name/description
        name_desc = f"{str(meta.get('name','')).lower()} {str(meta.get('description','')).lower()}"
        def attr_present(attr: str) -> bool:
            if attr in item_tags:
                return True
            if attr in name_desc:
                return True
            for syn in synonyms.get(attr, []):
                if syn in item_tags or syn in name_desc:
                    return True
            return False

        matched_attr_count = sum(1 for a in requested_attrs if attr_present(a))

        # If 2+ attrs requested (e.g., "hot" AND "sweet"), require at least 2 present; otherwise skip
        if len(requested_attrs) >= 2 and matched_attr_count < 2:
            continue
        # If exactly 1 strong attr requested, require presence or apply heavy penalty
        coverage_penalty = 0.0
        if len(requested_attrs) == 1 and matched_attr_count == 0:
            coverage_penalty = 1.0

        final_score = base_score + tag_bonus + course_bonus + popularity_bonus - neg_penalty - coverage_penalty

        # Budget filter/penalty (filter out too expensive if budget provided)
        price = float(meta.get("price", 0.0) or 0.0)
        if budget:
            try:
                b = float(budget)
                if price > b:
                    # Skip items beyond budget
                    continue
            except (TypeError, ValueError):
                pass

        scored.append({
            "id": meta.get("id"),
            "name": meta.get("name"),
            "description": meta.get("description", ""),
            "score": base_score,
            "final_score": final_score,
            "metadata": meta,
        })

    # Sort and take up to top 3
    scored.sort(key=lambda x: x["final_score"], reverse=True)
    top = scored[:3]

    # Hydrate from Supabase for freshness (price, availability, image)
    hydrated = _hydrate_from_supabase(top)
    return hydrated or top

def _hydrate_from_supabase(matches: list):
    """Fetch fresh details from Supabase for the given match IDs and merge fields.

    Returns a new list with merged metadata; if hydration fails, returns original matches.
    """
    if not matches:
        return matches

    ids = [m.get("metadata", {}).get("id") or m.get("id") for m in matches]
    ids = [str(i) for i in ids if i is not None]
    if not ids:
        return matches

    supabase_url = os.getenv("SUPABASE_URL") or ""
    supabase_key = os.getenv("SUPABASE_KEY") or ""
    if not (supabase_url and supabase_key):
        return matches

    try:
        headers = {
            "apikey": supabase_key,
            "Authorization": f"Bearer {supabase_key}",
            "Content-Type": "application/json",
        }
        # Build "in" filter: id=in.(1,2,3)
        in_clause = ",".join(ids)
        url = f"{supabase_url}/rest/v1/menu_items?id=in.({in_clause})"
        resp = requests.get(url, headers=headers)
        resp.raise_for_status()
        rows = resp.json()
        by_id = {str(r.get("id")): r for r in rows}

        merged = []
        for m in matches:
            meta = m.get("metadata", {})
            mid = str(meta.get("id") or m.get("id"))
            fresh = by_id.get(mid)
            if fresh:
                # Merge core fields
                meta.update({
                    "name": fresh.get("name", meta.get("name")),
                    "description": fresh.get("description", meta.get("description")),
                    "image_url": fresh.get("image_url", meta.get("image_url")),
                    "price": fresh.get("price", meta.get("price")),
                    "is_veg": fresh.get("is_veg", meta.get("is_veg")),
                    "is_bestseller": fresh.get("is_bestseller", meta.get("is_bestseller")),
                    "is_available": fresh.get("is_available", meta.get("is_available")),
                    "category_id": fresh.get("category_id", meta.get("category_id")),
                    "tags": fresh.get("tags", meta.get("tags")),
                })
            merged.append({
                "id": meta.get("id"),
                "name": meta.get("name"),
                "description": meta.get("description", ""),
                "score": m.get("score", 0.0),
                "final_score": m.get("final_score", m.get("score", 0.0)),
                "metadata": meta,
            })
        return merged
    except Exception as e:

        return matches