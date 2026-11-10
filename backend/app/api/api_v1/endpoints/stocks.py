from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from pydantic import BaseModel
from app.db.session import get_db
from app.db.models import StockShare, Turf

router = APIRouter()

class StockTradeRequest(BaseModel):
    stock_id: int
    shares: int

@router.get("/")
async def get_turf_stocks(db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(StockShare))
    stocks = result.scalars().all()
    if not stocks:
        turf_res = await db.execute(select(Turf))
        turf = turf_res.scalars().first()
        turf_id = turf.id if turf else None
        default_stock = StockShare(
            turf_id=turf_id,
            share_price=128.75,
            price_change_percentage=6.99,
            available_shares=1000
        )
        db.add(default_stock)
        await db.commit()
        result = await db.execute(select(StockShare))
        stocks = result.scalars().all()

    items = []
    for s in stocks:
        items.append({
            "id": s.id,
            "turf_name": "Kalyani Sports Turf",
            "location": "Kalyani, West Bengal",
            "share_price": s.share_price,
            "price_change_percentage": s.price_change_percentage,
            "available_shares": s.available_shares,
            "user_owned_shares": 120,
            "user_revenue_share_percentage": 3.00
        })
    return items

@router.post("/buy")
async def buy_shares(trade: StockTradeRequest, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(StockShare).filter(StockShare.id == trade.stock_id))
    stock = result.scalar_one_or_none()
    if not stock:
        raise HTTPException(status_code=404, detail="Stock share not found")
    if stock.available_shares < trade.shares:
        raise HTTPException(status_code=400, detail="Not enough shares available")
    
    stock.available_shares -= trade.shares
    await db.commit()
    return {"message": f"Successfully purchased {trade.shares} shares!", "remaining_shares": stock.available_shares}

@router.post("/sell")
async def sell_shares(trade: StockTradeRequest, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(StockShare).filter(StockShare.id == trade.stock_id))
    stock = result.scalar_one_or_none()
    if not stock:
        raise HTTPException(status_code=404, detail="Stock share not found")
    
    stock.available_shares += trade.shares
    await db.commit()
    return {"message": f"Successfully sold {trade.shares} shares!", "remaining_shares": stock.available_shares}

