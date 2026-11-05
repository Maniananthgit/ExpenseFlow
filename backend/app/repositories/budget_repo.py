import uuid
from decimal import Decimal
from typing import List, Optional
from sqlalchemy.orm import Session, joinedload
from sqlalchemy import func, extract
from app.models.budget import Budget
from app.models.transaction import Transaction
from app.repositories.base import BaseRepository


class BudgetRepository(BaseRepository[Budget]):
    def __init__(self):
        super().__init__(Budget)

    def get_by_user_and_id(self, db: Session, user_id: uuid.UUID, budget_id: uuid.UUID) -> Optional[Budget]:
        return db.query(Budget).options(
            joinedload(Budget.category)
        ).filter(
            Budget.id == budget_id,
            Budget.user_id == user_id
        ).first()

    def get_user_budgets(self, db: Session, user_id: uuid.UUID, month: int, year: int) -> List[Budget]:
        return db.query(Budget).options(
            joinedload(Budget.category)
        ).filter(
            Budget.user_id == user_id,
            Budget.month == month,
            Budget.year == year,
        ).all()

    def get_by_category_and_period(
        self, db: Session, user_id: uuid.UUID, category_id: uuid.UUID, month: int, year: int
    ) -> Optional[Budget]:
        return db.query(Budget).filter(
            Budget.user_id == user_id,
            Budget.category_id == category_id,
            Budget.month == month,
            Budget.year == year,
        ).first()

    def get_spent_for_category(
        self, db: Session, user_id: uuid.UUID, category_id: uuid.UUID, month: int, year: int
    ) -> Decimal:
        val = db.query(func.coalesce(func.sum(Transaction.amount), 0)).filter(
            Transaction.user_id == user_id,
            Transaction.category_id == category_id,
            Transaction.type == "EXPENSE",
            extract("month", Transaction.transaction_date) == month,
            extract("year", Transaction.transaction_date) == year,
        ).scalar()
        return Decimal(str(val or 0.00))


budget_repo = BudgetRepository()
