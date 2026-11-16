import json
import logging
from datetime import datetime
from typing import List, Optional, Dict, Any
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import desc, or_
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy.orm import selectinload

from app.db.session import get_db
from app.db.models import Match, MatchParticipant, Turf, User
from app.schemas.schemas import (
    Match as MatchSchema,
    MatchCreate,
    MatchUpdate,
    MatchScoreUpdate,
    MatchTimelineEventCreate,
    MatchFinishRequest,
    MatchParticipant as MatchParticipantSchema,
    MatchParticipantCreate,
)
from app.core.security import get_current_user
from app.core.websocket_manager import ws_manager

logger = logging.getLogger(__name__)

router = APIRouter()


async def get_current_user_obj(
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user),
) -> User:
    """Resolve and verify authenticated User database record from JWT or Firebase token."""
    user_id = current_user.get("user_id")
    uid = current_user.get("uid")
    email = current_user.get("email") or current_user.get("sub")

    user = None
    if user_id:
        res = await db.execute(select(User).filter(User.id == int(user_id)))
        user = res.scalar_one_or_none()

    if not user and uid:
        res = await db.execute(select(User).filter(User.firebase_uid == str(uid)))
        user = res.scalar_one_or_none()

    if not user and email:
        res = await db.execute(select(User).filter(User.email == str(email).lower()))
        user = res.scalar_one_or_none()

    if not user:
        user = User(
            firebase_uid=str(uid or f"user_{datetime.utcnow().timestamp()}"),
            email=str(email or "user@example.com").lower(),
            full_name=current_user.get("name") or "Turf Player",
            role=current_user.get("role", "user"),
            is_verified=True,
        )
        db.add(user)
        await db.commit()
        await db.refresh(user)

    return user


@router.get("/", response_model=List[MatchSchema])
async def read_matches(
    sport_type: Optional[str] = Query(None, description="Filter by sport"),
    status_filter: Optional[str] = Query(None, alias="status", description="Filter by status (scheduled, live, completed)"),
    search: Optional[str] = Query(None, description="Search by title, team, or venue"),
    db: AsyncSession = Depends(get_db),
):
    """Retrieve all matches with optional filters. Never injects fake demo records."""
    query = (
        select(Match)
        .options(selectinload(Match.turf), selectinload(Match.participants))
        .order_by(desc(Match.id))
    )

    if sport_type and sport_type.lower() != "all":
        query = query.filter(Match.sport_type.ilike(f"%{sport_type}%"))

    if status_filter and status_filter.lower() != "all":
        query = query.filter(Match.status == status_filter.lower())

    if search:
        s = f"%{search}%"
        query = query.filter(
            or_(
                Match.title.ilike(s),
                Match.team_a_name.ilike(s),
                Match.team_b_name.ilike(s),
                Match.venue_name.ilike(s),
                Match.location.ilike(s),
            )
        )

    result = await db.execute(query)
    matches = result.scalars().all()
    return matches


@router.get("/my", response_model=List[MatchSchema])
async def read_my_matches(
    tab: Optional[str] = Query("all", description="Tab filter: 'all', 'created', 'live', 'upcoming', 'completed'"),
    current_user: User = Depends(get_current_user_obj),
    db: AsyncSession = Depends(get_db),
):
    """Retrieve matches created by or joined by the authenticated user."""
    # Find match IDs where user is a participant
    part_res = await db.execute(
        select(MatchParticipant.match_id).filter(MatchParticipant.user_id == current_user.id)
    )
    joined_match_ids = {row[0] for row in part_res.fetchall()}

    # Base query for matches owned or joined
    query = (
        select(Match)
        .options(selectinload(Match.turf), selectinload(Match.participants))
        .filter(or_(Match.creator_id == current_user.id, Match.id.in_(joined_match_ids) if joined_match_ids else False))
        .order_by(desc(Match.id))
    )

    if tab == "created":
        query = (
            select(Match)
            .options(selectinload(Match.turf), selectinload(Match.participants))
            .filter(Match.creator_id == current_user.id)
            .order_by(desc(Match.id))
        )
    elif tab == "live":
        query = query.filter(Match.status == "live")
    elif tab == "upcoming":
        query = query.filter(Match.status == "scheduled")
    elif tab == "completed":
        query = query.filter(Match.status == "completed")

    result = await db.execute(query)
    matches = result.scalars().all()
    return matches


