from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from typing import List, Optional

from app.db.session import get_db
from app.db.models import User, FCMToken, Wallet, WalletTransaction, Referral
from app.schemas.schemas import (
    User as UserSchema, UserCreate, FCMTokenCreate, FCMToken as FCMTokenSchema,
    UserUpdateRole, WalletResponse, WalletTransactionResponse, ReferralResponse
)
from app.core.security import get_current_user
from app.core.websocket_manager import ws_manager
import logging

logger = logging.getLogger(__name__)

router = APIRouter()

async def get_db_user(db: AsyncSession, firebase_uid: str) -> User:
    result = await db.execute(select(User).filter(User.firebase_uid == firebase_uid))
    return result.scalar_one_or_none()

@router.get("/check-availability")
async def check_availability(
    email: Optional[str] = None,
    phone: Optional[str] = None,
    db: AsyncSession = Depends(get_db)
):
    """Real-time validation endpoint for signup form checking email/phone existence."""
    if email:
        email_clean = email.strip().lower()
        query = await db.execute(select(User).filter(User.email == email_clean))
        if query.scalar_one_or_none():
            return {"available": False, "field": "email", "message": "Email is already registered"}
    if phone:
        phone_clean = phone.strip()
        query = await db.execute(select(User).filter(User.phone == phone_clean))
        if query.scalar_one_or_none():
            return {"available": False, "field": "phone", "message": "Phone number is already registered"}
    return {"available": True, "message": "Available"}

