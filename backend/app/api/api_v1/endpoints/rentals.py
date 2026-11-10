from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from pydantic import BaseModel
from typing import Optional
from app.db.session import get_db
from app.db.models import RentalItem

router = APIRouter()

class RentalItemCreate(BaseModel):
    name: str
    price_per_day: float
    category: str = "Football"
    image_url: Optional[str] = None

@router.get("/")
async def get_rental_items(db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(RentalItem))
    items = result.scalars().all()
    if not items:
        default_items = [
            RentalItem(name="Match Football", price_per_day=100.0, category="Football"),
            RentalItem(name="Goalkeeper Gloves", price_per_day=150.0, category="Football"),
            RentalItem(name="Football Shoes", price_per_day=200.0, category="Football"),
            RentalItem(name="Training Bibs (Set of 10)", price_per_day=50.0, category="Football"),
        ]
        for item in default_items:
            db.add(item)
        await db.commit()
        result = await db.execute(select(RentalItem))
        items = result.scalars().all()
    return items

@router.post("/")
async def create_rental_item(item_in: RentalItemCreate, db: AsyncSession = Depends(get_db)):
    item = RentalItem(**item_in.model_dump())
    db.add(item)
    await db.commit()
    await db.refresh(item)
    return item

