from threading import Thread
from time import sleep

import uvicorn
from fastapi import FastAPI

from apps.billing.app.consumer import run_consumer
from packages.logging.src import logging

app = FastAPI()
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