@router.post("/", response_model=MatchSchema)
async def create_match(
    match: MatchCreate,
    current_user: User = Depends(get_current_user_obj),
    db: AsyncSession = Depends(get_db),
):
    """Create a new match. Authenticated user is bound as creator permanently."""
    match_dict = match.model_dump()
    match_dict["creator_id"] = current_user.id
    match_dict["current_players_count"] = 1

    db_match = Match(**match_dict)
    db.add(db_match)
    await db.commit()
    await db.refresh(db_match)
    match_id = db_match.id

    # Register the creator as the first participant (Team A captain / player)
    creator_participant = MatchParticipant(
        match_id=match_id,
        user_id=current_user.id,
        team="A",
        player_name=current_user.full_name or "Match Host",
        player_role="Host / Player",
        jersey_number="1",
    )
    db.add(creator_participant)
    await db.commit()

    # Re-fetch with relationships loaded
    result = await db.execute(
        select(Match)
        .options(selectinload(Match.turf), selectinload(Match.participants))
        .filter(Match.id == match_id)
        .execution_options(populate_existing=True)
    )
    full_match = result.scalar_one()

    await ws_manager.broadcast("scoreboard", {
        "type": "new_match",
        "match_id": full_match.id,
        "sport_type": full_match.sport_type,
        "team_a_name": full_match.team_a_name,
        "team_b_name": full_match.team_b_name,
        "team_a_score": full_match.team_a_score,
        "team_b_score": full_match.team_b_score,
        "status": full_match.status,
    })

    return full_match


@router.get("/{match_id}", response_model=MatchSchema)
async def get_match(match_id: int, db: AsyncSession = Depends(get_db)):
    """Fetch complete details of a specific match."""
    result = await db.execute(
        select(Match)
        .options(selectinload(Match.turf), selectinload(Match.participants))
        .filter(Match.id == match_id)
    )
    match = result.scalar_one_or_none()
    if not match:
        raise HTTPException(status_code=404, detail="Match not found")
    return match


@router.put("/{match_id}", response_model=MatchSchema)
async def update_match(
    match_id: int,
    match_update: MatchUpdate,
    current_user: User = Depends(get_current_user_obj),
    db: AsyncSession = Depends(get_db),
):
    """Update match details. Enforces creator ownership."""
    result = await db.execute(
        select(Match)
        .options(selectinload(Match.turf), selectinload(Match.participants))
        .filter(Match.id == match_id)
    )
    match = result.scalar_one_or_none()
    if not match:
        raise HTTPException(status_code=404, detail="Match not found")

    if match.creator_id != current_user.id and current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Forbidden: Only the match creator can edit this match",
        )

    update_data = match_update.model_dump(exclude_unset=True)
    for field, val in update_data.items():
        setattr(match, field, val)

    match.updated_at = datetime.utcnow()
    await db.commit()
    await db.refresh(match)

    await ws_manager.broadcast("scoreboard", {
        "type": "match_updated",
        "match_id": match.id,
        "status": match.status,
        "team_a_score": match.team_a_score,
        "team_b_score": match.team_b_score,
    })

    return match


@router.delete("/{match_id}")
async def delete_match(
    match_id: int,
    current_user: User = Depends(get_current_user_obj),
    db: AsyncSession = Depends(get_db),
):
    """Delete a match. Enforces creator ownership."""
    result = await db.execute(select(Match).filter(Match.id == match_id))
    match = result.scalar_one_or_none()
    if not match:
        raise HTTPException(status_code=404, detail="Match not found")

    if match.creator_id != current_user.id and current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Forbidden: Only the match creator can delete this match",
        )

    await db.delete(match)
    await db.commit()

    await ws_manager.broadcast("scoreboard", {
        "type": "match_deleted",
        "match_id": match_id,
    })

    return {"success": True, "message": "Match deleted successfully"}


@router.post("/{match_id}/join", response_model=MatchParticipantSchema)
async def join_match(
    match_id: int,
    participant_data: MatchParticipantCreate,
    current_user: User = Depends(get_current_user_obj),
    db: AsyncSession = Depends(get_db),
):
    """Join an open match as a participant on Team A or Team B."""
    result = await db.execute(select(Match).filter(Match.id == match_id))
    match = result.scalar_one_or_none()
    if not match:
        raise HTTPException(status_code=404, detail="Match not found")

    if match.status in ("completed", "cancelled"):
        raise HTTPException(status_code=400, detail=f"Cannot join a {match.status} match")

    # Check if user already joined
    existing = await db.execute(
        select(MatchParticipant).filter(
            MatchParticipant.match_id == match_id,
            MatchParticipant.user_id == current_user.id,
        )
    )
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="You have already joined this match")

    if match.current_players_count >= match.max_players:
        raise HTTPException(status_code=400, detail="Match is already full")

    chosen_team = (participant_data.team or "A").upper()
    if chosen_team not in ("A", "B"):
        chosen_team = "A"

    player_name = participant_data.player_name or current_user.full_name or current_user.email or f"Player {current_user.id}"

    new_participant = MatchParticipant(
        match_id=match_id,
        user_id=current_user.id,
        team=chosen_team,
        player_name=player_name,
        player_role=participant_data.player_role or "Player",
        jersey_number=participant_data.jersey_number or "",
    )
    db.add(new_participant)

    match.current_players_count = (match.current_players_count or 0) + 1
    await db.commit()
    await db.refresh(new_participant)

    await ws_manager.broadcast("scoreboard", {
        "type": "participant_joined",
        "match_id": match_id,
        "player_name": new_participant.player_name,
        "team": new_participant.team,
        "current_players_count": match.current_players_count,
    })

    return new_participant


