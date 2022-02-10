import logging
import base64
import os
import json
from google.cloud import bigquery
import base64
import os

from flask import Flask, request


app = Flask(__name__)

@app.route("/", methods=["POST"])
def index():
    table_id = os.getenv("TABLE_ID")

    if table_id is None:
        logging.error("TABLE_ID is missing")
        return f"TABLE_ID is missing", 500

    envelope = request.get_json()
    if not envelope:
        msg = "no Pub/Sub message received"
        logging.info(f"Error: {msg}")
        return f"Bad Request: {msg}", 400

    if not isinstance(envelope, dict) or "message" not in envelope:
        msg = "invalid Pub/Sub message format"
        logging.info(f"Error: {msg}")
        return f"Bad Request: {msg}", 400

    pubsub_message = envelope["message"]

    if isinstance(pubsub_message, dict) and "data" in pubsub_message:
        event_data = json.loads(base64.b64decode(pubsub_message['data']).decode('utf-8'))
        client = bigquery.Client()
        errors = client.insert_rows_json(table_id, [event_data])
        if not errors:
            logging.info("New rows have been added.")
        else:
            raise ValueError("Encountered errors while inserting row: {}".format(errors))

    return "", 204
