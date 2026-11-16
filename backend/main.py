import os
import logging
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from sqlalchemy import text
from app.api.api_v1.api import api_router
from app.db.session import engine, Base
import app.db.models # Ensure models are loaded

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Ensure uploads directory exists relative to backend root
UPLOAD_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "uploads")
os.makedirs(UPLOAD_DIR, exist_ok=True)

app = FastAPI(title="Turf App API", description="Scalable, Secure, Cloud-Native API")

# Mount static uploads directory for free local file serving
app.mount("/uploads", StaticFiles(directory=UPLOAD_DIR), name="uploads")

async def run_auto_migrations():
    """Safely apply missing columns across existing Postgres/SQLite tables."""
    is_sqlite = "sqlite" in engine.url.drivername

    async with engine.begin() as conn:
        if is_sqlite:
            # Query existing columns for users
            try:
                user_cols_res = await conn.execute(text("PRAGMA table_info(users)"))
                user_cols = {row[1] for row in user_cols_res.fetchall()}
                user_additions = [
                    ("phone", "VARCHAR"),
                    ("hashed_password", "VARCHAR"),
                    ("is_verified", "BOOLEAN DEFAULT 0"),
                    ("owner_status", "VARCHAR DEFAULT 'pending'"),
                    ("rejection_reason", "VARCHAR"),
                    ("business_name", "VARCHAR"),
                    ("city", "VARCHAR"),
                    ("created_at", "TIMESTAMP"),
                ]
                for col_name, col_type in user_additions:
                    if col_name not in user_cols:
                        try:
                            await conn.execute(text(f"ALTER TABLE users ADD COLUMN {col_name} {col_type}"))
                            logger.info(f"SQLite auto-migration: Added users.{col_name}")
                        except Exception as e:
                            logger.debug(f"SQLite user col add note ({col_name}): {e}")
            except Exception as e:
                logger.debug(f"SQLite users pragma note: {e}")

            # Query existing columns for turfs
            try:
                turf_cols_res = await conn.execute(text("PRAGMA table_info(turfs)"))
                turf_cols = {row[1] for row in turf_cols_res.fetchall()}
                turf_additions = [
                    ("owner_id", "INTEGER REFERENCES users(id)"),
                    ("pitch_info", "VARCHAR DEFAULT '1 Nets'"),
                    ("equipment_provided", "VARCHAR"),
                    ("turf_type", "VARCHAR DEFAULT 'Artificial'"),
                    ("status", "VARCHAR DEFAULT 'pending'"),
                    ("rejection_reason", "VARCHAR"),
                    ("document_url", "VARCHAR"),
                    ("contact_phone", "VARCHAR"),
                    ("created_at", "TIMESTAMP"),
                ]
                for col_name, col_type in turf_additions:
                    if col_name not in turf_cols:
                        try:
                            await conn.execute(text(f"ALTER TABLE turfs ADD COLUMN {col_name} {col_type}"))
                            logger.info(f"SQLite auto-migration: Added turfs.{col_name}")
                        except Exception as e:
                            logger.debug(f"SQLite turf col add note ({col_name}): {e}")
            except Exception as e:
                logger.debug(f"SQLite turfs pragma note: {e}")

            # Slots & Matches
            try:
                slot_cols_res = await conn.execute(text("PRAGMA table_info(slots)"))
                slot_cols = {row[1] for row in slot_cols_res.fetchall()}
                if "locked_until" not in slot_cols:
                    try: await conn.execute(text("ALTER TABLE slots ADD COLUMN locked_until TIMESTAMP"))
                    except Exception: pass
                if "locked_by" not in slot_cols:
                    try: await conn.execute(text("ALTER TABLE slots ADD COLUMN locked_by INTEGER REFERENCES users(id)"))
                    except Exception: pass

                match_cols_res = await conn.execute(text("PRAGMA table_info(matches)"))
                match_cols = {row[1] for row in match_cols_res.fetchall()}
                match_additions = [
                    ("creator_id", "INTEGER REFERENCES users(id)"),
                    ("turf_id", "INTEGER REFERENCES turfs(id)"),
                    ("title", "VARCHAR"),
                    ("sport_type", "VARCHAR DEFAULT 'Football'"),
                    ("format", "VARCHAR DEFAULT '5v5'"),
                    ("venue_name", "VARCHAR DEFAULT 'Play Arena'"),
                    ("location", "VARCHAR DEFAULT 'Koramangala, Bengaluru'"),
                    ("match_date", "VARCHAR"),
                    ("match_time", "VARCHAR"),
                    ("duration_minutes", "INTEGER DEFAULT 60"),
                    ("team_a_name", "VARCHAR DEFAULT 'Team Alpha'"),
                    ("team_b_name", "VARCHAR DEFAULT 'Team Beta'"),
                    ("team_a_score", "INTEGER DEFAULT 0"),
                    ("team_b_score", "INTEGER DEFAULT 0"),
                    ("team_a_color", "VARCHAR DEFAULT 'Neon Green'"),
                    ("team_b_color", "VARCHAR DEFAULT 'Royal Blue'"),
                    ("status", "VARCHAR DEFAULT 'scheduled'"),
                    ("max_players", "INTEGER DEFAULT 10"),
                    ("current_players_count", "INTEGER DEFAULT 1"),
                    ("price_per_player", "FLOAT DEFAULT 0.0"),
                    ("skill_level", "VARCHAR DEFAULT 'Intermediate'"),
                    ("scoreboard_state_json", "TEXT"),
                    ("timeline_events_json", "TEXT"),
                    ("mvp_player_name", "VARCHAR"),
                    ("mvp_notes", "VARCHAR"),
                    ("start_time", "TIMESTAMP DEFAULT CURRENT_TIMESTAMP"),
                    ("created_at", "TIMESTAMP DEFAULT CURRENT_TIMESTAMP"),
                    ("updated_at", "TIMESTAMP DEFAULT CURRENT_TIMESTAMP"),
                ]
                for col_name, col_type in match_additions:
                    if col_name not in match_cols:
                        try:
                            await conn.execute(text(f"ALTER TABLE matches ADD COLUMN {col_name} {col_type}"))
                            logger.info(f"SQLite auto-migration: Added matches.{col_name}")
                        except Exception as e:
                            logger.debug(f"SQLite match col add note ({col_name}): {e}")

                try:
                    await conn.execute(text("""
                        CREATE TABLE IF NOT EXISTS match_participants (
                            id INTEGER PRIMARY KEY AUTOINCREMENT,
                            match_id INTEGER NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
                            user_id INTEGER NOT NULL REFERENCES users(id),
                            team VARCHAR DEFAULT 'A',
                            player_name VARCHAR NOT NULL,
                            player_role VARCHAR,
                            jersey_number VARCHAR,
                            joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                        )
                    """))
                except Exception as e:
                    logger.debug(f"SQLite match_participants table note: {e}")
                # Tournament table auto-migration
                try:
                    tourn_cols_res = await conn.execute(text("PRAGMA table_info(tournaments)"))
                    tourn_cols = {row[1] for row in tourn_cols_res.fetchall()}
                    tourn_additions = [
                        ("description", "TEXT"),
                        ("sport", "VARCHAR DEFAULT 'Football'"),
                        ("level", "VARCHAR DEFAULT 'Open Category'"),
                        ("venue", "VARCHAR DEFAULT 'Play Arena'"),
                        ("area", "VARCHAR DEFAULT 'Koramangala'"),
                        ("city", "VARCHAR DEFAULT 'Bangalore'"),
                        ("banner_image", "VARCHAR"),
                        ("entry_fee", "FLOAT DEFAULT 0.0"),
                        ("registered_teams_count", "INTEGER DEFAULT 0"),
                        ("end_date", "TIMESTAMP"),
                        ("registration_deadline", "TIMESTAMP"),
                        ("rules", "TEXT"),
                        ("creator_id", "INTEGER REFERENCES users(id)"),
                        ("contact_phone", "VARCHAR"),
                        ("organizer_name", "VARCHAR"),
                        ("fixtures_generated", "BOOLEAN DEFAULT 0"),
                        ("created_at", "TIMESTAMP DEFAULT CURRENT_TIMESTAMP"),
                        ("updated_at", "TIMESTAMP DEFAULT CURRENT_TIMESTAMP"),
                    ]
                    for col_name, col_type in tourn_additions:
                        if col_name not in tourn_cols:
                            try:
                                await conn.execute(text(f"ALTER TABLE tournaments ADD COLUMN {col_name} {col_type}"))
                                logger.info(f"SQLite auto-migration: Added tournaments.{col_name}")
                            except Exception as e:
                                logger.debug(f"SQLite tourn col add note ({col_name}): {e}")
                except Exception as e:
                    logger.debug(f"SQLite tournaments pragma note: {e}")

                try:
                    await conn.execute(text("""
                        CREATE TABLE IF NOT EXISTS direct_messages (
                            id INTEGER PRIMARY KEY AUTOINCREMENT,
                            room_id VARCHAR NOT NULL,
                            sender_id INTEGER REFERENCES users(id),
                            recipient_id INTEGER REFERENCES users(id),
                            sender_name VARCHAR,
                            message TEXT,
                            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                        )
                    """))
                except Exception as e:
                    logger.debug(f"SQLite direct_messages table note: {e}")
            except Exception as e:
                logger.debug(f"SQLite auxiliary pragma note: {e}")
        else:
            migration_statements = [
                "ALTER TABLE users ADD COLUMN IF NOT EXISTS phone VARCHAR",
                "ALTER TABLE users ADD COLUMN IF NOT EXISTS hashed_password VARCHAR",
                "ALTER TABLE users ADD COLUMN IF NOT EXISTS is_verified BOOLEAN DEFAULT FALSE",
                "ALTER TABLE users ADD COLUMN IF NOT EXISTS owner_status VARCHAR DEFAULT 'pending'",
                "ALTER TABLE users ADD COLUMN IF NOT EXISTS rejection_reason VARCHAR",
                "ALTER TABLE users ADD COLUMN IF NOT EXISTS business_name VARCHAR",
                "ALTER TABLE users ADD COLUMN IF NOT EXISTS city VARCHAR",
                "ALTER TABLE users ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP",
                "ALTER TABLE turfs ADD COLUMN IF NOT EXISTS owner_id INTEGER REFERENCES users(id)",
                "ALTER TABLE turfs ADD COLUMN IF NOT EXISTS pitch_info VARCHAR DEFAULT '1 Nets'",
                "ALTER TABLE turfs ADD COLUMN IF NOT EXISTS equipment_provided VARCHAR",
                "ALTER TABLE turfs ADD COLUMN IF NOT EXISTS turf_type VARCHAR DEFAULT 'Artificial'",
                "ALTER TABLE turfs ADD COLUMN IF NOT EXISTS status VARCHAR DEFAULT 'pending'",
                "ALTER TABLE turfs ADD COLUMN IF NOT EXISTS rejection_reason VARCHAR",
                "ALTER TABLE turfs ADD COLUMN IF NOT EXISTS document_url VARCHAR",
                "ALTER TABLE turfs ADD COLUMN IF NOT EXISTS contact_phone VARCHAR",
                "ALTER TABLE turfs ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP",
                "ALTER TABLE slots ADD COLUMN IF NOT EXISTS locked_until TIMESTAMP",
                "ALTER TABLE slots ADD COLUMN IF NOT EXISTS locked_by INTEGER REFERENCES users(id)",
                "ALTER TABLE matches ADD COLUMN IF NOT EXISTS creator_id INTEGER REFERENCES users(id)",
                "ALTER TABLE matches ADD COLUMN IF NOT EXISTS turf_id INTEGER REFERENCES turfs(id)",
                "ALTER TABLE matches ADD COLUMN IF NOT EXISTS title VARCHAR",
                "ALTER TABLE matches ADD COLUMN IF NOT EXISTS sport_type VARCHAR DEFAULT 'Football'",
                "ALTER TABLE matches ADD COLUMN IF NOT EXISTS format VARCHAR DEFAULT '5v5'",
                "ALTER TABLE matches ADD COLUMN IF NOT EXISTS venue_name VARCHAR DEFAULT 'Play Arena'",
                "ALTER TABLE matches ADD COLUMN IF NOT EXISTS location VARCHAR DEFAULT 'Koramangala, Bengaluru'",
                "ALTER TABLE matches ADD COLUMN IF NOT EXISTS match_date VARCHAR",
                "ALTER TABLE matches ADD COLUMN IF NOT EXISTS match_time VARCHAR",
                "ALTER TABLE matches ADD COLUMN IF NOT EXISTS duration_minutes INTEGER DEFAULT 60",
                "ALTER TABLE matches ADD COLUMN IF NOT EXISTS team_a_name VARCHAR DEFAULT 'Team Alpha'",
                "ALTER TABLE matches ADD COLUMN IF NOT EXISTS team_b_name VARCHAR DEFAULT 'Team Beta'",
                "ALTER TABLE matches ADD COLUMN IF NOT EXISTS team_a_score INTEGER DEFAULT 0",
                "ALTER TABLE matches ADD COLUMN IF NOT EXISTS team_b_score INTEGER DEFAULT 0",
                "ALTER TABLE matches ADD COLUMN IF NOT EXISTS team_a_color VARCHAR DEFAULT 'Neon Green'",
                "ALTER TABLE matches ADD COLUMN IF NOT EXISTS team_b_color VARCHAR DEFAULT 'Royal Blue'",
                "ALTER TABLE matches ADD COLUMN IF NOT EXISTS status VARCHAR DEFAULT 'scheduled'",
                "ALTER TABLE matches ADD COLUMN IF NOT EXISTS max_players INTEGER DEFAULT 10",
                "ALTER TABLE matches ADD COLUMN IF NOT EXISTS current_players_count INTEGER DEFAULT 1",
                "ALTER TABLE matches ADD COLUMN IF NOT EXISTS price_per_player FLOAT DEFAULT 0.0",
                "ALTER TABLE matches ADD COLUMN IF NOT EXISTS skill_level VARCHAR DEFAULT 'Intermediate'",
                "ALTER TABLE matches ADD COLUMN IF NOT EXISTS scoreboard_state_json TEXT",
                "ALTER TABLE matches ADD COLUMN IF NOT EXISTS timeline_events_json TEXT",
                "ALTER TABLE matches ADD COLUMN IF NOT EXISTS mvp_player_name VARCHAR",
                "ALTER TABLE matches ADD COLUMN IF NOT EXISTS mvp_notes VARCHAR",
                "ALTER TABLE matches ADD COLUMN IF NOT EXISTS start_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP",
                "ALTER TABLE matches ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP",
                "ALTER TABLE matches ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP",
                """CREATE TABLE IF NOT EXISTS match_participants (
                    id SERIAL PRIMARY KEY,
                    match_id INTEGER NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
                    user_id INTEGER NOT NULL REFERENCES users(id),
                    team VARCHAR DEFAULT 'A',
                    player_name VARCHAR NOT NULL,
                    player_role VARCHAR,
                    jersey_number VARCHAR,
                    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )""",
                "ALTER TABLE tournaments ADD COLUMN IF NOT EXISTS description TEXT",
                "ALTER TABLE tournaments ADD COLUMN IF NOT EXISTS sport VARCHAR DEFAULT 'Football'",
                "ALTER TABLE tournaments ADD COLUMN IF NOT EXISTS level VARCHAR DEFAULT 'Open Category'",
                "ALTER TABLE tournaments ADD COLUMN IF NOT EXISTS venue VARCHAR DEFAULT 'Play Arena'",
                "ALTER TABLE tournaments ADD COLUMN IF NOT EXISTS area VARCHAR DEFAULT 'Koramangala'",
                "ALTER TABLE tournaments ADD COLUMN IF NOT EXISTS city VARCHAR DEFAULT 'Bangalore'",
                "ALTER TABLE tournaments ADD COLUMN IF NOT EXISTS banner_image VARCHAR",
                "ALTER TABLE tournaments ADD COLUMN IF NOT EXISTS entry_fee FLOAT DEFAULT 0.0",
                "ALTER TABLE tournaments ADD COLUMN IF NOT EXISTS registered_teams_count INTEGER DEFAULT 0",
                "ALTER TABLE tournaments ADD COLUMN IF NOT EXISTS end_date TIMESTAMP",
                "ALTER TABLE tournaments ADD COLUMN IF NOT EXISTS registration_deadline TIMESTAMP",
                "ALTER TABLE tournaments ADD COLUMN IF NOT EXISTS rules TEXT",
                "ALTER TABLE tournaments ADD COLUMN IF NOT EXISTS creator_id INTEGER REFERENCES users(id)",
                "ALTER TABLE tournaments ADD COLUMN IF NOT EXISTS contact_phone VARCHAR",
                "ALTER TABLE tournaments ADD COLUMN IF NOT EXISTS organizer_name VARCHAR",
                "ALTER TABLE tournaments ADD COLUMN IF NOT EXISTS fixtures_generated BOOLEAN DEFAULT FALSE",
                "ALTER TABLE tournaments ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP",
                "ALTER TABLE tournaments ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP",
                """CREATE TABLE IF NOT EXISTS direct_messages (
                    id SERIAL PRIMARY KEY,
                    room_id VARCHAR NOT NULL,
                    sender_id INTEGER REFERENCES users(id),
                    recipient_id INTEGER REFERENCES users(id),
                    sender_name VARCHAR,
                    message TEXT,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )""",
            ]
            for stmt in migration_statements:
                try:
                    await conn.execute(text(stmt))
                except Exception as e:
                    logger.debug(f"Migration note ({stmt}): {e}")

