from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import func, desc
from typing import List, Optional
from datetime import datetime

from app.db.session import get_db
from app.db.models import User, Turf, Slot, Booking, AdminAuditLog
from app.schemas.schemas import (
    Turf as TurfSchema,
    TurfApprovalAction,
    OwnerStatusAction,
    AdminChangePasswordRequest,
    AdminAuditLogResponse
)
from app.core.security import get_current_user, hash_password, verify_password
from app.core.websocket_manager import ws_manager
import logging

logger = logging.getLogger(__name__)

router = APIRouter()

async def get_current_admin(
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
) -> User:
    """Validate that the requesting session belongs to an active Platform Administrator."""
    email = current_user.get("email") or current_user.get("sub")
    uid = current_user.get("uid")

    query = select(User)
    if email:
        query = query.filter(User.email == email.lower())
    elif uid:
        query = query.filter(User.firebase_uid == uid)
    else:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or missing authentication credentials"
        )

    res = await db.execute(query)
    user = res.scalar_one_or_none()

    if not user:
        raise HTTPException(status_code=404, detail="Administrator account not found")

    if user.role != "admin":
        logger.warning(f"Unauthorized admin access attempt by user {user.id} ({user.email})")
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access restricted: Platform Administrator privileges required."
        )

    return user

@router.get("/overview")
async def get_admin_overview(
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_current_admin)
):
    """Return aggregated platform metrics, registration counts, and recent activity logs."""
    # Turfs counts
    all_turfs_res = await db.execute(select(Turf))
    turfs = all_turfs_res.scalars().all()
    total_turfs = len(turfs)
    pending_turfs = sum(1 for t in turfs if (t.status or "pending").lower() == "pending")
    approved_turfs = sum(1 for t in turfs if (t.status or "").lower() == "approved")
    rejected_turfs = sum(1 for t in turfs if (t.status or "").lower() == "rejected")

    # Owners counts
    all_users_res = await db.execute(select(User))
    users = all_users_res.scalars().all()
    owners = [u for u in users if u.role == "owner"]
    total_owners = len(owners)
    active_owners = sum(1 for o in owners if (o.owner_status or "pending").lower() == "approved")
    pending_owners = sum(1 for o in owners if (o.owner_status or "pending").lower() == "pending")
    suspended_owners = sum(1 for o in owners if (o.owner_status or "").lower() == "suspended")
    total_players = sum(1 for u in users if u.role in ("user", None))

    # Bookings count
    bookings_res = await db.execute(select(func.count(Booking.id)))
    total_bookings = bookings_res.scalar() or 0

    # Recent Audit Activities
    logs_res = await db.execute(select(AdminAuditLog).order_by(desc(AdminAuditLog.created_at)).limit(10))
    recent_logs = []
    for l in logs_res.scalars().all():
        recent_logs.append({
            "id": l.id,
            "action": l.action,
            "target_type": l.target_type,
            "target_id": l.target_id,
            "details": l.details,
            "created_at": l.created_at.isoformat() if l.created_at else None
        })

    return {
        "total_turfs": total_turfs,
        "pending_turfs": pending_turfs,
        "approved_turfs": approved_turfs,
        "rejected_turfs": rejected_turfs,
        "total_owners": total_owners,
        "active_owners": active_owners,
        "pending_owners": pending_owners,
        "suspended_owners": suspended_owners,
        "total_users": total_players,
        "total_bookings": total_bookings,
        "recent_activities": recent_logs
    }

@router.get("/turf-registrations")
async def list_turf_registrations(
    status_filter: Optional[str] = Query(None, alias="status"),
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_current_admin)
):
    """Retrieve all submitted turf registrations with owner details, documents, and approval status."""
    query = select(Turf).order_by(desc(Turf.created_at))
    if status_filter and status_filter.lower() != "all":
        query = query.filter(func.lower(Turf.status) == status_filter.lower())

    turfs_res = await db.execute(query)
    turfs = turfs_res.scalars().all()

    results = []
    for t in turfs:
        owner = None
        if t.owner_id:
            owner_res = await db.execute(select(User).filter(User.id == t.owner_id))
            owner = owner_res.scalar_one_or_none()

        results.append({
            "id": t.id,
            "name": t.name,
            "location": t.location,
            "price_per_hour": t.price_per_hour,
            "owner_id": t.owner_id,
            "image_url": t.image_url,
            "document_url": t.document_url,
            "description": t.description,
            "sport_types": t.sport_types,
            "amenities": t.amenities,
            "surface_type": t.turf_type,
            "pitch_info": t.pitch_info,
            "status": (t.status or "pending").lower(),
            "rejection_reason": t.rejection_reason,
            "contact_phone": t.contact_phone or (owner.phone if owner else None),
            "created_at": t.created_at.isoformat() if t.created_at else None,
            "owner": {
                "id": owner.id if owner else None,
                "full_name": owner.full_name if owner else "Unknown Owner",
                "email": owner.email if owner else None,
                "phone": owner.phone if owner else None,
                "business_name": owner.business_name if owner else t.name,
                "city": owner.city if owner else t.location,
                "owner_status": (owner.owner_status or "pending").lower() if owner else "pending"
            } if owner else None
        })

    return results

