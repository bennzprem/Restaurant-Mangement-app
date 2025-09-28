from flask import Blueprint, request, jsonify
from .recommender import recommend_items

recommendation_bp = Blueprint("recommendation", __name__)

@recommendation_bp.route("/recommendations/<string:user_id>", methods=["GET"])
def get_recommendations(user_id):
    try:
        recs = recommend_items(user_id)
        return jsonify({"recommendations": recs})
    except Exception as e:
        return jsonify({"error": str(e)}), 500
