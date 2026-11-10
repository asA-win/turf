from pydantic import BaseModel
from typing import List, Optional
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

class TurfCreate(TurfBase):
    pass

class Turf(TurfBase):
    id: int
    average_rating: float = 0.0
    total_reviews: int = 0
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

class UserCreate(UserBase):
    firebase_uid: str

class UserUpdateRole(BaseModel):
    role: str

class User(UserBase):
    id: int
    role: str
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

class MatchBase(BaseModel):
    turf_id: int
    team_a_name: str = "Team A"
    team_b_name: str = "Team B"
    team_a_score: int = 0
    team_b_score: int = 0
    status: str = "live"
    sport_type: str = "Football"

class MatchCreate(MatchBase):
    pass

class Match(MatchBase):
    id: int
    start_time: datetime
    turf: Optional[Turf] = None
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
