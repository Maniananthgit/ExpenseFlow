import csv
import io
import calendar
from datetime import date
from decimal import Decimal
from typing import Optional, List, Dict, Any
from sqlalchemy.orm import Session
from sqlalchemy import func, extract
from app.models.user import User
from app.models.transaction import Transaction
from app.models.category import Category
from app.repositories.transaction_repo import transaction_repo
from app.schemas.report import MonthlyReportResponse, YearlyReportResponse, DailyExpenseItem
from app.schemas.dashboard import CategoryBreakdownItem, MonthlyTrendItem


class ReportService:
    def get_monthly_report(
        self, db: Session, user: User, month: int, year: int
    ) -> MonthlyReportResponse:
        _, last_day = calendar.monthrange(year, month)
        start_date = date(year, month, 1)
        end_date = date(year, month, last_day)

        total_income = transaction_repo.get_total_by_type(db, user.id, "INCOME", start_date, end_date)
        total_expense = transaction_repo.get_total_by_type(db, user.id, "EXPENSE", start_date, end_date)
        net_savings = total_income - total_expense
        savings_rate = (
            float((net_savings / total_income) * Decimal("100.00"))
            if total_income > Decimal("0.00")
            else 0.0
        )

        expense_categories_raw = transaction_repo.get_category_breakdown(
            db, user.id, "EXPENSE", start_date, end_date
        )
        category_breakdown = []
        for r in expense_categories_raw:
            pct = (
                float((r["total_amount"] / total_expense) * Decimal("100.00"))
                if total_expense > Decimal("0.00")
                else 0.0
            )
            category_breakdown.append(
                CategoryBreakdownItem(
                    category_id=r["category_id"],
                    category_name=r["category_name"],
                    category_color=r["category_color"],
                    category_icon=r["category_icon"],
                    total_amount=r["total_amount"],
                    percentage=round(pct, 2),
                    transaction_count=r["count"],
                )
            )

        # Daily breakdown
        daily_rows = db.query(
            Transaction.transaction_date,
            Transaction.type,
            func.coalesce(func.sum(Transaction.amount), 0).label("total"),
        ).filter(
            Transaction.user_id == user.id,
            Transaction.transaction_date >= start_date,
            Transaction.transaction_date <= end_date,
        ).group_by(
            Transaction.transaction_date,
            Transaction.type,
        ).order_by(Transaction.transaction_date.asc()).all()

        daily_map: Dict[str, Dict[str, Decimal]] = {}
        for day in range(1, last_day + 1):
            d_str = date(year, month, day).isoformat()
            daily_map[d_str] = {"INCOME": Decimal("0.00"), "EXPENSE": Decimal("0.00")}

        for r in daily_rows:
            d_str = r.transaction_date.isoformat()
            if d_str in daily_map:
                daily_map[d_str][r.type] = Decimal(str(r.total or 0.00))

        daily_breakdown = [
            DailyExpenseItem(
                date=k,
                income=v["INCOME"],
                expense=v["EXPENSE"],
            )
            for k, v in sorted(daily_map.items())
        ]

        # Top 5 expenses
        top_txs = db.query(Transaction).join(Category).filter(
            Transaction.user_id == user.id,
            Transaction.type == "EXPENSE",
            Transaction.transaction_date >= start_date,
            Transaction.transaction_date <= end_date,
        ).order_by(Transaction.amount.desc()).limit(5).all()

        top_expenses = [
            {
                "id": str(t.id),
                "description": t.description or t.category.name,
                "category": t.category.name,
                "amount": float(t.amount),
                "date": t.transaction_date.isoformat(),
            }
            for t in top_txs
        ]

        return MonthlyReportResponse(
            currency=user.currency,
            month=month,
            year=year,
            month_name=calendar.month_name[month],
            total_income=total_income,
            total_expense=total_expense,
            net_savings=net_savings,
            savings_rate=round(savings_rate, 2),
            category_breakdown=category_breakdown,
            daily_breakdown=daily_breakdown,
            top_expenses=top_expenses,
        )

    def get_yearly_report(self, db: Session, user: User, year: int) -> YearlyReportResponse:
        start_date = date(year, 1, 1)
        end_date = date(year, 12, 31)

        total_income = transaction_repo.get_total_by_type(db, user.id, "INCOME", start_date, end_date)
        total_expense = transaction_repo.get_total_by_type(db, user.id, "EXPENSE", start_date, end_date)
        net_savings = total_income - total_expense
        savings_rate = (
            float((net_savings / total_income) * Decimal("100.00"))
            if total_income > Decimal("0.00")
            else 0.0
        )

        # Monthly trends
        monthly_data = transaction_repo.get_monthly_sums(db, user.id, year)
        matrix = {m: {"INCOME": Decimal("0.00"), "EXPENSE": Decimal("0.00")} for m in range(1, 13)}
        for row in monthly_data:
            m = row["month"]
            t = row["type"]
            if m in matrix and t in matrix[m]:
                matrix[m][t] = row["total_amount"]

        monthly_trends = [
            MonthlyTrendItem(
                month=m,
                month_name=calendar.month_abbr[m],
                year=year,
                income=matrix[m]["INCOME"],
                expense=matrix[m]["EXPENSE"],
                net_savings=matrix[m]["INCOME"] - matrix[m]["EXPENSE"],
            )
            for m in range(1, 13)
        ]

        # Category breakdown for the entire year
        expense_categories_raw = transaction_repo.get_category_breakdown(
            db, user.id, "EXPENSE", start_date, end_date
        )
        category_breakdown = []
        for r in expense_categories_raw:
            pct = (
                float((r["total_amount"] / total_expense) * Decimal("100.00"))
                if total_expense > Decimal("0.00")
                else 0.0
            )
            category_breakdown.append(
                CategoryBreakdownItem(
                    category_id=r["category_id"],
                    category_name=r["category_name"],
                    category_color=r["category_color"],
                    category_icon=r["category_icon"],
                    total_amount=r["total_amount"],
                    percentage=round(pct, 2),
                    transaction_count=r["count"],
                )
            )

        return YearlyReportResponse(
            currency=user.currency,
            year=year,
            total_income=total_income,
            total_expense=total_expense,
            net_savings=net_savings,
            savings_rate=round(savings_rate, 2),
            monthly_trends=monthly_trends,
            category_breakdown=category_breakdown,
        )

    def export_csv(
        self,
        db: Session,
        user: User,
        start_date: Optional[date] = None,
        end_date: Optional[date] = None,
        type: Optional[str] = None,
    ) -> str:
        items, _ = transaction_repo.get_filtered(
            db=db,
            user_id=user.id,
            type=type,
            start_date=start_date,
            end_date=end_date,
            skip=0,
            limit=100000,
        )

        output = io.StringIO()
        writer = csv.writer(output)
        writer.writerow(["Transaction ID", "Date", "Type", "Category", "Amount", "Currency", "Description", "Created At"])

        for t in items:
            writer.writerow([
                str(t.id),
                t.transaction_date.isoformat(),
                t.type,
                t.category.name if t.category else "Uncategorized",
                f"{t.amount:.2f}",
                user.currency,
                t.description or "",
                t.created_at.isoformat() if t.created_at else "",
            ])

        return output.getvalue()


report_service = ReportService()
