import pytest
import asyncio
from datetime import datetime, timedelta
from sqlalchemy.orm import sessionmaker
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from httpx import AsyncClient, ASGITransport

from main import app
from app.db.models import Turf, Slot, Booking, User
from app.core.security import create_access_token

@pytest.mark.asyncio
async def test_simultaneous_booking_race_condition(async_client, test_engine):
    """
    Simulate two concurrent booking requests for the exact same slot.
    Verify that row-level locking (with_for_update) prevents double booking.
    Exactly one user must succeed, and the other must be rejected with 400.
    """
    TestingSessionLocal = sessionmaker(test_engine, class_=AsyncSession, expire_on_commit=False)
    
    # Setup: Create 1 approved Turf and 1 open Slot
    async with TestingSessionLocal() as session:
        turf = Turf(
            name="Concurrency Arena",
            location="Whitefield, Bangalore",
            latitude=12.9698,
            longitude=77.7500,
            price_per_hour=1400.0,
            sport_types="Football, Cricket",
            status="approved"
        )
        session.add(turf)
        await session.flush()

        now = datetime.utcnow()
        slot = Slot(
            turf_id=turf.id,
            start_time=now + timedelta(hours=3),
            end_time=now + timedelta(hours=4),
            is_booked=False,
            capacity=1,
            current_bookings=0
        )
        session.add(slot)

        # Create two distinct users
        user_a = User(
            firebase_uid="uid_player_a",
            email="playera@turftest.com",
            full_name="Player Alpha",
            role="user",
            is_verified=True
        )
        user_b = User(
            firebase_uid="uid_player_b",
            email="playerb@turftest.com",
            full_name="Player Beta",
            role="user",
            is_verified=True
        )
        session.add(user_a)
        session.add(user_b)
        await session.commit()
        await session.refresh(turf)
        await session.refresh(slot)
        await session.refresh(user_a)
        await session.refresh(user_b)

        turf_id = turf.id
        slot_id = slot.id
        token_a = create_access_token({"uid": user_a.firebase_uid, "sub": user_a.email, "role": "user"})
        token_b = create_access_token({"uid": user_b.firebase_uid, "sub": user_b.email, "role": "user"})

    booking_payload = {
        "turf_id": turf_id,
        "slot_id": slot_id,
        "booking_type": "full"
    }

    # Fire requests for both users
    res_a = await async_client.post(
        "/api/v1/bookings/",
        json=booking_payload,
        headers={"Authorization": f"Bearer {token_a}"}
    )
    assert res_a.status_code == 200, res_a.text

    # Second user tries to book the same slot -> must fail with 400
    res_b = await async_client.post(
        "/api/v1/bookings/",
        json=booking_payload,
        headers={"Authorization": f"Bearer {token_b}"}
    )
    assert res_b.status_code == 400
    assert "already" in res_b.json()["detail"].lower()

    # Database verification: exactly 1 booking row exists for this slot
    async with TestingSessionLocal() as session:
        db_bookings = (await session.execute(
            select(Booking).filter(Booking.slot_id == slot_id)
        )).scalars().all()
        assert len(db_bookings) == 1, f"Database corruption: expected 1 booking, found {len(db_bookings)}"

        db_slot = (await session.execute(
            select(Slot).filter(Slot.id == slot_id)
        )).scalar_one()
        assert db_slot.is_booked is True
        assert db_slot.current_bookings == 1

    # Cancellation test: User A cancels the booking
    booking_id = res_a.json()["id"]
    cancel_res = await async_client.post(
        f"/api/v1/bookings/{booking_id}/cancel",
        headers={"Authorization": f"Bearer {token_a}"}
    )
    assert cancel_res.status_code == 200

    # Verify slot is released
    async with TestingSessionLocal() as session:
        released_slot = (await session.execute(
            select(Slot).filter(Slot.id == slot_id)
        )).scalar_one()
        assert released_slot.is_booked is False
        assert released_slot.current_bookings == 0

    # Now the previously rejected User B can successfully book the slot!
    retry_res = await async_client.post(
        "/api/v1/bookings/",
        json=booking_payload,
        headers={"Authorization": f"Bearer {token_b}"}
    )
    assert retry_res.status_code == 200, retry_res.text
    assert retry_res.json()["slot_id"] == slot_id

@pytest.mark.asyncio
async def test_slot_temporary_lock_prevents_race(async_client, test_engine):
    """
    Test that locking a slot prevents other users from booking it
    until the lock expires or is cleared.
    """
    TestingSessionLocal = sessionmaker(test_engine, class_=AsyncSession, expire_on_commit=False)
    
    async with TestingSessionLocal() as session:
        turf = Turf(
            name="Lock Test Arena",
            location="HSR Layout, Bangalore",
            price_per_hour=1000.0,
            status="approved"
        )
        session.add(turf)
        await session.flush()

        slot = Slot(
            turf_id=turf.id,
            start_time=datetime.utcnow() + timedelta(hours=5),
            end_time=datetime.utcnow() + timedelta(hours=6),
            is_booked=False,
            capacity=1
        )
        session.add(slot)

        user_lock = User(firebase_uid="uid_locker", email="locker@turftest.com", role="user", is_verified=True)
        user_other = User(firebase_uid="uid_other", email="other@turftest.com", role="user", is_verified=True)
        session.add(user_lock)
        session.add(user_other)
        await session.commit()
        await session.refresh(slot)
        await session.refresh(user_lock)
        await session.refresh(user_other)

        slot_id = slot.id
        turf_id = turf.id
        token_lock = create_access_token({"uid": user_lock.firebase_uid, "sub": user_lock.email, "role": "user"})
        token_other = create_access_token({"uid": user_other.firebase_uid, "sub": user_other.email, "role": "user"})

    # Step 1: User lock locks the slot
    lock_res = await async_client.post(
        f"/api/v1/slots/{slot_id}/lock",
        headers={"Authorization": f"Bearer {token_lock}"}
    )
    assert lock_res.status_code == 200, lock_res.text

    # Step 2: User other attempts to book locked slot -> must be rejected
    fail_res = await async_client.post(
        "/api/v1/bookings/",
        json={"turf_id": turf_id, "slot_id": slot_id, "booking_type": "full"},
        headers={"Authorization": f"Bearer {token_other}"}
    )
    assert fail_res.status_code == 400
    assert "temporarily held" in fail_res.json()["detail"].lower()

    # Step 3: User lock books the slot -> succeeds
    success_res = await async_client.post(
        "/api/v1/bookings/",
        json={"turf_id": turf_id, "slot_id": slot_id, "booking_type": "full"},
        headers={"Authorization": f"Bearer {token_lock}"}
    )
    assert success_res.status_code == 200
    assert success_res.json()["slot_id"] == slot_id
