import pytest

@pytest.mark.asyncio
async def test_root(async_client):
    response = await async_client.get("/")
    assert response.status_code == 200
    assert response.json()["message"] == "Welcome to Turf App API"

@pytest.mark.asyncio
async def test_get_coaches(async_client):
    response = await async_client.get("/api/v1/coaches/")
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)
    assert len(data) >= 3

@pytest.mark.asyncio
async def test_parking_status(async_client):
    response = await async_client.get("/api/v1/parking/status")
    assert response.status_code == 200
    data = response.json()
    assert "available_slots" in data
    assert data["total_slots"] == 50

@pytest.mark.asyncio
async def test_get_rentals(async_client):
    response = await async_client.get("/api/v1/rentals/")
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)
    assert len(data) >= 4

@pytest.mark.asyncio
async def test_get_community_posts(async_client):
    response = await async_client.get("/api/v1/community/")
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)

@pytest.mark.asyncio
async def test_get_stocks(async_client):
    response = await async_client.get("/api/v1/stocks/")
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)


@pytest.mark.asyncio
async def test_get_match_stats(async_client):
    from app.core.security import create_access_token
    token = create_access_token({"uid": "test_user_stats", "user_id": 999, "role": "user"})
    headers = {"Authorization": f"Bearer {token}"}
    create_res = await async_client.post(
        "/api/v1/matches/",
        json={"title": "Stats Test Match", "team_a_name": "Team A", "team_b_name": "Team B"},
        headers=headers,
    )
    assert create_res.status_code == 200
    match_id = create_res.json()["id"]

    stats_res = await async_client.get(f"/api/v1/matches/{match_id}/stats")
    assert stats_res.status_code == 200
    stats = stats_res.json()
    assert stats["match_id"] == match_id
    assert "mvp" in stats
    assert "team_metrics" in stats

@pytest.mark.asyncio
async def test_ws_manager_broadcast():
    from app.core.websocket_manager import ws_manager
    # Broadcast to an empty channel gracefully handles with no errors
    await ws_manager.broadcast("slots_test", {"type": "slot_locked", "slot_id": 999})
    assert True
