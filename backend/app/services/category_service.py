import uuid
from typing import List, Optional
from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from app.models.category import Category
from app.models.transaction import Transaction
from app.models.budget import Budget
from app.repositories.category_repo import category_repo
from app.schemas.category import CategoryCreate, CategoryUpdate


class CategoryService:
    def get_categories(self, db: Session, user_id: uuid.UUID, type: Optional[str] = None) -> List[Category]:
        return category_repo.get_for_user(db, user_id, type=type)

    def get_category(self, db: Session, category_id: uuid.UUID, user_id: uuid.UUID) -> Category:
        category = category_repo.get_user_category_by_id(db, category_id, user_id)
        if not category:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Category not found.",
            )
        return category

    def create_category(self, db: Session, user_id: uuid.UUID, category_in: CategoryCreate) -> Category:
        existing = category_repo.get_by_name_and_type(db, user_id, category_in.name, category_in.type)
        if existing:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Category '{category_in.name}' for {category_in.type.lower()} already exists.",
            )

        category = Category(
            user_id=user_id,
            name=category_in.name.strip(),
            type=category_in.type,
            color=category_in.color or "#3B82F6",
            icon=category_in.icon or "category",
            is_system=False,
        )
        return category_repo.create(db, category)

    def update_category(
        self, db: Session, category_id: uuid.UUID, user_id: uuid.UUID, update_in: CategoryUpdate
    ) -> Category:
        category = category_repo.get_user_owned_category_by_id(db, category_id, user_id)
        if not category:
            # Check if it's a system category
            system_cat = category_repo.get_user_category_by_id(db, category_id, user_id)
            if system_cat and system_cat.is_system:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="Default system categories cannot be modified.",
                )
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Category not found.",
            )

        if update_in.name is not None:
            category.name = update_in.name.strip()
        if update_in.type is not None:
            category.type = update_in.type
        if update_in.color is not None:
            category.color = update_in.color
        if update_in.icon is not None:
            category.icon = update_in.icon

        db.commit()
        db.refresh(category)
        return category

    def delete_category(self, db: Session, category_id: uuid.UUID, user_id: uuid.UUID) -> None:
        category = category_repo.get_user_owned_category_by_id(db, category_id, user_id)
        if not category:
            system_cat = category_repo.get_user_category_by_id(db, category_id, user_id)
            if system_cat and system_cat.is_system:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="Default system categories cannot be deleted.",
                )
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Category not found.",
            )

        # Check if transactions or budgets exist for this category
        has_transactions = db.query(Transaction).filter(
            Transaction.user_id == user_id,
            Transaction.category_id == category_id
        ).first()
        if has_transactions:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Cannot delete category because it has existing transactions.",
            )

        db.delete(category)
        db.commit()


category_service = CategoryService()

