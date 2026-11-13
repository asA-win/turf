from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import func
from typing import List, Optional
from datetime import datetime, timedelta

from app.db.session import get_db
from app.db.models import Slot, Turf, User
from app.schemas.schemas import Slot as SlotSchema, SlotCreate
from app.core.security import get_current_user
from app.core.websocket_manager import ws_manager

router = APIRouter()

async def get_db_user_from_token(current_user: dict, db: AsyncSession) -> Optional[User]:
    uid = current_user.get("uid")
    email = current_user.get("email") or current_user.get("sub")
    query = select(User)
    if email:
        query = query.filter((User.email == email.lower()) | (User.firebase_uid == uid))
    elif uid:
        query = query.filter(User.firebase_uid == uid)
    else:
        return None
    res = await db.execute(query)
    return res.scalar_one_or_none()

@router.get("/", response_model=List[SlotSchema])
async def read_slots(
    turf_id: int, 
    date: Optional[str] = None,
    skip: int = 0, 
    limit: int = 100, 
    db: AsyncSession = Depends(get_db)
):
    query = select(Slot).filter(Slot.turf_id == turf_id)
    target_date = None
    
    if date:
        try:
            target_date = datetime.strptime(date, "%Y-%m-%d").date()
            query = query.filter(func.date(Slot.start_time) == target_date)
        except ValueError:
            pass # Ignore invalid date format
            
    result = await db.execute(query.order_by(Slot.start_time).offset(skip).limit(limit))
    slots = list(result.scalars().all())
    
    # Auto-generate operational slots (06:00 - 23:00) if none exist yet for this turf on this date
    if not slots and turf_id:
        turf_check = await db.execute(select(Turf).filter(Turf.id == turf_id))
        turf = turf_check.scalar_one_or_none()
        if turf:
            day_to_generate = target_date if target_date else datetime.utcnow().date()
            new_slots = []
            for hour in range(6, 23):
                start_dt = datetime.combine(day_to_generate, datetime.min.time()).replace(hour=hour)
                end_dt = start_dt + timedelta(hours=1)
                s = Slot(
                    turf_id=turf_id,
                    start_time=start_dt,
                    end_time=end_dt,
                    is_booked=False,
                    capacity=10,
                    current_bookings=0
                )
                db.add(s)
                new_slots.append(s)
            try:
                await db.commit()
                for s in new_slots:
                    await db.refresh(s)
                slots = new_slots
            except Exception:
                await db.rollback()

    # Check for expired temporary checkout locks (preserve owner administrative blocks > 24h)
    now = datetime.utcnow()
    for slot in slots:
        if slot.locked_until and slot.locked_until < now:
            slot.locked_until = None
            slot.locked_by = None
            
    return slots

@router.post("/{slot_id}/lock", response_model=SlotSchema)
async def lock_slot(
    slot_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    user = await get_db_user_from_token(current_user, db)
    if not user:
        raise HTTPException(status_code=401, detail="User not found")

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
    user = await get_db_user_from_token(current_user, db)
    if not user:
        raise HTTPException(status_code=401, detail="User not found")

    if user.role == "owner" and user.owner_status != "approved":
        raise HTTPException(
            status_code=403,
            detail="Operational access restricted: Account is pending admin approval or suspended."
        )

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
    user = await get_db_user_from_token(current_user, db)
    if not user:
        raise HTTPException(status_code=401, detail="User not found")

    if user.role == "owner" and user.owner_status != "approved":
        raise HTTPException(
            status_code=403,
            detail="Operational access restricted: Account is pending admin approval or suspended."
        )

    slot_result = await db.execute(select(Slot).filter(Slot.id == slot_id))
    slot = slot_result.scalar_one_or_none()

    if not slot:
        raise HTTPException(status_code=404, detail="Slot not found")

    turf_result = await db.execute(select(Turf).filter(Turf.id == slot.turf_id))
    turf = turf_result.scalar_one_or_none()

    if user.role != "admin" and turf and turf.owner_id != user.id:
        raise HTTPException(status_code=403, detail="Not authorized to manage this slot")

    now = datetime.utcnow()
    # Toggle slot administrative block (locks slot for 30 days or clears it)
    if slot.locked_until and slot.locked_until > now:
        # Currently blocked -> Unblock
        slot.locked_until = None
        slot.locked_by = None
        is_blocked = False
    else:
        # Currently open -> Block for administrative/maintenance hold
        slot.locked_until = now + timedelta(days=30)
        slot.locked_by = user.id
        is_blocked = True

    await db.commit()
    await db.refresh(slot)

    # Real-time WebSocket broadcast to all users viewing this turf
    await ws_manager.broadcast(f"slots_{slot.turf_id}", {
        "type": "slot_toggled",
        "slot_id": slot.id,
        "turf_id": slot.turf_id,
        "is_blocked": is_blocked,
        "is_booked": slot.is_booked,
        "locked_until": slot.locked_until.isoformat() if slot.locked_until else None
    })

    return slot
