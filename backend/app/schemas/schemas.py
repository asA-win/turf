from pydantic import BaseModel
from typing import List, Optional, Dict, Any
from datetime import datetime

class TurfBase(BaseModel):
    name: str
    location: str
    price_per_hour: float
    image_url: Optional[str] = None
    description: Optional[str] = None
    sport_types: Optional[str] = "Football,Cricket"
    amenities: Optional[str] = "Parking,UPI,Water"
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    pitch_info: Optional[str] = "1 Nets"
    equipment_provided: Optional[str] = None
    turf_type: Optional[str] = "Artificial"
    owner_id: Optional[int] = None
    status: Optional[str] = "pending" # 'pending', 'approved', 'rejected'
    rejection_reason: Optional[str] = None
    document_url: Optional[str] = None
    contact_phone: Optional[str] = None

class TurfCreate(TurfBase):
    pass

class Turf(TurfBase):
    id: int
    average_rating: float = 0.0
    total_reviews: int = 0
    created_at: Optional[datetime] = None
    class Config:
        from_attributes = True

class SlotBase(BaseModel):
    turf_id: int
    start_time: datetime
    end_time: datetime
    is_booked: bool = False
    capacity: int = 1
    current_bookings: int = 0

class SlotCreate(SlotBase):
    pass

class Slot(SlotBase):
    id: int
    locked_until: Optional[datetime] = None
    locked_by: Optional[int] = None
    class Config:
        from_attributes = True

class UserBase(BaseModel):
    firebase_uid: Optional[str] = None
    email: Optional[str] = None
    full_name: Optional[str] = "User"
    phone: Optional[str] = None
    owner_status: Optional[str] = "pending" # 'pending', 'approved', 'rejected', 'suspended'
    rejection_reason: Optional[str] = None
    business_name: Optional[str] = None
    city: Optional[str] = None

class UserCreate(UserBase):
    firebase_uid: str
    password: Optional[str] = None

class UserUpdate(BaseModel):
    full_name: Optional[str] = None
    email: Optional[str] = None
    phone: Optional[str] = None
    business_name: Optional[str] = None
    city: Optional[str] = None

class UserUpdateRole(BaseModel):
    role: str

class User(UserBase):
    id: int
    role: str
    created_at: Optional[datetime] = None
    class Config:
        from_attributes = True

class BookingBase(BaseModel):
    turf_id: int
    slot_id: int
    booking_type: str = "full" # 'full' or 'join'

class BookingCreate(BookingBase):
    pass

class Booking(BookingBase):
    id: int
    user_id: int
    booking_date: datetime
    total_price: float
    status: str
    class Config:
        from_attributes = True

class MatchParticipantBase(BaseModel):
    team: str = "A"
    player_name: str
    player_role: Optional[str] = None
    jersey_number: Optional[str] = None

class MatchParticipantCreate(BaseModel):
    team: Optional[str] = "A"
    player_name: Optional[str] = None
    player_role: Optional[str] = None
    jersey_number: Optional[str] = None

class MatchParticipant(MatchParticipantBase):
    id: int
    match_id: int
    user_id: int
    joined_at: Optional[datetime] = None
    class Config:
        from_attributes = True

class MatchBase(BaseModel):
    title: Optional[str] = None
    turf_id: Optional[int] = None
    sport_type: str = "Football"
    format: Optional[str] = "5v5"
    venue_name: Optional[str] = "Play Arena"
    location: Optional[str] = "Koramangala, Bengaluru"
    match_date: Optional[str] = None
    match_time: Optional[str] = None
    duration_minutes: Optional[int] = 60
    team_a_name: str = "Team Alpha"
    team_b_name: str = "Team Beta"
    team_a_score: int = 0
    team_b_score: int = 0
    team_a_color: Optional[str] = "Neon Green"
    team_b_color: Optional[str] = "Royal Blue"
    status: str = "scheduled"
    max_players: Optional[int] = 10
    current_players_count: Optional[int] = 1
    price_per_player: Optional[float] = 0.0
    skill_level: Optional[str] = "Intermediate"
    scoreboard_state_json: Optional[str] = None
    timeline_events_json: Optional[str] = None
    mvp_player_name: Optional[str] = None
    mvp_notes: Optional[str] = None

class MatchCreate(MatchBase):
    pass

