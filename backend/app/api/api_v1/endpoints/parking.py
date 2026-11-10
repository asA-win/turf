from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from pydantic import BaseModel
from typing import Optional
from app.db.session import get_db
from app.db.models import ParkingReservation, User, Turf
from app.core.websocket_manager import ws_manager

router = APIRouter()

class ParkingReserveRequest(BaseModel):
    user_id: Optional[int] = 1
    turf_id: Optional[int] = 1
    vehicle_type: str = "Car"
    price: float = 50.0

@router.get("/status")
async def get_parking_status(db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(ParkingReservation))
    res_list = result.scalars().all()
    total_slots = 50
    used_slots = len(res_list)
    available_slots = max(0, total_slots - used_slots)
    
    return {
        "venue": "Elite Arena",
        "available_slots": available_slots,
        "total_slots": total_slots,
        "price": 50.0,
        "vehicle_types": ["Car", "Bike", "EV"]
    }

@router.post("/reserve")
async def reserve_parking(req: ParkingReserveRequest, db: AsyncSession = Depends(get_db)):
    res = ParkingReservation(
        user_id=req.user_id,
        turf_id=req.turf_id,
        vehicle_type=req.vehicle_type,
        price=req.price,
        status="reserved"
    )
    db.add(res)
    await db.commit()
    await db.refresh(res)

    result = await db.execute(select(ParkingReservation))
    res_list = result.scalars().all()
    total_slots = 50
    used_slots = len(res_list)
    available_slots = max(0, total_slots - used_slots)

    await ws_manager.broadcast("parking", {
        "type": "parking_updated",
        "available_slots": available_slots,
        "total_slots": total_slots,
        "vehicle_type": req.vehicle_type,
        "price": req.price,
        "message": f"New {req.vehicle_type} parking reserved"
    })

    return {
        "message": "Parking slot reserved successfully!",
        "reservation": res,
        "available_slots": available_slots,
        "total_slots": total_slots
    }

@router.post("/release")
async def release_parking(db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(ParkingReservation).order_by(ParkingReservation.id.desc()).limit(1))
    latest = result.scalar_one_or_none()
    if latest:
        await db.delete(latest)
        await db.commit()

    result = await db.execute(select(ParkingReservation))
    res_list = result.scalars().all()
    total_slots = 50
    available_slots = max(0, total_slots - len(res_list))

    await ws_manager.broadcast("parking", {
        "type": "parking_updated",
        "available_slots": available_slots,
        "total_slots": total_slots,
        "message": "Parking slot released"
    })

    return {"message": "Parking slot released", "available_slots": available_slots, "total_slots": total_slots}


