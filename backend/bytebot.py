# bytebot.py

import os
from pinecone import Pinecone
from sentence_transformers import SentenceTransformer # <-- NEW: Import SentenceTransformer

class ByteBot:
    def __init__(self, supabase_url: str, supabase_headers: dict):
        self.supabase_url = supabase_url
        self.supabase_headers = supabase_headers

        # Init Pinecone (remains the same)
        pc = Pinecone(
            api_key=os.environ.get("PINECONE_API_KEY")
        )
        self.index = pc.Index("menu-items")

        # NEW: Load the free, local embedding model from Hugging Face
        # The first time this runs, it will download the model (a few hundred MB).
        print("Loading local embedding model...")
        self.embedding_model = SentenceTransformer('all-MiniLM-L6-v2')
        print("Embedding model loaded.")


    def semantic_search(self, query: str):
        """Find closest dish using local embeddings + Pinecone"""
        # NEW: Create embeddings using the local model
        embedding = self.embedding_model.encode(query).tolist()
        
        results = self.index.query(
            vector=embedding,
            top_k=1,
            include_metadata=True
        )
        return results.to_dict()