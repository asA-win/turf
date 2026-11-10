import pytest
from httpx import AsyncClient

@pytest.mark.asyncio
async def test_send_and_verify_otp(async_client: AsyncClient):
    # 1. Send OTP
    send_res = await async_client.post(
        "/api/v1/auth/send-otp",
        json={"identifier": "+919876543210"}
    )
    assert send_res.status_code == 200
    data = send_res.json()
    assert data["success"] is True
    assert "otp" in data
    otp_code = data["otp"]

    # 2. Verify OTP
    verify_res = await async_client.post(
        "/api/v1/auth/verify-otp",
        json={"identifier": "+919876543210", "code": otp_code}
    )
    assert verify_res.status_code == 200
    verify_data = verify_res.json()
    assert "access_token" in verify_data
    assert verify_data["token_type"] == "bearer"
    assert verify_data["user"]["phone"] == "+919876543210"

@pytest.mark.asyncio
async def test_forgot_and_reset_password(async_client: AsyncClient):
    # Create / verify user first
    verify_res = await async_client.post(
        "/api/v1/auth/verify-otp",
        json={"identifier": "testreset@example.com", "code": "123456"}
    )
    assert verify_res.status_code == 200

    # Forgot password
    forgot_res = await async_client.post(
        "/api/v1/auth/forgot-password",
        json={"identifier": "testreset@example.com"}
    )
    assert forgot_res.status_code == 200
    reset_otp = forgot_res.json()["otp"]

    # Reset password
    reset_res = await async_client.post(
        "/api/v1/auth/reset-password",
        json={
            "identifier": "testreset@example.com",
            "code": reset_otp,
            "new_password": "NewSecretPassword123"
        }
    )
    assert reset_res.status_code == 200
    assert reset_res.json()["success"] is True

    # Login with new password
    login_res = await async_client.post(
        "/api/v1/auth/login",
        json={
            "email": "testreset@example.com",
            "password": "NewSecretPassword123"
        }
    )
    assert login_res.status_code == 200
    assert "access_token" in login_res.json()

@pytest.mark.asyncio
async def test_user_wallet_and_referral(async_client: AsyncClient):
    # Verify user
    res = await async_client.post(
        "/api/v1/auth/verify-otp",
        json={"identifier": "walletuser@example.com", "code": "123456"}
    )
    token = res.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # Fetch wallet
    wallet_res = await async_client.get("/api/v1/users/wallet", headers=headers)
    assert wallet_res.status_code == 200
    assert wallet_res.json()["balance"] >= 0

    # Add money
    topup_res = await async_client.post("/api/v1/users/wallet/add-money?amount=250", headers=headers)
    assert topup_res.status_code == 200
    assert topup_res.json()["balance"] >= 250

    # Referral info
    ref_res = await async_client.get("/api/v1/users/referral", headers=headers)
    assert ref_res.status_code == 200
    assert "referral_code" in ref_res.json()
