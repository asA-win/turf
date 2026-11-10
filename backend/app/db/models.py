from sqlalchemy import Column, Integer, String, Float, Boolean, ForeignKey, DateTime
from sqlalchemy.orm import relationship
from datetime import datetime
from app.db.session import Base

class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    firebase_uid = Column(String, unique=True, index=True)
    email = Column(String, unique=True, index=True)
    full_name = Column(String)
    role = Column(String, default="user") # 'user' or 'admin'
    phone = Column(String, nullable=True)

class Turf(Base):
    __tablename__ = "turfs"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True)
    location = Column(String)
    price_per_hour = Column(Float)
    image_url = Column(String, nullable=True)
    description = Column(String, nullable=True)
    sport_types = Column(String, default="Football,Cricket") # Comma-separated list
    amenities = Column(String, default="Parking,UPI,Water") # Comma-separated list
    latitude = Column(Float, nullable=True)
    longitude = Column(Float, nullable=True)
    pitch_info = Column(String, default="1 Nets")
    equipment_provided = Column(String, nullable=True)
    turf_type = Column(String, default="Artificial")
    owner_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    
    owner = relationship("User")
    slots = relationship("Slot", back_populates="turf")

class Slot(Base):
    __tablename__ = "slots"
    
    id = Column(Integer, primary_key=True, index=True)
    turf_id = Column(Integer, ForeignKey("turfs.id"))
    start_time = Column(DateTime)
    end_time = Column(DateTime)
    is_booked = Column(Boolean, default=False)
    capacity = Column(Integer, default=1) # 1 for private, >1 for joinable slots
    current_bookings = Column(Integer, default=0)
    locked_until = Column(DateTime, nullable=True)
    locked_by = Column(Integer, ForeignKey("users.id"), nullable=True)
    
    turf = relationship("Turf", back_populates="slots")
    bookings = relationship("Booking", back_populates="slot")

class Booking(Base):
    __tablename__ = "bookings"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    turf_id = Column(Integer, ForeignKey("turfs.id"))
    slot_id = Column(Integer, ForeignKey("slots.id"))
    booking_date = Column(DateTime, default=datetime.utcnow)
    total_price = Column(Float)
    status = Column(String, default="confirmed")
    booking_type = Column(String, default="full") # 'full' (private) or 'join'
    
    user = relationship("User")
    turf = relationship("Turf")
    slot = relationship("Slot", back_populates="bookings")

class Favorite(Base):
    __tablename__ = "favorites"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    turf_id = Column(Integer, ForeignKey("turfs.id"))
    
    user = relationship("User")
    turf = relationship("Turf")

class Review(Base):
    __tablename__ = "reviews"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    turf_id = Column(Integer, ForeignKey("turfs.id"))
    rating = Column(Integer) # 1-5
    comment = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    user = relationship("User")
    turf = relationship("Turf")

class Offer(Base):
    __tablename__ = "offers"
    
    id = Column(Integer, primary_key=True, index=True)
    turf_id = Column(Integer, ForeignKey("turfs.id"), nullable=True) # Null if global offer
    title = Column(String)
    description = Column(String)
    discount_value = Column(Float)
    discount_type = Column(String, default="flat") # 'flat' or 'percentage'
    min_booking_amount = Column(Float, default=0.0)
    
    turf = relationship("Turf")

class FCMToken(Base):
    __tablename__ = "fcm_tokens"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    token = Column(String, unique=True, index=True)
    
    user = relationship("User")

class Match(Base):
    __tablename__ = "matches"
    
    id = Column(Integer, primary_key=True, index=True)
    turf_id = Column(Integer, ForeignKey("turfs.id"))
    team_a_name = Column(String, default="Team A")
    team_b_name = Column(String, default="Team B")
    team_a_score = Column(Integer, default=0)
    team_b_score = Column(Integer, default=0)
    status = Column(String, default="live") # 'live', 'completed', 'scheduled'
    sport_type = Column(String, default="Football")
    start_time = Column(DateTime, default=datetime.utcnow)
    
    turf = relationship("Turf")

class Tournament(Base):
    __tablename__ = "tournaments"
    
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, index=True)
    prize_pool = Column(Float, default=1000000.0)
    total_teams = Column(Integer, default=16)
    format = Column(String, default="Knockout")
    status = Column(String, default="upcoming") # 'upcoming', 'ongoing', 'completed'
    start_date = Column(DateTime, default=datetime.utcnow)

class Team(Base):
    __tablename__ = "teams"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True)
    captain_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    matches_played = Column(Integer, default=12)
    wins = Column(Integer, default=9)
    goals_scored = Column(Integer, default=32)
    rank = Column(Integer, default=2)

class CommunityPost(Base):
    __tablename__ = "community_posts"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    content = Column(String)
    image_url = Column(String, nullable=True)
    likes_count = Column(Integer, default=0)
    comments_count = Column(Integer, default=0)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    user = relationship("User")

class RentalItem(Base):
    __tablename__ = "rental_items"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True)
    price_per_day = Column(Float)
    category = Column(String, default="Football")
    image_url = Column(String, nullable=True)

class Coach(Base):
    __tablename__ = "coaches"
    
    id = Column(Integer, primary_key=True, index=True)
    full_name = Column(String, index=True)
    role = Column(String)
    rating = Column(Float, default=4.8)
    price_per_session = Column(Float)
    image_url = Column(String, nullable=True)

class ParkingReservation(Base):
    __tablename__ = "parking_reservations"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    turf_id = Column(Integer, ForeignKey("turfs.id"))
    vehicle_type = Column(String, default="Car") # 'Car', 'Bike', 'EV'
    price = Column(Float, default=50.0)
    status = Column(String, default="reserved")

class StockShare(Base):
    __tablename__ = "stock_shares"
    
    id = Column(Integer, primary_key=True, index=True)
    turf_id = Column(Integer, ForeignKey("turfs.id"))
    share_price = Column(Float, default=128.75)
    price_change_percentage = Column(Float, default=6.99)
    available_shares = Column(Integer, default=1000)
    
    turf = relationship("Turf")

