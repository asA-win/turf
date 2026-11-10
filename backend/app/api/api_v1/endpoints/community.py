from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from pydantic import BaseModel
from typing import Optional
from app.db.session import get_db
from app.db.models import CommunityPost, User
from app.core.security import get_current_user
from app.core.websocket_manager import ws_manager

router = APIRouter()

class PostCreate(BaseModel):
    content: str
    image_url: Optional[str] = None

@router.get("/")
async def get_community_posts(db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(CommunityPost))
    posts = result.scalars().all()
    if not posts:
        default_post = CommunityPost(
            content="Great match last night! ⚽🔥 What a comeback victory!",
            image_url="https://images.unsplash.com/photo-1529900748604-07564a03e7a6?w=800",
            likes_count=100,
            comments_count=24
        )
        db.add(default_post)
        await db.commit()
        result = await db.execute(select(CommunityPost))
        posts = result.scalars().all()

    res = []
    for p in posts:
        res.append({
            "id": p.id,
            "author": "Alex Johnson",
            "content": p.content,
            "image_url": p.image_url,
            "likes_count": p.likes_count,
            "comments_count": p.comments_count,
            "created_at": p.created_at.strftime("%Y-%m-%d %H:%M") if p.created_at else "Just now"
        })
    return res

@router.post("/")
async def create_post(
    post_in: PostCreate,
    db: AsyncSession = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    post = CommunityPost(
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

