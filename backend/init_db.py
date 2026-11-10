import asyncio
import os
import asyncpg
from app.core.config import settings

async def check_db_connectivity():
    # Use the URL from settings (which should be from .env)
    url = settings.DATABASE_URL
    # asyncpg expects 'postgresql://' or 'postgres://', not 'postgresql+asyncpg://'
    asyncpg_url = url.replace("postgresql+asyncpg://", "postgresql://")
    print(f"Connecting to database with URL: {asyncpg_url.replace('root', '****')}") # Mask password

    # 1. Try connecting to the specified database first
    try:
        conn = await asyncpg.connect(asyncpg_url)
        print("Successfully connected to the 'turf' database.")
        await conn.close()
        return True
    except asyncpg.exceptions.InvalidCatalogNameError:
        print("Error: Database 'turf' does not exist.")
        # 2. Try connecting to the default 'postgres' database to verify credentials
        try:
            default_url = asyncpg_url.replace("/turf", "/postgres")
            print(f"Trying to verify credentials by connecting to the default 'postgres' database...")
            conn = await asyncpg.connect(default_url)
            print("Credentials verified! You just need to create the 'turf' database.")
            await conn.close()
            return "needs_db_create"
        except Exception as e:
            print(f"Credentials failed even for the default database: {e}")
            return False
    except asyncpg.exceptions.InvalidPasswordError:
        print("Error: Password authentication failed. Please double-check your password.")
        return False
    except Exception as e:
        print(f"Unexpected error: {e}")
        return False

async def main():
    result = await check_db_connectivity()
    if result is True:
        # Run the actual table creation
        from app.db.session import engine, Base
        import app.db.models # Ensure models are loaded
        async with engine.begin() as conn:
            # Drop all tables first to ensure we have the latest schema (owner_id, etc)
            await conn.run_sync(Base.metadata.drop_all)
            await conn.run_sync(Base.metadata.create_all)
        print("Database tables reset and created successfully in the 'turf' database.")
    elif result == "needs_db_create":
        # Attempt to create the database automatically if possible
        # (Though asyncpg can't create DB if it's connected to another DB normally without some work,
        # usually better to let user do it if we're not sure about psql).
        pass

if __name__ == "__main__":
    asyncio.run(main())
