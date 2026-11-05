import uuid
from sqlalchemy import Column, String, Boolean, DateTime, ForeignKey, Index, func
from sqlalchemy.orm import relationship
from app.database.session import Base
from app.models.guid import GUID


class Category(Base):
    __tablename__ = "categories"

    id = Column(GUID, primary_key=True, default=uuid.uuid4)
    user_id = Column(GUID, ForeignKey("users.id", ondelete="CASCADE"), nullable=True, index=True)
    name = Column(String(100), nullable=False)
    type = Column(String(20), nullable=False)  # "INCOME" or "EXPENSE"
    color = Column(String(20), default="#3B82F6", nullable=False)
    icon = Column(String(50), default="category", nullable=False)
    is_system = Column(Boolean, default=False, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)

    __table_args__ = (
        Index("ix_categories_user_type", "user_id", "type"),
    )

    # Relationships
    user = relationship("User", back_populates="categories")
    transactions = relationship("Transaction", back_populates="category")
    budgets = relationship("Budget", back_populates="category")
