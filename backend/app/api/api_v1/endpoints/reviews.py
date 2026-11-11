from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy.orm import selectinload
from typing import List

from app.db.session import get_db
from app.db.models import Review, User, Turf
from app.schemas.schemas import Review as ReviewSchema, ReviewCreate
from app.core.security import get_current_user
from app.core.websocket_manager import ws_manager

router = APIRouter()

@router.get("/{turf_id}", response_model=List[ReviewSchema])
async def read_turf_reviews(
    turf_id: int,
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(
        select(Review)
        .filter(Review.turf_id == turf_id)
        .options(selectinload(Review.user))
        .order_by(Review.created_at.desc())
    )
    reviews = result.scalars().all()
    return reviews

@router.post("/", response_model=ReviewSchema)
async def create_review(
    review_in: ReviewCreate,
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    firebase_uid = current_user.get("uid")
    user_result = await db.execute(select(User).filter(User.firebase_uid == firebase_uid))
    user = user_result.scalar_one_or_none()
    
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    new_review = Review(
        user_id=user.id,
        turf_id=review_in.turf_id,
        rating=review_in.rating,
        comment=review_in.comment
    )
    db.add(new_review)
    await db.commit()
    await db.refresh(new_review)
    
    # Reload with user relationship
    result = await db.execute(
        select(Review)
        .filter(Review.id == new_review.id)
        .options(selectinload(Review.user))
    )
    loaded_review = result.scalar_one()

    await ws_manager.broadcast(f"reviews_{review_in.turf_id}", {
        "type": "new_review",
        "id": loaded_review.id,
        "turf_id": loaded_review.turf_id,
        "rating": loaded_review.rating,
        "comment": loaded_review.comment,
        "user_name": user.full_name or user.email or "Player",
    })

    return loaded_review
