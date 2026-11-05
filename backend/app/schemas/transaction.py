import uuid
from datetime import date, datetime
from decimal import Decimal
from typing import Optional, List, Literal
from pydantic import BaseModel, Field, ConfigDict
from app.schemas.category import CategoryResponse


class TransactionBase(BaseModel):
    category_id: uuid.UUID
    amount: Decimal = Field(..., gt=0, decimal_places=2, max_digits=14)
    type: Literal["INCOME", "EXPENSE"]
    description: Optional[str] = Field(None, max_length=500)
    transaction_date: date


class TransactionCreate(TransactionBase):
    pass


class TransactionUpdate(BaseModel):
    category_id: Optional[uuid.UUID] = None
    amount: Optional[Decimal] = Field(None, gt=0, decimal_places=2, max_digits=14)
    type: Optional[Literal["INCOME", "EXPENSE"]] = None
    description: Optional[str] = Field(None, max_length=500)
    transaction_date: Optional[date] = None


class TransactionResponse(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    category_id: uuid.UUID
    amount: Decimal
    type: str
    description: Optional[str] = None
    transaction_date: date
    created_at: datetime
    updated_at: datetime
    category: Optional[CategoryResponse] = None

    model_config = ConfigDict(from_attributes=True)


class TransactionListResponse(BaseModel):
    items: List[TransactionResponse]
    total: int
    page: int
    page_size: int
    total_pages: int

