from datetime import date
from typing import Optional
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from app.api.deps import get_db, get_current_user
from app.models.user import User
from app.schemas.dashboard import (
    DashboardSummary,
    DashboardCategoryBreakdown,
    DashboardMonthlyTrends,
)
from app.services.dashboard_service import dashboard_service

router = APIRouter(prefix="/dashboard", tags=["Dashboard"])


@router.get("/summary", response_model=DashboardSummary)
def get_dashboard_summary(
    month: Optional[int] = Query(None, ge=1, le=12, description="Month (defaults to current month)"),
    year: Optional[int] = Query(None, ge=2000, le=2100, description="Year (defaults to current year)"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Retrieve key financial metrics and recent transactions for dashboard."""
    return dashboard_service.get_summary(db, current_user, month, year)


@router.get("/monthly", response_model=DashboardMonthlyTrends)
def get_monthly_trends(
    year: Optional[int] = Query(None, ge=2000, le=2100, description="Year (defaults to current year)"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Retrieve 12-month spending and income trends for visual charts."""
    return dashboard_service.get_monthly_trends(db, current_user, year)


@router.get("/category-breakdown", response_model=DashboardCategoryBreakdown)
def get_category_breakdown(
    month: Optional[int] = Query(None, ge=1, le=12, description="Month (defaults to current month)"),
    year: Optional[int] = Query(None, ge=2000, le=2100, description="Year (defaults to current year)"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Retrieve category-wise spending and income proportions."""
    return dashboard_service.get_category_breakdown(db, current_user, month, year)
