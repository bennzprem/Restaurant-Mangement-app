from flask import Blueprint, request, jsonify
import os
from services.recommender import recommend_items
from services.hybrid_search import find_craving
from services.menu_embeddings import precompute_menu_embeddings

recommendation_bp = Blueprint('recommendation', __name__)
@recommendation_bp.route("/recommendations/<string:user_id>", methods=["GET"])
def get_recommendations(user_id):
    try:
        recs = recommend_items(user_id)
        return jsonify({"recommendations": recs})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@recommendation_bp.route("/api/find_craving", methods=["POST"])
def api_find_craving():
    """Find menu items based on user craving query using AI-driven hybrid approach"""
    data = request.get_json()
    query = data.get("craving","")
    if not query:
        return jsonify({"error":"Missing craving"}),400

    try:
        top_items = find_craving(query)
        result = [
            {
                "id": c['metadata']['id'],
                "name": c['metadata']['name'],
                "description": c['metadata']['description'],
                "score": c.get('final_score', c.get('score', 0)),
                "metadata": c['metadata']
            } for c in top_items
        ]
        return jsonify({"craving": query, "matches": result})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@recommendation_bp.route("/api/admin/reembed", methods=["POST"])
def api_reembed():
    """Admin-only: trigger re-embedding and Pinecone upsert for all menu items."""
    try:
        # Optional: add a simple auth check using a header or env secret
        admin_secret = request.headers.get("X-Admin-Secret", "")
        expected = (os.getenv("ADMIN_REEMBED_SECRET") or "").strip()
        if expected and admin_secret != expected:
            return jsonify({"error": "Unauthorized"}), 401

        precompute_menu_embeddings()
        return jsonify({"status": "re-embed started"}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500
