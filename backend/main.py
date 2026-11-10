import os
import logging
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
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
            logger.info("Database tables initialized successfully.")
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

