from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from pydantic import BaseModel
from typing import Optional
from app.db.session import get_db
from app.db.models import Coach

router = APIRouter()

class CoachCreate(BaseModel):
    full_name: str
    role: str
    rating: float = 4.8
    price_per_session: float
    image_url: Optional[str] = None

@router.get("/")
async def get_coaches(db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Coach))
    coaches = result.scalars().all()
    if not coaches:
        default_coaches = [
            Coach(full_name="Rahul Sharma", role="Football Coach", rating=4.8, price_per_session=1500.0, image_url="https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100"),
            Coach(full_name="David Martinez", role="AFC Certified Coach", rating=4.7, price_per_session=1350.0, image_url="https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=100"),
            Coach(full_name="Vikram Singh", role="Cricket Tactics", rating=4.9, price_per_session=1200.0, image_url="https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?w=100"),
            Coach(full_name="Ananya Roy", role="Badminton & Racquet", rating=4.8, price_per_session=1100.0, image_url="https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100"),
            Coach(full_name="Marcus Vance", role="Fitness & Conditioning", rating=4.6, price_per_session=900.0, image_url="https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=100"),
        ]
        for c in default_coaches:
            db.add(c)
        await db.commit()
        result = await db.execute(select(Coach))
        coaches = result.scalars().all()
    return coaches

@router.post("/")
async def create_coach(coach_in: CoachCreate, db: AsyncSession = Depends(get_db)):
    coach = Coach(**coach_in.model_dump())
    db.add(coach)
    await db.commit()
    await db.refresh(coach)
    return coach

