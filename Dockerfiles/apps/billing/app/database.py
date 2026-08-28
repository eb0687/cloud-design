from env import BillingEnvVars
from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker
from apps.billing.app.models import Base


def create_session_factory(config: BillingEnvVars) -> sessionmaker[Session]:
    engine = create_engine(config.database_url())
    Base.metadata.create_all(engine)
    return sessionmaker(bind=engine)