async def ensure_super_admin(db_session=None):
    """Ensure platform super-admin account exists with master credentials."""
    from app.db.session import AsyncSessionLocal
    from app.db.models import User
    from app.core.security import hash_password
    from sqlalchemy.future import select

    admin_email = os.getenv("ADMIN_EMAIL", "admin@turfplatform.com").strip().lower()
    admin_password = os.getenv("ADMIN_PASSWORD", "AdminMaster@2026!")

    async def _seed(session):
        # Guarantee both master emails have admin access
        admin_emails = list({admin_email, "admin@turfplatform.com", "admin@example.com"})
        for email_addr in admin_emails:
            res = await session.execute(select(User).filter(User.email == email_addr))
            admin = res.scalar_one_or_none()
            if not admin:
                admin = User(
                    email=email_addr,
                    full_name="Platform Super Admin",
                    firebase_uid=f"admin_{email_addr.replace('@', '_').replace('.', '_')}",
                    role="admin",
                    hashed_password=hash_password(admin_password),
                    owner_status="approved",
                    is_verified=True
                )
                session.add(admin)
                await session.commit()
                logger.info(f"Super-admin seeded: {email_addr}")
            else:
                admin.role = "admin"
                admin.is_verified = True
                admin.owner_status = "approved"
                admin.hashed_password = hash_password(admin_password)
                await session.commit()
                logger.info(f"Super-admin account verified: {email_addr}")

    if db_session is not None:
        try:
            await _seed(db_session)
        except Exception as e:
            logger.warning(f"Super-admin verification note: {e}")
    else:
        async with AsyncSessionLocal() as session:
            try:
                await _seed(session)
            except Exception as e:
                logger.warning(f"Super-admin verification note: {e}")

