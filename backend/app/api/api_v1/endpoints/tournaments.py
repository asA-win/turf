import json
import logging
from datetime import datetime
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from pydantic import BaseModel
from sqlalchemy import desc
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy.orm import selectinload

from app.db.session import get_db
from app.db.models import Tournament, TournamentRegistration, TournamentMatch, User
from app.schemas.schemas import (
    Tournament as TournamentSchema,
    TournamentDetail as TournamentDetailSchema,
    TournamentCreate,
    TournamentUpdate,
    TournamentRegistrationCreate,
    TournamentRegistrationStatusUpdate,
    TournamentRegistrationOut,
    TournamentMatchOut,
    TournamentMatchScoreUpdate,
    TournamentFixturesGenerate,
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
        # Create persistent user record if authenticated through valid provider but not yet in DB
        user = User(
            firebase_uid=str(uid or f"user_{datetime.utcnow().timestamp()}"),
            email=str(email or "user@example.com").lower(),
            full_name=current_user.get("name") or "Tournament Player",
            role=current_user.get("role", "user"),
            is_verified=True,
        )
        db.add(user)
        await db.commit()
        await db.refresh(user)

    return user


# =====================================================================
# 1. TOURNAMENT LISTING & CREATION
# =====================================================================

@router.get("/", response_model=List[TournamentSchema])
async def get_tournaments(
    sport: Optional[str] = None,
    status_filter: Optional[str] = Query(None, alias="status"),
    search: Optional[str] = None,
    db: AsyncSession = Depends(get_db),
):
    """
    Get all published tournaments from actual database.
    Does NOT inject any hardcoded fake demo tournaments.
    """
    query = select(Tournament).order_by(desc(Tournament.created_at))

    if sport and sport.lower() != "all":
        query = query.filter(Tournament.sport.ilike(f"%{sport.strip()}%"))

    if status_filter and status_filter.lower() != "all":
        query = query.filter(Tournament.status.ilike(f"%{status_filter.strip()}%"))

    if search and search.strip():
        term = f"%{search.strip()}%"
        query = query.filter(
            (Tournament.title.ilike(term)) |
            (Tournament.venue.ilike(term)) |
            (Tournament.area.ilike(term)) |
            (Tournament.city.ilike(term))
        )

    result = await db.execute(query)
    tournaments = result.scalars().all()
    return tournaments


@router.get("/my", response_model=List[TournamentSchema])
async def get_my_tournaments(
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_user_obj),
):
    """
    Get all tournaments created by or registered/booked by the authenticated user.
    Includes both organizer tournaments and player team registrations.
    """
    reg_subquery = select(TournamentRegistration.tournament_id).filter(TournamentRegistration.user_id == user.id)
    result = await db.execute(
        select(Tournament)
        .filter(
            (Tournament.creator_id == user.id) |
            (Tournament.id.in_(reg_subquery))
        )
        .order_by(desc(Tournament.created_at))
    )
    my_tournaments = result.scalars().all()
    return my_tournaments


@router.post("/", response_model=TournamentDetailSchema)
async def create_tournament(
    req: TournamentCreate,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_user_obj),
):
    """
    Create a new tournament.
    Automatically assigns and permanently binds authenticated user's ID as creator_id.
    """
    data = req.model_dump()
    start_date = data.pop("start_date", None) or datetime.utcnow()
    organizer = data.pop("organizer_name", None) or user.full_name or "Tournament Organizer"
    
    t = Tournament(
        **data,
        start_date=start_date,
        creator_id=user.id,
        organizer_name=organizer,
        registered_teams_count=0,
        fixtures_generated=False,
        created_at=datetime.utcnow(),
        updated_at=datetime.utcnow(),
    )
    db.add(t)
    await db.commit()
    await db.refresh(t)

    # Fetch with relations
    res = await db.execute(
        select(Tournament)
        .options(selectinload(Tournament.registrations), selectinload(Tournament.matches))
        .filter(Tournament.id == t.id)
    )
    tournament_full = res.scalar_one()

    # Real-time WebSocket Broadcast
    await ws_manager.broadcast("tournaments", {
        "type": "tournament_created",
        "tournament": {
            "id": t.id,
            "title": t.title,
            "sport": t.sport,
            "format": t.format,
            "prize_pool": t.prize_pool,
            "entry_fee": t.entry_fee,
            "total_teams": t.total_teams,
            "registered_teams_count": 0,
            "status": t.status,
            "venue": t.venue,
            "area": t.area,
            "city": t.city,
            "creator_id": t.creator_id,
            "created_at": t.created_at.isoformat(),
        }
    })

    return tournament_full


