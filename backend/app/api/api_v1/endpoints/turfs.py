from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import func
from typing import List, Optional

from app.db.session import get_db
from app.db.models import Turf, User as UserModel, Booking, Slot, Review
from app.schemas.schemas import Turf as TurfSchema, TurfCreate

from app.core.security import get_current_user
from app.core.websocket_manager import ws_manager

router = APIRouter()

async def get_turf_rating_info(db: AsyncSession, turf_id: int):
    # Calculate average rating and total reviews
    result = await db.execute(
        select(
            func.avg(Review.rating).label("average"),
            func.count(Review.id).label("count")
        ).filter(Review.turf_id == turf_id)
    )
    rating_data = result.one()
    return {
        "average_rating": float(rating_data.average) if rating_data.average else 0.0,
        "total_reviews": int(rating_data.count) if rating_data.count else 0
    }

@router.get("/stats")
async def read_turf_stats(
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    firebase_uid = current_user.get("uid")
    user_result = await db.execute(select(UserModel).filter(UserModel.firebase_uid == firebase_uid))
    user = user_result.scalar_one_or_none()
    
    if not user:
        # This is a valid 404 if the user sync hasn't happened yet
        raise HTTPException(status_code=404, detail="User not found")

    # Get all turfs owned by this user
    turfs_result = await db.execute(select(Turf).filter(Turf.owner_id == user.id))
    turfs = turfs_result.scalars().all()
    turf_ids = [t.id for t in turfs]

    if not turf_ids:
        return {"total_revenue": 0, "total_bookings": 0, "active_turfs": 0}

    # Get total bookings
    bookings_result = await db.execute(select(Booking).filter(Booking.turf_id.in_(turf_ids)))
    bookings = bookings_result.scalars().all()
    
    total_revenue = sum(b.total_price for b in bookings)
    total_bookings = len(bookings)

    return {
        "total_revenue": total_revenue,
        "total_bookings": total_bookings,
        "active_turfs": len(turf_ids)
    }

@router.get("/", response_model=List[TurfSchema])
async def read_turfs(
    skip: int = 0, 
    limit: int = 100, 
    owner_id: Optional[int] = None,
    search: Optional[str] = None,
    sport_type: Optional[str] = None,
    date: Optional[str] = None,
    db: AsyncSession = Depends(get_db)
):
    query = select(Turf)
    if owner_id:
        query = query.filter(Turf.owner_id == owner_id)
    if search:
        query = query.filter(Turf.name.ilike(f"%{search}%"))
    if sport_type and sport_type != "All Sports":
        query = query.filter(Turf.sport_types.ilike(f"%{sport_type}%"))
    
    result = await db.execute(query.offset(skip).limit(limit))
    turfs = result.scalars().all()
    
    # Add rating info to each turf
    for turf in turfs:
        rating_info = await get_turf_rating_info(db, turf.id)
        turf.average_rating = rating_info["average_rating"]
        turf.total_reviews = rating_info["total_reviews"]
        
    return turfs

@router.post("/", response_model=TurfSchema)
async def create_turf(
    turf: TurfCreate, 
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    # Get current user from DB to get the integer ID
    firebase_uid = current_user.get("uid")
    user_result = await db.execute(select(UserModel).filter(UserModel.firebase_uid == firebase_uid))
    db_user = user_result.scalar_one_or_none()
    
    turf_data = turf.model_dump()
    if db_user:
        turf_data["owner_id"] = db_user.id
        
    db_turf = Turf(**turf_data)
    db.add(db_turf)
    await db.commit()
    await db.refresh(db_turf)
    
    # Initialize with 0 ratings
    db_turf.average_rating = 0.0
    db_turf.total_reviews = 0

    await ws_manager.broadcast("booking_updates", {
        "type": "turf_created",
        "turf_id": db_turf.id,
        "name": db_turf.name,
    })

    return db_turf

@router.get("/my-turfs", response_model=List[TurfSchema])
async def read_my_turfs(
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    firebase_uid = current_user.get("uid")
    user_result = await db.execute(select(UserModel).filter(UserModel.firebase_uid == firebase_uid))
    user = user_result.scalar_one_or_none()
    
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    query = select(Turf).filter(Turf.owner_id == user.id)
    result = await db.execute(query)
    turfs = result.scalars().all()
    
    for turf in turfs:
        rating_info = await get_turf_rating_info(db, turf.id)
        turf.average_rating = rating_info["average_rating"]
        turf.total_reviews = rating_info["total_reviews"]
        
    return turfs

@router.get("/{turf_id}", response_model=TurfSchema)
async def read_turf(turf_id: int, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Turf).filter(Turf.id == turf_id))
    turf = result.scalar_one_or_none()
    if turf is None:
        raise HTTPException(status_code=404, detail="Turf not found")
        
    rating_info = await get_turf_rating_info(db, turf.id)
    turf.average_rating = rating_info["average_rating"]
    turf.total_reviews = rating_info["total_reviews"]
    
    return turf

@router.put("/{turf_id}", response_model=TurfSchema)
async def update_turf(
    turf_id: int, 
    turf_in: TurfCreate, 
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    firebase_uid = current_user.get("uid")
    user_result = await db.execute(select(UserModel).filter(UserModel.firebase_uid == firebase_uid))
    user = user_result.scalar_one_or_none()

    result = await db.execute(select(Turf).filter(Turf.id == turf_id))
    db_turf = result.scalar_one_or_none()
    
    if db_turf is None:
        raise HTTPException(status_code=404, detail="Turf not found")
    
    # Check if user is owner or admin
    if user.role != "admin" and db_turf.owner_id != user.id:
        raise HTTPException(status_code=403, detail="Not authorized to update this turf")
    
    update_data = turf_in.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(db_turf, key, value)
    
    db.add(db_turf)
    await db.commit()
    await db.refresh(db_turf)
    
    rating_info = await get_turf_rating_info(db, db_turf.id)
    db_turf.average_rating = rating_info["average_rating"]
    db_turf.total_reviews = rating_info["total_reviews"]
    
    return db_turf

@router.delete("/{turf_id}")
async def delete_turf(
    turf_id: int, 
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    firebase_uid = current_user.get("uid")
    user_result = await db.execute(select(UserModel).filter(UserModel.firebase_uid == firebase_uid))
    user = user_result.scalar_one_or_none()

    result = await db.execute(select(Turf).filter(Turf.id == turf_id))
    db_turf = result.scalar_one_or_none()
    
    if db_turf is None:
        raise HTTPException(status_code=404, detail="Turf not found")
    
    # Check if user is owner or admin
    if user.role != "admin" and db_turf.owner_id != user.id:
        raise HTTPException(status_code=403, detail="Not authorized to delete this turf")
    
    await db.delete(db_turf)
    await db.commit()
    return {"message": "Turf deleted successfully"}
