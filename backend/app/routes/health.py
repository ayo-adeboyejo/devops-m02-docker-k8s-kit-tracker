from flask import Blueprint, jsonify

from app.db import get_connection

bp = Blueprint("health", __name__)


@bp.get("/healthz")
def healthz():
    return jsonify(status="ok"), 200


@bp.get("/readyz")
def readyz():
    try:
        with get_connection(timeout=2) as conn:
            conn.execute("SELECT 1")
    except Exception:
        return jsonify(status="unavailable", error="Database is not reachable",
                       code="db_unavailable"), 503
    return jsonify(status="ready"), 200