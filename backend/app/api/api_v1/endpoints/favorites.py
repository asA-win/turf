from fastapi import APIRouter, Depends, HTTPException, status, Response
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy.orm import joinedload
from typing import List, Optional

from app.db.session import get_db
from app.db.models import Favorite, User, Turf
from app.schemas.schemas import Favorite as FavoriteSchema, FavoriteCreate
from app.core.security import get_current_user

router = APIRouter()

@router.get("/", response_model=List[FavoriteSchema])
async def read_my_favorites(
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    firebase_uid = current_user.get("uid")
    user_result = await db.execute(select(User).filter(User.firebase_uid == firebase_uid))
    user = user_result.scalar_one_or_none()
    
    if not user:
        user = User(
            firebase_uid=firebase_uid,
            email=current_user.get("email", "user@example.com"),
            full_name=current_user.get("name", "Demo User"),
            role="user"
        )
        db.add(user)
        await db.commit()
        await db.refresh(user)


    # Use joinedload to ensure 'turf' is loaded for the schema
    result = await db.execute(
        select(Favorite)
        .options(joinedload(Favorite.turf))
        .filter(Favorite.user_id == user.id)
    )
    favorites = result.scalars().all()
    return favorites

@router.post("/", response_model=Optional[FavoriteSchema])
async def toggle_favorite(
    favorite_in: FavoriteCreate,
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    firebase_uid = current_user.get("uid")
    user_result = await db.execute(select(User).filter(User.firebase_uid == firebase_uid))
    user = user_result.scalar_one_or_none()
    
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    # Check if already exists
    exist_result = await db.execute(
        select(Favorite).filter(
            Favorite.user_id == user.id, 
            Favorite.turf_id == favorite_in.turf_id
        )
    )
    existing = exist_result.scalar_one_or_none()
    
    if existing:
        await db.delete(existing)
        await db.commit()
        return Response(status_code=status.HTTP_204_NO_CONTENT)

    new_fav = Favorite(user_id=user.id, turf_id=favorite_in.turf_id)
    db.add(new_fav)
    await db.commit()
    
    # Reload with turf joined for the response model
    final_result = await db.execute(
        select(Favorite)
        .options(joinedload(Favorite.turf))
        .filter(Favorite.id == new_fav.id)
    )
    return final_result.scalar_one()