class MatchUpdate(BaseModel):
    title: Optional[str] = None
    sport_type: Optional[str] = None
    format: Optional[str] = None
    venue_name: Optional[str] = None
    location: Optional[str] = None
    match_date: Optional[str] = None
    match_time: Optional[str] = None
    duration_minutes: Optional[int] = None
    team_a_name: Optional[str] = None
    team_b_name: Optional[str] = None
    team_a_color: Optional[str] = None
    team_b_color: Optional[str] = None
    status: Optional[str] = None
    max_players: Optional[int] = None
    price_per_player: Optional[float] = None
    skill_level: Optional[str] = None
    scoreboard_state_json: Optional[str] = None
    timeline_events_json: Optional[str] = None
    mvp_player_name: Optional[str] = None
    mvp_notes: Optional[str] = None

class MatchScoreUpdate(BaseModel):
    team_a_score: Optional[int] = None
    team_b_score: Optional[int] = None
    status: Optional[str] = None
    scoreboard_state_json: Optional[str] = None

class MatchTimelineEventCreate(BaseModel):
    event_type: str
    minute: Optional[str] = None
    team: Optional[str] = None
    player_name: Optional[str] = None
    description: Optional[str] = None
    score_snapshot: Optional[str] = None

class MatchFinishRequest(BaseModel):
    mvp_player_name: Optional[str] = None
    mvp_notes: Optional[str] = None
    final_team_a_score: Optional[int] = None
    final_team_b_score: Optional[int] = None

class Match(MatchBase):
    id: int
    creator_id: Optional[int] = None
    start_time: Optional[datetime] = None
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None
    turf: Optional[Turf] = None
    participants: List[MatchParticipant] = []
    class Config:
        from_attributes = True

class FavoriteBase(BaseModel):
    turf_id: int

class FavoriteCreate(FavoriteBase):
    pass

class Favorite(FavoriteBase):
    id: int
    user_id: int
    turf: Turf
    class Config:
        from_attributes = True

class OfferBase(BaseModel):
    turf_id: Optional[int] = None
    title: str
    description: str
    discount_value: float
    discount_type: str = "flat"
    min_booking_amount: float = 0.0

class OfferCreate(OfferBase):
    pass

class Offer(OfferBase):
    id: int
    class Config:
        from_attributes = True

class ReviewBase(BaseModel):
    turf_id: int
    rating: int
    comment: Optional[str] = None

class ReviewCreate(ReviewBase):
    pass

class Review(ReviewBase):
    id: int
    user_id: int
    created_at: datetime
    user: User
    class Config:
        from_attributes = True

class FCMTokenBase(BaseModel):
    token: str

class FCMTokenCreate(FCMTokenBase):
    pass

class FCMToken(FCMTokenBase):
    id: int
    user_id: int
    class Config:
        from_attributes = True

# --- Authentication & OTP Schemas ---
class SendOTPRequest(BaseModel):
    identifier: str # phone or email

class RegisterUserRequest(BaseModel):
    email: str
    password: str
    full_name: Optional[str] = "User"
    phone: Optional[str] = None

class RegisterOwnerRequest(BaseModel):
    business_name: str
    owner_name: str
    email: str
    phone: str
    password: str
    city: Optional[str] = "Bangalore"
    turf_name: Optional[str] = None
    hourly_price: Optional[float] = 1200.0
    sports: Optional[str] = "Football, Cricket"
    amenities: Optional[str] = "Floodlights, Parking, Drinking Water"
    surface_type: Optional[str] = "FIFA Grade Artificial Turf"
    document_url: Optional[str] = None
    image_url: Optional[str] = None
    pitch_info: Optional[str] = "Standard Match Pitch"
    description: Optional[str] = None

class VerifyOTPRequest(BaseModel):
    identifier: str
    code: str
    role: Optional[str] = "user"

class LoginRequest(BaseModel):
    email: str
    password: str

class ForgotPasswordRequest(BaseModel):
    identifier: str # phone or email

class ResetPasswordRequest(BaseModel):
    identifier: str
    code: str
    new_password: str

class ChangePasswordRequest(BaseModel):
    old_password: str
    new_password: str

class AuthTokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: User

# --- Wallet & Referral Schemas ---
class WalletResponse(BaseModel):
    id: int
    user_id: int
    balance: float
    coins: int
    class Config:
        from_attributes = True

class WalletTransactionResponse(BaseModel):
    id: int
    title: str
    amount: float
    transaction_type: str
    created_at: datetime
    class Config:
        from_attributes = True

class ReferralResponse(BaseModel):
    referral_code: str
    total_referred: int = 0
    total_rewards: float = 0.0

