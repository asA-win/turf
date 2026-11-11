from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from pydantic import BaseModel
from typing import Optional
from app.db.session import get_db
from app.db.models import Team
from app.core.websocket_manager import ws_manager

router = APIRouter()

class TeamCreate(BaseModel):
    name: str

class TeamMemberInvite(BaseModel):
    name: str
    role: str = "Player"

@router.get("/")
async def get_teams(db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Team))
    teams = result.scalars().all()
    if not teams:
        default_team = Team(name="Turf Titans", matches_played=12, wins=9, goals_scored=32, rank=2)
        db.add(default_team)
        await db.commit()
        result = await db.execute(select(Team))
        teams = result.scalars().all()

    res = []
    for t in teams:
        res.append({
            "id": t.id,
            "name": t.name,
            "matches_played": t.matches_played,
            "wins": t.wins,
            "goals_scored": t.goals_scored,
            "rank": t.rank,
            "members": [
                {"name": "John Doe", "role": "Captain"},
                {"name": "Alex Johnson", "role": "Midfielder"},
                {"name": "Michael Brown", "role": "Defender"},
                {"name": "David Williams", "role": "Goalkeeper"},
            ]
        })
    return res

@router.post("/")
async def create_team(team_in: TeamCreate, db: AsyncSession = Depends(get_db)):
    team = Team(name=team_in.name, matches_played=0, wins=0, goals_scored=0, rank=1)
    db.add(team)
    await db.commit()
    await db.refresh(team)

    await ws_manager.broadcast("teams", {
        "type": "team_created",
        "team": {
            "id": team.id,
            "name": team.name,
            "matches_played": team.matches_played,
            "wins": team.wins,
            "goals_scored": team.goals_scored,
            "rank": team.rank,
        }
    })

    return team

@router.post("/{team_id}/members")
async def invite_team_member(team_id: int, member_in: TeamMemberInvite, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Team).filter(Team.id == team_id))
    team = result.scalar_one_or_none()
    if not team:
        raise HTTPException(status_code=404, detail="Team not found")

    await ws_manager.broadcast("teams", {
        "type": "member_joined",
        "team_id": team_id,
        "member": {
            "name": member_in.name,
            "role": member_in.role
        }
    })
    return {"message": f"Member {member_in.name} invited successfully!", "role": member_in.role}


