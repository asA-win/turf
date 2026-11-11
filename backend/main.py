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

# Ensure uploads directory exists
os.makedirs("uploads", exist_ok=True)

app = FastAPI(title="Turf App API", description="Scalable, Secure, Cloud-Native API")

# Mount static uploads directory for free local file serving
app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")

async def run_auto_migrations():
    """Safely apply missing columns across existing Postgres/SQLite tables."""
    migration_statements = [
        "ALTER TABLE users ADD COLUMN IF NOT EXISTS phone VARCHAR",
        "ALTER TABLE users ADD COLUMN IF NOT EXISTS hashed_password VARCHAR",
        "ALTER TABLE users ADD COLUMN IF NOT EXISTS is_verified BOOLEAN DEFAULT FALSE",
        "ALTER TABLE turfs ADD COLUMN IF NOT EXISTS owner_id INTEGER REFERENCES users(id)",
        "ALTER TABLE turfs ADD COLUMN IF NOT EXISTS pitch_info VARCHAR DEFAULT '1 Nets'",
        "ALTER TABLE turfs ADD COLUMN IF NOT EXISTS equipment_provided VARCHAR",
        "ALTER TABLE turfs ADD COLUMN IF NOT EXISTS turf_type VARCHAR DEFAULT 'Artificial'",
        "ALTER TABLE slots ADD COLUMN IF NOT EXISTS locked_until TIMESTAMP",
        "ALTER TABLE slots ADD COLUMN IF NOT EXISTS locked_by INTEGER REFERENCES users(id)",
        "ALTER TABLE matches ADD COLUMN IF NOT EXISTS sport_type VARCHAR DEFAULT 'Football'",
        "ALTER TABLE matches ADD COLUMN IF NOT EXISTS start_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP",
        "ALTER TABLE matches ADD COLUMN IF NOT EXISTS status VARCHAR DEFAULT 'live'",
    ]
    async with engine.begin() as conn:
        for stmt in migration_statements:
            try:
                await conn.execute(text(stmt))
            except Exception as e:
                logger.debug(f"Migration note ({stmt}): {e}")

@app.on_event("startup")
async def on_startup():
    import asyncio
    db_host = engine.url.host or "local/sqlite"
    logger.info(f"Connecting to database host: {db_host} (driver: {engine.url.drivername})...")
    logger.info("Initializing database tables...")
    for attempt in range(1, 10):
        try:
            async with engine.begin() as conn:
                await conn.run_sync(Base.metadata.create_all)
            await run_auto_migrations()
            logger.info("Database tables and column migrations completed successfully.")
            try:
                from seed_db import seed_data
                await seed_data()
                logger.info("Production data seeded successfully.")
            except Exception as seed_err:
                logger.warning(f"Seed data notice: {seed_err}")
            break
        except Exception as e:
            logger.warning(f"Database connection attempt {attempt}/9 failed: {e}. Retrying in 2s...")
            if attempt == 9:
                logger.error(f"Failed to connect to database at '{db_host}' after 9 attempts.")
                raise
            await asyncio.sleep(2)

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