# --- Tournament Schemas ---
class TournamentRegistrationCreate(BaseModel):
    team_name: str
    team_tag: Optional[str] = None
    captain_name: str
    contact_phone: str
    contact_email: Optional[str] = None
    emergency_contact: Optional[str] = None
    jersey_color: Optional[str] = "Neon Green"
    skill_level: Optional[str] = "Intermediate / Club"
    players: Optional[List[dict]] = []
    special_requests: Optional[str] = None

class TournamentRegistrationStatusUpdate(BaseModel):
    status: str # 'Approved', 'Rejected', 'Cancelled', 'Pending'

class TournamentRegistrationOut(BaseModel):
    id: int
    tournament_id: int
    user_id: int
    team_name: str
    team_tag: Optional[str] = None
    captain_name: str
    contact_phone: str
    contact_email: Optional[str] = None
    emergency_contact: Optional[str] = None
    jersey_color: Optional[str] = None
    skill_level: Optional[str] = None
    players_json: Optional[str] = None
    players_count: int = 1
    special_requests: Optional[str] = None
    status: str = "Approved"
    created_at: datetime
    class Config:
        from_attributes = True

class TournamentMatchOut(BaseModel):
    id: int
    tournament_id: int
    match_number: int
    round: int = 1
    stage: str
    stage_group: Optional[str] = None
    team_a_registration_id: Optional[int] = None
    team_b_registration_id: Optional[int] = None
    team_a_name: str
    team_b_name: str
    team_a_score: int = 0
    team_b_score: int = 0
    winner_name: Optional[str] = None
    status: str = "scheduled"
    venue_pitch: Optional[str] = None
    scheduled_time: Optional[str] = None
    notes: Optional[str] = None
    created_at: datetime
    updated_at: datetime
    class Config:
        from_attributes = True

class TournamentMatchScoreUpdate(BaseModel):
    team_a_score: int
    team_b_score: int
    status: Optional[str] = "completed"
    winner_name: Optional[str] = None

class TournamentFixturesGenerate(BaseModel):
    strategy: Optional[str] = "balanced" # 'balanced', 'seeded', 'random'

class TournamentBase(BaseModel):
    title: str
    description: Optional[str] = None
    sport: str = "Football"
    format: str = "5v5 Knockout"
    level: str = "Open Category"
    venue: str = "Play Arena"
    area: str = "Koramangala"
    city: str = "Bangalore"
    banner_image: Optional[str] = None
    prize_pool: float = 100000.0
    entry_fee: float = 0.0
    total_teams: int = 16
    start_date: Optional[datetime] = None
    end_date: Optional[datetime] = None
    registration_deadline: Optional[datetime] = None
    rules: Optional[str] = None
    status: str = "Open Entry"
    contact_phone: Optional[str] = None
    organizer_name: Optional[str] = None

class TournamentCreate(TournamentBase):
    pass

class TournamentUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    sport: Optional[str] = None
    format: Optional[str] = None
    level: Optional[str] = None
    venue: Optional[str] = None
    area: Optional[str] = None
    city: Optional[str] = None
    banner_image: Optional[str] = None
    prize_pool: Optional[float] = None
    entry_fee: Optional[float] = None
    total_teams: Optional[int] = None
    start_date: Optional[datetime] = None
    end_date: Optional[datetime] = None
    registration_deadline: Optional[datetime] = None
    rules: Optional[str] = None
    status: Optional[str] = None
    contact_phone: Optional[str] = None
    organizer_name: Optional[str] = None

class Tournament(TournamentBase):
    id: int
    creator_id: Optional[int] = None
    registered_teams_count: int = 0
    fixtures_generated: bool = False
    created_at: datetime
    updated_at: datetime
    class Config:
        from_attributes = True

class TournamentDetail(Tournament):
    registrations: List[TournamentRegistrationOut] = []
    matches: List[TournamentMatchOut] = []
    class Config:
        from_attributes = True

# --- Admin Panel Action Schemas ---
class TurfApprovalAction(BaseModel):
    reason: Optional[str] = None

class OwnerStatusAction(BaseModel):
    status: str # 'active', 'suspended', 'rejected', 'approved'
    reason: Optional[str] = None

class AdminChangePasswordRequest(BaseModel):
    current_password: str
    new_password: str

class AdminAuditLogResponse(BaseModel):
    id: int
    admin_id: Optional[int] = None
    action: str
    target_type: str
    target_id: Optional[int] = None
    details: str
    created_at: datetime
    class Config:
        from_attributes = True


