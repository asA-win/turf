from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from typing import List
from pydantic import BaseModel

from app.db.session import get_db
from app.db.models import Booking, Slot, Turf, User
from app.schemas.schemas import Booking as BookingSchema, BookingCreate
from app.core.security import get_current_user
from app.core.websocket_manager import ws_manager

from app.core.notifications import send_to_user

router = APIRouter()

@router.get("/my-bookings", response_model=List[BookingSchema])
async def read_my_bookings(
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


    result = await db.execute(select(Booking).filter(Booking.user_id == user.id))
    bookings = result.scalars().all()
    return bookings

@router.post("/", response_model=BookingSchema)
async def create_booking(
    booking: BookingCreate,
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    firebase_uid = current_user.get("uid")
    user_result = await db.execute(select(User).filter(User.firebase_uid == firebase_uid))
    user = user_result.scalar_one_or_none()
    
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    # Verify slot and turf
    slot_result = await db.execute(
        select(Slot).filter(Slot.id == booking.slot_id).with_for_update()
    )
    slot = slot_result.scalar_one_or_none()
    
    if not slot or slot.turf_id != booking.turf_id:
        await db.rollback()
        raise HTTPException(status_code=400, detail="Invalid slot or turf")

    if slot.is_booked:
        await db.rollback()
        raise HTTPException(status_code=400, detail="Slot is already fully booked")

    # Check for temporary locks by other users
    from datetime import datetime
    now = datetime.utcnow()
    if slot.locked_until and slot.locked_until > now and slot.locked_by != user.id:
        await db.rollback()
        raise HTTPException(status_code=400, detail="Slot is temporarily held by another user")

    # Check capacity for 'join' booking
    if booking.booking_type == "join":
        if slot.capacity <= 1:
            await db.rollback()
            raise HTTPException(status_code=400, detail="This slot does not support joining")
        if slot.current_bookings >= slot.capacity:
            await db.rollback()
            raise HTTPException(status_code=400, detail="Slot is full")
    
    turf_result = await db.execute(select(Turf).filter(Turf.id == booking.turf_id))
    turf = turf_result.scalar_one_or_none()
    
    # Calculate price (join bookings might be cheaper)
    price = turf.price_per_hour
    if booking.booking_type == "join":
        price = price / slot.capacity # Simple split for now
        
    # Create booking
    new_booking = Booking(
        user_id=user.id,
        turf_id=booking.turf_id,
        slot_id=booking.slot_id,
        total_price=price,
        booking_type=booking.booking_type
    )
    
    # Update slot status
    if booking.booking_type == "full":
        slot.is_booked = True
        slot.current_bookings = slot.capacity
        slot.locked_until = None # Clear lock
        slot.locked_by = None
    else:
        slot.current_bookings += 1
        if slot.current_bookings >= slot.capacity:
            slot.is_booked = True
            slot.locked_until = None
            slot.locked_by = None
    
    db.add(new_booking)
    await db.commit()
    await db.refresh(new_booking)

    # Real-time WebSocket broadcast to all users viewing this turf's slots
    await ws_manager.broadcast(f"slots_{booking.turf_id}", {
        "type": "slot_booked",
        "slot_id": booking.slot_id,
        "turf_id": booking.turf_id,
        "is_booked": slot.is_booked,
        "current_bookings": slot.current_bookings,
        "capacity": slot.capacity,
    })

    # Real-time WebSocket broadcast to Live Booking Requests (Turf Owners / Admins)
    slot_time_str = f"{slot.start_time.strftime('%I:%M %p')} - {slot.end_time.strftime('%I:%M %p')}" if slot and slot.start_time and slot.end_time else "Evening Slot"
    await ws_manager.broadcast("booking_requests", {
        "type": "new_booking_request",
        "id": new_booking.id,
        "name": user.full_name or user.email or "Player",
        "turf_id": booking.turf_id,
        "turf_name": turf.name if turf else "Turf Arena",
        "slot_id": booking.slot_id,
        "slot": slot_time_str,
        "sport": "Football (6v6)",
        "price": f"₹{int(price)}",
        "players": f"{slot.capacity if slot else 10} Players",
        "status": new_booking.status or "confirmed",
    })

    # Real-time WebSocket broadcast to personal user channel and global booking updates
    await ws_manager.broadcast(f"user_{user.id}", {
        "type": "booking_created",
        "booking_id": new_booking.id,
        "turf_id": booking.turf_id,
        "slot_id": booking.slot_id,
    })
    await ws_manager.broadcast("booking_updates", {
        "type": "booking_created",
        "booking_id": new_booking.id,
        "turf_id": booking.turf_id,
        "slot_id": booking.slot_id,
    })
    
    # Send Notification to User
    try:
        await send_to_user(
            db, 
            user.id, 
            "Booking Confirmed!", 
            f"Your booking for {turf.name} at {slot.start_time.strftime('%I:%M %p')} is confirmed.",
            {"booking_id": str(new_booking.id)}
        )
        
        # Send Notification to Owner
        if turf.owner_id:
            await send_to_user(
                db,
                turf.owner_id,
                "New Booking!",
                f"A new booking has been made for {turf.name} by {user.full_name or user.email}.",
                {"booking_id": str(new_booking.id)}
            )
    except Exception as e:
        # Don't fail the booking if notification fails
        print(f"Notification error: {e}")
        
    return new_booking

@router.get("/requests")
async def get_booking_requests(
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    result = await db.execute(
        select(Booking, Slot, Turf, User)
        .outerjoin(Slot, Booking.slot_id == Slot.id)
        .outerjoin(Turf, Booking.turf_id == Turf.id)
        .outerjoin(User, Booking.user_id == User.id)
        .order_by(Booking.id.desc())
        .limit(30)
    )
    rows = result.all()
    requests = []
    for booking, slot, turf, user in rows:
        slot_str = "Evening Slot"
        if slot and slot.start_time and slot.end_time:
            slot_str = f"{slot.start_time.strftime('%I:%M %p')} - {slot.end_time.strftime('%I:%M %p')}"
        requests.append({
            "id": booking.id,
            "name": user.full_name or user.email if user else "Rahul Sharma",
            "turf_name": turf.name if turf else "Greenfield Arena",
            "turf_id": booking.turf_id,
            "slot_id": booking.slot_id,
            "slot": slot_str,
            "sport": "Football (6v6)",
            "price": f"₹{int(booking.total_price)}",
            "players": f"{slot.capacity if slot else 10} Players",
            "status": booking.status or "confirmed",
        })
    return requests

class RespondBookingRequest(BaseModel):
    action: str  # "accept" or "decline"

@router.post("/{booking_id}/respond")
async def respond_booking_request(
    booking_id: int,
    req: RespondBookingRequest,
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    result = await db.execute(select(Booking).filter(Booking.id == booking_id))
    booking = result.scalar_one_or_none()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")

    new_status = "confirmed" if req.action == "accept" else "declined"
    booking.status = new_status

    if req.action == "decline":
        slot_result = await db.execute(select(Slot).filter(Slot.id == booking.slot_id))
        slot = slot_result.scalar_one_or_none()
        if slot:
            slot.is_booked = False
            slot.current_bookings = max(0, slot.current_bookings - 1)
            await ws_manager.broadcast(f"slots_{booking.turf_id}", {
                "type": "slot_released",
                "slot_id": booking.slot_id,
                "turf_id": booking.turf_id,
                "is_booked": slot.is_booked,
                "current_bookings": slot.current_bookings,
                "capacity": slot.capacity,
            })

    await db.commit()

    await ws_manager.broadcast("booking_requests", {
        "type": "request_status_updated",
        "booking_id": booking_id,
        "status": new_status,
    })
    await ws_manager.broadcast("booking_updates", {
        "type": "request_status_updated",
        "booking_id": booking_id,
        "status": new_status,
    })
    await ws_manager.broadcast(f"user_{booking.user_id}", {
        "type": "booking_status_updated",
        "booking_id": booking_id,
        "status": new_status,
    })

    return {"message": f"Booking {new_status}", "booking_id": booking_id, "status": new_status}

@router.post("/{booking_id}/cancel")
async def cancel_booking(
    booking_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    firebase_uid = current_user.get("uid")
    user_result = await db.execute(select(User).filter(User.firebase_uid == firebase_uid))
    user = user_result.scalar_one_or_none()

    result = await db.execute(
        select(Booking).filter(Booking.id == booking_id)
    )
    booking = result.scalar_one_or_none()
    
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
        
    if booking.user_id != user.id and user.role != "admin":
        raise HTTPException(status_code=403, detail="Not authorized to cancel this booking")

    if booking.status == "cancelled":
        return {"message": "Booking already cancelled"}

    # Update booking status
    booking.status = "cancelled"
    
    # Free up the slot
    slot_result = await db.execute(select(Slot).filter(Slot.id == booking.slot_id))
    slot = slot_result.scalar_one_or_none()
    if slot:
        if booking.booking_type == "full":
            slot.is_booked = False
            slot.current_bookings = 0
        else:
            slot.current_bookings -= 1
            slot.is_booked = False # Even if one person cancels, it's not fully booked anymore
    
    await db.commit()

    # Real-time WebSocket broadcast to all users viewing this turf's slots
    await ws_manager.broadcast(f"slots_{booking.turf_id}", {
        "type": "slot_released",
        "slot_id": booking.slot_id,
        "turf_id": booking.turf_id,
        "is_booked": slot.is_booked if slot else False,
        "current_bookings": slot.current_bookings if slot else 0,
        "capacity": slot.capacity if slot else 1,
    })

    await ws_manager.broadcast("booking_updates", {
        "type": "booking_cancelled",
        "booking_id": booking_id,
        "turf_id": booking.turf_id,
        "slot_id": booking.slot_id,
    })
    await ws_manager.broadcast("booking_requests", {
        "type": "booking_cancelled",
        "booking_id": booking_id,
        "turf_id": booking.turf_id,
    })
    await ws_manager.broadcast(f"user_{booking.user_id}", {
        "type": "booking_cancelled",
        "booking_id": booking_id,
    })

    return {"message": "Booking cancelled successfully"}