@router.post("/{match_id}/leave")
async def leave_match(
    match_id: int,
    current_user: User = Depends(get_current_user_obj),
    db: AsyncSession = Depends(get_db),
):
    """Leave a match if registered as a participant."""
    result = await db.execute(select(Match).filter(Match.id == match_id))
    match = result.scalar_one_or_none()
    if not match:
        raise HTTPException(status_code=404, detail="Match not found")

    if match.creator_id == current_user.id:
        raise HTTPException(
            status_code=400,
            detail="The match creator cannot leave the match. You may delete the match instead.",
        )

    res = await db.execute(
        select(MatchParticipant).filter(
            MatchParticipant.match_id == match_id,
            MatchParticipant.user_id == current_user.id,
        )
    )
    participant = res.scalar_one_or_none()
    if not participant:
        raise HTTPException(status_code=404, detail="You are not registered in this match")

    await db.delete(participant)
    match.current_players_count = max(0, (match.current_players_count or 1) - 1)
    await db.commit()

    await ws_manager.broadcast("scoreboard", {
        "type": "participant_left",
        "match_id": match_id,
        "user_id": current_user.id,
        "current_players_count": match.current_players_count,
    })

    return {"success": True, "message": "Successfully left match"}


@router.put("/{match_id}/score", response_model=MatchSchema)
async def update_score(
    match_id: int,
    score_update: MatchScoreUpdate,
    current_user: User = Depends(get_current_user_obj),
    db: AsyncSession = Depends(get_db),
):
    """Update live score, status, or scoreboard state. Enforces creator ownership."""
    result = await db.execute(
        select(Match)
        .options(selectinload(Match.turf), selectinload(Match.participants))
        .filter(Match.id == match_id)
    )
    match = result.scalar_one_or_none()
    if not match:
        raise HTTPException(status_code=404, detail="Match not found")

    if match.creator_id != current_user.id and current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Forbidden: Only the match creator can update the scoreboard",
        )

    if score_update.team_a_score is not None:
        match.team_a_score = score_update.team_a_score
    if score_update.team_b_score is not None:
        match.team_b_score = score_update.team_b_score
    if score_update.status is not None:
        match.status = score_update.status
    if score_update.scoreboard_state_json is not None:
        match.scoreboard_state_json = score_update.scoreboard_state_json

    match.updated_at = datetime.utcnow()
    await db.commit()
    await db.refresh(match)

    await ws_manager.broadcast("scoreboard", {
        "type": "score_update",
        "match_id": match.id,
        "team_a_score": match.team_a_score,
        "team_b_score": match.team_b_score,
        "status": match.status,
        "scoreboard_state_json": match.scoreboard_state_json,
    })

    return match


@router.post("/{match_id}/timeline")
async def record_timeline_event(
    match_id: int,
    event: MatchTimelineEventCreate,
    current_user: User = Depends(get_current_user_obj),
    db: AsyncSession = Depends(get_db),
):
    """Add a timeline event (goal, card, wicket, point, etc.). Enforces creator ownership."""
    result = await db.execute(select(Match).filter(Match.id == match_id))
    match = result.scalar_one_or_none()
    if not match:
        raise HTTPException(status_code=404, detail="Match not found")

    if match.creator_id != current_user.id and current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Forbidden: Only the match creator can record timeline events",
        )

    events_list = []
    if match.timeline_events_json:
        try:
            events_list = json.loads(match.timeline_events_json)
            if not isinstance(events_list, list):
                events_list = []
        except Exception:
            events_list = []

    new_event_entry = {
        "id": len(events_list) + 1,
        "event_type": event.event_type,
        "minute": event.minute or f"{len(events_list) + 1}'",
        "team": event.team or "A",
        "player_name": event.player_name or "Player",
        "description": event.description or "",
        "score_snapshot": event.score_snapshot or f"{match.team_a_score} - {match.team_b_score}",
        "timestamp": datetime.utcnow().isoformat(),
    }
    events_list.append(new_event_entry)

    match.timeline_events_json = json.dumps(events_list)
    match.updated_at = datetime.utcnow()
    await db.commit()

    await ws_manager.broadcast("scoreboard", {
        "type": "timeline_event",
        "match_id": match_id,
        "event": new_event_entry,
        "all_events": events_list,
    })

    return {"success": True, "events": events_list, "new_event": new_event_entry}


