from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from pydantic import BaseModel
from app.db.session import get_db
from app.db.models import Tournament

router = APIRouter()

class TournamentRegisterRequest(BaseModel):
    tournament_id: int
    team_name: str

@router.get("/")
async def get_tournaments(db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Tournament))
    tournaments = result.scalars().all()
    if not tournaments:
        default_t = Tournament(
            title="Summer Cup 2025",
            prize_pool=1000000.0,
            total_teams=16,
            format="Knockout",
            status="upcoming"
        )
        db.add(default_t)
        await db.commit()
        result = await db.execute(select(Tournament))
        tournaments = result.scalars().all()
    return tournaments

@router.post("/register")
async def register_team(req: TournamentRegisterRequest, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Tournament).filter(Tournament.id == req.tournament_id))
    t = result.scalar_one_or_none()
    if not t:
        raise HTTPException(status_code=404, detail="Tournament not found")
    return {"message": f"Team '{req.team_name}' successfully registered for {t.title}!"}

