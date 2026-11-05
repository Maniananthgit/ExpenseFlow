import uuid
from typing import List, Optional
from sqlalchemy.orm import Session
from sqlalchemy import or_
from app.models.category import Category
from app.repositories.base import BaseRepository


class CategoryRepository(BaseRepository[Category]):
    def __init__(self):
        super().__init__(Category)

    def get_for_user(self, db: Session, user_id: uuid.UUID, type: Optional[str] = None) -> List[Category]:
        """Gets all categories accessible to user: user-owned categories + default system categories."""
        query = db.query(Category).filter(
            or_(Category.user_id == user_id, Category.user_id.is_(None))
        )
        if type:
            query = query.filter(Category.type == type)
        return query.order_by(Category.is_system.desc(), Category.name.asc()).all()

    def get_user_category_by_id(self, db: Session, category_id: uuid.UUID, user_id: uuid.UUID) -> Optional[Category]:
        """Gets a category accessible to this user by ID."""
        return db.query(Category).filter(
            Category.id == category_id,
            or_(Category.user_id == user_id, Category.user_id.is_(None))
        ).first()

    def get_user_owned_category_by_id(self, db: Session, category_id: uuid.UUID, user_id: uuid.UUID) -> Optional[Category]:
        """Gets a custom category specifically owned by this user (can be modified/deleted)."""
        return db.query(Category).filter(
            Category.id == category_id,
            Category.user_id == user_id,
            Category.is_system.is_(False)
        ).first()

    def get_by_name_and_type(self, db: Session, user_id: uuid.UUID, name: str, type: str) -> Optional[Category]:
        return db.query(Category).filter(
            Category.name.ilike(name.strip()),
            Category.type == type,
            or_(Category.user_id == user_id, Category.user_id.is_(None))
        ).first()


category_repo = CategoryRepository()

