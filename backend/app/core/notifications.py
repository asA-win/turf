from firebase_admin import messaging
from typing import List, Optional
import logging

logger = logging.getLogger(__name__)

async def send_fcm_notification(
    tokens: List[str],
    title: str,
    body: str,
    data: Optional[dict] = None
):
    """
    Sends a push notification to a list of FCM tokens.
    """
    if not tokens:
        return

    message = messaging.MulticastMessage(
        notification=messaging.Notification(
            title=title,
            body=body,
        ),
        data=data,
        tokens=tokens,
    )
    
    try:
        response = messaging.send_multicast(message)
        logger.info(f"Successfully sent {response.success_count} notifications")
        if response.failure_count > 0:
            logger.warning(f"Failed to send {response.failure_count} notifications")
        return response
    except Exception as e:
        logger.error(f"Error sending FCM notification: {e}")
        return None

async def send_to_user(db, user_id: int, title: str, body: str, data: Optional[dict] = None):
    """
    Helper to send notification to all devices of a specific user.
    """
    from sqlalchemy.future import select
    from app.db.models import FCMToken
    
    result = await db.execute(select(FCMToken).filter(FCMToken.user_id == user_id))
    tokens = [t.token for t in result.scalars().all()]
    
    if tokens:
        await send_fcm_notification(tokens, title, body, data)
