from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from pydantic import BaseModel
from typing import List
from app.db.session import get_db
from app.db.models import Tournament
from app.schemas.schemas import Tournament as TournamentSchema, TournamentCreate
from app.core.websocket_manager import ws_manager

router = APIRouter()

class TournamentRegisterRequest(BaseModel):
    tournament_id: int
    team_name: str

@router.get("/", response_model=List[TournamentSchema])
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

@router.post("/", response_model=TournamentSchema)
async def create_tournament(req: TournamentCreate, db: AsyncSession = Depends(get_db)):
    t = Tournament(**req.model_dump())
    db.add(t)
    await db.commit()
    await db.refresh(t)

    await ws_manager.broadcast("tournaments", {
        "type": "tournament_created",
        "tournament": {
            "id": t.id,
            "title": t.title,
            "prize_pool": t.prize_pool,
            "total_teams": t.total_teams,
            "format": t.format,
            "status": t.status,
        }
    })

    return t

@router.get("/{tournament_id}", response_model=TournamentSchema)
async def get_tournament_by_id(tournament_id: int, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Tournament).filter(Tournament.id == tournament_id))
    t = result.scalar_one_or_none()
    if not t:
        raise HTTPException(status_code=404, detail="Tournament not found")
    return t

@router.post("/register")
async def register_team(req: TournamentRegisterRequest, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Tournament).filter(Tournament.id == req.tournament_id))
    t = result.scalar_one_or_none()
    if not t:
        raise HTTPException(status_code=404, detail="Tournament not found")

    await ws_manager.broadcast("tournaments", {
        "type": "tournament_registered",
        "tournament_id": req.tournament_id,
        "team_name": req.team_name,
    })

    return {"message": f"Team '{req.team_name}' successfully registered for {t.title}!"}


