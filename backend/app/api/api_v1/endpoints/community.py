from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
from app.db.session import get_db
from app.db.models import CommunityPost, User, DirectMessage
from app.core.security import get_current_user
from app.core.websocket_manager import ws_manager

router = APIRouter()

class PostCreate(BaseModel):
    content: str
    image_url: Optional[str] = None

@router.get("/")
async def get_community_posts(db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(CommunityPost, User)
        .outerjoin(User, CommunityPost.user_id == User.id)
        .order_by(CommunityPost.id.desc())
    )
    rows = result.all()
    if not rows:
        default_post = CommunityPost(
            content="Great match last night! ⚽🔥 What a comeback victory!",
            image_url="https://images.unsplash.com/photo-1529900748604-07564a03e7a6?w=800",
            likes_count=100,
            comments_count=24
        )
        db.add(default_post)
        await db.commit()
        result = await db.execute(
            select(CommunityPost, User)
            .outerjoin(User, CommunityPost.user_id == User.id)
            .order_by(CommunityPost.id.desc())
        )
        rows = result.all()

    res = []
    for post, user in rows:
        author = "Player"
        if user:
            author = user.full_name or user.username or "Player"
        res.append({
            "id": post.id,
            "author": author,
            "content": post.content,
            "image_url": post.image_url,
            "likes_count": post.likes_count,
            "comments_count": post.comments_count,
            "created_at": post.created_at.strftime("%Y-%m-%d %H:%M") if post.created_at else "Just now"
        })
    return res

