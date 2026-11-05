import uuid
from datetime import date
from typing import Optional, Literal
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session
from app.api.deps import get_db, get_current_user
from app.models.user import User
from app.schemas.transaction import (
    TransactionCreate,
    TransactionUpdate,
    TransactionResponse,
    TransactionListResponse,
)
from app.services.transaction_service import transaction_service

router = APIRouter(prefix="/transactions", tags=["Transactions"])


@router.post("", response_model=TransactionResponse, status_code=status.HTTP_201_CREATED)
def create_transaction(
    transaction_in: TransactionCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Add a new income or expense transaction."""
    return transaction_service.create_transaction(db, current_user.id, transaction_in)


@router.get("", response_model=TransactionListResponse)
def get_transactions(
    type: Optional[Literal["INCOME", "EXPENSE"]] = Query(None, description="Filter by transaction type"),
    category_id: Optional[uuid.UUID] = Query(None, description="Filter by category ID"),
    start_date: Optional[date] = Query(None, description="Filter from start date (inclusive)"),
    end_date: Optional[date] = Query(None, description="Filter to end date (inclusive)"),
    search: Optional[str] = Query(None, description="Search description or category name"),
    page: int = Query(1, ge=1, description="Page number"),
    page_size: int = Query(20, ge=1, le=100, description="Items per page"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Get paginated list of transactions with flexible filters."""
    return transaction_service.list_transactions(
        db=db,
        user_id=current_user.id,
        type=type,
        category_id=category_id,
        start_date=start_date,
        end_date=end_date,
        search=search,
        page=page,
        page_size=page_size,
    )


@router.get("/{transaction_id}", response_model=TransactionResponse)
def get_transaction(
    transaction_id: uuid.UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Get single transaction by ID."""
    return transaction_service.get_transaction(db, current_user.id, transaction_id)


@router.put("/{transaction_id}", response_model=TransactionResponse)
def update_transaction(
    transaction_id: uuid.UUID,
    transaction_in: TransactionUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Update an existing transaction."""
    return transaction_service.update_transaction(db, current_user.id, transaction_id, transaction_in)


@router.delete("/{transaction_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_transaction(
    transaction_id: uuid.UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Delete a transaction."""
    transaction_service.delete_transaction(db, current_user.id, transaction_id)
    return None
