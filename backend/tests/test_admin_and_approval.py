import pytest
from httpx import AsyncClient
from sqlalchemy.orm import sessionmaker
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select

from app.db.models import User, Turf, AdminAuditLog
from app.core.security import hash_password, create_access_token

@pytest.mark.asyncio
async def test_admin_seeding_and_auth(async_client: AsyncClient, test_engine):
    """Test super-admin authentication and access control."""
    from main import ensure_super_admin
    TestingSessionLocal = sessionmaker(test_engine, class_=AsyncSession, expire_on_commit=False)
    async with TestingSessionLocal() as session:
        await ensure_super_admin(session)

    # Admin Login with initial credentials
    login_res = await async_client.post("/api/v1/auth/login", json={
        "email": "admin@turfplatform.com",
        "password": "AdminMaster@2026!"
    })
    assert login_res.status_code == 200, login_res.text
    admin_auth = login_res.json()
    assert admin_auth["user"]["role"] == "admin"
    admin_token = admin_auth["access_token"]
    admin_headers = {"Authorization": f"Bearer {admin_token}"}

    # Admin Overview
    overview_res = await async_client.get("/api/v1/admin/overview", headers=admin_headers)
    assert overview_res.status_code == 200
    overview_data = overview_res.json()
    assert "total_turfs" in overview_data
    assert "total_owners" in overview_data

    # Non-admin access should be rejected with 403
    user_token = create_access_token({"uid": "user123", "email": "user@test.com", "role": "user"})
    non_admin_headers = {"Authorization": f"Bearer {user_token}"}
    forbidden_res = await async_client.get("/api/v1/admin/overview", headers=non_admin_headers)
    assert forbidden_res.status_code in (401, 403, 404)

