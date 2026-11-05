import uuid
from datetime import date
from typing import Optional
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session
from app.api.deps import get_db, get_current_user
from app.models.user import User
from app.schemas.budget import (
    BudgetCreate,
    BudgetUpdate,
    BudgetResponse,
    BudgetSummaryResponse,
)
from app.services.budget_service import budget_service

router = APIRouter(prefix="/budgets", tags=["Budgets"])


@router.post("", response_model=BudgetResponse, status_code=status.HTTP_201_CREATED)
def create_budget(
    budget_in: BudgetCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Create a monthly category budget."""
    return budget_service.create_budget(db, current_user.id, budget_in)


@router.get("", response_model=BudgetSummaryResponse)
def get_budgets(
    month: Optional[int] = Query(None, ge=1, le=12, description="Month (1-12, defaults to current month)"),
    year: Optional[int] = Query(None, ge=2000, le=2100, description="Year (defaults to current year)"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Retrieve all category budgets for the specified month/year with real spending calculations."""
    today = date.today()
    m = month or today.month
    y = year or today.year
    return budget_service.get_budgets(db, current_user.id, m, y)


@router.get("/{budget_id}", response_model=BudgetResponse)
def get_budget(
    budget_id: uuid.UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Get single budget by ID."""
    return budget_service.get_budget(db, current_user.id, budget_id)


@router.put("/{budget_id}", response_model=BudgetResponse)
def update_budget(
    budget_id: uuid.UUID,
    budget_in: BudgetUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Update a budget amount or category."""
    return budget_service.update_budget(db, current_user.id, budget_id, budget_in)


@router.delete("/{budget_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_budget(
    budget_id: uuid.UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Delete a budget."""
    budget_service.delete_budget(db, current_user.id, budget_id)
    return None