@router.post("/")
async def create_post(
    post_in: PostCreate,
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    user_id = current_user.get("user_id") if isinstance(current_user, dict) else None
    post = CommunityPost(
        user_id=user_id,
        content=post_in.content,
        image_url=post_in.image_url,
        likes_count=0,
        comments_count=0
    )
    db.add(post)
    await db.commit()
    await db.refresh(post)

    author = current_user.get("name") or current_user.get("email") or "Player"
    post_payload = {
        "type": "new_post",
        "id": post.id,
        "author": author,
        "role": "Active Player",
        "avatar": "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100",
        "time": "Just now",
        "content": post.content,
        "image": post.image_url or "https://images.unsplash.com/photo-1529900748604-07564a03e7a6?w=800",
        "likes": 0,
        "isLiked": false if False else False,
        "comments": 0
    }
    await ws_manager.broadcast("community", post_payload)

    return post

@router.post("/{post_id}/like")
async def like_post(post_id: int, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(CommunityPost).filter(CommunityPost.id == post_id))
    post = result.scalar_one_or_none()
    if not post:
        raise HTTPException(status_code=404, detail="Post not found")
    post.likes_count += 1
    await db.commit()

    await ws_manager.broadcast("community", {
        "type": "post_liked",
        "post_id": post_id,
        "likes": post.likes_count
    })

    return {"message": "Liked!", "likes_count": post.likes_count}


# --- Direct 1-on-1 Friend Chat Endpoints ---

def canonicalize_room_id(raw_room: str) -> tuple[str, str]:
    """
    Returns (canonical_room, reverse_room).
    E.g. 'dm_user31_user12' -> ('dm_user12_user31', 'dm_user31_user12')
    """
    clean = raw_room.replace("chat_", "").strip()
    parts = clean.split("_")
    if len(parts) >= 3 and parts[0] == "dm":
        p1 = "".join(c for c in parts[1] if c.isalnum()).lower()
        p2 = "".join(c for c in parts[2] if c.isalnum()).lower()
        sorted_p = sorted([p1, p2])
        canon = f"dm_{sorted_p[0]}_{sorted_p[1]}"
        rev = f"dm_{sorted_p[1]}_{sorted_p[0]}"
        return canon, rev
    return clean, clean

class DirectMessageIn(BaseModel):
    room_id: str
    sender_name: str
    text: str
    sender_id: Optional[int] = None
    recipient_id: Optional[int] = None

@router.get("/chat/conversations")
@router.get("/chat/my-chats")
async def get_conversations(
    username: Optional[str] = None,
    user_id: Optional[int] = None,
    db: AsyncSession = Depends(get_db)
):
    """
    Retrieve active 1-on-1 conversations for a user.
    """
    clean_u = (username or "").strip().lower()
    norm_u = "".join(c for c in clean_u if c.isalnum()).lower()
    from sqlalchemy import or_

    filters = []
    if user_id:
        filters.append(DirectMessage.sender_id == user_id)
        filters.append(DirectMessage.recipient_id == user_id)
    if clean_u:
        filters.append(DirectMessage.room_id.ilike(f"%{clean_u}%"))
        filters.append(DirectMessage.sender_name.ilike(f"%{clean_u}%"))
    if norm_u and norm_u != clean_u:
        filters.append(DirectMessage.room_id.ilike(f"%{norm_u}%"))
        filters.append(DirectMessage.sender_name.ilike(f"%{norm_u}%"))

    if filters:
        stmt = select(DirectMessage).filter(or_(*filters)).order_by(DirectMessage.id.desc()).limit(150)
    else:
        stmt = select(DirectMessage).order_by(DirectMessage.id.desc()).limit(50)

    result = await db.execute(stmt)
    rows = result.scalars().all()

    conversations = {}
    for m in rows:
        canon_room, _ = canonicalize_room_id(m.room_id)
        if canon_room not in conversations:
            # Determine partner username
            parts = canon_room.replace("dm_", "").split("_")
            partner_username = "Friend"
            if len(parts) >= 2:
                p0, p1 = parts[0], parts[1]
                target_u = norm_u or clean_u
                if target_u:
                    partner_username = p1 if p0 == target_u else p0
                elif user_id:
                    partner_username = f"User {p1}" if str(user_id) == p0 else f"User {p0}"
                else:
                    partner_username = p0 if m.sender_name.lower() != p0 else p1

            partner_name = partner_username.capitalize() if partner_username.isalnum() else partner_username

            conversations[canon_room] = {
                "id": m.id,
                "room_id": canon_room,
                "name": partner_name,
                "username": partner_username,
                "role": "Community Player",
                "avatar": "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100",
                "lastMsg": m.message,
                "time": m.created_at.strftime("%I:%M %p") if m.created_at else "Just now",
                "unread": 0,
                "isOnline": True,
                "status": "Online",
            }

    return list(conversations.values())

@router.get("/chat/{room_id}/messages")
async def get_direct_messages(
    room_id: str,
    db: AsyncSession = Depends(get_db)
):
    """Retrieve chat history for a 1-on-1 friend conversation room."""
    clean_room = room_id.replace("chat_", "").strip()
    canon_room, rev_room = canonicalize_room_id(clean_room)

    result = await db.execute(
        select(DirectMessage)
        .filter(
            (DirectMessage.room_id == canon_room) |
            (DirectMessage.room_id == rev_room) |
            (DirectMessage.room_id == clean_room) |
            (DirectMessage.room_id == f"chat_{clean_room}")
        )
        .order_by(DirectMessage.id.asc())
        .limit(150)
    )
    rows = result.scalars().all()
    return [
        {
            "id": m.id,
            "room_id": m.room_id,
            "sender_id": m.sender_id,
            "recipient_id": m.recipient_id,
            "sender": m.sender_name,
            "sender_name": m.sender_name,
            "text": m.message,
            "time": m.created_at.strftime("%I:%M %p") if m.created_at else "Just now",
            "timestamp": m.created_at.isoformat() if m.created_at else None,
        }
        for m in rows
    ]

@router.post("/chat/send")
async def send_direct_message(
    msg_in: DirectMessageIn,
    db: AsyncSession = Depends(get_db)
):
    """Save direct chat message and broadcast in real time across the room."""
    canon_room, rev_room = canonicalize_room_id(msg_in.room_id)
    sender = (msg_in.sender_name or "").strip()
    if not sender or sender.lower() in ["me", "user", "player"]:
        parts = canon_room.replace("dm_", "").split("_")
        if len(parts) >= 2:
            sender = parts[0]

    dm = DirectMessage(
        room_id=canon_room,
        sender_id=msg_in.sender_id,
        recipient_id=msg_in.recipient_id,
        sender_name=sender,
        message=msg_in.text,
        created_at=datetime.utcnow()
    )
    db.add(dm)
    await db.commit()
    await db.refresh(dm)

    payload = {
        "id": dm.id,
        "room_id": canon_room,
        "sender_id": dm.sender_id,
        "recipient_id": dm.recipient_id,
        "sender": dm.sender_name,
        "sender_name": dm.sender_name,
        "text": dm.message,
        "time": dm.created_at.strftime("%I:%M %p"),
        "timestamp": dm.created_at.isoformat(),
    }

    # Broadcast on WebSocket to both canonical room, reverse room, and chat_ prefixes
    await ws_manager.broadcast(canon_room, payload)
    await ws_manager.broadcast(f"chat_{canon_room}", payload)
    if rev_room != canon_room:
        await ws_manager.broadcast(rev_room, payload)
        await ws_manager.broadcast(f"chat_{rev_room}", payload)

    # Broadcast to inbox channels
    await ws_manager.broadcast("chat_inbox", payload)

    return payload


