# bytebot.py

import os
from pinecone import Pinecone
from sentence_transformers import SentenceTransformer

class ByteBot:
    def __init__(self, supabase_url: str, supabase_headers: dict):
        self.supabase_url = supabase_url
        self.supabase_headers = supabase_headers

        pc = Pinecone(api_key=os.environ.get("PINECONE_API_KEY"))
        self.index = pc.Index("menu-items")

        print("Loading local embedding model...")
        self.embedding_model = SentenceTransformer('all-MiniLM-L6-v2')
        print("Embedding model loaded.")

    def semantic_search(self, query: str, metadata_filter: dict = None, k: int = 3):
        """Find closest dish using local embeddings + Pinecone, with a configurable top_k."""
        embedding = self.embedding_model.encode(query).tolist()
        
        results = self.index.query(
            vector=embedding,
            top_k=k,
            include_metadata=True,
            filter=metadata_filter
        )
        return results.to_dict()