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
                if "sport_type" not in match_cols:
                    try: await conn.execute(text("ALTER TABLE matches ADD COLUMN sport_type VARCHAR DEFAULT 'Football'"))
                    except Exception: pass
                if "start_time" not in match_cols:
                    try: await conn.execute(text("ALTER TABLE matches ADD COLUMN start_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP"))
                    except Exception: pass
                if "status" not in match_cols:
                    try: await conn.execute(text("ALTER TABLE matches ADD COLUMN status VARCHAR DEFAULT 'live'"))
                    except Exception: pass
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
                "ALTER TABLE matches ADD COLUMN IF NOT EXISTS sport_type VARCHAR DEFAULT 'Football'",
                "ALTER TABLE matches ADD COLUMN IF NOT EXISTS start_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP",
                "ALTER TABLE matches ADD COLUMN IF NOT EXISTS status VARCHAR DEFAULT 'live'",
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

