from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy.orm import selectinload
from typing import List

from app.db.session import get_db
from app.db.models import Match, Turf
from app.schemas.schemas import Match as MatchSchema, MatchCreate
from app.core.websocket_manager import ws_manager

router = APIRouter()

@router.get("/")
async def read_matches(db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Match).options(selectinload(Match.turf)))
    matches = result.scalars().all()
    if not matches:
        turf_res = await db.execute(select(Turf))
        first_turf = turf_res.scalars().first()
        if not first_turf:
            first_turf = Turf(
                name="Play Arena",
                location="Koramangala, Bengaluru",
                price_per_hour=1200.0,
                sport_types="Football,Cricket",
                amenities="Floodlights,Locker Room,Parking",
            )
            db.add(first_turf)
            await db.commit()
            await db.refresh(first_turf)

        default_m = Match(
            turf_id=first_turf.id,
            team_a_name="Turf Titans",
            team_b_name="Kickers United",
            team_a_score=2,
            team_b_score=1,
            status="live",
            sport_type="Football"
        )
        db.add(default_m)
        await db.commit()
        result = await db.execute(select(Match).options(selectinload(Match.turf)))
        matches = result.scalars().all()
    return matches


@router.post("/", response_model=MatchSchema)
async def create_match(match: MatchCreate, db: AsyncSession = Depends(get_db)):
    db_match = Match(**match.model_dump())
    db.add(db_match)
    await db.commit()
    await db.refresh(db_match)

    await ws_manager.broadcast("scoreboard", {
        "type": "new_match",
        "match_id": db_match.id,
        "sport_type": db_match.sport_type,
        "team_a_name": db_match.team_a_name,
        "team_b_name": db_match.team_b_name,
        "team_a_score": db_match.team_a_score,
        "team_b_score": db_match.team_b_score,
        "status": db_match.status
    })

    return db_match

@router.put("/{match_id}/score")
async def update_score(match_id: int, team_a_score: int, team_b_score: int, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Match).filter(Match.id == match_id))
    match = result.scalar_one_or_none()
    if not match:
        raise HTTPException(status_code=404, detail="Match not found")
    match.team_a_score = team_a_score
    match.team_b_score = team_b_score
    await db.commit()
    await db.refresh(match)

    await ws_manager.broadcast("scoreboard", {
        "type": "score_update",
        "match_id": match.id,
        "team_a_score": match.team_a_score,
        "team_b_score": match.team_b_score,
        "status": match.status
    })

    return match


