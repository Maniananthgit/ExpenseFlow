import uuid
from typing import List, Optional, Literal
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session
from app.api.deps import get_db, get_current_user
from app.models.user import User
from app.schemas.category import CategoryCreate, CategoryUpdate, CategoryResponse
from app.services.category_service import category_service

router = APIRouter(prefix="/categories", tags=["Categories"])


@router.get("", response_model=List[CategoryResponse])
def get_categories(
    type: Optional[Literal["INCOME", "EXPENSE"]] = Query(None, description="Filter by category type"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """List all categories accessible to user (custom + system categories)."""
    return category_service.get_categories(db, current_user.id, type=type)


@router.post("", response_model=CategoryResponse, status_code=status.HTTP_201_CREATED)
def create_category(
    category_in: CategoryCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Create a new custom category."""
    return category_service.create_category(db, current_user.id, category_in)


@router.put("/{category_id}", response_model=CategoryResponse)
def update_category(
    category_id: uuid.UUID,
    category_in: CategoryUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Update a custom category owned by the user."""
    return category_service.update_category(db, category_id, current_user.id, category_in)


@router.delete("/{category_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_category(
    category_id: uuid.UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Delete a custom category owned by the user."""
    category_service.delete_category(db, category_id, current_user.id)
    return None
