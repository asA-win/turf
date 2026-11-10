import json
from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from app.core.websocket_manager import ws_manager

router = APIRouter()

@router.websocket("/scoreboard")
async def websocket_scoreboard(websocket: WebSocket):
    channel = "scoreboard"
    await ws_manager.connect(websocket, channel)
    try:
        while True:
            data_text = await websocket.receive_text()
            try:
                data = json.loads(data_text)
                await ws_manager.broadcast(channel, data)
            except Exception:
                pass
    except WebSocketDisconnect:
        ws_manager.disconnect(websocket, channel)

@router.websocket("/slots/{turf_id}")
async def websocket_slots(websocket: WebSocket, turf_id: int):
    channel = f"slots_{turf_id}"
    await ws_manager.connect(websocket, channel)
    try:
        while True:
            data_text = await websocket.receive_text()
            try:
                data = json.loads(data_text)
                await ws_manager.broadcast(channel, data)
            except Exception:
                pass
    except WebSocketDisconnect:
        ws_manager.disconnect(websocket, channel)

@router.websocket("/chat/{room_id}")
async def websocket_chat(websocket: WebSocket, room_id: str):
    channel = f"chat_{room_id}"
    await ws_manager.connect(websocket, channel)
    try:
        while True:
            data_text = await websocket.receive_text()
            try:
                data = json.loads(data_text)
                await ws_manager.broadcast(channel, data)
            except Exception:
                pass
    except WebSocketDisconnect:
        ws_manager.disconnect(websocket, channel)

@router.websocket("/user/{user_id}")
async def websocket_user(websocket: WebSocket, user_id: str):
    channel = f"user_{user_id}"
    await ws_manager.connect(websocket, channel)
    try:
        while True:
            data_text = await websocket.receive_text()
            try:
                data = json.loads(data_text)
                await ws_manager.broadcast(channel, data)
            except Exception:
                pass
    except WebSocketDisconnect:
        ws_manager.disconnect(websocket, channel)

@router.websocket("/community")
async def websocket_community(websocket: WebSocket):
    channel = "community"
    await ws_manager.connect(websocket, channel)
    try:
        while True:
            data_text = await websocket.receive_text()
            try:
                data = json.loads(data_text)
                await ws_manager.broadcast(channel, data)
            except Exception:
                pass
    except WebSocketDisconnect:
        ws_manager.disconnect(websocket, channel)

@router.websocket("/booking_requests")
async def websocket_booking_requests(websocket: WebSocket):
    channel = "booking_requests"
    await ws_manager.connect(websocket, channel)
    try:
        while True:
            data_text = await websocket.receive_text()
            try:
                data = json.loads(data_text)
                await ws_manager.broadcast(channel, data)
            except Exception:
                pass
    except WebSocketDisconnect:
        ws_manager.disconnect(websocket, channel)

@router.websocket("/booking_updates")
async def websocket_booking_updates(websocket: WebSocket):
    channel = "booking_updates"
    await ws_manager.connect(websocket, channel)
    try:
        while True:
            data_text = await websocket.receive_text()
            try:
                data = json.loads(data_text)
                await ws_manager.broadcast(channel, data)
            except Exception:
                pass
    except WebSocketDisconnect:
        ws_manager.disconnect(websocket, channel)

@router.websocket("/parking")
async def websocket_parking(websocket: WebSocket):
    channel = "parking"
    await ws_manager.connect(websocket, channel)
    try:
        while True:
            data_text = await websocket.receive_text()
            try:
                data = json.loads(data_text)
                await ws_manager.broadcast(channel, data)
            except Exception:
                pass
    except WebSocketDisconnect:
        ws_manager.disconnect(websocket, channel)

@router.websocket("/channel/{channel_name}")
async def websocket_generic_channel(websocket: WebSocket, channel_name: str):
    channel = channel_name
    await ws_manager.connect(websocket, channel)
    try:
        while True:
            data_text = await websocket.receive_text()
            try:
                data = json.loads(data_text)
                await ws_manager.broadcast(channel, data)
            except Exception:
                pass
    except WebSocketDisconnect:
        ws_manager.disconnect(websocket, channel)

