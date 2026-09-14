# PROK

**Predictive and Responsible Operations For Knowledge**

An AI-powered College Personal Guide bringing together student attendance, document management, scholarship assistance, personalised course recommendations, an AI college guide, teacher operations, and admin analytics — all from a single backend.

---

## Architecture

```
Clients                 Backend              Database
┌──────────────┐         ┌──────────────┐    ┌──────────────┐
│ Flutter (mobile)│         │ FastAPI (8000)│    │  MongoDB      │
│ React (web/5173)│──REST─►│               │►─►│  (27017)       │
└──────────────┘         └──────────────┘    └──────────────┘
```

- **One FastAPI backend** serves both mobile and web via REST JSON APIs.
- **One MongoDB** database (`prok_db`) with a collection per feature domain.
- **Flutter** app for students and teachers (Android / iOS).
- **React + Vite** admin dashboard (browser).
- **Python AI service** (Stage 2) for recommendations, scholarship matching, and the college AI guide.

---

## Prerequisites

| Tool | Version | Install |
|---|---|---|
| Docker & Docker Compose | any recent | https://docs.docker.com/get-docker/ |
| Python | 3.11+ | https://python.org |
| Node.js | 18+ | https://nodejs.org |
| Flutter SDK | 3.19+ | https://docs.flutter.dev/get-started/install |

---

## Quick Start

### 1. Start MongoDB

```bash
# From the PROK/ root
docker compose up -d
```

MongoDB will be available at `mongodb://localhost:27017`.
The `database/init.js` script runs automatically on first start, creating collections, indexes, and a seed admin account.

**Seed admin credentials:**
- Email: `admin@prok.edu`
- Password: `admin1234`

> ⚠️ Change this password immediately in production.

---

### 2. Start the Backend

```bash
cd backend

# Create and activate a virtual environment
python3 -m venv .venv
source .venv/bin/activate        # Windows: .venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Configure environment
cp .env.example .env
# Edit .env if needed (defaults work for local Docker Mongo)

# Run
uvicorn app.main:app --reload --port 8000
```

- API: http://localhost:8000
- Interactive docs: http://localhost:8000/docs
- Health check: http://localhost:8000/health

---

### 3. Start the Web Dashboard

```bash
cd web

# Install dependencies
npm install

# Configure environment
cp .env.example .env.local
# Default: VITE_API_BASE_URL=http://localhost:8000

# Run
npm run dev
```

- Dashboard: http://localhost:5173

---

### 4. Start the Mobile App

```bash
cd mobile

# Get dependencies
flutter pub get

# Run on a connected device or emulator
flutter run
```

> For Android emulator the backend URL is pre-set to `http://10.0.2.2:8000`.
> For a physical device or iOS simulator, update `kApiBaseUrl` in `lib/core/constants.dart` to your machine’s LAN IP.

---

## Project Structure

```
PROK/
├── mobile/              # Flutter app
│   └── lib/
│       ├── core/        # Constants, router
│       ├── models/      # Data classes
│       ├── providers/   # ChangeNotifier state
│       ├── screens/     # UI screens
│       ├── services/    # HTTP API client
│       └── widgets/     # Reusable widgets
├── web/                 # React + Vite + TypeScript
│   └── src/
│       ├── components/  # Shared UI components
│       ├── hooks/       # Custom React hooks
│       ├── layouts/     # Page shells
│       ├── pages/       # Route-level pages
│       ├── services/    # Axios API client
│       ├── types/       # TypeScript types
│       └── utils/       # Helpers
├── backend/             # FastAPI
│   └── app/
│       ├── core/        # Config, security
│       ├── db/          # MongoDB connection
│       ├── models/      # DB document shapes
│       ├── routers/     # API endpoints
│       ├── schemas/     # Pydantic request/response
│       ├── services/    # Business logic
│       └── utils/       # Helpers
├── ai/                  # Python AI service (Stage 2)
├── database/            # MongoDB init script
├── docs/                # Architecture docs
├── docker-compose.yml
├── .gitignore
└── README.md
```

---

## API Reference (Stage 1)

| Method | Endpoint | Description |
|---|---|---|
| GET | `/` | Root — API status |
| GET | `/health` | Health + DB ping |
| POST | `/auth/register` | Register a new user |
| POST | `/auth/login` | Login (returns JWT) |
| GET | `/auth/me` | Current user (auth required) |

Full interactive docs at http://localhost:8000/docs

---

## Stage 2 (not yet implemented)

- Student attendance CRUD
- Teacher attendance operations
- Document upload / management
- Scholarship search and AI matching
- Personalised course recommendations
- AI College Guide (chat)
- Admin analytics and verification dashboard
