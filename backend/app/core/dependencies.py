from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from app.core.security import decode_token
from app.db.connection import get_database
from jose import JWTError

bearerScheme = HTTPBearer()

async def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(bearerScheme), db=Depends(get_database)):
    token = credentials.credentials
    try:
        payload = decode_token(token)
        user_id = payload.get("sub")
        if not user_id:
            raise HTTPException(status_code=401, detail="Invalid token")
    except JWTError:
        raise HTTPException(status_code=401, detail="Invalid token")
    from bson import ObjectId
    user = await db.users.find_one({"_id": ObjectId(user_id)})
    if not user:
        raise HTTPException(status_code=401, detail="User not found")
    return user

def require_role(*roles):
    async def check(current_user=Depends(get_current_user)):
        if current_user["role"] not in roles:
            raise HTTPException(status_code=403, detail="Access denied")
        return current_user
    return check
