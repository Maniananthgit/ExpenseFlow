from datetime import date
from typing import Optional, Literal
from fastapi import APIRouter, Depends, Query, Response
from sqlalchemy.orm import Session
from app.api.deps import get_db, get_current_user
from app.models.user import User
from app.schemas.report import MonthlyReportResponse, YearlyReportResponse
from app.services.report_service import report_service

router = APIRouter(prefix="/reports", tags=["Reports"])


@router.get("/monthly", response_model=MonthlyReportResponse)
def get_monthly_report(
    month: Optional[int] = Query(None, ge=1, le=12, description="Month (defaults to current month)"),
    year: Optional[int] = Query(None, ge=2000, le=2100, description="Year (defaults to current year)"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Generate in-depth monthly report with daily spending and top expenses."""
    today = date.today()
    m = month or today.month
    y = year or today.year
    return report_service.get_monthly_report(db, current_user, m, y)


@router.get("/yearly", response_model=YearlyReportResponse)
def get_yearly_report(
    year: Optional[int] = Query(None, ge=2000, le=2100, description="Year (defaults to current year)"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Generate yearly financial report with full month-by-month trajectory."""
    y = year or date.today().year
    return report_service.get_yearly_report(db, current_user, y)


@router.get("/export")
def export_transactions_csv(
    start_date: Optional[date] = Query(None, description="Start date filter"),
    end_date: Optional[date] = Query(None, description="End date filter"),
    type: Optional[Literal["INCOME", "EXPENSE"]] = Query(None, description="Type filter"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Export transactions to standard CSV format."""
    csv_content = report_service.export_csv(
        db=db,
        user=current_user,
        start_date=start_date,
        end_date=end_date,
        type=type,
    )
    filename = f"expenseflow_transactions_{date.today().isoformat()}.csv"
    return Response(
        content=csv_content,
        media_type="text/csv",
        headers={"Content-Disposition": f'attachment; filename="{filename}"'},
    )
