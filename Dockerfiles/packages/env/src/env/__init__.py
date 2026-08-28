from pydantic import BaseModel
from dotenv import load_dotenv
import os
from pathlib import Path
from typing import TypeVar

from packages.logging.src import logging

T = TypeVar("T", bound=BaseModel)
log = logging.get_logger(__name__)


class GateEnvVars(BaseModel):
    GATE_HOST: str
    GATE_PORT: int
    GATE_INVENTORY_URL: str
    BILLING_RABBITMQ_HOST: str
    BILLING_RABBITMQ_PORT: int
    BILLING_RABBITMQ_MANAGEMENT_PORT: int
    BILLING_RABBITMQ_USER: str
    BILLING_RABBITMQ_PASSWORD: str
    BILLING_RABBITMQ_QUEUE: str


class InventoryEnvVars(BaseModel):
    INVENTORY_PORT: int
    INVENTORY_HOST: str
    INVENTORY_POSTGRES_HOST: str
    INVENTORY_POSTGRES_USER: str
    INVENTORY_POSTGRES_PASSWORD: str
    INVENTORY_POSTGRES_DB: str
    INVENTORY_POSTGRES_PORT: int

    def database_url(self) -> str:
        return (
            f"postgresql+psycopg://{self.INVENTORY_POSTGRES_USER}:"
            f"{self.INVENTORY_POSTGRES_PASSWORD}@{self.INVENTORY_POSTGRES_HOST}:"
            f"{self.INVENTORY_POSTGRES_PORT}/{self.INVENTORY_POSTGRES_DB}"
        )


class BillingEnvVars(BaseModel):
    BILLING_DATABASE_URL: str
    BILLING_POSTGRES_HOST: str
    BILLING_POSTGRES_USER: str
    BILLING_POSTGRES_PASSWORD: str
    BILLING_POSTGRES_DB: str
    BILLING_POSTGRES_PORT: int
    BILLING_RABBITMQ_HOST: str
    BILLING_RABBITMQ_PORT: int
    BILLING_RABBITMQ_MANAGEMENT_PORT: int
    BILLING_RABBITMQ_USER: str
    BILLING_RABBITMQ_PASSWORD: str
    BILLING_RABBITMQ_QUEUE: str

    def database_url(self) -> str:
        return (
            f"postgresql+psycopg://{self.BILLING_POSTGRES_USER}:"
            f"{self.BILLING_POSTGRES_PASSWORD}@{self.BILLING_POSTGRES_HOST}:"
            f"{self.BILLING_POSTGRES_PORT}/{self.BILLING_POSTGRES_DB}"
        )


def load_env(env_class: type[T]) -> T:
    env_file = Path(__file__).resolve().parent.parent.parent.parent.parent / ".env"
    if env_file.exists():
        log.info(f"Loading environment variables from: {env_file}")
        load_dotenv(str(env_file), verbose=True)
    return env_class.model_validate(dict(os.environ))
