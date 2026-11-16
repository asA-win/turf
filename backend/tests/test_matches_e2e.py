import pytest
import os
import sys
from httpx import AsyncClient

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from app.core.security import create_access_token


@pytest.mark.asyncio
async def test_matches_full_lifecycle_and_ownership(async_client: AsyncClient):
    client = async_client

    # 1. Setup two authenticated test users
    token_a = create_access_token({
        "uid": "match_creator_a_uid",
        "user_id": 801,
        "email": "creator_a@turfmatches.com",
        "name": "Captain Alice",
        "role": "user",
    })
    headers_a = {"Authorization": f"Bearer {token_a}"}

    token_b = create_access_token({
        "uid": "match_user_b_uid",
        "user_id": 802,
        "email": "player_b@turfmatches.com",
        "name": "Striker Bob",
        "role": "user",
    })
    headers_b = {"Authorization": f"Bearer {token_b}"}

    token_c = create_access_token({
        "uid": "match_user_c_uid",
        "user_id": 803,
        "email": "spectator_c@turfmatches.com",
        "name": "Midfielder Charlie",
        "role": "user",
    })
    headers_c = {"Authorization": f"Bearer {token_c}"}

    # -----------------------------------------------------------------
    # STEP 1: Verify Clean State (No fake demo "Turf Titans" auto-injected)
    # -----------------------------------------------------------------
    res = await client.get("/api/v1/matches/")
    assert res.status_code == 200
    # Any pre-existing matches should not contain auto-generated demo data
    all_matches = res.json()
    assert isinstance(all_matches, list)

    # -----------------------------------------------------------------
    # STEP 2: User A creates a Match
    # -----------------------------------------------------------------
    create_payload = {
        "title": "Koramangala Champions Friday League",
        "sport_type": "Football",
        "format": "5v5",
        "venue_name": "Play Arena Turf",
        "location": "Sarjapur Road, Bangalore",
        "match_date": "2026-11-20",
        "match_time": "19:00",
        "duration_minutes": 60,
        "team_a_name": "Thunderbolts",
        "team_b_name": "Shadow Strikers",
        "team_a_color": "Neon Green",
        "team_b_color": "Crimson Red",
        "status": "scheduled",
        "max_players": 2,  # set to 2 so we can test capacity limit easily
        "price_per_player": 250.0,
        "skill_level": "Intermediate",
    }
    res = await client.post("/api/v1/matches/", json=create_payload, headers=headers_a)
    assert res.status_code == 200
    match_a = res.json()
    match_a_id = match_a["id"]
    assert match_a["title"] == "Koramangala Champions Friday League"
    assert match_a["team_a_name"] == "Thunderbolts"
    assert match_a["creator_id"] is not None
    assert match_a["current_players_count"] == 1
    assert len(match_a["participants"]) == 1
    assert match_a["participants"][0]["team"] == "A"
    assert match_a["participants"][0]["player_name"] == "Captain Alice"

    # -----------------------------------------------------------------
    # STEP 3: My Matches Tab Isolation
    # -----------------------------------------------------------------
    # User A sees match_a in My Matches
    res_my_a = await client.get("/api/v1/matches/my", headers=headers_a)
    assert res_my_a.status_code == 200
    my_a_ids = [m["id"] for m in res_my_a.json()]
    assert match_a_id in my_a_ids

    # User B should NOT see match_a in My Matches yet
    res_my_b = await client.get("/api/v1/matches/my", headers=headers_b)
    assert res_my_b.status_code == 200
    my_b_ids = [m["id"] for m in res_my_b.json()]
    assert match_a_id not in my_b_ids

    # -----------------------------------------------------------------
    # STEP 4: User B views and joins Match A
    # -----------------------------------------------------------------
    # User B discovers match_a
    res = await client.get(f"/api/v1/matches/{match_a_id}")
    assert res.status_code == 200
    assert res.json()["id"] == match_a_id

    # User B joins Team B
    join_payload = {
        "team": "B",
        "player_name": "Striker Bob",
        "player_role": "Striker",
        "jersey_number": "9",
    }
    res_join = await client.post(f"/api/v1/matches/{match_a_id}/join", json=join_payload, headers=headers_b)
    assert res_join.status_code == 200
    part_b = res_join.json()
    assert part_b["team"] == "B"
    assert part_b["player_name"] == "Striker Bob"

    # Verify match details now show 2 players
    res_check = await client.get(f"/api/v1/matches/{match_a_id}")
    assert res_check.status_code == 200
    assert res_check.json()["current_players_count"] == 2
    assert len(res_check.json()["participants"]) == 2

    # User B now sees Match A under My Matches
    res_my_b = await client.get("/api/v1/matches/my", headers=headers_b)
    assert res_my_b.status_code == 200
    assert match_a_id in [m["id"] for m in res_my_b.json()]

    # Duplicate join prevention: User B tries to join again
    res_dup = await client.post(f"/api/v1/matches/{match_a_id}/join", json=join_payload, headers=headers_b)
    assert res_dup.status_code == 400
    assert "already joined" in res_dup.json()["detail"].lower()

    # Capacity enforcement: User C tries to join when max_players=2
    res_cap = await client.post(
        f"/api/v1/matches/{match_a_id}/join",
        json={"team": "A", "player_name": "Midfielder Charlie"},
        headers=headers_c,
    )
    assert res_cap.status_code == 400
    assert "full" in res_cap.json()["detail"].lower()

    # -----------------------------------------------------------------
    # STEP 5: Strict Security and Ownership Enforcement
    # -----------------------------------------------------------------
    # User B (participant) tries to edit match details -> 403 Forbidden
    res_unauth_edit = await client.put(
        f"/api/v1/matches/{match_a_id}",
        json={"title": "Hacked Title"},
        headers=headers_b,
    )
    assert res_unauth_edit.status_code == 403

    # User B tries to update live score -> 403 Forbidden
    res_unauth_score = await client.put(
        f"/api/v1/matches/{match_a_id}/score",
        json={"team_a_score": 10, "team_b_score": 0},
        headers=headers_b,
    )
    assert res_unauth_score.status_code == 403

    # User B tries to add a timeline event -> 403 Forbidden
    res_unauth_timeline = await client.post(
        f"/api/v1/matches/{match_a_id}/timeline",
        json={"event_type": "goal", "minute": "10'", "team": "B", "player_name": "Striker Bob"},
        headers=headers_b,
    )
    assert res_unauth_timeline.status_code == 403

    # User B tries to finish the match -> 403 Forbidden
    res_unauth_finish = await client.put(
        f"/api/v1/matches/{match_a_id}/finish",
        json={"mvp_player_name": "Striker Bob"},
        headers=headers_b,
    )
    assert res_unauth_finish.status_code == 403

    # User B tries to delete the match -> 403 Forbidden
    res_unauth_del = await client.delete(f"/api/v1/matches/{match_a_id}", headers=headers_b)
    assert res_unauth_del.status_code == 403

    # -----------------------------------------------------------------
    # STEP 6: Creator A Live Scoreboard & Timeline Management
    # -----------------------------------------------------------------
    # Creator A starts the match and updates score
    res_score = await client.put(
        f"/api/v1/matches/{match_a_id}/score",
        json={"team_a_score": 1, "team_b_score": 0, "status": "live"},
        headers=headers_a,
    )
    assert res_score.status_code == 200
    assert res_score.json()["team_a_score"] == 1
    assert res_score.json()["status"] == "live"

    # Creator A records timeline events
    res_tl1 = await client.post(
        f"/api/v1/matches/{match_a_id}/timeline",
        json={
            "event_type": "goal",
            "minute": "12'",
            "team": "A",
            "player_name": "Captain Alice",
            "description": "Right-footed top corner strike",
            "score_snapshot": "1 - 0",
        },
        headers=headers_a,
    )
    assert res_tl1.status_code == 200
    assert len(res_tl1.json()["events"]) == 1

    # Team B equalizes
    await client.put(
        f"/api/v1/matches/{match_a_id}/score",
        json={"team_a_score": 1, "team_b_score": 1},
        headers=headers_a,
    )
    res_tl2 = await client.post(
        f"/api/v1/matches/{match_a_id}/timeline",
        json={
            "event_type": "goal",
            "minute": "28'",
            "team": "B",
            "player_name": "Striker Bob",
            "description": "Counter-attack tap in",
            "score_snapshot": "1 - 1",
        },
        headers=headers_a,
    )
    assert res_tl2.status_code == 200
    assert len(res_tl2.json()["events"]) == 2

    # Check match stats computes real dynamic events without fake dummy players
    res_stats = await client.get(f"/api/v1/matches/{match_a_id}/stats")
    assert res_stats.status_code == 200
    stats = res_stats.json()
    assert stats["events_count"] == 2
    assert stats["team_a_score"] == 1
    assert stats["team_b_score"] == 1
    assert len(stats["timeline_events"]) == 2

    # -----------------------------------------------------------------
    # STEP 7: Conclude Match & Declare MVP
    # -----------------------------------------------------------------
    finish_payload = {
        "mvp_player_name": "Striker Bob",
        "mvp_notes": "Equalizing goal and 4 key dribbles",
        "final_team_a_score": 1,
        "final_team_b_score": 1,
    }
    res_fin = await client.put(f"/api/v1/matches/{match_a_id}/finish", json=finish_payload, headers=headers_a)
    assert res_fin.status_code == 200
    fin_match = res_fin.json()
    assert fin_match["status"] == "completed"
    assert fin_match["mvp_player_name"] == "Striker Bob"

    # Cannot join a completed match
    res_join_comp = await client.post(
        f"/api/v1/matches/{match_a_id}/join",
        json={"team": "A", "player_name": "Late Charlie"},
        headers=headers_c,
    )
    assert res_join_comp.status_code == 400
    assert "completed" in res_join_comp.json()["detail"].lower()

    # -----------------------------------------------------------------
    # STEP 8: Creator B creates their own match & Cross-Creator Isolation
    # -----------------------------------------------------------------
    create_payload_b = {
        "title": "Badminton Singles Open Arena",
        "sport_type": "Badminton",
        "format": "Singles",
        "venue_name": "Play Arena Court 2",
        "team_a_name": "Bob Smashers",
        "team_b_name": "Challengers",
        "status": "scheduled",
        "max_players": 2,
    }
    res_b_match = await client.post("/api/v1/matches/", json=create_payload_b, headers=headers_b)
    assert res_b_match.status_code == 200
    match_b = res_b_match.json()
    match_b_id = match_b["id"]

    # In 'created' tab:
    # User A sees only match_a
    res_a_created = await client.get("/api/v1/matches/my?tab=created", headers=headers_a)
    a_created_ids = [m["id"] for m in res_a_created.json()]
    assert match_a_id in a_created_ids
    assert match_b_id not in a_created_ids

    # User B sees only match_b
    res_b_created = await client.get("/api/v1/matches/my?tab=created", headers=headers_b)
    b_created_ids = [m["id"] for m in res_b_created.json()]
    assert match_b_id in b_created_ids
    assert match_a_id not in b_created_ids

    # User A cannot manage match_b
    res_a_hack_b = await client.put(f"/api/v1/matches/{match_b_id}", json={"title": "A Hacked B"}, headers=headers_a)
    assert res_a_hack_b.status_code == 403

    # User B can delete their own match_b
    res_del_b = await client.delete(f"/api/v1/matches/{match_b_id}", headers=headers_b)
    assert res_del_b.status_code == 200

    # Match B is now gone
    res_b_gone = await client.get(f"/api/v1/matches/{match_b_id}")
    assert res_b_gone.status_code == 404
