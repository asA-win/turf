from sqlalchemy import Column, Integer, String, Float, Boolean, ForeignKey, DateTime, Text
from sqlalchemy.orm import relationship
from datetime import datetime
from app.db.session import Base

class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    firebase_uid = Column(String, unique=True, index=True)
    email = Column(String, unique=True, index=True)
    full_name = Column(String)
    role = Column(String, default="user") # 'user', 'owner', 'admin'
    phone = Column(String, nullable=True)
    hashed_password = Column(String, nullable=True)
    is_verified = Column(Boolean, default=False)
    owner_status = Column(String, default="pending") # 'pending', 'approved', 'rejected', 'suspended'
    rejection_reason = Column(String, nullable=True)
    business_name = Column(String, nullable=True)
    city = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

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
    status = Column(String, default="pending") # 'pending', 'approved', 'rejected'
    rejection_reason = Column(String, nullable=True)
    document_url = Column(String, nullable=True)
    contact_phone = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    
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
    creator_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    turf_id = Column(Integer, ForeignKey("turfs.id"), nullable=True)
    title = Column(String, nullable=True)
    sport_type = Column(String, default="Football") # 'Football', 'Cricket', 'Badminton', 'Basketball', 'Tennis'
    format = Column(String, default="5v5")
    venue_name = Column(String, default="Play Arena")
    location = Column(String, default="Koramangala, Bengaluru")
    match_date = Column(String, nullable=True)
    match_time = Column(String, nullable=True)
    duration_minutes = Column(Integer, default=60)
    team_a_name = Column(String, default="Team Alpha")
    team_b_name = Column(String, default="Team Beta")
    team_a_score = Column(Integer, default=0)
    team_b_score = Column(Integer, default=0)
    team_a_color = Column(String, default="Neon Green")
    team_b_color = Column(String, default="Royal Blue")
    status = Column(String, default="scheduled") # 'scheduled', 'live', 'completed', 'cancelled'
    max_players = Column(Integer, default=10)
    current_players_count = Column(Integer, default=1)
    price_per_player = Column(Float, default=0.0)
    skill_level = Column(String, default="Intermediate")
    scoreboard_state_json = Column(Text, nullable=True)
    timeline_events_json = Column(Text, nullable=True)
    mvp_player_name = Column(String, nullable=True)
    mvp_notes = Column(String, nullable=True)
    start_time = Column(DateTime, default=datetime.utcnow)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    turf = relationship("Turf")
    creator = relationship("User", foreign_keys=[creator_id])
    participants = relationship("MatchParticipant", back_populates="match", cascade="all, delete-orphan", lazy="selectin")

class MatchParticipant(Base):
    __tablename__ = "match_participants"
    
    id = Column(Integer, primary_key=True, index=True)
    match_id = Column(Integer, ForeignKey("matches.id", ondelete="CASCADE"), nullable=False)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    team = Column(String, default="A") # 'A' or 'B'
    player_name = Column(String, nullable=False)
    player_role = Column(String, nullable=True)
    jersey_number = Column(String, nullable=True)
    joined_at = Column(DateTime, default=datetime.utcnow)
    
    match = relationship("Match", back_populates="participants")
    user = relationship("User")

class Tournament(Base):
    __tablename__ = "tournaments"
    
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, index=True)
    description = Column(String, nullable=True)
    sport = Column(String, default="Football") # 'Football', 'Cricket', 'Badminton', 'Basketball', 'Tennis', 'Volleyball'
    format = Column(String, default="5v5 Knockout")
    level = Column(String, default="Open Category")
    venue = Column(String, default="Play Arena")
    area = Column(String, default="Koramangala")
    city = Column(String, default="Bangalore")
    banner_image = Column(String, nullable=True)
    prize_pool = Column(Float, default=100000.0)
    entry_fee = Column(Float, default=0.0)
    total_teams = Column(Integer, default=16)
    registered_teams_count = Column(Integer, default=0)
    start_date = Column(DateTime, default=datetime.utcnow)
    end_date = Column(DateTime, nullable=True)
    registration_deadline = Column(DateTime, nullable=True)
    rules = Column(String, nullable=True)
    status = Column(String, default="Open Entry") # 'Draft', 'Open Entry', 'Upcoming', 'Ongoing (Live)', 'Completed', 'Cancelled'
    creator_id = Column(Integer, ForeignKey("users.id"), index=True, nullable=True)
    contact_phone = Column(String, nullable=True)
    organizer_name = Column(String, nullable=True)
    fixtures_generated = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    creator = relationship("User", foreign_keys=[creator_id])
    registrations = relationship("TournamentRegistration", back_populates="tournament", cascade="all, delete-orphan")
    matches = relationship("TournamentMatch", back_populates="tournament", cascade="all, delete-orphan")

