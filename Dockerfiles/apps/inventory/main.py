from fastapi import FastAPI, HTTPException, Response, status
import uvicorn
import packages.error.src.error as error
from packages.env.src.env import load_env, InventoryEnvVars
from packages.logging.src import logging
from pydantic import BaseModel
from sqlalchemy import String, create_engine, select
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column, sessionmaker

log = logging.get_logger("inventory")


class Base(DeclarativeBase):
    pass


class Movie(BaseModel):
    id: int
    title: str
    description: str


class MovieRecord(Base):
    __tablename__ = "movies"

    id: Mapped[int] = mapped_column(primary_key=True)
    title: Mapped[str] = mapped_column(String, nullable=False)
    description: Mapped[str] = mapped_column(String, nullable=False)

    def to_movie(self) -> Movie:
        return Movie(id=self.id, title=self.title, description=self.description)


env = load_env(InventoryEnvVars)
engine = create_engine(env.database_url())
log.info(
    "Connecting to inventory database at %s:%s/%s",
    env.INVENTORY_POSTGRES_HOST,
    env.INVENTORY_POSTGRES_PORT,
    env.INVENTORY_POSTGRES_DB,
)
SessionLocal = sessionmaker(engine)

Base.metadata.create_all(engine)

app = FastAPI()


class CreateMovie(BaseModel):
    title: str
    description: str


@app.get("/api/movies", responses=error.common_responses)
def list_movies(title: str | None = None) -> list[Movie]:
    query = select(MovieRecord).order_by(MovieRecord.id)
    if title:
        query = query.where(MovieRecord.title.ilike(f"%{title}%"))

    with SessionLocal() as session:
        records = session.scalars(query).all()
    return [record.to_movie() for record in records]


@app.post("/api/movies", responses=error.common_responses)
def create_movie(movie: CreateMovie) -> Movie:
    with SessionLocal() as session:
        record = MovieRecord(title=movie.title, description=movie.description)
        session.add(record)
        session.commit()
        session.refresh(record)
        return record.to_movie()


@app.delete(
    "/api/movies",
    status_code=status.HTTP_204_NO_CONTENT,
    responses=error.common_responses,
)
def delete_movies() -> Response:
    with SessionLocal() as session:
        session.query(MovieRecord).delete()
        session.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@app.get("/api/movies/{movie_id}", responses=error.common_responses)
def get_movie(movie_id: int) -> Movie:
    with SessionLocal() as session:
        record = session.get(MovieRecord, movie_id)
    if record is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Movie not found"
        )
    return record.to_movie()


@app.put("/api/movies/{movie_id}", responses=error.common_responses)
def update_movie(movie_id: int, movie: CreateMovie) -> Movie:
    with SessionLocal() as session:
        record = session.get(MovieRecord, movie_id)
        if record is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND, detail="Movie not found"
            )
        record.title = movie.title
        record.description = movie.description
        session.commit()
        session.refresh(record)
        return record.to_movie()


@app.delete(
    "/api/movies/{movie_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    responses=error.common_responses,
)
def delete_movie(movie_id: int) -> Response:
    with SessionLocal() as session:
        record = session.get(MovieRecord, movie_id)
        if record is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND, detail="Movie not found"
            )
        session.delete(record)
        session.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@app.get("/")
def root():
    return {"service": "inventory", "status": "ok"}


def main():
    log.info("Starting inventory service...")

    uvicorn.run(
        "apps.inventory.main:app",
        host=env.INVENTORY_HOST,
        port=env.INVENTORY_PORT,
        reload=True,
        log_config=logging.LOGGING_CONFIG,
    )


if __name__ == "__main__":
    main()