# =====================================================================
# 2. TOURNAMENT DETAILS, EDITING & DELETION (STRICT OWNERSHIP)
# =====================================================================

@router.get("/{tournament_id}", response_model=TournamentDetailSchema)
async def get_tournament_by_id(tournament_id: int, db: AsyncSession = Depends(get_db)):
    """Fetch complete tournament details, registered teams, and fixture matches."""
    result = await db.execute(
        select(Tournament)
        .options(
            selectinload(Tournament.registrations),
            selectinload(Tournament.matches)
        )
        .filter(Tournament.id == tournament_id)
    )
    t = result.scalar_one_or_none()
    if not t:
        raise HTTPException(status_code=404, detail="Tournament not found")
    return t


@router.put("/{tournament_id}", response_model=TournamentDetailSchema)
async def update_tournament(
    tournament_id: int,
    req: TournamentUpdate,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_user_obj),
):
    """
    Edit tournament details.
    CRITICAL OWNERSHIP RULE: Only the creator who created the tournament can modify it.
    """
    result = await db.execute(
        select(Tournament)
        .options(selectinload(Tournament.registrations), selectinload(Tournament.matches))
        .filter(Tournament.id == tournament_id)
    )
    t = result.scalar_one_or_none()
    if not t:
        raise HTTPException(status_code=404, detail="Tournament not found")

    # Authorize ownership
    if t.creator_id != user.id and user.role != "admin":
        logger.warning(f"Unauthorized update attempt: User {user.id} tried to edit tournament {t.id} owned by {t.creator_id}")
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Forbidden: Only the tournament creator can edit this tournament."
        )

    # Apply updates
    update_data = req.model_dump(exclude_unset=True)
    for field, val in update_data.items():
        if val is not None:
            setattr(t, field, val)

    t.updated_at = datetime.utcnow()
    await db.commit()
    await db.refresh(t)

    # Real-time WebSocket Broadcast
    await ws_manager.broadcast("tournaments", {
        "type": "tournament_updated",
        "tournament_id": t.id,
        "title": t.title,
        "status": t.status,
        "prize_pool": t.prize_pool,
        "venue": t.venue,
        "dates": f"{t.start_date.isoformat() if t.start_date else ''}",
    })

    return t


@router.delete("/{tournament_id}")
async def delete_or_cancel_tournament(
    tournament_id: int,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_user_obj),
):
    """
    Cancel or delete a tournament.
    CRITICAL OWNERSHIP RULE: Only the original creator can delete or cancel the tournament.
    """
    result = await db.execute(
        select(Tournament)
        .options(selectinload(Tournament.matches))
        .filter(Tournament.id == tournament_id)
    )
    t = result.scalar_one_or_none()
    if not t:
        raise HTTPException(status_code=404, detail="Tournament not found")

    # Authorize ownership
    if t.creator_id != user.id and user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Forbidden: Only the tournament creator can delete or cancel this tournament."
        )

    # Check status: if completed or active matches are running, mark cancelled instead of deleting records
    has_active_matches = any(m.status in ("live", "completed") for m in t.matches)
    if has_active_matches:
        t.status = "Cancelled"
        t.updated_at = datetime.utcnow()
        await db.commit()
        msg = "Tournament has recorded matches. Marked status as Cancelled."
    else:
        await db.delete(t)
        await db.commit()
        msg = "Tournament deleted successfully."

    # Real-time WebSocket Broadcast
    await ws_manager.broadcast("tournaments", {
        "type": "tournament_deleted",
        "tournament_id": tournament_id,
        "status": "Cancelled" if has_active_matches else "Deleted"
    })

    return {"success": True, "message": msg}


