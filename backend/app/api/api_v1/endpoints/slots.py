from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import func
from typing import List, Optional
from datetime import datetime

from app.db.session import get_db
from app.db.models import Slot, Turf, User
from app.schemas.schemas import Slot as SlotSchema, SlotCreate
from app.core.security import get_current_user
from app.core.websocket_manager import ws_manager

router = APIRouter()

from datetime import timedelta

@router.get("/", response_model=List[SlotSchema])
async def read_slots(
    turf_id: int, 
    date: Optional[str] = None,
    skip: int = 0, 
    limit: int = 100, 
    db: AsyncSession = Depends(get_db)
):
    query = select(Slot).filter(Slot.turf_id == turf_id)
    
    if date:
        try:
            target_date = datetime.strptime(date, "%Y-%m-%d").date()
            query = query.filter(func.date(Slot.start_time) == target_date)
        except ValueError:
            pass # Ignore invalid date format
            
    result = await db.execute(query.order_by(Slot.start_time).offset(skip).limit(limit))
    slots = result.scalars().all()
    
    # Check for expired locks
    now = datetime.utcnow()
    for slot in slots:
        if slot.locked_until and slot.locked_until < now:
            slot.locked_until = None
            slot.locked_by = None
            # Note: We don't commit here to avoid slowing down GET requests, 
            # the status is just adjusted in the response. 
            # Actual cleanup happens during booking or explicit lock.
            
    return slots

@router.post("/{slot_id}/lock", response_model=SlotSchema)
async def lock_slot(
    slot_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    firebase_uid = current_user.get("uid")
    user_result = await db.execute(select(User).filter(User.firebase_uid == firebase_uid))
    user = user_result.scalar_one_or_none()

    # Use with_for_update to prevent race conditions during locking
    result = await db.execute(
        select(Slot).filter(Slot.id == slot_id).with_for_update()
    )
    slot = result.scalar_one_or_none()
    
    if not slot:
        raise HTTPException(status_code=404, detail="Slot not found")

    if slot.is_booked:
        raise HTTPException(status_code=400, detail="Slot already booked")

    now = datetime.utcnow()
    
    # If locked by someone else and not expired
    if slot.locked_until and slot.locked_until > now and slot.locked_by != user.id:
        raise HTTPException(status_code=400, detail="Slot is temporarily locked by another user")

    # Lock for 10 minutes
    slot.locked_until = now + timedelta(minutes=10)
    slot.locked_by = user.id
    
    await db.commit()
    await db.refresh(slot)

    # Real-time WebSocket broadcast to all users viewing this turf
    await ws_manager.broadcast(f"slots_{slot.turf_id}", {
        "type": "slot_locked",
        "slot_id": slot.id,
        "turf_id": slot.turf_id,
        "locked_until": slot.locked_until.isoformat() if slot.locked_until else None,
        "locked_by": slot.locked_by
    })

    return slot

@router.post("/", response_model=SlotSchema)
async def create_slot(
    slot: SlotCreate, 
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    # Verify authorization (only owner of the turf or admin)
    firebase_uid = current_user.get("uid")
    user_result = await db.execute(select(User).filter(User.firebase_uid == firebase_uid))
    user = user_result.scalar_one_or_none()

    turf_result = await db.execute(select(Turf).filter(Turf.id == slot.turf_id))
    turf = turf_result.scalar_one_or_none()

    if not turf:
        raise HTTPException(status_code=404, detail="Turf not found")
    
    if user.role != "admin" and turf.owner_id != user.id:
        raise HTTPException(status_code=403, detail="Not authorized to manage slots for this turf")

    db_slot = Slot(**slot.model_dump())
    db.add(db_slot)
    await db.commit()
    await db.refresh(db_slot)

    # Real-time WebSocket broadcast to all users viewing this turf
    await ws_manager.broadcast(f"slots_{db_slot.turf_id}", {
        "type": "slot_created",
        "slot_id": db_slot.id,
        "turf_id": db_slot.turf_id,
        "start_time": db_slot.start_time.isoformat() if db_slot.start_time else None,
        "end_time": db_slot.end_time.isoformat() if db_slot.end_time else None,
        "is_booked": db_slot.is_booked
    })

    return db_slot

@router.post("/{slot_id}/toggle", response_model=SlotSchema)
async def toggle_slot(
    slot_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    firebase_uid = current_user.get("uid")
    user_result = await db.execute(select(User).filter(User.firebase_uid == firebase_uid))
    user = user_result.scalar_one_or_none()

    slot_result = await db.execute(select(Slot).filter(Slot.id == slot_id))
    slot = slot_result.scalar_one_or_none()

    if not slot:
        raise HTTPException(status_code=404, detail="Slot not found")

    turf_result = await db.execute(select(Turf).filter(Turf.id == slot.turf_id))
    turf = turf_result.scalar_one_or_none()

    if user.role != "admin" and turf.owner_id != user.id:
        raise HTTPException(status_code=403, detail="Not authorized to manage this slot")

    slot.is_booked = not slot.is_booked
    await db.commit()
    await db.refresh(slot)

    # Real-time WebSocket broadcast to all users viewing this turf
    await ws_manager.broadcast(f"slots_{slot.turf_id}", {
        "type": "slot_toggled",
        "slot_id": slot.id,
        "turf_id": slot.turf_id,
        "is_booked": slot.is_booked
    })

    return slot
