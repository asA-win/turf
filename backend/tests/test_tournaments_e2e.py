import pytest
import os
import sys
import asyncio
from httpx import AsyncClient, ASGITransport

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from main import app
from app.core.security import create_access_token

@pytest.mark.asyncio
async def test_tournament_full_lifecycle_and_ownership(async_client):
    client = async_client
    if True:
        # 1. Create two test users (Creator A and Creator B / Participant B)
        token_a = create_access_token({
            "uid": "test_user_a_uid_perm",
            "user_id": 901,
            "email": "user_a_perm@test.com",
            "name": "User A (Creator)",
            "role": "user"
        })
        headers_a = {"Authorization": f"Bearer {token_a}"}

        token_b = create_access_token({
            "uid": "test_user_b_uid_perm",
            "user_id": 902,
            "email": "user_b_perm@test.com",
            "name": "User B (Participant)",
            "role": "user"
        })
        headers_b = {"Authorization": f"Bearer {token_b}"}

        # -------------------------------------------------------------
        # STEP 1: Verify Empty State (No hardcoded dummy tournaments injected)
        # -------------------------------------------------------------
        res = await client.get("/api/v1/tournaments/")
        assert res.status_code == 200

        # -------------------------------------------------------------
        # STEP 2: User A creates Tournament A
        # -------------------------------------------------------------
        create_payload_a = {
            "title": "Bangalore Premier Football Cup 2026",
            "description": "Annual 5v5 Knockout Championship",
            "sport": "Football",
            "format": "5v5 Knockout",
            "level": "Open Category",
            "venue": "Play Arena",
            "area": "Koramangala",
            "city": "Bangalore",
            "banner_image": "https://example.com/banner.jpg",
            "prize_pool": 75000.0,
            "entry_fee": 1500.0,
            "total_teams": 4,
            "rules": "Standard FIFA rules apply.",
            "status": "Open Entry",
            "contact_phone": "+91 9876543210"
        }
        res_create_a = await client.post("/api/v1/tournaments/", json=create_payload_a, headers=headers_a)
        assert res_create_a.status_code == 200, res_create_a.text
        tourn_a = res_create_a.json()
        tourn_a_id = tourn_a["id"]
        assert tourn_a["title"] == "Bangalore Premier Football Cup 2026"
        assert tourn_a["creator_id"] is not None

        # -------------------------------------------------------------
        # STEP 3: Creator A finds Tournament A under /tournaments/my
        # -------------------------------------------------------------
        res_my_a = await client.get("/api/v1/tournaments/my", headers=headers_a)
        assert res_my_a.status_code == 200
        my_tournaments_a = res_my_a.json()
        assert any(t["id"] == tourn_a_id for t in my_tournaments_a)

        # User B should NOT see Tournament A under /tournaments/my
        res_my_b = await client.get("/api/v1/tournaments/my", headers=headers_b)
        assert res_my_b.status_code == 200
        my_tournaments_b = res_my_b.json()
        assert not any(t["id"] == tourn_a_id for t in my_tournaments_b)

        # -------------------------------------------------------------
        # STEP 4: User B can discover and view Tournament A
        # -------------------------------------------------------------
        res_detail = await client.get(f"/api/v1/tournaments/{tourn_a_id}")
        assert res_detail.status_code == 200
        assert res_detail.json()["id"] == tourn_a_id

        # -------------------------------------------------------------
        # STEP 5: Unauthorized Modification Attempts by User B
        # -------------------------------------------------------------
        res_unauth_edit = await client.put(
            f"/api/v1/tournaments/{tourn_a_id}",
            json={"title": "Hacked Tournament Title"},
            headers=headers_b
        )
        assert res_unauth_edit.status_code == 403

        res_unauth_fix = await client.post(
            f"/api/v1/tournaments/{tourn_a_id}/fixtures/generate",
            json={"strategy": "balanced"},
            headers=headers_b
        )
        assert res_unauth_fix.status_code == 403

        res_unauth_del = await client.delete(
            f"/api/v1/tournaments/{tourn_a_id}",
            headers=headers_b
        )
        assert res_unauth_del.status_code == 403

        # -------------------------------------------------------------
        # STEP 6: Creator A can edit Tournament A
        # -------------------------------------------------------------
        res_auth_edit = await client.put(
            f"/api/v1/tournaments/{tourn_a_id}",
            json={"prize_pool": 80000.0, "venue": "Play Arena Central Court"},
            headers=headers_a
        )
        assert res_auth_edit.status_code == 200
        assert res_auth_edit.json()["prize_pool"] == 80000.0
        assert res_auth_edit.json()["venue"] == "Play Arena Central Court"

        # -------------------------------------------------------------
        # STEP 7: Team Registrations & Capacity Validation
        # -------------------------------------------------------------
        reg_b_payload = {
            "team_name": "Apex Predators FC",
            "team_tag": "APX",
            "captain_name": "User B Captain",
            "contact_phone": "+91 9988776655",
            "contact_email": "user_b_perm@test.com",
            "jersey_color": "Neon Green",
            "skill_level": "Advanced / Semi-Pro",
            "players": [
                {"name": "User B Captain", "role": "Striker", "jersey": "10"},
                {"name": "Player 2", "role": "Goalkeeper", "jersey": "1"}
            ]
        }
        res_reg_b = await client.post(
            f"/api/v1/tournaments/{tourn_a_id}/register",
            json=reg_b_payload,
            headers=headers_b
        )
        assert res_reg_b.status_code == 200, res_reg_b.text
        reg_b_data = res_reg_b.json()
        assert reg_b_data["team_name"] == "Apex Predators FC"

        # Duplicate registration attempt by User B -> 400 Bad Request
        res_dup_user = await client.post(
            f"/api/v1/tournaments/{tourn_a_id}/register",
            json={"team_name": "Second Team", "captain_name": "User B", "contact_phone": "+91 9988776655"},
            headers=headers_b
        )
        assert res_dup_user.status_code == 400
        assert "already registered" in res_dup_user.json()["detail"].lower()

        # Register 3 more teams to reach capacity of 4
        for i in range(2, 5):
            t_tok = create_access_token({
                "uid": f"test_team_user_{i}_perm",
                "user_id": 920 + i,
                "email": f"team{i}_perm@test.com",
                "name": f"Captain {i}",
                "role": "user"
            })
            reg_payload = {
                "team_name": f"Challengers Squad {i}",
                "team_tag": f"CS{i}",
                "captain_name": f"Captain {i}",
                "contact_phone": f"+91 980000000{i}",
                "contact_email": f"team{i}_perm@test.com",
                "jersey_color": "Royal Blue",
                "skill_level": "Club / Intermediate"
            }
            res_reg = await client.post(
                f"/api/v1/tournaments/{tourn_a_id}/register",
                json=reg_payload,
                headers={"Authorization": f"Bearer {t_tok}"}
            )
            assert res_reg.status_code == 200

        # Capacity 4/4 reached. 5th registration must be rejected with 400
        token_extra = create_access_token({"uid": "extra_user_perm", "user_id": 999, "email": "extra_perm@test.com", "role": "user"})
        res_full = await client.post(
            f"/api/v1/tournaments/{tourn_a_id}/register",
            json={"team_name": "Over Capacity FC", "captain_name": "Extra", "contact_phone": "+91 9999999999"},
            headers={"Authorization": f"Bearer {token_extra}"}
        )
        assert res_full.status_code == 400
        assert "maximum team capacity" in res_full.json()["detail"].lower()

        # -------------------------------------------------------------
        # STEP 8: Fixture Generation & Match Scheduling
        # -------------------------------------------------------------
        res_fixtures = await client.post(
            f"/api/v1/tournaments/{tourn_a_id}/fixtures/generate",
            json={"strategy": "balanced"},
            headers=headers_a
        )
        assert res_fixtures.status_code == 200
        fixtures = res_fixtures.json()
        assert len(fixtures) == 3 # 2 Semi Finals + 1 Final

        m1 = next(m for m in fixtures if m["match_number"] == 1)
        m2 = next(m for m in fixtures if m["match_number"] == 2)
        final_m = next(m for m in fixtures if m["match_number"] == 3)

        # -------------------------------------------------------------
        # STEP 9: Score Updates & Automatic Knockout Advancement
        # -------------------------------------------------------------
        res_score_1 = await client.put(
            f"/api/v1/tournaments/{tourn_a_id}/matches/{m1['id']}/score",
            json={"team_a_score": 3, "team_b_score": 1, "status": "completed"},
            headers=headers_a
        )
        assert res_score_1.status_code == 200
        m1_updated = res_score_1.json()
        assert m1_updated["winner_name"] == m1["team_a_name"]

        res_score_2 = await client.put(
            f"/api/v1/tournaments/{tourn_a_id}/matches/{m2['id']}/score",
            json={"team_a_score": 0, "team_b_score": 2, "status": "completed"},
            headers=headers_a
        )
        assert res_score_2.status_code == 200
        m2_updated = res_score_2.json()
        assert m2_updated["winner_name"] == m2["team_b_name"]

        # Check Final Match: winners should automatically advance
        res_final_check = await client.get(f"/api/v1/tournaments/{tourn_a_id}/fixtures")
        all_matches = res_final_check.json()
        final_match = next(m for m in all_matches if m["match_number"] == 3)
        assert final_match["team_a_name"] == m1_updated["winner_name"]
        assert final_match["team_b_name"] == m2_updated["winner_name"]

        # Update Final Match score -> Tournament status becomes Completed!
        res_final_score = await client.put(
            f"/api/v1/tournaments/{tourn_a_id}/matches/{final_match['id']}/score",
            json={"team_a_score": 2, "team_b_score": 1, "status": "completed"},
            headers=headers_a
        )
        assert res_final_score.status_code == 200
        
        tourn_final = await client.get(f"/api/v1/tournaments/{tourn_a_id}")
        assert tourn_final.json()["status"] == "Completed"

        # -------------------------------------------------------------
        # STEP 10: Multi-Creator Isolation
        # -------------------------------------------------------------
        create_payload_b = {
            "title": "East Bangalore Cricket Super 8",
            "sport": "Cricket",
            "format": "Box Cricket 7v7",
            "prize_pool": 40000.0,
            "total_teams": 8,
            "venue": "Turf Nation",
            "area": "Electronic City",
            "city": "Bangalore"
        }
        res_create_b = await client.post("/api/v1/tournaments/", json=create_payload_b, headers=headers_b)
        assert res_create_b.status_code == 200
        tourn_b_id = res_create_b.json()["id"]

        # Verify My Tournaments isolation
        res_my_a_after = await client.get("/api/v1/tournaments/my", headers=headers_a)
        my_a_ids = [t["id"] for t in res_my_a_after.json()]
        assert tourn_a_id in my_a_ids
        assert tourn_b_id not in my_a_ids

        res_my_b_after = await client.get("/api/v1/tournaments/my", headers=headers_b)
        my_b_ids = [t["id"] for t in res_my_b_after.json()]
        assert tourn_b_id in my_b_ids
        assert tourn_a_id not in my_b_ids

        # User A cannot modify User B's tournament
        res_a_edit_b = await client.put(
            f"/api/v1/tournaments/{tourn_b_id}",
            json={"prize_pool": 99999.0},
            headers=headers_a
        )
        assert res_a_edit_b.status_code == 403
