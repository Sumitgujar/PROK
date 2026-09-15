import os
import uuid
from pathlib import Path
from fastapi import UploadFile
from app.core.config import settings

os.makedirs(settings.upload_dir, exist_ok=True)

async def save_file(file: UploadFile, owner_id: str):
    ext = Path(file.filename or "file").suffix
    filename = f"{owner_id}_{uuid.uuid4().hex}{ext}"
    dest = os.path.join(settings.upload_dir, filename)
    content = await file.read()
    if len(content) > settings.max_file_size:
        raise ValueError(f"File too large (max {settings.max_file_size//1024//1024}MB)")
    with open(dest, "wb") as f:
        f.write(content)
    return f"/files/{filename}", len(content), file.filename or filename

def delete_file(file_url: str):
    filename = file_url.split("/")[-1]
    path = os.path.join(settings.upload_dir, filename)
    if os.path.exists(path):
        os.remove(path)
