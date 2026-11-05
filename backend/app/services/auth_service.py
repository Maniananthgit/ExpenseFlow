import uuid
from typing import List, Dict, Any
from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from app.models.user import User
from app.models.category import Category
from app.repositories.user_repo import user_repo
from app.schemas.user import UserCreate, UserUpdate
from app.schemas.auth import ChangePasswordRequest
from app.core.security import get_password_hash, verify_password, create_access_token

DEFAULT_INCOME_CATEGORIES: List[Dict[str, Any]] = [
    {"name": "Salary", "type": "INCOME", "color": "#10B981", "icon": "payments"},
    {"name": "Freelancing", "type": "INCOME", "color": "#06B6D4", "icon": "laptop"},
    {"name": "Business", "type": "INCOME", "color": "#3B82F6", "icon": "business"},
    {"name": "Investment", "type": "INCOME", "color": "#8B5CF6", "icon": "trending_up"},
    {"name": "Other", "type": "INCOME", "color": "#6B7280", "icon": "more_horiz"},
]

DEFAULT_EXPENSE_CATEGORIES: List[Dict[str, Any]] = [
    {"name": "Food", "type": "EXPENSE", "color": "#F59E0B", "icon": "restaurant"},
    {"name": "Transportation", "type": "EXPENSE", "color": "#3B82F6", "icon": "directions_car"},
    {"name": "Shopping", "type": "EXPENSE", "color": "#EC4899", "icon": "shopping_bag"},
    {"name": "Healthcare", "type": "EXPENSE", "color": "#EF4444", "icon": "local_hospital"},
    {"name": "Education", "type": "EXPENSE", "color": "#8B5CF6", "icon": "school"},
    {"name": "Bills", "type": "EXPENSE", "color": "#F97316", "icon": "receipt_long"},
    {"name": "Entertainment", "type": "EXPENSE", "color": "#6366F1", "icon": "movie"},
    {"name": "Other", "type": "EXPENSE", "color": "#6B7280", "icon": "more_horiz"},
]


class AuthService:
    def register(self, db: Session, user_in: UserCreate) -> User:
        existing_user = user_repo.get_by_email(db, user_in.email)
        if existing_user:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="A user with this email already exists.",
            )

        hashed_password = get_password_hash(user_in.password)
        user = User(
            email=user_in.email.lower().strip(),
            hashed_password=hashed_password,
            full_name=user_in.full_name.strip(),
            currency=user_in.currency.strip().upper(),
            is_active=True,
        )
        db.add(user)
        db.flush()

        # Seed initial default categories for this user
        for cat_data in DEFAULT_INCOME_CATEGORIES + DEFAULT_EXPENSE_CATEGORIES:
            cat = Category(
                user_id=user.id,
                name=cat_data["name"],
                type=cat_data["type"],
                color=cat_data["color"],
                icon=cat_data["icon"],
                is_system=True,
            )
            db.add(cat)

        db.commit()
        db.refresh(user)
        return user

    def authenticate(self, db: Session, email: str, password: str) -> User:
        user = user_repo.get_by_email(db, email)
        if not user:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Incorrect email or password.",
                headers={"WWW-Authenticate": "Bearer"},
            )
        if not verify_password(password, user.hashed_password):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Incorrect email or password.",
                headers={"WWW-Authenticate": "Bearer"},
            )
        if not user.is_active:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="User account is inactive.",
            )
        return user

    def update_profile(self, db: Session, user: User, update_in: UserUpdate) -> User:
        if update_in.email and update_in.email.lower().strip() != user.email:
            existing = user_repo.get_by_email(db, update_in.email)
            if existing and existing.id != user.id:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Email is already taken by another account.",
                )
            user.email = update_in.email.lower().strip()
        
        if update_in.full_name:
            user.full_name = update_in.full_name.strip()
        if update_in.currency:
            user.currency = update_in.currency.strip().upper()

        db.commit()
        db.refresh(user)
        return user

    def change_password(self, db: Session, user: User, pass_in: ChangePasswordRequest) -> None:
        if not verify_password(pass_in.current_password, user.hashed_password):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Current password does not match.",
            )
        if len(pass_in.new_password) < 6:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="New password must be at least 6 characters.",
            )
        user.hashed_password = get_password_hash(pass_in.new_password)
        db.commit()


auth_service = AuthService()

