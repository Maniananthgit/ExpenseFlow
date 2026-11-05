import uuid
from datetime import date
from decimal import Decimal
from typing import List, Optional, Tuple, Dict, Any
from sqlalchemy.orm import Session, joinedload
from sqlalchemy import func, extract
from app.models.transaction import Transaction
from app.models.category import Category
from app.repositories.base import BaseRepository


class TransactionRepository(BaseRepository[Transaction]):
    def __init__(self):
        super().__init__(Transaction)

    def get_by_user_and_id(self, db: Session, user_id: uuid.UUID, transaction_id: uuid.UUID) -> Optional[Transaction]:
        return db.query(Transaction).options(
            joinedload(Transaction.category)
        ).filter(
            Transaction.id == transaction_id,
            Transaction.user_id == user_id
        ).first()

    def get_filtered(
        self,
        db: Session,
        user_id: uuid.UUID,
        type: Optional[str] = None,
        category_id: Optional[uuid.UUID] = None,
        start_date: Optional[date] = None,
        end_date: Optional[date] = None,
        search: Optional[str] = None,
        skip: int = 0,
        limit: int = 20,
    ) -> Tuple[List[Transaction], int]:
        query = db.query(Transaction).options(
            joinedload(Transaction.category)
        ).filter(Transaction.user_id == user_id)

        if type:
            query = query.filter(Transaction.type == type)
        if category_id:
            query = query.filter(Transaction.category_id == category_id)
        if start_date:
            query = query.filter(Transaction.transaction_date >= start_date)
        if end_date:
            query = query.filter(Transaction.transaction_date <= end_date)
        if search:
            search_pattern = f"%{search.strip()}%"
            query = query.join(Transaction.category).filter(
                (Transaction.description.ilike(search_pattern)) | (Category.name.ilike(search_pattern))
            )

        total = query.count()
        items = query.order_by(Transaction.transaction_date.desc(), Transaction.created_at.desc()).offset(skip).limit(limit).all()
        return items, total

    def get_total_by_type(
        self,
        db: Session,
        user_id: uuid.UUID,
        type: str,
        start_date: Optional[date] = None,
        end_date: Optional[date] = None,
    ) -> Decimal:
        query = db.query(func.coalesce(func.sum(Transaction.amount), 0)).filter(
            Transaction.user_id == user_id,
            Transaction.type == type,
        )
        if start_date:
            query = query.filter(Transaction.transaction_date >= start_date)
        if end_date:
            query = query.filter(Transaction.transaction_date <= end_date)
        
        val = query.scalar()
        return Decimal(str(val or 0.00))

    def get_category_breakdown(
        self,
        db: Session,
        user_id: uuid.UUID,
        type: str,
        start_date: Optional[date] = None,
        end_date: Optional[date] = None,
    ) -> List[Dict[str, Any]]:
        query = db.query(
            Category.id.label("category_id"),
            Category.name.label("category_name"),
            Category.color.label("category_color"),
            Category.icon.label("category_icon"),
            func.coalesce(func.sum(Transaction.amount), 0).label("total_amount"),
            func.count(Transaction.id).label("count"),
        ).join(
            Transaction, Transaction.category_id == Category.id
        ).filter(
            Transaction.user_id == user_id,
            Transaction.type == type,
        )

        if start_date:
            query = query.filter(Transaction.transaction_date >= start_date)
        if end_date:
            query = query.filter(Transaction.transaction_date <= end_date)

        rows = query.group_by(Category.id, Category.name, Category.color, Category.icon)\
                    .order_by(func.sum(Transaction.amount).desc())\
                    .all()

        return [
            {
                "category_id": r.category_id,
                "category_name": r.category_name,
                "category_color": r.category_color,
                "category_icon": r.category_icon,
                "total_amount": Decimal(str(r.total_amount or 0.00)),
                "count": r.count,
            }
            for r in rows
        ]

    def get_monthly_sums(
        self,
        db: Session,
        user_id: uuid.UUID,
        year: int,
    ) -> List[Dict[str, Any]]:
        rows = db.query(
            extract("month", Transaction.transaction_date).label("month"),
            Transaction.type.label("type"),
            func.coalesce(func.sum(Transaction.amount), 0).label("total_amount"),
        ).filter(
            Transaction.user_id == user_id,
            extract("year", Transaction.transaction_date) == year,
        ).group_by(
            extract("month", Transaction.transaction_date),
            Transaction.type,
        ).all()

        return [
            {
                "month": int(r.month),
                "type": r.type,
                "total_amount": Decimal(str(r.total_amount or 0.00)),
            }
            for r in rows
        ]

    def get_recent(self, db: Session, user_id: uuid.UUID, limit: int = 5) -> List[Transaction]:
        return db.query(Transaction).options(
            joinedload(Transaction.category)
        ).filter(
            Transaction.user_id == user_id
        ).order_by(
            Transaction.transaction_date.desc(),
            Transaction.created_at.desc()
        ).limit(limit).all()


transaction_repo = TransactionRepository()
