from fastapi import APIRouter, Depends, status, Request
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from app.api.deps import get_db, get_current_user
from app.models.user import User
from app.schemas.auth import Token, LoginRequest, ChangePasswordRequest
from app.schemas.user import UserCreate, UserUpdate, UserResponse
from app.services.auth_service import auth_service
from app.core.security import create_access_token

router = APIRouter(prefix="/auth", tags=["Authentication"])


@router.post("/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
def register(user_in: UserCreate, db: Session = Depends(get_db)):
    """Register a new user account and seed default categories."""
    return auth_service.register(db, user_in)


@router.post("/login", response_model=Token)
async def login(request: Request, db: Session = Depends(get_db)):
    """Authenticate user with email/password (supports JSON or Form data) and return JWT access token."""
    email = None
    password = None

    content_type = request.headers.get("content-type", "")
    if "application/json" in content_type:
        body = await request.json()
        email = body.get("email") or body.get("username")
        password = body.get("password")
    else:
        form = await request.form()
        email = form.get("username") or form.get("email")
        password = form.get("password")

    if not email or not password:
        user = auth_service.authenticate(db, "", "")
    else:
        user = auth_service.authenticate(db, str(email), str(password))

    access_token = create_access_token(subject=user.id)
    return Token(
        access_token=access_token,
        token_type="bearer",
        user=UserResponse.model_validate(user),
    )


@router.get("/me", response_model=UserResponse)
def get_current_user_profile(current_user: User = Depends(get_current_user)):
    """Retrieve the authenticated user's profile."""
    return current_user


@router.put("/me", response_model=UserResponse)
def update_profile(
    update_in: UserUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Update profile information (name, currency, email)."""
    return auth_service.update_profile(db, current_user, update_in)


@router.post("/change-password", status_code=status.HTTP_200_OK)
def change_password(
    pass_in: ChangePasswordRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Change the authenticated user's password."""
    auth_service.change_password(db, current_user, pass_in)
    return {"message": "Password updated successfully."}


@router.post("/logout", status_code=status.HTTP_200_OK)
def logout(current_user: User = Depends(get_current_user)):
    """Log out current user (token discarded client-side)."""
    return {"message": "Logged out successfully."}