@router.post("/turf-registrations/{turf_id}/approve")
async def approve_turf_registration(
    turf_id: int,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_current_admin)
):
    """Approve a submitted turf registration and grant the owner live operational access."""
    turf_res = await db.execute(select(Turf).filter(Turf.id == turf_id))
    turf = turf_res.scalar_one_or_none()
    if not turf:
        raise HTTPException(status_code=404, detail="Turf registration not found")

    turf.status = "approved"
    turf.rejection_reason = None
    db.add(turf)

    # Elevate & approve owner
    owner = None
    if turf.owner_id:
        owner_res = await db.execute(select(User).filter(User.id == turf.owner_id))
        owner = owner_res.scalar_one_or_none()
        if owner:
            owner.owner_status = "approved"
            owner.role = "owner"
            owner.rejection_reason = None
            db.add(owner)

    # Record Admin Audit Log
    audit = AdminAuditLog(
        admin_id=admin.id,
        action="APPROVE_TURF",
        target_type="turf",
        target_id=turf_id,
        details=f"Admin {admin.full_name} ({admin.email}) approved venue '{turf.name}' for owner #{turf.owner_id} ({owner.full_name if owner else 'N/A'})"
    )
    db.add(audit)
    await db.commit()
    await db.refresh(turf)

    # Broadcast real-time WebSocket event
    await ws_manager.broadcast("booking_updates", {
        "type": "turf_approved",
        "turf_id": turf.id,
        "owner_id": turf.owner_id,
        "name": turf.name,
        "status": "approved"
    })

    logger.info(f"[ADMIN] Approved turf #{turf.id} ('{turf.name}') by admin #{admin.id}")
    return {
        "success": True,
        "message": f"Venue '{turf.name}' approved successfully! Owner account is now active.",
        "turf_id": turf.id,
        "status": "approved"
    }

@router.post("/turf-registrations/{turf_id}/reject")
async def reject_turf_registration(
    turf_id: int,
    action: TurfApprovalAction,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_current_admin)
):
    """Reject a turf registration with an explicit rejection reason for the owner."""
    turf_res = await db.execute(select(Turf).filter(Turf.id == turf_id))
    turf = turf_res.scalar_one_or_none()
    if not turf:
        raise HTTPException(status_code=404, detail="Turf registration not found")

    reason = (action.reason or "").strip()
    if not reason:
        reason = "Venue does not meet platform quality, licensing, or verification requirements."

    turf.status = "rejected"
    turf.rejection_reason = reason
    db.add(turf)

    # Update owner status
    owner = None
    if turf.owner_id:
        owner_res = await db.execute(select(User).filter(User.id == turf.owner_id))
        owner = owner_res.scalar_one_or_none()
        if owner:
            owner.owner_status = "rejected"
            owner.rejection_reason = reason
            db.add(owner)

    # Record Admin Audit Log
    audit = AdminAuditLog(
        admin_id=admin.id,
        action="REJECT_TURF",
        target_type="turf",
        target_id=turf_id,
        details=f"Admin {admin.full_name} rejected venue '{turf.name}'. Reason: {reason}"
    )
    db.add(audit)
    await db.commit()

    # Broadcast real-time WebSocket event
    await ws_manager.broadcast("booking_updates", {
        "type": "turf_rejected",
        "turf_id": turf.id,
        "owner_id": turf.owner_id,
        "name": turf.name,
        "reason": reason,
        "status": "rejected"
    })

    logger.info(f"[ADMIN] Rejected turf #{turf.id} ('{turf.name}'). Reason: {reason}")
    return {
        "success": True,
        "message": f"Venue '{turf.name}' has been rejected.",
        "turf_id": turf.id,
        "reason": reason,
        "rejection_reason": reason,
        "status": "rejected"
    }