class TournamentRegistration(Base):
    __tablename__ = "tournament_registrations"

    id = Column(Integer, primary_key=True, index=True)
    tournament_id = Column(Integer, ForeignKey("tournaments.id"), index=True)
    user_id = Column(Integer, ForeignKey("users.id"), index=True)
    team_name = Column(String, index=True)
    team_tag = Column(String, nullable=True)
    captain_name = Column(String)
    contact_phone = Column(String)
    contact_email = Column(String, nullable=True)
    emergency_contact = Column(String, nullable=True)
    jersey_color = Column(String, default="Neon Green")
    skill_level = Column(String, default="Intermediate / Club")
    players_json = Column(String, nullable=True) # JSON array of player dicts
    players_count = Column(Integer, default=1)
    special_requests = Column(String, nullable=True)
    status = Column(String, default="Approved") # 'Pending', 'Approved', 'Rejected', 'Cancelled'
    created_at = Column(DateTime, default=datetime.utcnow)

    tournament = relationship("Tournament", back_populates="registrations")
    user = relationship("User", foreign_keys=[user_id])

class TournamentMatch(Base):
    __tablename__ = "tournament_matches"

    id = Column(Integer, primary_key=True, index=True)
    tournament_id = Column(Integer, ForeignKey("tournaments.id"), index=True)
    match_number = Column(Integer)
    round = Column(Integer, default=1)
    stage = Column(String) # e.g. "Quarter Final 1", "Semi Final 1", "Grand Final"
    stage_group = Column(String) # "Quarter Finals", "Semi Finals", "Final"
    team_a_registration_id = Column(Integer, ForeignKey("tournament_registrations.id"), nullable=True)
    team_b_registration_id = Column(Integer, ForeignKey("tournament_registrations.id"), nullable=True)
    team_a_name = Column(String)
    team_b_name = Column(String)
    team_a_score = Column(Integer, default=0)
    team_b_score = Column(Integer, default=0)
    winner_name = Column(String, nullable=True)
    status = Column(String, default="scheduled") # 'scheduled', 'live', 'completed', 'cancelled'
    venue_pitch = Column(String, nullable=True)
    scheduled_time = Column(String, nullable=True)
    notes = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    tournament = relationship("Tournament", back_populates="matches")
    team_a_registration = relationship("TournamentRegistration", foreign_keys=[team_a_registration_id])
    team_b_registration = relationship("TournamentRegistration", foreign_keys=[team_b_registration_id])

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

class OTPCode(Base):
    __tablename__ = "otp_codes"
    
    id = Column(Integer, primary_key=True, index=True)
    identifier = Column(String, index=True) # phone or email
    code = Column(String, index=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    expires_at = Column(DateTime)
    is_used = Column(Boolean, default=False)

class Wallet(Base):
    __tablename__ = "wallets"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), unique=True)
    balance = Column(Float, default=500.0)
    coins = Column(Integer, default=120)
    
    user = relationship("User")

class WalletTransaction(Base):
    __tablename__ = "wallet_transactions"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    title = Column(String)
    amount = Column(Float)
    transaction_type = Column(String, default="credit") # 'credit' or 'debit'
    created_at = Column(DateTime, default=datetime.utcnow)
    
    user = relationship("User")

class Referral(Base):
    __tablename__ = "referrals"
    
    id = Column(Integer, primary_key=True, index=True)
    referrer_id = Column(Integer, ForeignKey("users.id"))
    referred_email = Column(String, nullable=True)
    reward_amount = Column(Float, default=100.0)
    status = Column(String, default="completed") # 'pending', 'completed'
    created_at = Column(DateTime, default=datetime.utcnow)
    
    referrer = relationship("User")

class AdminAuditLog(Base):
    __tablename__ = "admin_audit_logs"
    
    id = Column(Integer, primary_key=True, index=True)
    admin_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    action = Column(String, index=True) # 'APPROVE_TURF', 'REJECT_TURF', 'SUSPEND_OWNER', 'ACTIVATE_OWNER', etc.
    target_type = Column(String) # 'turf', 'owner', 'admin'
    target_id = Column(Integer, nullable=True)
    details = Column(String)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    admin = relationship("User")

class DirectMessage(Base):
    __tablename__ = "direct_messages"

    id = Column(Integer, primary_key=True, index=True)
    room_id = Column(String, index=True)
    sender_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    recipient_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    sender_name = Column(String)
    message = Column(Text)
    created_at = Column(DateTime, default=datetime.utcnow)

    sender = relationship("User", foreign_keys=[sender_id])
    recipient = relationship("User", foreign_keys=[recipient_id])



