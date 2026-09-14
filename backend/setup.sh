#!/usr/bin/env bash
# One-shot dev setup for the PROK backend.
# Run from the backend/ directory.
set -e

echo "=== PROK Backend Setup ==="

# 1. Virtual environment
if [ ! -d ".venv" ]; then
  python3 -m venv .venv
  echo "[OK] Virtual environment created."
fi

source .venv/bin/activate
echo "[OK] Virtual environment activated."

# 2. Install dependencies
pip install -r requirements.txt
echo "[OK] Dependencies installed."

# 3. Copy env
if [ ! -f ".env" ]; then
  cp .env.example .env
  echo "[OK] .env created from .env.example."
  echo "     IMPORTANT: Update SECRET_KEY before deploying!"
fi

# 4. Seed database (requires MongoDB to be running)
echo ""
echo "Seeding database ..."
python -m scripts.seed

echo ""
echo "=== Setup complete ==="
echo ""
echo "Start the server with:"
echo "  source .venv/bin/activate"
echo "  uvicorn app.main:app --reload --port 8000"
echo ""
echo "Run tests with:"
echo "  pytest -v"