@app.on_event("startup")
async def on_startup():
    import sys
    import asyncio
    if "pytest" in sys.modules:
        logger.info("Running under pytest: skipping startup DB auto-migration loop.")
        return

    db_host = engine.url.host or "local/sqlite"
    logger.info(f"Connecting to database host: {db_host} (driver: {engine.url.drivername})...")
    logger.info("Initializing database tables...")
    for attempt in range(1, 4):
        try:
            async with engine.begin() as conn:
                await conn.run_sync(Base.metadata.create_all)
            await run_auto_migrations()
            await ensure_super_admin()
            logger.info("Database tables and column migrations completed successfully.")
            try:
                from seed_db import seed_data
                await seed_data()
                logger.info("Production data seeded successfully.")
            except Exception as seed_err:
                logger.warning(f"Seed data notice: {seed_err}")
            break
        except Exception as e:
            logger.warning(f"Database connection attempt {attempt}/3 failed: {e}. Retrying in 1s...")
            if attempt == 3:
                logger.error(f"Failed to connect to database at '{db_host}'.")
                if os.getenv("ENVIRONMENT") == "development" or db_host in ("localhost", "127.0.0.1"):
                    logger.warning("Local development: continuing in degraded mode.")
                    break
                raise
            await asyncio.sleep(1)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.middleware("http")
async def log_requests(request: Request, call_next):
    if request.method == "OPTIONS":
        return await call_next(request)
        
    logger.info(f"Incoming Request: {request.method} {request.url}")
    try:
        response = await call_next(request)
        if response.status_code >= 400:
            logger.error(f"Error Response: {response.status_code} for {request.url}")
        return response
    except Exception as e:
        logger.exception(f"Exception during request: {e}")
        raise

app.include_router(api_router, prefix="/api/v1")

@app.get("/")
def root():
    return {"message": "Welcome to Turf App API"}

@app.get("/health")
def health():
    return {"status": "ok", "app": "Turf App API"}

@app.get("/api/v1/system/migrate")
async def system_migrate():
    await run_auto_migrations()
    try:
        from seed_db import seed_data
        await seed_data()
        return {"status": "ok", "message": "Schema auto-migrated and seed verified"}
    except Exception as e:
        return {"status": "error", "message": str(e)}

@app.get("/api/v1/system/seed")
async def system_seed():
    try:
        from seed_db import seed_data
        await seed_data()
        return {"status": "ok", "message": "Data seeded successfully"}
    except Exception as e:
        return {"status": "error", "message": str(e)}

