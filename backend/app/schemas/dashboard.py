import uuid
from decimal import Decimal
from typing import List, Optional
from pydantic import BaseModel
from app.schemas.transaction import TransactionResponse


class CategoryBreakdownItem(BaseModel):
    category_id: uuid.UUID
    category_name: str
    category_color: str
    category_icon: str
    total_amount: Decimal
    percentage: float
    transaction_count: int


class MonthlyTrendItem(BaseModel):
    month: int
    month_name: str
    year: int
    income: Decimal
    expense: Decimal
    net_savings: Decimal


class DashboardSummary(BaseModel):
    currency: str
    total_income: Decimal
    total_expenses: Decimal
    current_balance: Decimal
    monthly_income: Decimal
    monthly_spending: Decimal
    monthly_savings: Decimal
    savings_rate: float
    recent_transactions: List[TransactionResponse]


class DashboardCategoryBreakdown(BaseModel):
    currency: str
    month: int
    year: int
    income_categories: List[CategoryBreakdownItem]
    expense_categories: List[CategoryBreakdownItem]


class DashboardMonthlyTrends(BaseModel):
    currency: str
    trends: List[MonthlyTrendItem]

