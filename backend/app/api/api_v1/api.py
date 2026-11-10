from fastapi import APIRouter
from app.api.api_v1.endpoints import (
    turfs, users, bookings, slots, favorites, reviews, upload, matches, offers,
    tournaments, teams, community, rentals, coaches, parking, stocks, ws, auth
)

api_router = APIRouter()
api_router.include_router(auth.router, prefix="/auth", tags=["auth"])
api_router.include_router(turfs.router, prefix="/turfs", tags=["turfs"])
api_router.include_router(users.router, prefix="/users", tags=["users"])
api_router.include_router(bookings.router, prefix="/bookings", tags=["bookings"])
api_router.include_router(slots.router, prefix="/slots", tags=["slots"])
api_router.include_router(favorites.router, prefix="/favorites", tags=["favorites"])
api_router.include_router(reviews.router, prefix="/reviews", tags=["reviews"])
api_router.include_router(offers.router, prefix="/offers", tags=["offers"])
api_router.include_router(upload.router, prefix="/upload", tags=["upload"])
api_router.include_router(matches.router, prefix="/matches", tags=["matches"])
api_router.include_router(tournaments.router, prefix="/tournaments", tags=["tournaments"])
api_router.include_router(teams.router, prefix="/teams", tags=["teams"])
api_router.include_router(community.router, prefix="/community", tags=["community"])
api_router.include_router(rentals.router, prefix="/rentals", tags=["rentals"])
api_router.include_router(coaches.router, prefix="/coaches", tags=["coaches"])
api_router.include_router(parking.router, prefix="/parking", tags=["parking"])
api_router.include_router(stocks.router, prefix="/stocks", tags=["stocks"])
api_router.include_router(ws.router, prefix="/ws", tags=["websocket"])
