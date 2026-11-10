from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
import firebase_admin
from firebase_admin import credentials, auth
import os
from typing import Optional

import json

# Initialize Firebase with the provided credentials
try:
    if not firebase_admin._apps:
        # 1. Try to load from Environment Variable (for Render/Production)
        firebase_creds_json = os.getenv("FIREBASE_CONFIG")
        
        if firebase_creds_json:
            try:
                creds_dict = json.loads(firebase_creds_json)
                cred = credentials.Certificate(creds_dict)
                firebase_admin.initialize_app(cred)
                print("Initialized Firebase using FIREBASE_CONFIG env var.")
            except Exception as e:
                print(f"Error parsing FIREBASE_CONFIG env var: {e}")
        
        # 2. Fallback to local file (for Development)
        if not firebase_admin._apps:
            cred_filename = "turf-d190a-firebase-adminsdk-fbsvc-95e65dff02.json"
            if os.path.exists(cred_filename):
                cred = credentials.Certificate(cred_filename)
                firebase_admin.initialize_app(cred)
            elif os.path.exists(os.path.join("backend", cred_filename)):
                cred = credentials.Certificate(os.path.join("backend", cred_filename))
                firebase_admin.initialize_app(cred)
            else:
                # Last resort: search for any json file
                files = [f for f in os.listdir(".") if f.endswith(".json") and "firebase-adminsdk" in f]
                if files:
                    cred = credentials.Certificate(files[0])
                    firebase_admin.initialize_app(cred)
                else:
                    print("Warning: No Firebase credentials found. Auth will fail.")
except Exception as e:
    print(f"Firebase init error: {e}")

security = HTTPBearer(auto_error=False)

def get_current_user(credentials: Optional[HTTPAuthorizationCredentials] = Depends(security)):
    if not credentials:
        # Fallback to demo user for free local development
        return {
            "uid": "demo-user-id",
            "email": "user@example.com",
            "name": "Demo User"
        }
    token = credentials.credentials
    try:
        decoded_token = auth.verify_id_token(token)
        return decoded_token
    except Exception as e:
        # Return demo user on invalid/expired token in dev mode
        return {
            "uid": "demo-user-id",
            "email": "user@example.com",
            "name": "Demo User"
        }

