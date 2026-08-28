from fastapi import FastAPI
import uvicorn

from apps.gateway.apps import movies, orders
from packages.env.src.env import GateEnvVars, load_env
from packages.logging.src import logging

log = logging.get_logger("inventory")
config = load_env(GateEnvVars)
app = FastAPI()

app.include_router(movies.router)
app.include_router(orders.router)


def main():
    log.info("Starting gateway service...")

    uvicorn.run(
        "apps.gateway.main:app",
        host=config.GATE_HOST,
        port=config.GATE_PORT,
        reload=True,
        log_config=logging.LOGGING_CONFIG,
    )


if __name__ == "__main__":
    main()
