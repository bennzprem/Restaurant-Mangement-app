import requests
import json
import os
from dotenv import load_dotenv
import time
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry
from concurrent.futures import ThreadPoolExecutor, as_completed

# Load .env when running as a standalone module
load_dotenv()

# Supabase configuration
SUPABASE_URL = (os.getenv("SUPABASE_URL") or "").rstrip("/") + "/rest/v1/menu_items"
SUPABASE_KEY = os.getenv("SUPABASE_KEY") or ""
headers = {"apikey": SUPABASE_KEY, "Authorization": f"Bearer {SUPABASE_KEY}", "Content-Type": "application/json"}

def fetch_menu_items():
    """Fetch menu from Supabase"""
    response = requests.get(SUPABASE_URL, headers=headers)
    return response.json()

def _build_http_session():
    session = requests.Session()
    retry = Retry(total=3, backoff_factor=1.2, status_forcelist=[429, 500, 502, 503, 504])
    adapter = HTTPAdapter(max_retries=retry, pool_connections=8, pool_maxsize=8)
    session.mount("https://", adapter)
    session.headers.update({"Connection": "keep-alive"})
    return session

_SESSION = _build_http_session()

def get_embedding(text):
    """Function to generate embedding (Groq) with retries; returns None on failure."""
    api_key = os.getenv('GROQ_API_KEY')
    headers = {"Authorization": f"Bearer {api_key}", "Content-Type": "application/json"}
    # Reuse resilient HTTP session
    session = _SESSION
    models_to_try = ["text-embedding-3-small", "text-embedding-3-large"]
    # Try OpenAI-compatible endpoint with simple retries
    for model in models_to_try:
        last_err = None
        for _ in range(3):
            try:
                resp = session.post(
                    "https://api.groq.com/openai/v1/embeddings",
                    headers=headers,
                    json={"input": text, "model": model},
                    timeout=20,
                )
                if resp.ok:
                    data = resp.json()
                    if isinstance(data, dict) and data.get("data"):
                        return data["data"][0]["embedding"]
                    last_err = f"Unexpected response: {str(data)[:200]}"
                else:
                    last_err = resp.text
            except Exception as e:
                last_err = str(e)
                time.sleep(1.5)
        # move to next model if current failed after retries

    # Fallback to legacy endpoint with short timeout
    try:
        resp = session.post(
            "https://api.groq.ai/embeddings",
            headers={"Authorization": f"Bearer {api_key}"},
            json={"input": text, "model": "bge-small"},
            timeout=10,
        )
        if resp.ok:
            legacy = resp.json()
            if isinstance(legacy, dict) and legacy.get("embedding"):
                return legacy["embedding"]
    except Exception:
        pass

    return None


def _trim_text(t: str, max_chars: int = 512) -> str:
    t = t or ""
    return t[:max_chars]

def _embed_chunk(chunk, headers, model, timeout=18):
    session = _SESSION
    for _ in range(2):
        try:
            resp = session.post(
                "https://api.groq.com/openai/v1/embeddings",
                headers=headers,
                json={"input": chunk, "model": model},
                timeout=timeout,
            )
            if resp.ok:
                data = resp.json()
                if isinstance(data, dict) and data.get("data"):
                    out = [None] * len(chunk)
                    for item in data["data"]:
                        idx = item.get("index")
                        if idx is not None and 0 <= idx < len(chunk):
                            out[idx] = item.get("embedding")
                    return out
            time.sleep(0.8)
        except Exception:
            time.sleep(0.8)
    # fallback per item
    return [get_embedding(text) for text in chunk]

def get_embeddings_batch(texts, batch_size=32):
    """Batch embedding using Groq OpenAI-compatible endpoint with retries.

    Returns a list of embeddings (or None for failed items), preserving order.
    """
    api_key = os.getenv('GROQ_API_KEY')
    headers = {"Authorization": f"Bearer {api_key}", "Content-Type": "application/json"}
    model = os.getenv("EMBEDDING_MODEL", "nomic-embed-text-v1.5")
    model = os.getenv("EMBEDDING_MODEL", "nomic-embed-text-v1.5")
    texts = [_trim_text(t) for t in texts]
    results = [None] * len(texts)

    tasks = []
    with ThreadPoolExecutor(max_workers=4) as ex:
        for start in range(0, len(texts), batch_size):
            chunk = texts[start:start+batch_size]
            fut = ex.submit(_embed_chunk, chunk, headers, model)
            tasks.append((start, fut))
        for start, fut in tasks:
            out = fut.result()
            for i, vec in enumerate(out):
                results[start + i] = vec
    return results

def precompute_menu_embeddings():
    """Precompute menu embeddings and upload to Pinecone"""
    # Fetch menu from Supabase
    menu_items = fetch_menu_items()
    print(f"Fetched {len(menu_items)} menu items from Supabase")

    # Function to generate embedding (Groq or OpenAI)
    def get_embedding(text):
        return globals()["get_embedding"](text)

    # Prepare Pinecone client and skip already-embedded items
    from pinecone import Pinecone
    pc = Pinecone(api_key=os.getenv("PINECONE_API_KEY"))
    index = pc.Index("menu-items")

    all_ids = [str(it["id"]) for it in menu_items]
    existing: set[str] = set()
    # fetch in chunks to avoid large requests
    for start in range(0, len(all_ids), 100):
        chunk_ids = all_ids[start:start+100]
        try:
            fetched = index.fetch(ids=chunk_ids)
            # pinecone-client v3 returns {"vectors": {id: {...}}}
            vectors_map = (fetched or {}).get("vectors", {})
            existing.update(vectors_map.keys())
        except Exception:
            # If fetch fails, assume none exist for this chunk
            pass

    items_to_embed = [it for it in menu_items if str(it["id"]) not in existing]
    if not items_to_embed:
        print("All items already embedded. Nothing to do.")
        return
    print(f"Embedding {len(items_to_embed)} new/updated items (skipping {len(menu_items)-len(items_to_embed)} already present)")

    # Prepare Pinecone upsert data (include tags if present)
    pinecone_data = []
    texts = [f"{it['name']} - {it.get('description','')}" for it in items_to_embed]
    vectors = get_embeddings_batch(texts, batch_size=32)

    for item, vector in zip(items_to_embed, vectors):
        if vector is None:
            print(f"Skipping embedding for item {item.get('id')} due to embedding failure")
            continue
        meta = {
            "id": item["id"],
            "name": item["name"],
            "description": item.get("description",""),
            "image_url": item.get("image_url",""),
            "price": item.get("price", 0.0),
            "is_veg": item.get("is_veg", False),
            "is_bestseller": item.get("is_bestseller", False),
            "is_available": item.get("is_available", True),
            "category_id": item.get("category_id", 1),
            "tags": item.get("tags") or [],
        }
        pinecone_data.append({"id": str(item["id"]), "values": vector, "metadata": meta})

    if not pinecone_data:
        print("No embeddings were created. Check GROQ_API_KEY connectivity and try again.")
        return

    # Upsert to Pinecone in manageable chunks
    try:
        uploaded = 0
        for start in range(0, len(pinecone_data), 100):
            batch = pinecone_data[start:start+100]
            index.upsert(vectors=batch)
            uploaded += len(batch)
        print(f"Uploaded {uploaded} menu embeddings to Pinecone ✅")
    except Exception as e:
        print(f"Pinecone upsert failed: {e}")

if __name__ == "__main__":
    precompute_menu_embeddings()
