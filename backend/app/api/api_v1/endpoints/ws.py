import json
from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from app.core.websocket_manager import ws_manager

router = APIRouter()

async def _handle_ws_loop(websocket: WebSocket, channel: str):
    await ws_manager.connect(websocket, channel)
    try:
        while True:
            data_text = await websocket.receive_text()
            try:
                data = json.loads(data_text)
                if data.get("type") == "ping":
                    await websocket.send_text(json.dumps({"type": "pong"}))
                    continue
                await ws_manager.broadcast(channel, data)
            except Exception:
                pass
    except WebSocketDisconnect:
        ws_manager.disconnect(websocket, channel)

@router.websocket("/scoreboard")
async def websocket_scoreboard(websocket: WebSocket):
    await _handle_ws_loop(websocket, "scoreboard")

@router.websocket("/slots/{turf_id}")
async def websocket_slots(websocket: WebSocket, turf_id: int):
    await _handle_ws_loop(websocket, f"slots_{turf_id}")

@router.websocket("/chat/{room_id}")
async def websocket_chat(websocket: WebSocket, room_id: str):
    await _handle_ws_loop(websocket, f"chat_{room_id}")

@router.websocket("/user/{user_id}")
async def websocket_user(websocket: WebSocket, user_id: str):
    await _handle_ws_loop(websocket, f"user_{user_id}")

@router.websocket("/community")
async def websocket_community(websocket: WebSocket):
    await _handle_ws_loop(websocket, "community")

@router.websocket("/booking_requests")
async def websocket_booking_requests(websocket: WebSocket):
    await _handle_ws_loop(websocket, "booking_requests")

@router.websocket("/booking_updates")
async def websocket_booking_updates(websocket: WebSocket):
    await _handle_ws_loop(websocket, "booking_updates")

@router.websocket("/parking")
async def websocket_parking(websocket: WebSocket):
    await _handle_ws_loop(websocket, "parking")

@router.websocket("/tournaments")
async def websocket_tournaments(websocket: WebSocket):
    await _handle_ws_loop(websocket, "tournaments")

@router.websocket("/teams")
async def websocket_teams(websocket: WebSocket):
    await _handle_ws_loop(websocket, "teams")

@router.websocket("/stocks")
async def websocket_stocks(websocket: WebSocket):
    await _handle_ws_loop(websocket, "stocks")

@router.websocket("/reviews/{turf_id}")
async def websocket_reviews(websocket: WebSocket, turf_id: int):
    await _handle_ws_loop(websocket, f"reviews_{turf_id}")

@router.websocket("/channel/{channel_name}")
async def websocket_generic_channel(websocket: WebSocket, channel_name: str):
    await _handle_ws_loop(websocket, channel_name)


