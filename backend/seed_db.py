import asyncio
from datetime import datetime, timedelta
from app.db.session import AsyncSessionLocal
from app.db.models import Turf, Slot, User, Offer
from sqlalchemy.future import select

async def seed_data():
    from app.db.session import engine, Base
    import app.db.models
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    async with AsyncSessionLocal() as session:
        # Check if turfs already exist
        existing = await session.execute(select(Turf))
        if len(existing.scalars().all()) >= 3:
            return

        async def get_or_create_user(email, full_name, firebase_uid, role):
            res = await session.execute(select(User).filter(User.email == email))
            user = res.scalar_one_or_none()
            if not user:
                user = User(email=email, full_name=full_name, firebase_uid=firebase_uid, role=role)
                session.add(user)
                await session.flush()
            return user

        admin_user = await get_or_create_user("admin@example.com", "System Admin", "admin_uid_123", "admin")
        owner_user = await get_or_create_user("owner@example.com", "Elite Turf Owner", "owner_uid_123", "owner")

        async def get_or_create_turf(name, **kwargs):
            res = await session.execute(select(Turf).filter(Turf.name == name))
            turf = res.scalar_one_or_none()
            if not turf:
                turf = Turf(name=name, **kwargs)
                session.add(turf)
                await session.flush()
            return turf

        turf1 = await get_or_create_turf(
            "Play Arena",
            location="Koramangala, Bengaluru",
            price_per_hour=1200.0,
            image_url="https://images.unsplash.com/photo-1529900748604-07564a03e7a6?w=800",
            description="Premium FIFA-standard turf with high-speed LED floodlights, locker rooms, and spectator seating.",
            sport_types="Football, Cricket, Badminton",
            owner_id=owner_user.id,
            latitude=12.9352,
            longitude=77.6245,
            average_rating=4.8,
            total_reviews=128
        )

        turf2 = await get_or_create_turf(
            "Greenfield Arena",
            location="HSR Layout, Bengaluru",
            price_per_hour=1000.0,
            image_url="https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=800",
            description="Top-tier natural hybrid turf with digital scoreboards, shaded dugouts, and parking.",
            sport_types="Football, Cricket, Basketball",
            owner_id=owner_user.id,
            latitude=12.9121,
            longitude=77.6446,
            average_rating=4.6,
            total_reviews=96
        )

        turf3 = await get_or_create_turf(
            "Turf Nation",
            location="Electronic City, Bengaluru",
            price_per_hour=800.0,
            image_url="https://images.unsplash.com/photo-1575361204480-aadea25e6e68?w=800",
            description="Affordable box cricket and 5-a-side football turf with all-weather synthetic turf.",
            sport_types="Football, Cricket",
            owner_id=owner_user.id,
            latitude=12.8399,
            longitude=77.6770,
            average_rating=4.4,
            total_reviews=75
        )

        # Create slots for each turf for today & tomorrow
        today = datetime.now().replace(minute=0, second=0, microsecond=0)
        for turf in [turf1, turf2, turf3]:
            for day_offset in range(3):
                base_day = today + timedelta(days=day_offset)
                for h in range(6, 23, 2):
                    start = base_day.replace(hour=h)
                    end = start + timedelta(hours=1)
                    is_join = (h % 4 == 0)
                    slot = Slot(
                        turf_id=turf.id,
                        start_time=start,
                        end_time=end,
                        is_booked=False,
                        capacity=10 if is_join else 1,
                        current_bookings=0
                    )
                    session.add(slot)

        # Create live promotional offers
        offer1 = Offer(
            turf_id=turf1.id,
            title="TURF100",
            description="Get ₹100 instant discount on slot bookings",
            discount_value=100.0,
            discount_type="flat",
            min_booking_amount=500.0
        )
        offer2 = Offer(
            turf_id=turf2.id,
            title="WEEKEND20",
            description="20% off on all weekend evening bookings",
            discount_value=20.0,
            discount_type="percentage",
            min_booking_amount=800.0
        )
        session.add(offer1)
        session.add(offer2)

        await session.commit()
        print("Initial production data seeded successfully.")

if __name__ == "__main__":
    asyncio.run(seed_data())
