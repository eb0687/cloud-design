import pika
from pika.adapters.blocking_connection import BlockingChannel
from pika.spec import Basic, BasicProperties
from pydantic import ValidationError
from sqlalchemy import create_engine
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import sessionmaker

# from apps.billing.app.config import get_config
# from apps.billing.app.database import create_session_factory
from apps.billing.app.models import Base, CreateOrderSchema, Order
from packages.env.src.env import BillingEnvVars, load_env
from packages.logging.src import logging

log = logging.get_logger("billing")

config = load_env(BillingEnvVars)
engine = create_engine(config.database_url())
Base.metadata.create_all(engine)
SessionLocal = sessionmaker(bind=engine)


def save_order(order: Order) -> None:
    with SessionLocal() as session:
        session.add(order)
        session.commit()
        session.refresh(order)


def handle_message(
    channel: BlockingChannel,
    method: Basic.Deliver,
    body: bytes,
) -> None:

    try:
        order = CreateOrderSchema.model_validate_json(body)
        db_order = order.to_order()
        save_order(db_order)
    except ValidationError as e:
        log.error("Invalid billing message: %s", e)
        channel.basic_nack(delivery_tag=method.delivery_tag, requeue=False)
        return
    except SQLAlchemyError as e:
        log.exception("Database error, requeueing billing message: %s", e)
        channel.basic_nack(delivery_tag=method.delivery_tag, requeue=True)
        return
    except Exception as e:
        log.exception("Unexpected error, requeueing billing message: %s", e)
        return

    channel.basic_ack(delivery_tag=method.delivery_tag)
    log.info("Saved billing order %s", db_order.id)


def run_consumer() -> None:

    credentials = pika.PlainCredentials(
        username=config.BILLING_RABBITMQ_USER, password=config.BILLING_RABBITMQ_PASSWORD
    )

    connection = pika.BlockingConnection(
        pika.ConnectionParameters(
            host=config.BILLING_RABBITMQ_HOST,
            port=config.BILLING_RABBITMQ_PORT,
            credentials=credentials,
        )
    )

    channel = connection.channel()
    channel.queue_declare(queue=config.BILLING_RABBITMQ_QUEUE, durable=True)
    # channel.basic_qos(prefetch_count=1)

    def callback(
        channel: BlockingChannel,
        method: Basic.Deliver,
        _: BasicProperties,
        body: bytes,
    ) -> None:
        handle_message(channel, method, body)

    channel.basic_consume(
        queue=config.BILLING_RABBITMQ_QUEUE,
        on_message_callback=callback,
        auto_ack=False,
    )

    log.info("Listening on RabbitMQ queue %s", config.BILLING_RABBITMQ_QUEUE)
    channel.start_consuming()