# =====================================================================
# 3. TEAM REGISTRATION & MANAGEMENT
# =====================================================================

class LegacyRegisterRequest(BaseModel):
    tournament_id: int
    team_name: str

@router.post("/register")
async def register_team_legacy(
    req: LegacyRegisterRequest,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_user_obj),
):
    """Backward-compatible registration endpoint delegating to secure registration flow."""
    return await register_team_for_tournament(
        tournament_id=req.tournament_id,
        req=TournamentRegistrationCreate(
            team_name=req.team_name,
            captain_name=user.full_name or "Captain",
            contact_phone=user.phone or "+91 9876543210",
            contact_email=user.email,
        ),
        db=db,
        user=user,
    )


@router.post("/{tournament_id}/register", response_model=TournamentRegistrationOut)
async def register_team_for_tournament(
    tournament_id: int,
    req: TournamentRegistrationCreate,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_user_obj),
):
    """
    Register a team for a tournament.
    Enforces capacity limits, deadlines, and duplicate checks.
    """
    result = await db.execute(
        select(Tournament)
        .options(selectinload(Tournament.registrations))
        .filter(Tournament.id == tournament_id)
    )
    t = result.scalar_one_or_none()
    if not t:
        raise HTTPException(status_code=404, detail="Tournament not found")

    # Status check
    if t.status in ("Completed", "Cancelled"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Registration is closed. Tournament is {t.status}."
        )

    # Deadline check
    if t.registration_deadline and datetime.utcnow() > t.registration_deadline:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Registration deadline for this tournament has passed."
        )

    # Capacity check (only count active approved/pending registrations)
    active_regs = [r for r in t.registrations if r.status != "Cancelled"]
    if len(active_regs) >= t.total_teams:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="This tournament has reached its maximum team capacity."
        )

    # Duplicate registration check for same user in same tournament
    user_duplicate = next((r for r in active_regs if r.user_id == user.id), None)
    if user_duplicate:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"You have already registered team '{user_duplicate.team_name}' for this tournament."
        )

    # Duplicate team name check
    clean_team_name = req.team_name.strip()
    team_name_duplicate = next((r for r in active_regs if r.team_name.lower() == clean_team_name.lower()), None)
    if team_name_duplicate:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"A team named '{clean_team_name}' is already registered in this tournament."
        )

    players_list = req.players or []
    players_count = max(len(players_list), 1)

    new_reg = TournamentRegistration(
        tournament_id=t.id,
        user_id=user.id,
        team_name=clean_team_name,
        team_tag=req.team_tag.strip().upper() if req.team_tag else None,
        captain_name=req.captain_name.strip(),
        contact_phone=req.contact_phone.strip(),
        contact_email=req.contact_email.strip() if req.contact_email else user.email,
        emergency_contact=req.emergency_contact,
        jersey_color=req.jersey_color or "Neon Green",
        skill_level=req.skill_level or "Intermediate / Club",
        players_json=json.dumps(players_list),
        players_count=players_count,
        special_requests=req.special_requests,
        status="Approved", # Default approved so team immediately qualifies
        created_at=datetime.utcnow(),
    )
    db.add(new_reg)

    # Update registered team count
    t.registered_teams_count = len(active_regs) + 1
    t.updated_at = datetime.utcnow()

    await db.commit()
    await db.refresh(new_reg)
    await db.refresh(t)

    # Real-time WebSocket Broadcast
    await ws_manager.broadcast("tournaments", {
        "type": "tournament_registered",
        "tournament_id": t.id,
        "team_name": new_reg.team_name,
        "registered_teams_count": t.registered_teams_count,
        "total_teams": t.total_teams,
    })

    return new_reg


