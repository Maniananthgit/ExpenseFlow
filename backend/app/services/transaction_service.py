import math
import uuid
from datetime import date
from typing import Optional
from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from app.models.transaction import Transaction
from app.repositories.transaction_repo import transaction_repo
from app.repositories.category_repo import category_repo
from app.schemas.transaction import TransactionCreate, TransactionUpdate, TransactionListResponse, TransactionResponse


class TransactionService:
    def create_transaction(
        self, db: Session, user_id: uuid.UUID, transaction_in: TransactionCreate
    ) -> Transaction:
        # Validate that category exists and matches transaction type
        category = category_repo.get_user_category_by_id(db, transaction_in.category_id, user_id)
        if not category:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Category not found.",
            )
        if category.type != transaction_in.type:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Category type '{category.type}' does not match transaction type '{transaction_in.type}'.",
            )

        transaction = Transaction(
            user_id=user_id,
            category_id=transaction_in.category_id,
            amount=transaction_in.amount,
            type=transaction_in.type,
            description=transaction_in.description.strip() if transaction_in.description else None,
            transaction_date=transaction_in.transaction_date,
        )
        return transaction_repo.create(db, transaction)

    def get_transaction(
        self, db: Session, user_id: uuid.UUID, transaction_id: uuid.UUID
    ) -> Transaction:
        transaction = transaction_repo.get_by_user_and_id(db, user_id, transaction_id)
        if not transaction:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Transaction not found.",
            )
        return transaction

    def list_transactions(
        self,
        db: Session,
        user_id: uuid.UUID,
        type: Optional[str] = None,
        category_id: Optional[uuid.UUID] = None,
        start_date: Optional[date] = None,
        end_date: Optional[date] = None,
        search: Optional[str] = None,
        page: int = 1,
        page_size: int = 20,
    ) -> TransactionListResponse:
        page = max(1, page)
        page_size = min(max(1, page_size), 100)
        skip = (page - 1) * page_size

        items, total = transaction_repo.get_filtered(
            db=db,
            user_id=user_id,
            type=type,
            category_id=category_id,
            start_date=start_date,
            end_date=end_date,
            search=search,
            skip=skip,
            limit=page_size,
        )

        total_pages = math.ceil(total / page_size) if total > 0 else 1

        return TransactionListResponse(
            items=[TransactionResponse.model_validate(item) for item in items],
            total=total,
            page=page,
            page_size=page_size,
            total_pages=total_pages,
        )

    def update_transaction(
        self, db: Session, user_id: uuid.UUID, transaction_id: uuid.UUID, update_in: TransactionUpdate
    ) -> Transaction:
        transaction = self.get_transaction(db, user_id, transaction_id)

        target_type = update_in.type or transaction.type
        target_category_id = update_in.category_id or transaction.category_id

        if update_in.category_id or update_in.type:
            category = category_repo.get_user_category_by_id(db, target_category_id, user_id)
            if not category:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Category not found.",
                )
            if category.type != target_type:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Category type '{category.type}' does not match transaction type '{target_type}'.",
                )
            transaction.category_id = target_category_id
            transaction.type = target_type

        if update_in.amount is not None:
            transaction.amount = update_in.amount
        if update_in.description is not None:
            transaction.description = update_in.description.strip() if update_in.description else None
        if update_in.transaction_date is not None:
            transaction.transaction_date = update_in.transaction_date

        db.commit()
        db.refresh(transaction)
        return transaction

    def delete_transaction(self, db: Session, user_id: uuid.UUID, transaction_id: uuid.UUID) -> None:
        transaction = self.get_transaction(db, user_id, transaction_id)
        db.delete(transaction)
        db.commit()


transaction_service = TransactionService()

