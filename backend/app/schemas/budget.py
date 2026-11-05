import uuid
from datetime import datetime
from decimal import Decimal
from typing import Optional, List
from pydantic import BaseModel, Field, ConfigDict
from app.schemas.category import CategoryResponse


class BudgetBase(BaseModel):
    category_id: uuid.UUID
    amount: Decimal = Field(..., gt=0, decimal_places=2, max_digits=14)
    month: int = Field(..., ge=1, le=12)
    year: int = Field(..., ge=2000, le=2100)


class BudgetCreate(BudgetBase):
    pass


class BudgetUpdate(BaseModel):
    amount: Optional[Decimal] = Field(None, gt=0, decimal_places=2, max_digits=14)
    month: Optional[int] = Field(None, ge=1, le=12)
    year: Optional[int] = Field(None, ge=2000, le=2100)
    category_id: Optional[uuid.UUID] = None


class BudgetResponse(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    category_id: uuid.UUID
    amount: Decimal
    month: int
    year: int
    created_at: datetime
    updated_at: datetime
    category: Optional[CategoryResponse] = None
    spent_amount: Decimal = Decimal("0.00")
    remaining_amount: Decimal = Decimal("0.00")
    utilization_percentage: float = 0.0
    is_exceeded: bool = False

    model_config = ConfigDict(from_attributes=True)


class BudgetSummaryResponse(BaseModel):
    total_budget: Decimal
    total_spent: Decimal
    total_remaining: Decimal
    overall_utilization: float
    budgets: List[BudgetResponse]