@router.get("/{match_id}/stats")
async def get_match_stats(match_id: int, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Match).options(selectinload(Match.turf)).filter(Match.id == match_id))
    match = result.scalar_one_or_none()
    if not match:
        raise HTTPException(status_code=404, detail="Match not found")

    sport = (match.sport_type or "football").lower()

    if "cricket" in sport:
        return {
            "match_id": match.id,
            "sport_type": "Cricket",
            "team_a_name": match.team_a_name,
            "team_b_name": match.team_b_name,
            "team_a_score": match.team_a_score,
            "team_b_score": match.team_b_score,
            "status": match.status,
            "best_player_of_match": {
                "name": "Amit Sharma",
                "team": match.team_a_name,
                "award": "Player of the Match",
                "rating": 9.6,
                "headline": "54 runs (26b) & 2/18 wickets",
                "avatar": "A",
            },
            "top_scorer": {
                "name": "Amit Sharma",
                "team": match.team_a_name,
                "runs": 54,
                "balls": 26,
                "fours": 5,
                "sixes": 4,
                "strike_rate": 207.7,
                "label": "Top Run Scorer",
            },
            "top_wicket_taker": {
                "name": "Rahul Verma",
                "team": match.team_b_name,
                "wickets": 3,
                "overs": "2.0",
                "runs_conceded": 14,
                "economy": 7.0,
                "label": "Most Wickets Taken",
            },
            "maximum_sixes": {
                "name": "Vikram Singh",
                "team": match.team_a_name,
                "sixes": 5,
                "label": "Maximum Sixes",
            },
            "best_economy": {
                "name": "Dinesh Kumar",
                "team": match.team_b_name,
                "economy": 5.5,
                "overs": "2.0",
                "label": "Best Economy Rate",
            },
            "team_metrics": [
                {"title": "Run Rate", "team_a": "11.0 RPO", "team_b": "9.0 RPO"},
                {"title": "Boundaries (4s / 6s)", "team_a": "8 / 5", "team_b": "6 / 3"},
                {"title": "Extras", "team_a": "6", "team_b": "9"},
                {"title": "Dot Ball %", "team_a": "38%", "team_b": "46%"},
            ],
        }
    elif "badminton" in sport:
        return {
            "match_id": match.id,
            "sport_type": "Badminton",
            "team_a_name": match.team_a_name,
            "team_b_name": match.team_b_name,
            "team_a_score": match.team_a_score,
            "team_b_score": match.team_b_score,
            "status": match.status,
            "best_player_of_match": {
                "name": "John Doe",
                "team": match.team_a_name,
                "award": "Player of the Match",
                "rating": 9.5,
                "headline": "42 Rally Points & Decider Set Smash Winner",
                "avatar": "J",
            },
            "top_scorer": {
                "name": "John Doe",
                "team": match.team_a_name,
                "points": 42,
                "label": "Top Points Scorer",
            },
            "smash_winners": {
                "name": "Dev Raj",
                "team": match.team_a_name,
                "smashes": 14,
                "label": "Most Smash Winners",
            },
            "team_metrics": [
                {"title": "Points Won", "team_a": "61", "team_b": "54"},
                {"title": "Smash Winners", "team_a": "18", "team_b": "11"},
                {"title": "Unforced Errors", "team_a": "8", "team_b": "15"},
                {"title": "Service Streaks", "team_a": "6 max", "team_b": "4 max"},
            ],
        }
    elif "basketball" in sport:
        return {
            "match_id": match.id,
            "sport_type": "Basketball",
            "team_a_name": match.team_a_name,
            "team_b_name": match.team_b_name,
            "team_a_score": match.team_a_score,
            "team_b_score": match.team_b_score,
            "status": match.status,
            "best_player_of_match": {
                "name": "Sameer Rao",
                "team": match.team_a_name,
                "award": "Match MVP",
                "rating": 9.7,
                "headline": "24 Points, 8 Rebounds, 5 Assists",
                "avatar": "S",
            },
            "top_scorer": {
                "name": "Sameer Rao",
                "team": match.team_a_name,
                "points": 24,
                "fg_pct": "64%",
                "label": "Top Points Scorer",
            },
            "most_threes": {
                "name": "Dev Sharma",
                "team": match.team_b_name,
                "threes": 4,
                "label": "Most 3-Pointers",
            },
            "team_metrics": [
                {"title": "Field Goal %", "team_a": "52%", "team_b": "44%"},
                {"title": "3-Point FG %", "team_a": "41%", "team_b": "35%"},
                {"title": "Total Rebounds", "team_a": "34", "team_b": "28"},
                {"title": "Turnovers", "team_a": "9", "team_b": "14"},
            ],
        }
    else:
        return {
            "match_id": match.id,
            "sport_type": "Football",
            "team_a_name": match.team_a_name,
            "team_b_name": match.team_b_name,
            "team_a_score": match.team_a_score,
            "team_b_score": match.team_b_score,
            "status": match.status,
            "best_player_of_match": {
                "name": "Rahul Sharma",
                "team": match.team_a_name,
                "award": "Man of the Match",
                "rating": 9.4,
                "headline": "2 Goals & 1 Assist (89% Pass Acc)",
                "avatar": "R",
            },
            "top_scorer": {
                "name": "Rahul Sharma",
                "team": match.team_a_name,
                "goals": 2,
                "shots_on_target": 3,
                "label": "Top Scorer",
            },
            "top_assists": {
                "name": "Kiran Patel",
                "team": match.team_a_name,
                "assists": 2,
                "key_passes": 4,
                "label": "Most Assists",
            },
            "best_goalkeeper": {
                "name": "Arun Prasad",
                "team": match.team_b_name,
                "saves": 6,
                "save_percentage": "82%",
                "label": "Most Saves",
            },
            "team_metrics": [
                {"title": "Possession", "team_a": "58%", "team_b": "42%", "val_a": 58, "val_b": 42},
                {"title": "Shots", "team_a": "12", "team_b": "6", "val_a": 12, "val_b": 6},
                {"title": "Shots on Target", "team_a": "7", "team_b": "3", "val_a": 7, "val_b": 3},
                {"title": "Pass Accuracy", "team_a": "86%", "team_b": "74%", "val_a": 86, "val_b": 74},
                {"title": "Corners", "team_a": "4", "team_b": "2", "val_a": 4, "val_b": 2},
                {"title": "Fouls", "team_a": "5", "team_b": "6", "val_a": 5, "val_b": 6},
            ],
        }
