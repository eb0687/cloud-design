from pydantic import BaseModel
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column


class Base(DeclarativeBase):
    pass


class Order(Base):
    __tablename__ = "orders"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    user_id: Mapped[int]
    number_of_items: Mapped[int]
    total_amount: Mapped[int]


class CreateOrderSchema(BaseModel):
    user_id: int
    number_of_items: int
    total_amount: int

    def to_order(self) -> Order:
        return Order(
            user_id=self.user_id,
            number_of_items=self.number_of_items,
            total_amount=self.total_amount,
        )