@router.get("/{tournament_id}/registrations", response_model=List[TournamentRegistrationOut])
async def get_tournament_registrations(tournament_id: int, db: AsyncSession = Depends(get_db)):
    """Get all registered teams for a tournament."""
    res = await db.execute(
        select(TournamentRegistration)
        .filter(TournamentRegistration.tournament_id == tournament_id)
        .order_by(TournamentRegistration.created_at)
    )
    return res.scalars().all()


@router.put("/{tournament_id}/registrations/{registration_id}/status", response_model=TournamentRegistrationOut)
async def update_registration_status(
    tournament_id: int,
    registration_id: int,
    req: TournamentRegistrationStatusUpdate,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_user_obj),
):
    """
    Approve or reject a team registration.
    CRITICAL OWNERSHIP RULE: Only the tournament creator can approve or reject registrations.
    """
    tourn_res = await db.execute(select(Tournament).filter(Tournament.id == tournament_id))
    t = tourn_res.scalar_one_or_none()
    if not t:
        raise HTTPException(status_code=404, detail="Tournament not found")

    if t.creator_id != user.id and user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Forbidden: Only the tournament creator can approve or reject registrations."
        )

    reg_res = await db.execute(
        select(TournamentRegistration).filter(
            TournamentRegistration.id == registration_id,
            TournamentRegistration.tournament_id == tournament_id,
        )
    )
    reg = reg_res.scalar_one_or_none()
    if not reg:
        raise HTTPException(status_code=404, detail="Registration not found")

    prev_status = reg.status
    reg.status = req.status

    # Recalculate count of approved teams
    all_regs_res = await db.execute(
        select(TournamentRegistration).filter(
            TournamentRegistration.tournament_id == tournament_id,
            TournamentRegistration.status == "Approved"
        )
    )
    t.registered_teams_count = len(all_regs_res.scalars().all())
    t.updated_at = datetime.utcnow()

    await db.commit()
    await db.refresh(reg)

    # Real-time WebSocket Broadcast
    await ws_manager.broadcast("tournaments", {
        "type": "tournament_registration_status_changed",
        "tournament_id": tournament_id,
        "registration_id": reg.id,
        "status": reg.status,
        "registered_teams_count": t.registered_teams_count,
    })

    return reg


@router.delete("/{tournament_id}/registrations/{registration_id}")
async def cancel_registration(
    tournament_id: int,
    registration_id: int,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_user_obj),
):
    """
    Cancel a team's registration.
    Allowed by the team registrant OR the tournament creator.
    """
    tourn_res = await db.execute(select(Tournament).filter(Tournament.id == tournament_id))
    t = tourn_res.scalar_one_or_none()
    if not t:
        raise HTTPException(status_code=404, detail="Tournament not found")

    reg_res = await db.execute(
        select(TournamentRegistration).filter(
            TournamentRegistration.id == registration_id,
            TournamentRegistration.tournament_id == tournament_id,
        )
    )
    reg = reg_res.scalar_one_or_none()
    if not reg:
        raise HTTPException(status_code=404, detail="Registration not found")

    # Authorize: either the user who created this registration OR the tournament creator
    is_registrant = (reg.user_id == user.id)
    is_creator = (t.creator_id == user.id or user.role == "admin")
    if not (is_registrant or is_creator):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Forbidden: You are not authorized to cancel this registration."
        )

    # Status check: cannot cancel if tournament is already ongoing or completed
    if t.status in ("Ongoing (Live)", "Completed"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Cannot cancel registration once the tournament is {t.status}."
        )

    reg.status = "Cancelled"
    t.registered_teams_count = max(0, t.registered_teams_count - 1)
    t.updated_at = datetime.utcnow()

    await db.commit()

    # Real-time WebSocket Broadcast
    await ws_manager.broadcast("tournaments", {
        "type": "tournament_registration_cancelled",
        "tournament_id": tournament_id,
        "registration_id": reg.id,
        "registered_teams_count": t.registered_teams_count,
    })

    return {"success": True, "message": f"Registration for '{reg.team_name}' has been cancelled."}