@router.get("/owners")
async def list_turf_owners(
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_current_admin)
):
    """Retrieve all turf owners, their operational status, contact information, and registered venues."""
    owners_res = await db.execute(select(User).filter(User.role == "owner").order_by(desc(User.created_at)))
    owners = owners_res.scalars().all()

    results = []
    for o in owners:
        turfs_res = await db.execute(select(Turf).filter(Turf.owner_id == o.id))
        owner_turfs = turfs_res.scalars().all()

        results.append({
            "id": o.id,
            "full_name": o.full_name,
            "email": o.email,
            "phone": o.phone,
            "business_name": o.business_name or (owner_turfs[0].name if owner_turfs else "Sports Partner"),
            "city": o.city or "Bangalore",
            "owner_status": (o.owner_status or "pending").lower(),
            "rejection_reason": o.rejection_reason,
            "is_verified": o.is_verified,
            "created_at": o.created_at.isoformat() if o.created_at else None,
            "total_turfs": len(owner_turfs),
            "turfs": [
                {
                    "id": t.id,
                    "name": t.name,
                    "location": t.location,
                    "status": (t.status or "pending").lower(),
                    "price_per_hour": t.price_per_hour
                }
                for t in owner_turfs
            ]
        })

    return results

@router.post("/owners/{owner_id}/status")
async def update_owner_status(
    owner_id: int,
    action: OwnerStatusAction,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_current_admin)
):
    """Activate, suspend, or restore an owner's access."""
    owner_res = await db.execute(select(User).filter(User.id == owner_id))
    owner = owner_res.scalar_one_or_none()
    if not owner:
        raise HTTPException(status_code=404, detail="Turf Owner not found")

    target_status = action.status.strip().lower()
    if target_status not in ("approved", "active", "suspended", "rejected", "pending"):
        raise HTTPException(status_code=400, detail="Invalid status. Must be approved, suspended, rejected, or pending.")

    normalized_status = "approved" if target_status in ("approved", "active") else target_status
    owner.owner_status = normalized_status
    if action.reason:
        owner.rejection_reason = action.reason
    db.add(owner)

    audit = AdminAuditLog(
        admin_id=admin.id,
        action=f"{normalized_status.upper()}_OWNER",
        target_type="owner",
        target_id=owner_id,
        details=f"Admin {admin.full_name} set owner #{owner_id} ({owner.full_name}) status to '{normalized_status}'"
    )
    db.add(audit)
    await db.commit()

    await ws_manager.broadcast("booking_updates", {
        "type": "owner_status_updated",
        "owner_id": owner_id,
        "status": normalized_status
    })

    return {
        "success": True,
        "message": f"Owner #{owner_id} ({owner.full_name}) status updated to '{normalized_status}'.",
        "owner_id": owner_id,
        "status": normalized_status,
        "owner_status": normalized_status
    }

@router.get("/audit-logs", response_model=List[AdminAuditLogResponse])
async def get_audit_logs(
    limit: int = 50,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_current_admin)
):
    """Retrieve immutable chronological audit records of all administrative decisions."""
    logs_res = await db.execute(
        select(AdminAuditLog).order_by(desc(AdminAuditLog.created_at)).limit(limit)
    )
    return logs_res.scalars().all()

@router.post("/change-password")
async def change_admin_password(
    req: AdminChangePasswordRequest,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(get_current_admin)
):
    """Allow logged-in admin to securely change their master access password."""
    if not admin.hashed_password or not verify_password(req.current_password, admin.hashed_password):
        raise HTTPException(status_code=400, detail="Current master password is incorrect.")

    if len(req.new_password.strip()) < 8:
        raise HTTPException(status_code=400, detail="New password must be at least 8 characters long.")

    admin.hashed_password = hash_password(req.new_password.strip())
    db.add(admin)

    audit = AdminAuditLog(
        admin_id=admin.id,
        action="CHANGE_ADMIN_PASSWORD",
        target_type="admin",
        target_id=admin.id,
        details=f"Admin {admin.email} updated master password."
    )
    db.add(audit)
    await db.commit()

    return {"success": True, "message": "Master administrator password changed successfully."}
