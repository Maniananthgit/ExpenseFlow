import uuid
from sqlalchemy import Column, String, Numeric, Date, DateTime, ForeignKey, Index, func
from sqlalchemy.orm import relationship
from app.database.session import Base
from app.models.guid import GUID


class Transaction(Base):
    __tablename__ = "transactions"

    id = Column(GUID, primary_key=True, default=uuid.uuid4)
    user_id = Column(GUID, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    category_id = Column(GUID, ForeignKey("categories.id", ondelete="RESTRICT"), nullable=False, index=True)
    amount = Column(Numeric(14, 2), nullable=False)
    type = Column(String(20), nullable=False)  # "INCOME" or "EXPENSE"
    description = Column(String(500), nullable=True)
    transaction_date = Column(Date, nullable=False, index=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)

    __table_args__ = (
        Index("ix_transactions_user_date", "user_id", "transaction_date"),
        Index("ix_transactions_user_type", "user_id", "type"),
        Index("ix_transactions_user_cat", "user_id", "category_id"),
    )

    # Relationships
    user = relationship("User", back_populates="transactions")
    category = relationship("Category", back_populates="transactions")

