from threading import Thread
from time import sleep

import uvicorn
from fastapi import FastAPI
from fastapi.responses import Response
from prometheus_client import CONTENT_TYPE_LATEST, generate_latest

from apps.billing.app.consumer import run_consumer
from packages.logging.src import logging
from metrics import MetricsMiddleware

app = FastAPI()
app.add_middleware(MetricsMiddleware, service="billing")


@app.get("/metrics", include_in_schema=False)
def metrics() -> Response:
    return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)
log = logging.get_logger("billing")


@app.get("/")
def health():
    return {"service": "billing", "status": "ok"}


def consume_orders() -> None:
    while True:
        try:
            run_consumer()
        except Exception:
            log.exception("Billing consumer stopped; retrying in five seconds")
            sleep(5)


def main() -> None:
    Thread(target=consume_orders, daemon=True).start()
    uvicorn.run(app, host="0.0.0.0", port=8080, log_config=logging.LOGGING_CONFIG)


if __name__ == "__main__":
    main()
