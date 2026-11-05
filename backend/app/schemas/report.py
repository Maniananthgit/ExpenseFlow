import uuid
from decimal import Decimal
from typing import List, Dict, Any
from pydantic import BaseModel
from app.schemas.dashboard import CategoryBreakdownItem, MonthlyTrendItem


class DailyExpenseItem(BaseModel):
    date: str
    income: Decimal
    expense: Decimal


class MonthlyReportResponse(BaseModel):
    currency: str
    month: int
    year: int
    month_name: str
    total_income: Decimal
    total_expense: Decimal
    net_savings: Decimal
    savings_rate: float
    category_breakdown: List[CategoryBreakdownItem]
    daily_breakdown: List[DailyExpenseItem]
    top_expenses: List[Dict[str, Any]]


class YearlyReportResponse(BaseModel):
    currency: str
    year: int
    total_income: Decimal
    total_expense: Decimal
    net_savings: Decimal
    savings_rate: float
    monthly_trends: List[MonthlyTrendItem]
    category_breakdown: List[CategoryBreakdownItem]