# =====================================================================
# 4. FIXTURE GENERATION & MATCH SCHEDULING (STRICT OWNERSHIP)
# =====================================================================

@router.post("/{tournament_id}/fixtures/generate", response_model=List[TournamentMatchOut])
async def generate_tournament_fixtures(
    tournament_id: int,
    req: TournamentFixturesGenerate,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_user_obj),
):
    """
    Generate actual tournament fixtures from approved registered teams.
    CRITICAL OWNERSHIP RULE: Only the tournament creator can generate or modify fixtures.
    """
    tourn_res = await db.execute(
        select(Tournament)
        .options(selectinload(Tournament.registrations), selectinload(Tournament.matches))
        .filter(Tournament.id == tournament_id)
    )
    t = tourn_res.scalar_one_or_none()
    if not t:
        raise HTTPException(status_code=404, detail="Tournament not found")

    # Authorize ownership
    if t.creator_id != user.id and user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Forbidden: Only the tournament creator can generate tournament fixtures."
        )

    # Check for active approved registered teams
    approved_teams = [r for r in t.registrations if r.status == "Approved"]
    if len(approved_teams) < 2:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"At least 2 approved teams are required to generate fixtures. Currently approved: {len(approved_teams)}."
        )

    # Check if any matches have already been completed; protect against accidental overwrite
    completed_matches = [m for m in t.matches if m.status == "completed"]
    if completed_matches:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot regenerate fixtures because matches have already been completed."
        )

    # Clear unplayed matches
    for old_m in list(t.matches):
        await db.delete(old_m)

    team_list = list(approved_teams)
    strategy = (req.strategy or "balanced").lower()

    if strategy == "random":
        import random
        random.shuffle(team_list)
    elif strategy == "seeded":
        team_list.sort(key=lambda x: x.created_at)

    pitches = ["Center Pitch A", "North Court Pitch B", "East Turf Pitch C"]
    time_slots = [
        "Day 1 • 05:00 PM",
        "Day 1 • 06:15 PM",
        "Day 1 • 07:30 PM",
        "Day 1 • 08:45 PM",
        "Day 2 • 05:30 PM",
        "Day 2 • 07:00 PM",
        "Day 3 • 06:30 PM",
    ]

    new_matches: List[TournamentMatch] = []
    match_number = 1

    # Round 1: Pair registered teams
    pairs_count = len(team_list) // 2

    if pairs_count == 1:
        # Exactly 2 teams: Single Grand Final match!
        t1 = team_list[0]
        t2 = team_list[1]
        m = TournamentMatch(
            tournament_id=t.id,
            match_number=1,
            round=1,
            stage="Grand Final Championship",
            stage_group="Final",
            team_a_registration_id=t1.id,
            team_b_registration_id=t2.id,
            team_a_name=t1.team_name,
            team_b_name=t2.team_name,
            team_a_score=0,
            team_b_score=0,
            status="scheduled",
            venue_pitch="Championship Center Pitch",
            scheduled_time=time_slots[0],
            notes="Grand Final Championship Match",
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow(),
        )
        db.add(m)
        new_matches.append(m)

    elif pairs_count == 2:
        # 4 teams: Round 1 (Semi Finals), Round 2 (Grand Final)
        for i in range(2):
            t1 = team_list[i * 2]
            t2 = team_list[i * 2 + 1]
            m = TournamentMatch(
                tournament_id=t.id,
                match_number=match_number,
                round=1,
                stage=f"Semi Final {match_number}",
                stage_group="Semi Finals",
                team_a_registration_id=t1.id,
                team_b_registration_id=t2.id,
                team_a_name=t1.team_name,
                team_b_name=t2.team_name,
                team_a_score=0,
                team_b_score=0,
                status="scheduled",
                venue_pitch=pitches[i % len(pitches)],
                scheduled_time=time_slots[i % len(time_slots)],
                notes=f"Semi Final Match {match_number}",
                created_at=datetime.utcnow(),
                updated_at=datetime.utcnow(),
            )
            db.add(m)
            new_matches.append(m)
            match_number += 1

        # Grand Final
        final_m = TournamentMatch(
            tournament_id=t.id,
            match_number=match_number,
            round=2,
            stage="Grand Final Championship",
            stage_group="Final",
            team_a_registration_id=None,
            team_b_registration_id=None,
            team_a_name="Winner Match 1",
            team_b_name="Winner Match 2",
            team_a_score=0,
            team_b_score=0,
            status="scheduled",
            venue_pitch="Championship Center Pitch",
            scheduled_time="Day 2 • 07:30 PM",
            notes="Grand Final Championship Match",
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow(),
        )
        db.add(final_m)
        new_matches.append(final_m)

    elif pairs_count <= 4:
        # Up to 8 teams: Quarter Finals (Round 1), Semi Finals (Round 2), Grand Final (Round 3)
        round1_matches = []
        for i in range(pairs_count):
            t1 = team_list[i * 2]
            t2 = team_list[i * 2 + 1]
            m = TournamentMatch(
                tournament_id=t.id,
                match_number=match_number,
                round=1,
                stage=f"Quarter Final {match_number}",
                stage_group="Quarter Finals",
                team_a_registration_id=t1.id,
                team_b_registration_id=t2.id,
                team_a_name=t1.team_name,
                team_b_name=t2.team_name,
                team_a_score=0,
                team_b_score=0,
                status="scheduled",
                venue_pitch=pitches[(match_number - 1) % len(pitches)],
                scheduled_time=time_slots[(match_number - 1) % len(time_slots)],
                notes="Quarter Final Match",
                created_at=datetime.utcnow(),
                updated_at=datetime.utcnow(),
            )
            db.add(m)
            new_matches.append(m)
            round1_matches.append(m)
            match_number += 1

        # Semi Finals
        sf1 = TournamentMatch(
            tournament_id=t.id,
            match_number=match_number,
            round=2,
            stage="Semi Final 1",
            stage_group="Semi Finals",
            team_a_registration_id=None,
            team_b_registration_id=None,
            team_a_name="Winner Match 1",
            team_b_name="Winner Match 2" if len(round1_matches) >= 2 else "TBD",
            team_a_score=0,
            team_b_score=0,
            status="scheduled",
            venue_pitch="Pitch A (Main Court)",
            scheduled_time="Day 2 • 06:00 PM",
            notes="Semi Final 1 Match",
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow(),
        )
        db.add(sf1)
        new_matches.append(sf1)
        sf1_num = match_number
        match_number += 1

        sf2 = TournamentMatch(
            tournament_id=t.id,
            match_number=match_number,
            round=2,
            stage="Semi Final 2",
            stage_group="Semi Finals",
            team_a_registration_id=None,
            team_b_registration_id=None,
            team_a_name="Winner Match 3" if len(round1_matches) >= 3 else "TBD",
            team_b_name="Winner Match 4" if len(round1_matches) >= 4 else "TBD",
            team_a_score=0,
            team_b_score=0,
            status="scheduled",
            venue_pitch="Pitch B (North Arena)",
            scheduled_time="Day 2 • 07:15 PM",
            notes="Semi Final 2 Match",
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow(),
        )
        db.add(sf2)
        new_matches.append(sf2)
        sf2_num = match_number
        match_number += 1

        # Grand Final
        final_m = TournamentMatch(
            tournament_id=t.id,
            match_number=match_number,
            round=3,
            stage="Grand Final Championship",
            stage_group="Final",
            team_a_registration_id=None,
            team_b_registration_id=None,
            team_a_name=f"Winner Match {sf1_num}",
            team_b_name=f"Winner Match {sf2_num}",
            team_a_score=0,
            team_b_score=0,
            status="scheduled",
            venue_pitch="Championship Center Pitch",
            scheduled_time="Day 3 • 07:30 PM",
            notes="Grand Final Championship Match",
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow(),
        )
        db.add(final_m)
        new_matches.append(final_m)

    else:
        # Up to 16 teams (Round of 16 -> Quarters -> Semis -> Final)
        r1_count = min(pairs_count, 8)
        for i in range(r1_count):
            t1 = team_list[i * 2]
            t2 = team_list[i * 2 + 1]
            m = TournamentMatch(
                tournament_id=t.id,
                match_number=match_number,
                round=1,
                stage=f"Round of 16 • Match {match_number}",
                stage_group="Round of 16",
                team_a_registration_id=t1.id,
                team_b_registration_id=t2.id,
                team_a_name=t1.team_name,
                team_b_name=t2.team_name,
                team_a_score=0,
                team_b_score=0,
                status="scheduled",
                venue_pitch=pitches[(match_number - 1) % len(pitches)],
                scheduled_time=time_slots[(match_number - 1) % len(time_slots)],
                notes="Round of 16 Match",
                created_at=datetime.utcnow(),
                updated_at=datetime.utcnow(),
            )
            db.add(m)
            new_matches.append(m)
            match_number += 1

        # 4 Quarter Finals
        qf_start = match_number
        for q in range(4):
            qf = TournamentMatch(
                tournament_id=t.id,
                match_number=match_number,
                round=2,
                stage=f"Quarter Final {q + 1}",
                stage_group="Quarter Finals",
                team_a_name=f"Winner Match {q * 2 + 1}",
                team_b_name=f"Winner Match {q * 2 + 2}",
                status="scheduled",
                venue_pitch="Pitch A",
                scheduled_time=f"Day 2 • 0{5 + q}:00 PM",
                created_at=datetime.utcnow(),
                updated_at=datetime.utcnow(),
            )
            db.add(qf)
            new_matches.append(qf)
            match_number += 1

        # 2 Semi Finals
        sf_start = match_number
        sf1 = TournamentMatch(
            tournament_id=t.id,
            match_number=match_number,
            round=3,
            stage="Semi Final 1",
            stage_group="Semi Finals",
            team_a_name=f"Winner Match {qf_start}",
            team_b_name=f"Winner Match {qf_start + 1}",
            status="scheduled",
            venue_pitch="Pitch A",
            scheduled_time="Day 3 • 06:00 PM",
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow(),
        )
        db.add(sf1)
        new_matches.append(sf1)
        match_number += 1

        sf2 = TournamentMatch(
            tournament_id=t.id,
            match_number=match_number,
            round=3,
            stage="Semi Final 2",
            stage_group="Semi Finals",
            team_a_name=f"Winner Match {qf_start + 2}",
            team_b_name=f"Winner Match {qf_start + 3}",
            status="scheduled",
            venue_pitch="Pitch B",
            scheduled_time="Day 3 • 07:15 PM",
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow(),
        )
        db.add(sf2)
        new_matches.append(sf2)
        match_number += 1

        # Final
        final_m = TournamentMatch(
            tournament_id=t.id,
            match_number=match_number,
            round=4,
            stage="Grand Final Championship",
            stage_group="Final",
            team_a_name=f"Winner Match {sf_start}",
            team_b_name=f"Winner Match {sf_start + 1}",
            status="scheduled",
            venue_pitch="Championship Center Pitch",
            scheduled_time="Day 4 • 07:30 PM",
            created_at=datetime.utcnow(),
            updated_at=datetime.utcnow(),
        )
        db.add(final_m)
        new_matches.append(final_m)

    t.fixtures_generated = True
    t.updated_at = datetime.utcnow()
    await db.commit()

    # Re-query newly created matches with IDs
    res = await db.execute(
        select(TournamentMatch)
        .filter(TournamentMatch.tournament_id == tournament_id)
        .order_by(TournamentMatch.round, TournamentMatch.match_number)
    )
    generated_matches = res.scalars().all()

    # Real-time WebSocket Broadcast
    await ws_manager.broadcast("tournaments", {
        "type": "tournament_fixtures_generated",
        "tournament_id": tournament_id,
        "total_matches": len(generated_matches),
    })

    return generated_matches


