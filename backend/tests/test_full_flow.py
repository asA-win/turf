import pytest
from datetime import datetime, timedelta
from app.db.models import Turf, Slot

@pytest.mark.asyncio
async def test_full_auth_to_booking_flow(async_client, test_engine):
    # Step 1: User Signup / Create profile
    signup_payload = {
        "firebase_uid": "test-user-uid-123",
        "email": "testuser@example.com",
        "full_name": "Test User",
        "phone": "+1234567890"
    }
    signup_res = await async_client.post("/api/v1/users/", json=signup_payload)
    assert signup_res.status_code == 200, signup_res.text
    user_data = signup_res.json()
    assert user_data["firebase_uid"] == "test-user-uid-123"
    assert user_data["email"] == "testuser@example.com"

    # Step 2: Get user profile (/me endpoint)
    # create demo-user-id user to test /users/me with default get_current_user fallback
    demo_user_payload = {
        "firebase_uid": "demo-user-id",
        "email": "user@example.com",
        "full_name": "Demo User"
    }
    await async_client.post("/api/v1/users/", json=demo_user_payload)

    me_res = await async_client.get("/api/v1/users/me")
    assert me_res.status_code == 200
    assert me_res.json()["firebase_uid"] == "demo-user-id"

    # Step 3: Create a turf & slot in test DB
    from sqlalchemy.orm import sessionmaker
    from sqlalchemy.ext.asyncio import AsyncSession
    TestingSessionLocal = sessionmaker(test_engine, class_=AsyncSession, expire_on_commit=False)
    
    async with TestingSessionLocal() as session:
        turf = Turf(
            name="Apex Arena",
            location="Downtown Sports Hub",
            latitude=12.9716,
            longitude=77.5946,
            price_per_hour=1500.0,
            sport_types="Football,Cricket",
            image_url="https://example.com/turf.jpg",
            amenities="Lighting,Parking,Water"
        )
        session.add(turf)
        await session.commit()
        await session.refresh(turf)
        turf_id = turf.id

        now = datetime.utcnow()
        slot = Slot(
            turf_id=turf_id,
            start_time=now + timedelta(hours=1),
            end_time=now + timedelta(hours=2),
            is_booked=False,
            capacity=10,
            current_bookings=0
        )
        session.add(slot)
        await session.commit()
        await session.refresh(slot)
        slot_id = slot.id

    # Step 4: List Turfs
    turfs_res = await async_client.get("/api/v1/turfs/")
    assert turfs_res.status_code == 200
    assert len(turfs_res.json()) >= 1

    # Step 5: List Slots for Turf
    slots_res = await async_client.get(f"/api/v1/slots/?turf_id={turf_id}")
    assert slots_res.status_code == 200
    assert len(slots_res.json()) >= 1

    # Step 6: Create Booking
    booking_payload = {
        "turf_id": turf_id,
        "slot_id": slot_id,
        "booking_type": "full"
    }
    booking_res = await async_client.post("/api/v1/bookings/", json=booking_payload)
    assert booking_res.status_code == 200, booking_res.text
    booking_data = booking_res.json()
    assert booking_data["turf_id"] == turf_id
    assert booking_data["slot_id"] == slot_id
    booking_id = booking_data["id"]

    # Step 7: Retrieve My Bookings
    my_bookings_res = await async_client.get("/api/v1/bookings/my-bookings")
    assert my_bookings_res.status_code == 200
    my_bookings = my_bookings_res.json()
    assert any(b["id"] == booking_id for b in my_bookings)

    # Step 8: Cancel Booking
    cancel_res = await async_client.post(f"/api/v1/bookings/{booking_id}/cancel")
    assert cancel_res.status_code == 200
    assert cancel_res.json()["message"] == "Booking cancelled successfully"
