"""
CORS utility functions for the ByteEat application.
"""
from flask import jsonify

def _build_cors_preflight_response():
    """Build a CORS preflight response."""
    response = jsonify({'message': 'CORS preflight successful'})
    response.headers.add('Access-Control-Allow-Origin', '*')
    response.headers.add('Access-Control-Allow-Headers', 'Content-Type,Authorization')
    response.headers.add('Access-Control-Allow-Methods', 'GET,PUT,POST,DELETE,OPTIONS,PATCH')
    return response, 200

def cors_json_response(payload, status=200):
    """Create a JSON response with CORS headers."""
    response = jsonify(payload)
    response.headers.add('Access-Control-Allow-Origin', '*')
    return response, status
