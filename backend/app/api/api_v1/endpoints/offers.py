from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from typing import List, Optional

from app.db.session import get_db
from app.db.models import Offer
from app.schemas.schemas import Offer as OfferSchema, OfferCreate

router = APIRouter()

@router.get("/", response_model=List[OfferSchema])
async def read_offers(
    turf_id: Optional[int] = None,
    db: AsyncSession = Depends(get_db)
):
    query = select(Offer)
    if turf_id:
        # Get offers specific to this turf OR global offers (turf_id is null)
        query = query.filter((Offer.turf_id == turf_id) | (Offer.turf_id == None))
        
    result = await db.execute(query)
    return result.scalars().all()

@router.post("/", response_model=OfferSchema)
async def create_offer(
    offer: OfferCreate,
    db: AsyncSession = Depends(get_db)
):
    db_offer = Offer(**offer.model_dump())
    db.add(db_offer)
    await db.commit()
    await db.refresh(db_offer)
    return db_offer
