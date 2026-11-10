import asyncio
from datetime import datetime, timedelta
from app.db.session import AsyncSessionLocal
from app.db.models import Turf, Slot, User, Offer

async def seed_data():
    from app.db.session import engine, Base
    import app.db.models
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    async with AsyncSessionLocal() as session:
        # 1. Create Demo Users (Check existence first)
        from sqlalchemy.future import select
        
        async def get_or_create_user(email, full_name, firebase_uid, role):
            res = await session.execute(select(User).filter(User.email == email))
            user = res.scalar_one_or_none()
            if not user:
                user = User(email=email, full_name=full_name, firebase_uid=firebase_uid, role=role)
                session.add(user)
                await session.flush()
            return user

        admin_user = await get_or_create_user("admin@example.com", "System Admin", "demo-admin-id", "admin")
        owner_user = await get_or_create_user("owner@example.com", "Turf Owner", "demo-owner-id", "owner")

        # 2. Create Turfs (Check existence first)
        async def get_or_create_turf(name, **kwargs):
            res = await session.execute(select(Turf).filter(Turf.name == name))
            turf = res.scalar_one_or_none()
            if not turf:
                turf = Turf(name=name, **kwargs)
                session.add(turf)
                await session.flush()
            return turf

        turf1 = await get_or_create_turf(
            "City Arena Kilpauk",
            location="Kilpauk, Chennai",
            price_per_hour=1500.0,
            image_url="https://images.unsplash.com/photo-1574629810360-7efbbe195018?auto=format&fit=crop&q=80",
            description="Premium turf with high-quality artificial grass.",
            owner_id=owner_user.id,
            latitude=13.0827,
            longitude=80.2407
        )

        turf2 = await get_or_create_turf(
            "Skyline Arena",
            location="Nungambakkam, Chennai",
            price_per_hour=1800.0,
            image_url="https://images.unsplash.com/photo-1529900748604-07564a03e7a6?auto=format&fit=crop&q=80",
            description="Top-tier turf with floodlights.",
            owner_id=owner_user.id,
            latitude=13.0569,
            longitude=80.2425
        )

        # 3. Create Offers
        offer1 = Offer(
            turf_id=turf1.id,
            title="Early Bird Special",
            description="Get 20% off on all bookings today!",
            discount_value=20.0,
            discount_type="percentage",
            min_booking_amount=1000.0
        )
        offer2 = Offer(
            turf_id=turf2.id,
            title="Flat ₹300 Off",
            description="Save ₹300 on your first booking of the day.",
            discount_value=300.0,
            discount_type="flat",
            min_booking_amount=1500.0
        )
        session.add(offer1)
        session.add(offer2)

        # Create some slots for today
        today = datetime.now().replace(hour=0, minute=0, second=0, microsecond=0)
        for t_id in [turf1.id, turf2.id]:
            for i in range(16, 22): # Slots from 4 PM to 10 PM
                is_joinable = (i % 2 == 0)
                slot = Slot(
                    turf_id=t_id,
                    start_time=today + timedelta(hours=i),
                    end_time=today + timedelta(hours=i+1),
                    is_booked=False,
                    capacity=10 if is_joinable else 1,
                    current_bookings=0
                )
                session.add(slot)
        
        await session.commit()
    print("Initial data seeded successfully.")

if __name__ == "__main__":
    asyncio.run(seed_data())
