from fastapi import HTTPException, status, APIRouter
import pika
import pika.exceptions
from packages.env.src.env import GateEnvVars, load_env
from packages.logging.src import logging
from pydantic import BaseModel

log = logging.get_logger("inventory")
config = load_env(GateEnvVars)

router = APIRouter(prefix="/api/billing", tags=["Movies"])


class CreateOrderSchema(BaseModel):
    user_id: int
    number_of_items: int
    total_amount: int


@router.post("/", status_code=status.HTTP_200_OK)
def add_order(body: CreateOrderSchema):
    try:
        credentials = pika.PlainCredentials(
            username=config.BILLING_RABBITMQ_USER,
            password=config.BILLING_RABBITMQ_PASSWORD,
        )

        rabbit_connection = pika.BlockingConnection(
            pika.ConnectionParameters(
                host=config.BILLING_RABBITMQ_HOST,
                port=config.BILLING_RABBITMQ_PORT,
                credentials=credentials,
                heartbeat=30,
                blocked_connection_timeout=10,
            )
        )

        rabbit_channel = rabbit_connection.channel()

        rabbit_channel.queue_declare(
            queue=config.BILLING_RABBITMQ_QUEUE,
            durable=True,
        )

        rabbit_channel.confirm_delivery()

        rabbit_channel.basic_publish(
            exchange="",
            routing_key=config.BILLING_RABBITMQ_QUEUE,
            body=body.model_dump_json(),
            properties=pika.BasicProperties(
                delivery_mode=pika.DeliveryMode.Persistent,
                content_type="application/json",
            ),
            mandatory=True,
        )

        return {"status": "queued"}

    except pika.exceptions.UnroutableError:
        raise HTTPException(
            status_code=500,
            detail="Could not route billing message",
        )

    except pika.exceptions.AMQPError:
        raise HTTPException(
            status_code=503,
            detail="Billing queue unavailable",
        )
