import asyncio
from datetime import datetime, timedelta
from app.db.session import AsyncSessionLocal
from app.db.models import Turf, Slot, User, Offer, Tournament
from sqlalchemy.future import select

async def seed_data():
    from app.db.session import engine, Base
    import app.db.models

    async with AsyncSessionLocal() as session:
        # Check if turfs already exist
        existing = await session.execute(select(Turf))
        turfs_exist = len(existing.scalars().all()) >= 3

        # Check if tournaments already exist
        existing_t = await session.execute(select(Tournament))
        tournaments_exist = len(existing_t.scalars().all()) > 0

        if turfs_exist and tournaments_exist:
            return

        async def get_or_create_user(email, full_name, firebase_uid, role, default_pw=None):
            from app.core.security import hash_password
            res = await session.execute(select(User).filter(User.email == email))
            user = res.scalar_one_or_none()
            pw = default_pw or ("admin123" if role == "admin" else "owner123")
            if not user:
                user = User(
                    email=email,
                    full_name=full_name,
                    firebase_uid=firebase_uid,
                    role=role,
                    hashed_password=hash_password(pw),
                    is_verified=True
                )
                session.add(user)
                await session.flush()
            else:
                if not user.hashed_password:
                    user.hashed_password = hash_password(pw)
                user.is_verified = True
                user.role = role
                session.add(user)
                await session.flush()
            return user

        admin_user = await get_or_create_user("admin@example.com", "System Admin", "admin_uid_123", "admin", "admin123")
        owner_user = await get_or_create_user("owner@example.com", "Elite Turf Owner", "owner_uid_123", "owner", "owner123")
        customer_user = await get_or_create_user("customer@example.com", "Demo Customer", "customer_uid_123", "user", "password123")

        async def get_or_create_turf(name, **kwargs):
            kwargs.pop("average_rating", None)
            kwargs.pop("total_reviews", None)
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

        if not tournaments_exist:
            tourn1 = Tournament(
                title="Bangalore Premier Football Cup 2026",
                description="Annual 5v5 Knockout Championship with trophy and cash prizes.",
                sport="Football",
                format="5v5 Knockout",
                level="Open Category",
                venue="Play Arena",
                area="Koramangala",
                city="Bangalore",
                banner_image="https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=800",
                prize_pool=50000.0,
                entry_fee=0.0,
                total_teams=8,
                registered_teams_count=0,
                status="Open Entry",
                contact_phone="+91 9876543210",
                organizer_name="Play Arena Sports League",
                creator_id=admin_user.id if 'admin_user' in locals() else None,
                rules="Standard FIFA rules apply. Shin guards mandatory. Referees decision is final.",
                start_date=datetime.utcnow() + timedelta(days=7),
            )
            tourn2 = Tournament(
                title="Silicon Valley Box Cricket Cup",
                description="High intensity 7-a-side floodlight box cricket tournament.",
                sport="Cricket",
                format="Box Cricket 7v7",
                level="Open Category",
                venue="Greenfield Arena",
                area="HSR Layout",
                city="Bangalore",
                banner_image="https://images.unsplash.com/photo-1540747913346-19e32dc3e97e?w=800",
                prize_pool=75000.0,
                entry_fee=1200.0,
                total_teams=16,
                registered_teams_count=0,
                status="Open Entry",
                contact_phone="+91 9876501234",
                organizer_name="Bangalore Sports Circle",
                creator_id=admin_user.id if 'admin_user' in locals() else None,
                rules="Standard Box Cricket rules. 6 overs per innings. Tennis ball will be provided.",
                start_date=datetime.utcnow() + timedelta(days=14),
            )
            session.add(tourn1)
            session.add(tourn2)

        await session.commit()
        print("Initial production data seeded successfully.")

if __name__ == "__main__":
    asyncio.run(seed_data())
