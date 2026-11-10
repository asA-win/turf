import pytest
from starlette.testclient import TestClient
from main import app
from app.core.websocket_manager import ws_manager

def test_websocket_scoreboard_relay():
    client = TestClient(app)
    with client.websocket_connect("/api/v1/ws/scoreboard") as ws:
        # Send a live score event
        payload = {"type": "score_update", "match_id": 1, "team_a_score": 3, "team_b_score": 2}
        ws.send_json(payload)
        # Read back the broadcasted event
        data = ws.receive_json()
        assert data["type"] == "score_update"
        assert data["team_a_score"] == 3
        assert data["team_b_score"] == 2

def test_websocket_slots_relay():
    client = TestClient(app)
    with client.websocket_connect("/api/v1/ws/slots/1") as ws:
        payload = {"type": "slot_locked", "slot_id": 42, "turf_id": 1}
        ws.send_json(payload)
        data = ws.receive_json()
        assert data["type"] == "slot_locked"
        assert data["slot_id"] == 42

def test_websocket_chat_relay():
    client = TestClient(app)
    with client.websocket_connect("/api/v1/ws/chat/room_alpha") as ws:
        payload = {"sender": "Ronaldo", "text": "Let's play!", "time": "6:00 PM"}
        ws.send_json(payload)
        data = ws.receive_json()
        assert data["sender"] == "Ronaldo"
        assert data["text"] == "Let's play!"

@pytest.mark.asyncio
async def test_backend_broadcast_to_websocket_client():
    client = TestClient(app)
    with client.websocket_connect("/api/v1/ws/slots/99") as ws:
        # Simulate server-side lock broadcast from slots.py
        await ws_manager.broadcast("slots_99", {
            "type": "slot_locked",
            "slot_id": 100,
            "turf_id": 99,
            "locked_by": 1
        })
        received = ws.receive_json()
        assert received["type"] == "slot_locked"
        assert received["slot_id"] == 100
        assert received["turf_id"] == 99

def test_websocket_user_session_relay():
    client = TestClient(app)
    with client.websocket_connect("/api/v1/ws/user/user_123") as ws:
        payload = {"type": "session_active", "user_id": "user_123"}
        ws.send_json(payload)
        received = ws.receive_json()
        assert received["type"] == "session_active"

def test_check_availability_endpoint():
    with TestClient(app) as client:
        # Check random email availability
        res = client.get("/api/v1/users/check-availability?email=unique_player_999@example.com")
        assert res.status_code == 200
        assert res.json()["available"] is True

def test_websocket_booking_requests_relay():
    client = TestClient(app)
    with client.websocket_connect("/api/v1/ws/booking_requests") as ws:
        payload = {"type": "new_booking_request", "id": 777, "name": "Alwin", "sport": "Football"}
        ws.send_json(payload)
        data = ws.receive_json()
        assert data["type"] == "new_booking_request"
        assert data["id"] == 777
        assert data["name"] == "Alwin"

def test_websocket_parking_relay():
    client = TestClient(app)
    with client.websocket_connect("/api/v1/ws/parking") as ws:
        payload = {"type": "parking_updated", "available_slots": 22, "total_slots": 50}
        ws.send_json(payload)
        data = ws.receive_json()
        assert data["type"] == "parking_updated"
        assert data["available_slots"] == 22

def test_websocket_community_relay():
    client = TestClient(app)
    with client.websocket_connect("/api/v1/ws/community") as ws:
        payload = {"type": "new_post", "id": 55, "content": "Match was lit!"}
        ws.send_json(payload)
        data = ws.receive_json()
        assert data["type"] == "new_post"
        assert data["content"] == "Match was lit!"