@router.get("/{tournament_id}/fixtures", response_model=List[TournamentMatchOut])
async def get_tournament_fixtures(tournament_id: int, db: AsyncSession = Depends(get_db)):
    """Get all fixtures and match schedules for a tournament."""
    res = await db.execute(
        select(TournamentMatch)
        .filter(TournamentMatch.tournament_id == tournament_id)
        .order_by(TournamentMatch.round, TournamentMatch.match_number)
    )
    return res.scalars().all()


# =====================================================================
# 5. SCORE MANAGEMENT & RESULT SYNCHRONIZATION (STRICT OWNERSHIP)
# =====================================================================

@router.put("/{tournament_id}/matches/{match_id}/score", response_model=TournamentMatchOut)
async def update_match_score(
    tournament_id: int,
    match_id: int,
    req: TournamentMatchScoreUpdate,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_user_obj),
):
    """
    Update score and status for a tournament fixture.
    CRITICAL OWNERSHIP RULE: Only the tournament creator can enter and update match scores.
    Automatically advances knockout winners to subsequent rounds.
    """
    tourn_res = await db.execute(
        select(Tournament)
        .options(selectinload(Tournament.matches))
        .filter(Tournament.id == tournament_id)
    )
    t = tourn_res.scalar_one_or_none()
    if not t:
        raise HTTPException(status_code=404, detail="Tournament not found")

    # Authorize ownership
    if t.creator_id != user.id and user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Forbidden: Only the tournament creator can enter and update scores."
        )

    match_res = await db.execute(
        select(TournamentMatch).filter(
            TournamentMatch.id == match_id,
            TournamentMatch.tournament_id == tournament_id,
        )
    )
    m = match_res.scalar_one_or_none()
    if not m:
        raise HTTPException(status_code=404, detail="Match fixture not found")

    m.team_a_score = req.team_a_score
    m.team_b_score = req.team_b_score
    m.status = req.status or "completed"

    # Compute winner if match is completed
    if m.status == "completed":
        if m.team_a_score > m.team_b_score:
            m.winner_name = m.team_a_name
        elif m.team_b_score > m.team_a_score:
            m.winner_name = m.team_b_name
        else:
            m.winner_name = req.winner_name or f"{m.team_a_name} (Penalties)"

        # Propagate winner into subsequent bracket round match
        target_token = f"Winner Match {m.match_number}"
        for future_m in t.matches:
            if future_m.round > m.round:
                if future_m.team_a_name == target_token or target_token in future_m.team_a_name:
                    future_m.team_a_name = m.winner_name
                    future_m.updated_at = datetime.utcnow()
                elif future_m.team_b_name == target_token or target_token in future_m.team_b_name:
                    future_m.team_b_name = m.winner_name
                    future_m.updated_at = datetime.utcnow()

    # Update tournament status: if any match completed or live, set to Ongoing
    if m.status in ("live", "completed") and t.status in ("Draft", "Open Entry", "Upcoming"):
        t.status = "Ongoing (Live)"

    # If the Grand Final is completed, mark tournament as Completed
    final_matches = [match for match in t.matches if "final" in match.stage.lower() and "semi" not in match.stage.lower() and "quarter" not in match.stage.lower()]
    if final_matches and all(fm.status == "completed" for fm in final_matches):
        t.status = "Completed"

    m.updated_at = datetime.utcnow()
    t.updated_at = datetime.utcnow()

    await db.commit()
    await db.refresh(m)

    # Real-time WebSocket Broadcast to both tournament and scoreboard channels
    score_payload = {
        "type": "tournament_score_updated",
        "tournament_id": tournament_id,
        "match_id": m.id,
        "team_a_name": m.team_a_name,
        "team_b_name": m.team_b_name,
        "team_a_score": m.team_a_score,
        "team_b_score": m.team_b_score,
        "status": m.status,
        "winner_name": m.winner_name,
        "tournament_status": t.status,
    }
    await ws_manager.broadcast("tournaments", score_payload)
    await ws_manager.broadcast("scoreboard", score_payload)

    return m
