import asyncio
from datetime import datetime, timedelta
from sqlalchemy.future import select
from app.db.session import AsyncSessionLocal
from app.db.models import Turf, Slot, User, Match, Booking

async def seed_demo():
    async with AsyncSessionLocal() as session:
        # 1. Get or Create a User (Use the admin from initial seed as the target for demo)
        res = await session.execute(select(User).filter(User.email == "admin@example.com"))
        user = res.scalar_one_or_none()
        
        if not user:
            user = User(
                email="admin@example.com",
                full_name="Demo User",
                firebase_uid="demo-admin-id",
                role="admin"
            )
            session.add(user)
            await session.flush()

        # 2. Get a Turf
        res = await session.execute(select(Turf).limit(1))
        turf = res.scalar_one_or_none()
        
        if not turf:
            print("No turfs found. Please run seed_db.py first.")
            return

        # 3. Create a LIVE Match
        match = Match(
            turf_id=turf.id,
            team_a_name="Red Dragons",
            team_b_name="Blue Hawks",
            team_a_score=2,
            team_b_score=1,
            status="live",
            sport_type="Football",
            start_time=datetime.utcnow() - timedelta(minutes=45)
        )
        session.add(match)

        # 4. Create an Upcoming Booking for the user
        # First find a slot
        res = await session.execute(select(Slot).filter(Slot.turf_id == turf.id, Slot.is_booked == False).limit(1))
        slot = res.scalar_one_or_none()
        
        if slot:
            booking = Booking(
                user_id=user.id,
                turf_id=turf.id,
                slot_id=slot.id,
                total_price=turf.price_per_hour,
                booking_date=datetime.now() + timedelta(hours=2),
                status="confirmed",
                booking_type="full"
            )
            slot.is_booked = True
            session.add(booking)
            session.add(slot)

        await session.commit()
    print("Demo data (Match & Booking) seeded successfully.")

if __name__ == "__main__":
    asyncio.run(seed_demo())
