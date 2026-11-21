import logging

from flask import Flask

from app.config import Config
from app.db import init_pool


def create_app(config=Config):
    config.validate()

    app = Flask(__name__)
    app.json.sort_keys = False

    logging.basicConfig(level=logging.INFO,
                        format="%(asctime)s %(levelname)s %(name)s: %(message)s")

    init_pool(config)

    from app.routes import health
    app.register_blueprint(health.bp)

    return app