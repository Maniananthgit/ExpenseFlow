import calendar
import uuid
from datetime import date
from decimal import Decimal
from typing import List, Optional
from sqlalchemy.orm import Session
from app.models.user import User
from app.repositories.transaction_repo import transaction_repo
from app.schemas.dashboard import (
    DashboardSummary,
    DashboardCategoryBreakdown,
    DashboardMonthlyTrends,
    CategoryBreakdownItem,
    MonthlyTrendItem,
)
from app.schemas.transaction import TransactionResponse


class DashboardService:
    def get_summary(
        self, db: Session, user: User, month: Optional[int] = None, year: Optional[int] = None
    ) -> DashboardSummary:
        today = date.today()
        m = month or today.month
        y = year or today.year

        # Month date range
        _, last_day = calendar.monthrange(y, m)
        month_start = date(y, m, 1)
        month_end = date(y, m, last_day)

        # Lifetime totals
        total_income = transaction_repo.get_total_by_type(db, user.id, "INCOME")
        total_expenses = transaction_repo.get_total_by_type(db, user.id, "EXPENSE")
        current_balance = total_income - total_expenses

        # Monthly totals
        monthly_income = transaction_repo.get_total_by_type(db, user.id, "INCOME", month_start, month_end)
        monthly_spending = transaction_repo.get_total_by_type(db, user.id, "EXPENSE", month_start, month_end)
        monthly_savings = monthly_income - monthly_spending
        savings_rate = (
            float((monthly_savings / monthly_income) * Decimal("100.00"))
            if monthly_income > Decimal("0.00")
            else 0.0
        )

        # Recent transactions
        recent_txs = transaction_repo.get_recent(db, user.id, limit=5)
        recent_serialized = [TransactionResponse.model_validate(t) for t in recent_txs]

        return DashboardSummary(
            currency=user.currency,
            total_income=total_income,
            total_expenses=total_expenses,
            current_balance=current_balance,
            monthly_income=monthly_income,
            monthly_spending=monthly_spending,
            monthly_savings=monthly_savings,
            savings_rate=round(savings_rate, 2),
            recent_transactions=recent_serialized,
        )

    def get_category_breakdown(
        self, db: Session, user: User, month: Optional[int] = None, year: Optional[int] = None
    ) -> DashboardCategoryBreakdown:
        today = date.today()
        m = month or today.month
        y = year or today.year

        _, last_day = calendar.monthrange(y, m)
        start_date = date(y, m, 1)
        end_date = date(y, m, last_day)

        income_rows = transaction_repo.get_category_breakdown(db, user.id, "INCOME", start_date, end_date)
        expense_rows = transaction_repo.get_category_breakdown(db, user.id, "EXPENSE", start_date, end_date)

        total_income = sum((r["total_amount"] for r in income_rows), Decimal("0.00"))
        total_expense = sum((r["total_amount"] for r in expense_rows), Decimal("0.00"))

        def build_items(rows: list, total: Decimal) -> List[CategoryBreakdownItem]:
            items = []
            for r in rows:
                amt = r["total_amount"]
                pct = float((amt / total) * Decimal("100.00")) if total > Decimal("0.00") else 0.0
                items.append(
                    CategoryBreakdownItem(
                        category_id=r["category_id"],
                        category_name=r["category_name"],
                        category_color=r["category_color"],
                        category_icon=r["category_icon"],
                        total_amount=amt,
                        percentage=round(pct, 2),
                        transaction_count=r["count"],
                    )
                )
            return items

        return DashboardCategoryBreakdown(
            currency=user.currency,
            month=m,
            year=y,
            income_categories=build_items(income_rows, total_income),
            expense_categories=build_items(expense_rows, total_expense),
        )

    def get_monthly_trends(
        self, db: Session, user: User, year: Optional[int] = None
    ) -> DashboardMonthlyTrends:
        y = year or date.today().year
        monthly_data = transaction_repo.get_monthly_sums(db, user.id, y)

        # Map by month: {month_num: {"INCOME": Decimal, "EXPENSE": Decimal}}
        matrix = {m: {"INCOME": Decimal("0.00"), "EXPENSE": Decimal("0.00")} for m in range(1, 13)}
        for row in monthly_data:
            m = row["month"]
            t = row["type"]
            if m in matrix and t in matrix[m]:
                matrix[m][t] = row["total_amount"]

        trends: List[MonthlyTrendItem] = []
        for m in range(1, 13):
            inc = matrix[m]["INCOME"]
            exp = matrix[m]["EXPENSE"]
            trends.append(
                MonthlyTrendItem(
                    month=m,
                    month_name=calendar.month_abbr[m],
                    year=y,
                    income=inc,
                    expense=exp,
                    net_savings=inc - exp,
                )
            )

        return DashboardMonthlyTrends(currency=user.currency, trends=trends)


dashboard_service = DashboardService()