@router.get("/", response_model=List[UserSchema])
async def read_users(
    skip: int = 0,
    limit: int = 100,
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    # Check if current user is admin
    db_user = await get_db_user(db, current_user.get("uid"))
    if not db_user or db_user.role != "admin":
        raise HTTPException(status_code=403, detail="Not enough permissions")
        
    result = await db.execute(select(User).offset(skip).limit(limit))
    return result.scalars().all()

@router.patch("/{user_id}/role", response_model=UserSchema)
async def update_user_role(
    user_id: int,
    role_update: UserUpdateRole,
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    # Check if current user is admin
    admin_user = await get_db_user(db, current_user.get("uid"))
    if not admin_user or admin_user.role != "admin":
        raise HTTPException(status_code=403, detail="Not enough permissions")
        
    result = await db.execute(select(User).filter(User.id == user_id))
    db_user = result.scalar_one_or_none()
    
    if not db_user:
        raise HTTPException(status_code=404, detail="User not found")
        
    db_user.role = role_update.role
    db.add(db_user)
    await db.commit()
    await db.refresh(db_user)
    return db_user

@router.post("/fcm-token", response_model=FCMTokenSchema)
async def register_fcm_token(
    fcm_data: FCMTokenCreate,
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    firebase_uid = current_user.get("uid")
    result = await db.execute(select(User).filter(User.firebase_uid == firebase_uid))
    db_user = result.scalar_one_or_none()
    
    if not db_user:
        raise HTTPException(status_code=404, detail="User not found")
        
    # Check if token already exists for this user
    token_result = await db.execute(
        select(FCMToken).filter(FCMToken.user_id == db_user.id, FCMToken.token == fcm_data.token)
    )
    existing_token = token_result.scalar_one_or_none()
    
    if existing_token:
        return existing_token
        
    # Optional: If token exists for ANOTHER user, we might want to delete it or update it.
    # For now, just create a new record.
    new_token = FCMToken(user_id=db_user.id, token=fcm_data.token)
    db.add(new_token)
    await db.commit()
    await db.refresh(new_token)
    return new_token

@router.get("/me", response_model=UserSchema)
async def read_user_me(
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    firebase_uid = current_user.get("uid")
    logger.info(f"read_user_me: firebase_uid={firebase_uid}")
    result = await db.execute(select(User).filter(User.firebase_uid == firebase_uid))
    user = result.scalar_one_or_none()
    if user is None:
        logger.warning(f"read_user_me: User not found in DB for firebase_uid={firebase_uid}")
        raise HTTPException(status_code=404, detail="User not found")
    return user

@router.post("/", response_model=UserSchema)
async def create_user(user: UserCreate, db: AsyncSession = Depends(get_db)):
    logger.info(f"create_user: firebase_uid={user.firebase_uid}, email={user.email}")
    # Check if user already exists by email
    email = user.email or f"{user.firebase_uid}@placeholder.com"
    result = await db.execute(select(User).filter(User.email == email))
    db_user = result.scalar_one_or_none()
    
    if db_user:
        logger.info(f"create_user: User found by email={email}, updating firebase_uid to {user.firebase_uid}")
        # If user exists by email, update their firebase_uid to sync with current login
        db_user.firebase_uid = user.firebase_uid
        # Ensure name is updated if it was "User" or empty
        full_name = user.full_name or db_user.full_name or "User"
        db_user.full_name = full_name
        db_user.email = email

        # Assign roles based on specific emails during sync
        if email == "admin@example.com":
            db_user.role = "admin"
        elif email == "owner@example.com":
            db_user.role = "owner"
            
        db.add(db_user)
        await db.commit()
        await db.refresh(db_user)
        return db_user
    
    logger.info(f"create_user: Creating NEW user for firebase_uid={user.firebase_uid}")
    user_data = user.model_dump()
    user_data["email"] = email
    user_data["full_name"] = user.full_name or "User"
    
    # Assign roles based on specific emails
    if user_data.get("email") == "admin@example.com":
        user_data["role"] = "admin"
    elif user_data.get("email") == "owner@example.com":
        user_data["role"] = "owner"
    
    new_user = User(**user_data)
    db.add(new_user)
    await db.commit()
    await db.refresh(new_user)

    # Real-time WebSocket broadcast for new user registration
    await ws_manager.broadcast("community", {
        "type": "new_user_joined",
        "user": {
            "id": new_user.id,
            "name": new_user.full_name,
            "email": new_user.email,
            "role": new_user.role,
        }
    })

    return new_user

@router.put("/me", response_model=UserSchema)
async def update_user_me(
    user_in: UserCreate,
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    firebase_uid = current_user.get("uid")
    result = await db.execute(select(User).filter(User.firebase_uid == firebase_uid))
    user = result.scalar_one_or_none()
    
    if user is None:
        raise HTTPException(status_code=404, detail="User not found")
    
    update_data = user_in.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(user, key, value)
    
    db.add(user)
    await db.commit()
    await db.refresh(user)

    # Real-time WebSocket broadcast for live profile update
    await ws_manager.broadcast(f"user_{user.id}", {
        "type": "profile_updated",
        "user": {
            "id": user.id,
            "name": user.full_name,
            "email": user.email,
            "phone": user.phone,
        }
    })

    return user

@router.delete("/me")
async def delete_user_me(
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Delete current authenticated user account."""
    firebase_uid = current_user.get("uid")
    result = await db.execute(select(User).filter(User.firebase_uid == firebase_uid))
    user = result.scalar_one_or_none()
    
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
        
    await db.delete(user)
    await db.commit()
    return {"success": True, "message": "Account deleted successfully"}

@router.get("/wallet", response_model=WalletResponse)
async def get_user_wallet(
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Get persistent wallet balance and coins for authenticated user."""
    firebase_uid = current_user.get("uid")
    user = await get_db_user(db, firebase_uid)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    result = await db.execute(select(Wallet).filter(Wallet.user_id == user.id))
    wallet = result.scalar_one_or_none()
    if not wallet:
        wallet = Wallet(user_id=user.id, balance=500.0, coins=120)
        db.add(wallet)
        await db.commit()
        await db.refresh(wallet)
    return wallet

@router.post("/wallet/add-money", response_model=WalletResponse)
async def add_wallet_money(
    amount: float,
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Add funds to user wallet."""
    if amount <= 0:
        raise HTTPException(status_code=400, detail="Amount must be positive")
    firebase_uid = current_user.get("uid")
    user = await get_db_user(db, firebase_uid)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    result = await db.execute(select(Wallet).filter(Wallet.user_id == user.id))
    wallet = result.scalar_one_or_none()
    if not wallet:
        wallet = Wallet(user_id=user.id, balance=500.0 + amount, coins=120)
        db.add(wallet)
    else:
        wallet.balance += amount
        db.add(wallet)

    transaction = WalletTransaction(
        user_id=user.id,
        title="Wallet Top-Up",
        amount=amount,
        transaction_type="credit"
    )
    db.add(transaction)
    await db.commit()
    await db.refresh(wallet)
    return wallet

@router.get("/wallet/transactions", response_model=List[WalletTransactionResponse])
async def get_wallet_transactions(
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Get wallet transaction history."""
    firebase_uid = current_user.get("uid")
    user = await get_db_user(db, firebase_uid)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    result = await db.execute(
        select(WalletTransaction)
        .filter(WalletTransaction.user_id == user.id)
        .order_by(WalletTransaction.created_at.desc())
    )
    return result.scalars().all()

@router.get("/referral", response_model=ReferralResponse)
async def get_user_referral(
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Get user referral link and rewards stats."""
    firebase_uid = current_user.get("uid")
    user = await get_db_user(db, firebase_uid)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    referral_code = f"TURF{user.id:04d}"
    result = await db.execute(select(Referral).filter(Referral.referrer_id == user.id))
    referrals = result.scalars().all()

    total_rewards = sum(r.reward_amount for r in referrals if r.status == "completed")
    return ReferralResponse(
        referral_code=referral_code,
        total_referred=len(referrals),
        total_rewards=total_rewards
    )

@router.post("/become-owner", response_model=UserSchema)
async def become_venue_owner(
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Upgrade authenticated user to venue owner."""
    firebase_uid = current_user.get("uid")
    user = await get_db_user(db, firebase_uid)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    user.role = "owner"
    db.add(user)
    await db.commit()
    await db.refresh(user)
    return user

@router.post("/become-admin", response_model=UserSchema)
async def become_admin(
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Grant admin role to authenticated user for administrative access."""
    firebase_uid = current_user.get("uid")
    user = await get_db_user(db, firebase_uid)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    user.role = "admin"
    db.add(user)
    await db.commit()
    await db.refresh(user)
    return user



