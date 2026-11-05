import uuid
from decimal import Decimal
from typing import List
from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from app.models.budget import Budget
from app.repositories.budget_repo import budget_repo
from app.repositories.category_repo import category_repo
from app.schemas.budget import BudgetCreate, BudgetUpdate, BudgetResponse, BudgetSummaryResponse


class BudgetService:
    def _enrich_budget(self, db: Session, budget: Budget) -> BudgetResponse:
        spent = budget_repo.get_spent_for_category(
            db=db,
            user_id=budget.user_id,
            category_id=budget.category_id,
            month=budget.month,
            year=budget.year,
        )
        remaining = budget.amount - spent
        utilization = float((spent / budget.amount) * Decimal("100.00")) if budget.amount > 0 else 0.0
        is_exceeded = spent > budget.amount

        resp = BudgetResponse.model_validate(budget)
        resp.spent_amount = spent
        resp.remaining_amount = remaining
        resp.utilization_percentage = round(utilization, 2)
        resp.is_exceeded = is_exceeded
        return resp

    def create_budget(self, db: Session, user_id: uuid.UUID, budget_in: BudgetCreate) -> BudgetResponse:
        # Validate category
        category = category_repo.get_user_category_by_id(db, budget_in.category_id, user_id)
        if not category:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Category not found.",
            )
        if category.type != "EXPENSE":
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Budgets can only be assigned to EXPENSE categories.",
            )

        existing = budget_repo.get_by_category_and_period(
            db, user_id, budget_in.category_id, budget_in.month, budget_in.year
        )
        if existing:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="A budget for this category and month/year already exists. Edit the existing budget instead.",
            )

        budget = Budget(
            user_id=user_id,
            category_id=budget_in.category_id,
            amount=budget_in.amount,
            month=budget_in.month,
            year=budget_in.year,
        )
        saved = budget_repo.create(db, budget)
        return self._enrich_budget(db, saved)

    def get_budgets(self, db: Session, user_id: uuid.UUID, month: int, year: int) -> BudgetSummaryResponse:
        budgets = budget_repo.get_user_budgets(db, user_id, month, year)
        enriched = [self._enrich_budget(db, b) for b in budgets]

        total_budget = sum((b.amount for b in enriched), Decimal("0.00"))
        total_spent = sum((b.spent_amount for b in enriched), Decimal("0.00"))
        total_remaining = total_budget - total_spent
        overall_utilization = float((total_spent / total_budget) * Decimal("100.00")) if total_budget > 0 else 0.0

        return BudgetSummaryResponse(
            total_budget=total_budget,
            total_spent=total_spent,
            total_remaining=total_remaining,
            overall_utilization=round(overall_utilization, 2),
            budgets=enriched,
        )

    def get_budget(self, db: Session, user_id: uuid.UUID, budget_id: uuid.UUID) -> BudgetResponse:
        budget = budget_repo.get_by_user_and_id(db, user_id, budget_id)
        if not budget:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Budget not found.",
            )
        return self._enrich_budget(db, budget)

    def update_budget(
        self, db: Session, user_id: uuid.UUID, budget_id: uuid.UUID, update_in: BudgetUpdate
    ) -> BudgetResponse:
        budget = budget_repo.get_by_user_and_id(db, user_id, budget_id)
        if not budget:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Budget not found.",
            )

        if update_in.amount is not None:
            budget.amount = update_in.amount
        if update_in.month is not None:
            budget.month = update_in.month
        if update_in.year is not None:
            budget.year = update_in.year
        if update_in.category_id is not None:
            category = category_repo.get_user_category_by_id(db, update_in.category_id, user_id)
            if not category or category.type != "EXPENSE":
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Invalid expense category.",
                )
            budget.category_id = update_in.category_id

        db.commit()
        db.refresh(budget)
        return self._enrich_budget(db, budget)

    def delete_budget(self, db: Session, user_id: uuid.UUID, budget_id: uuid.UUID) -> None:
        budget = budget_repo.get_by_user_and_id(db, user_id, budget_id)
        if not budget:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Budget not found.",
            )
        db.delete(budget)
        db.commit()


budget_service = BudgetService()