@router.put("/{match_id}/finish", response_model=MatchSchema)
async def finish_match(
    match_id: int,
    finish_req: MatchFinishRequest,
    current_user: User = Depends(get_current_user_obj),
    db: AsyncSession = Depends(get_db),
):
    """Conclude the match and declare MVP. Enforces creator ownership."""
    result = await db.execute(
        select(Match)
        .options(selectinload(Match.turf), selectinload(Match.participants))
        .filter(Match.id == match_id)
    )
    match = result.scalar_one_or_none()
    if not match:
        raise HTTPException(status_code=404, detail="Match not found")

    if match.creator_id != current_user.id and current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Forbidden: Only the match creator can conclude the match",
        )

    match.status = "completed"
    if finish_req.mvp_player_name:
        match.mvp_player_name = finish_req.mvp_player_name
    if finish_req.mvp_notes:
        match.mvp_notes = finish_req.mvp_notes
    if finish_req.final_team_a_score is not None:
        match.team_a_score = finish_req.final_team_a_score
    if finish_req.final_team_b_score is not None:
        match.team_b_score = finish_req.final_team_b_score

    match.updated_at = datetime.utcnow()
    await db.commit()
    await db.refresh(match)

    await ws_manager.broadcast("scoreboard", {
        "type": "match_completed",
        "match_id": match.id,
        "status": "completed",
        "team_a_score": match.team_a_score,
        "team_b_score": match.team_b_score,
        "mvp_player_name": match.mvp_player_name,
    })

    return match


@router.get("/{match_id}/stats")
async def get_match_stats(match_id: int, db: AsyncSession = Depends(get_db)):
    """Compute real dynamic match statistics from scoreboard state and timeline events."""
    result = await db.execute(
        select(Match)
        .options(selectinload(Match.turf), selectinload(Match.participants))
        .filter(Match.id == match_id)
    )
    match = result.scalar_one_or_none()
    if not match:
        raise HTTPException(status_code=404, detail="Match not found")

    # Parse timeline events
    events = []
    if match.timeline_events_json:
        try:
            events = json.loads(match.timeline_events_json)
            if not isinstance(events, list):
                events = []
        except Exception:
            events = []

    # Count real events
    team_a_events = [e for e in events if e.get("team") == "A"]
    team_b_events = [e for e in events if e.get("team") == "B"]

    player_scores: Dict[str, int] = {}
    for e in events:
        p_name = e.get("player_name")
        if p_name and e.get("event_type") in ("goal", "point", "run", "basket", "wicket"):
            player_scores[p_name] = player_scores.get(p_name, 0) + 1

    top_scorer_name = None
    top_score_val = 0
    if player_scores:
        top_scorer_name = max(player_scores, key=player_scores.get)
        top_score_val = player_scores[top_scorer_name]

    # MVP fallback to recorded MVP, or top scorer, or Team A captain
    mvp_name = match.mvp_player_name or top_scorer_name
    if not mvp_name and match.participants:
        mvp_name = match.participants[0].player_name

    stats_response = {
        "match_id": match.id,
        "sport_type": match.sport_type,
        "team_a_name": match.team_a_name,
        "team_b_name": match.team_b_name,
        "team_a_score": match.team_a_score,
        "team_b_score": match.team_b_score,
        "status": match.status,
        "events_count": len(events),
        "mvp": {
            "name": mvp_name or "Pending",
            "notes": match.mvp_notes or ("Official Match MVP" if mvp_name else "Match in progress"),
            "rating": 9.5 if mvp_name else None,
        },
        "top_performer": {
            "name": top_scorer_name or (match.participants[0].player_name if match.participants else "None"),
            "stat": f"{top_score_val} Events" if top_scorer_name else "Active",
        },
        "team_metrics": [
            {"title": "Score", "team_a": str(match.team_a_score), "team_b": str(match.team_b_score)},
            {"title": "Key Events", "team_a": str(len(team_a_events)), "team_b": str(len(team_b_events))},
            {"title": "Roster Size", "team_a": str(len([p for p in match.participants if p.team == "A"])), "team_b": str(len([p for p in match.participants if p.team == "B"]))},
        ],
        "timeline_events": events,
    }

    return stats_response