@pytest.mark.asyncio
async def test_owner_registration_approval_and_isolation(async_client: AsyncClient, test_engine):
    """Test full owner registration, pending block, admin approval, and multi-tenant isolation."""
    from main import ensure_super_admin
    TestingSessionLocal = sessionmaker(test_engine, class_=AsyncSession, expire_on_commit=False)
    async with TestingSessionLocal() as session:
        await ensure_super_admin(session)

    admin_login = await async_client.post("/api/v1/auth/login", json={
        "email": "admin@turfplatform.com",
        "password": "AdminMaster@2026!"
    })
    admin_headers = {"Authorization": f"Bearer {admin_login.json()['access_token']}"}

    # Step 1: Register Owner 1
    reg1_res = await async_client.post("/api/v1/auth/register-owner", json={
        "business_name": "Apex Sports Hub",
        "owner_name": "Rohan Sharma",
        "email": "rohan@apexarena.com",
        "phone": "+919876543210",
        "password": "OwnerPassword@123",
        "turf_name": "Apex Arena Bangalore",
        "city": "Bengaluru",
        "hourly_price": 1200.0,
        "sports": "Football, Cricket",
        "amenities": "Parking, Floodlights",
        "surface_type": "FIFA Grade Synthetic",
        "document_url": "https://example.com/docs/license1.pdf"
    })
    assert reg1_res.status_code == 200, reg1_res.text
    owner1_data = reg1_res.json()
    assert owner1_data["user"]["owner_status"] == "pending"
    owner1_token = owner1_data["access_token"]
    owner1_headers = {"Authorization": f"Bearer {owner1_token}"}

    # Step 2: Pending owner is blocked from operational dashboard APIs
    blocked_my_turfs = await async_client.get("/api/v1/turfs/my-turfs", headers=owner1_headers)
    assert blocked_my_turfs.status_code == 403, "Pending owner should be blocked from operational my-turfs"

    blocked_requests = await async_client.get("/api/v1/bookings/requests", headers=owner1_headers)
    assert blocked_requests.status_code == 403, "Pending owner should be blocked from operational booking requests"

    # Step 3: Admin reviews pending registrations
    regs_res = await async_client.get("/api/v1/admin/turf-registrations", headers=admin_headers)
    assert regs_res.status_code == 200
    pending_list = regs_res.json()
    rohan_turf = next((t for t in pending_list if t["name"] == "Apex Arena Bangalore"), None)
    assert rohan_turf is not None
    assert rohan_turf["status"] == "pending"
    assert rohan_turf["document_url"] == "https://example.com/docs/license1.pdf"

    # Step 4: Admin Approves Owner 1's Turf
    approve_res = await async_client.post(
        f"/api/v1/admin/turf-registrations/{rohan_turf['id']}/approve",
        headers=admin_headers
    )
    assert approve_res.status_code == 200
    assert approve_res.json()["status"] == "approved"

    # Step 5: Approved Owner 1 can now access operational dashboard APIs
    allowed_my_turfs = await async_client.get("/api/v1/turfs/my-turfs", headers=owner1_headers)
    assert allowed_my_turfs.status_code == 200
    my_turfs = allowed_my_turfs.json()
    assert len(my_turfs) >= 1
    assert my_turfs[0]["id"] == rohan_turf["id"]

    # Step 6: Register Owner 2 (Multi-Tenant Isolation Test)
    reg2_res = await async_client.post("/api/v1/auth/register-owner", json={
        "business_name": "Titan Sports Hub",
        "owner_name": "Vikram Seth",
        "email": "vikram@titanarena.com",
        "phone": "+919876543211",
        "password": "OwnerPassword@123",
        "turf_name": "Titan Arena Whitefield",
        "city": "Bengaluru",
        "hourly_price": 1400.0,
        "sports": "Cricket",
        "amenities": "Parking, Floodlights",
        "surface_type": "Box Cricket Astro",
        "document_url": "https://example.com/docs/license2.pdf"
    })
    assert reg2_res.status_code == 200
    owner2_token = reg2_res.json()["access_token"]
    owner2_headers = {"Authorization": f"Bearer {owner2_token}"}

    # Admin approves Owner 2
    regs_res2 = await async_client.get("/api/v1/admin/turf-registrations", headers=admin_headers)
    vikram_turf = next(t for t in regs_res2.json() if t["name"] == "Titan Arena Whitefield")
    await async_client.post(f"/api/v1/admin/turf-registrations/{vikram_turf['id']}/approve", headers=admin_headers)

    # Verify Owner 2 only sees Owner 2's turf
    owner2_my_turfs = await async_client.get("/api/v1/turfs/my-turfs", headers=owner2_headers)
    assert owner2_my_turfs.status_code == 200
    turf_ids_owner2 = [t["id"] for t in owner2_my_turfs.json()]
    assert vikram_turf["id"] in turf_ids_owner2
    assert rohan_turf["id"] not in turf_ids_owner2, "Owner 2 must NOT see Owner 1's turf"

    # Step 7: Admin Rejection Flow
    reg3_res = await async_client.post("/api/v1/auth/register-owner", json={
        "business_name": "Invalid Venue",
        "owner_name": "Fake Name",
        "email": "fake@invalidarena.com",
        "phone": "+919876543212",
        "password": "OwnerPassword@123",
        "turf_name": "Unverified Ground",
        "city": "Bengaluru",
        "hourly_price": 500.0,
        "sports": "Football",
        "amenities": "None",
        "surface_type": "Mud",
        "document_url": "https://example.com/docs/invalid.pdf"
    })
    assert reg3_res.status_code == 200
    owner3_token = reg3_res.json()["access_token"]
    owner3_headers = {"Authorization": f"Bearer {owner3_token}"}
    fake_turf = (await async_client.get("/api/v1/admin/turf-registrations", headers=admin_headers)).json()
    target_fake = next(t for t in fake_turf if t["name"] == "Unverified Ground")

    reject_res = await async_client.post(
        f"/api/v1/admin/turf-registrations/{target_fake['id']}/reject",
        headers=admin_headers,
        json={"reason": "Missing legitimate municipal trade license and substandard surface photos."}
    )
    assert reject_res.status_code == 200
    assert reject_res.json()["status"] == "rejected"
    assert "municipal trade license" in reject_res.json()["rejection_reason"]

    # Rejected owner must remain blocked
    rejected_block = await async_client.get("/api/v1/turfs/my-turfs", headers=owner3_headers)
    assert rejected_block.status_code == 403

    # Step 8: Admin Owner Suspension Flow
    # Suspend Owner 1
    suspend_res = await async_client.post(
        f"/api/v1/admin/owners/{rohan_turf['owner_id']}/status",
        headers=admin_headers,
        json={"status": "suspended", "reason": "Investigation into duplicate booking complaints."}
    )
    assert suspend_res.status_code == 200
    assert suspend_res.json()["owner_status"] == "suspended"

    # Suspended owner must now be blocked from operational APIs
    suspended_block = await async_client.get("/api/v1/turfs/my-turfs", headers=owner1_headers)
    assert suspended_block.status_code == 403

    # Restore Owner 1
    restore_res = await async_client.post(
        f"/api/v1/admin/owners/{rohan_turf['owner_id']}/status",
        headers=admin_headers,
        json={"status": "approved"}
    )
    assert restore_res.status_code == 200
    assert restore_res.json()["owner_status"] == "approved"

    # Owner 1 can access again
    restored_access = await async_client.get("/api/v1/turfs/my-turfs", headers=owner1_headers)
    assert restored_access.status_code == 200

    # Step 9: Audit Logs are recorded
    audit_res = await async_client.get("/api/v1/admin/audit-logs", headers=admin_headers)
    assert audit_res.status_code == 200
    logs = audit_res.json()
    actions = [log["action"] for log in logs]
    assert "APPROVE_TURF" in actions
    assert "REJECT_TURF" in actions
    assert "SUSPENDED_OWNER" in actions or "APPROVED_OWNER" in actions
