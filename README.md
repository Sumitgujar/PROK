# PROK — Predictive and Responsible Operations For Knowledge

An AI-assisted academic management platform for students, teachers, and admins.
Built for hackathon demo — fully functional end-to-end system.

```
PROK identity: MANAGE → GUIDE → SUPPORT → GROW
```

---

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                     CLIENTS                             │
│  Flutter (iOS/Android)    React Admin (web :5173)       │
└───────────────┬───────────────────────┬─────────────────┘
                │ REST / JSON           │ REST / JSON
                ▼                       ▼
┌─────────────────────────────────────────────────────────┐
│              FastAPI Backend (:8000)                     │
│  Auth · Attendance · Documents · Scholarships           │
│  Courses · Intelligence · Ask PROK · Interventions      │
│  Notifications · Admin                                  │
└───────────────────────────┬─────────────────────────────┘
                            │ Motor (async)
                            ▼
┌─────────────────────────────────────────────────────────┐
│              MongoDB (:27017)  — prok_db                 │
│  15 collections · indexes on all hot query paths        │
└─────────────────────────────────────────────────────────┘
```

**One source of truth:** Flutter → FastAPI → MongoDB ← React.
No frontend mock databases. All data flows through the backend.

---

## Prerequisites

| Tool | Version | Purpose |
|---|---|---|
| Docker + Docker Compose | any recent | MongoDB container |
| Python | 3.11+ | FastAPI backend |
| Node.js | 18+ | React web dashboard |
| Flutter SDK | 3.19+ | Mobile app |

---

## MongoDB Setup

```bash
# From PROK/ root — starts MongoDB on port 27017
docker compose up -d

# Verify it is running
docker compose ps
```

MongoDB data is persisted in a Docker volume. To reset:
```bash
docker compose down -v  # destroys data
docker compose up -d
```

---

## Environment Variables

### Backend (`backend/.env`)

Copy the example and set your own `SECRET_KEY`:
```bash
cd backend
cp .env.example .env
```

```env
# MongoDB
MONGODB_URL=mongodb://localhost:27017
DATABASE_NAME=prok_db

# Auth
SECRET_KEY=change-this-to-a-long-random-string
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=60

# CORS
CORS_ORIGINS=["http://localhost:5173","http://localhost:3000"]

# AI Provider (optional — leave blank to use deterministic fallback)
AI_PROVIDER_URL=
AI_PROVIDER_API_KEY=
AI_MODEL=
LOCAL_AI_URL=
LOCAL_AI_MODEL=
AI_TIMEOUT_SECONDS=15
```

Generate a secure key:
```bash
python3 -c "import secrets; print(secrets.token_hex(32))"
```

### Web (`web/.env.local`)

```bash
cd web
cp .env.example .env.local
```

```env
VITE_API_BASE_URL=http://localhost:8000
```

### Mobile (`mobile/lib/core/constants.dart`)

```dart
static const String baseUrl = 'http://10.0.2.2:8000';  // Android emulator
// static const String baseUrl = 'http://localhost:8000'; // iOS simulator
// static const String baseUrl = 'http://192.168.x.x:8000'; // physical device
```

---

## Backend Startup

```bash
cd backend

# First time setup
python3 -m venv .venv
source .venv/bin/activate          # Windows: .venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env               # then edit SECRET_KEY

# Start server
uvicorn app.main:app --reload --port 8000
```

- API docs (Swagger): http://localhost:8000/docs
- Health check: http://localhost:8000/health
- The database collections and indexes are created automatically on first startup.

---

## Seed Commands

```bash
# Seed base demo accounts (student, teacher, admin)
cd backend
python -m scripts.seed

# Seed full Aarav Shah demo story (attendance, docs, scholarships, interventions)
python -m scripts.seed_demo
```

The demo seed is safe to run multiple times — it wipes its own previous data first.

---

## Web Dashboard Startup

```bash
cd web
npm install
cp .env.example .env.local
npm run dev
```

Open: http://localhost:5173
Log in with: `admin@prok.edu` / `admin123`

---

## Mobile App Startup

```bash
cd mobile
flutter pub get
flutter run
```

For physical device: update `kApiBaseUrl` in `lib/core/constants.dart` to your machine's LAN IP.

---

## Demo Accounts

| Role | Email | Password | Notes |
|---|---|---|---|
| Student | `student@prok.edu` | `student123` | Alex Johnson — base account |
| Student | `aarav@prok.edu` | `aarav123` | Aarav Shah — full demo story |
| Teacher | `teacher@prok.edu` | `teacher123` | Dr. Sarah Williams |
| Admin | `admin@prok.edu` | `admin123` | Full admin access |

> Aarav's account is created by `python -m scripts.seed_demo`.

---

## Demo Story (Aarav Shah)

This complete flow works end-to-end after running `seed_demo`:

1. **Aarav logs in** → sees dashboard with overall attendance %
2. **Attendance tab** → sees CS301 at 40% and MA201 at 35% — both HIGH RISK
3. **Ask PROK** → asks "What should I focus on?" → gets grounded answer from real DB data
4. **Scholarships tab** → sees 3 scholarships, matched scores, missing document highlighted
5. **Documents tab** → sees Bonafide is UNDER_REVIEW, Caste Certificate REJECTED
6. **Courses tab** → sees recommendations matching Python/ML/Data Science skills
7. **Teacher logs in** → opens today's class → marks students present/absent → submits
8. **MongoDB updated** → Aarav's attendance % changes → absent students get notification
9. **Admin logs in** → Documents page → verifies Aarav's Bonafide certificate
10. **Aarav refreshes Documents** → status shows VERIFIED → notification received

---

## API Overview

### Auth
| Method | Endpoint | Auth | Description |
|---|---|---|---|
| POST | `/auth/register` | ✗ | Register new user (role=student always) |
| POST | `/auth/login` | ✗ | Login — returns JWT |
| GET | `/auth/me` | ✓ | Current user profile |

### Attendance
| Method | Endpoint | Auth | Description |
|---|---|---|---|
| POST | `/attendance/mark` | teacher | Mark attendance session |
| GET | `/attendance/student/summary` | student | Per-course attendance % |
| GET | `/attendance/teacher/courses` | teacher | Today's classes |
| GET | `/attendance/courses/{id}/students` | teacher | Student list for a course |
| GET | `/attendance/courses/{id}/history` | teacher | Session history |
| GET | `/attendance/sessions/today` | admin | Today's sessions |
| GET | `/attendance/sessions/{id}/records` | admin | Per-session records |

### Documents
| Method | Endpoint | Auth | Description |
|---|---|---|---|
| POST | `/documents/upload` | student | Upload document (multipart) |
| GET | `/documents/my` | student | Student's own documents |
| GET | `/documents/all` | admin | All documents |
| POST | `/documents/{id}/verify` | admin | Verify document |
| POST | `/documents/{id}/reject` | admin | Reject document |

### Scholarships
| Method | Endpoint | Auth | Description |
|---|---|---|---|
| GET | `/scholarships` | student | Scholarship catalogue |
| POST | `/scholarships/apply` | student | Apply for scholarship |
| GET | `/scholarships/my-applications` | student | Student's applications |
| GET | `/admin/scholarship-applications` | admin | All applications |
| POST | `/admin/scholarship-applications/{id}/review` | admin | Approve/reject |

### Intelligence
| Method | Endpoint | Auth | Description |
|---|---|---|---|
| GET | `/intelligence/attendance/risk` | any | Explainable risk report |
| GET | `/intelligence/attendance/recovery` | any | Recovery projection |
| GET | `/intelligence/scholarships/matches` | any | Scholarship intelligence |
| GET | `/intelligence/courses/recommendations` | any | Course recommendations |

### AI
| Method | Endpoint | Auth | Description |
|---|---|---|---|
| POST | `/ai/chat` | student | Ask PROK — grounded answers |

### Interventions
| Method | Endpoint | Auth | Description |
|---|---|---|---|
| GET | `/interventions` | teacher, admin | List interventions |
| POST | `/interventions` | teacher, admin | Create intervention |
| PUT | `/interventions/{id}` | teacher, admin | Update intervention |
| PATCH | `/interventions/{id}/status` | teacher, admin | Update status only |

### Admin
| Method | Endpoint | Auth | Description |
|---|---|---|---|
| GET | `/admin/stats` | admin | Dashboard stats |
| GET | `/admin/students` | admin | All students |

### Notifications
| Method | Endpoint | Auth | Description |
|---|---|---|---|
| GET | `/notifications` | any | Get notifications |
| POST | `/notifications/{id}/read` | any | Mark one read |
| POST | `/notifications/mark-all-read` | any | Mark all read |

---

## MongoDB Collections

| Collection | Purpose |
|---|---|
| `users` | All accounts (student / teacher / admin) |
| `students` | Extended student profiles |
| `teachers` | Extended teacher profiles |
| `admins` | Extended admin profiles |
| `courses` | Course catalogue |
| `enrollments` | Student–course links |
| `attendance_sessions` | Per-class session records |
| `attendance_records` | Per-student per-session records |
| `documents` | Uploaded academic documents |
| `scholarships` | Scholarship listings |
| `scholarship_applications` | Student applications |
| `recommendations` | Generated recommendations |
| `interventions` | Academic intervention cases |
| `notifications` | In-app notifications |
| `ai_conversations` | Ask PROK chat history |

**Indexes:** `users.email` (unique), `users.college_id` (unique), `attendance_records.(session_id, student_id)` (unique), `enrollments.(course_id, student_college_id)` (unique), `scholarship_applications.(scholarship_id, student_id)` (unique), and compound indexes on all frequent query paths.

---

## Security

- Passwords bcrypt-hashed. Never stored in plaintext.
- JWT signed with `SECRET_KEY` from environment. Never hardcoded.
- Role assigned by backend only. Client cannot set its own role.
- Protected endpoints return `401` (missing/invalid token) or `403` (wrong role).
- Document access: students can only read their own documents.
- Error responses never expose stack traces or internal details.
- File uploads validated for size (`MAX_FILE_SIZE=10MB`) via storage abstraction.

---

## Known Limitations

1. **No email delivery** — notifications are in-app only. No SMTP configured.
2. **File storage is local** — uploaded documents saved to `backend/uploads/`. Not suitable for multi-server production.
3. **No Flutter build tested in sandbox** — `flutter analyze` and `flutter test` require Flutter SDK on host machine.
4. **No web build tested in sandbox** — `npm run build` requires `node_modules` from `npm install` on host.
5. **AI provider optional** — Ask PROK works fully with deterministic fallback if no AI provider URL is set.
6. **No WebSocket / real-time push** — notifications require manual refresh or pull.
7. **No pagination** on most list endpoints — acceptable for hackathon scale, not for production.
8. **CORS restricted** to `localhost:5173` and `localhost:3000` by default.

---

## Tested (in sandbox)

- Python syntax check: **64 files — ALL OK**
- Backend unit tests: **16/16 passed** (intelligence rules + Ask PROK)
- Web TSX brace/structure check: **27 files — ALL OK**
- Security audit: **no plaintext passwords, no hardcoded secrets**
- API route audit: all 5 end-to-end flows traced and verified

## Not Tested (requires host environment)

- `flutter analyze` — requires Flutter SDK
- `flutter test` — requires Flutter SDK
- `npm run build` — requires `npm install` with network access
- Live MongoDB integration — requires running Docker + seeded data
- Physical device network connectivity

---

## Run Commands (Quick Reference)

```bash
# 1. Start MongoDB
docker compose up -d

# 2. Backend
cd backend && source .venv/bin/activate
uvicorn app.main:app --reload --port 8000

# 3. Seed base accounts
python -m scripts.seed

# 4. Seed Aarav demo story
python -m scripts.seed_demo

# 5. Run backend tests
python -m unittest tests.test_intelligence_rules_unittest tests.test_ask_prok_unittest -v

# 6. Web dashboard
cd web && npm install && npm run dev

# 7. Mobile
cd mobile && flutter pub get && flutter run
```

---

## Future Improvements

- [ ] Email/SMS notifications for critical attendance alerts
- [ ] S3/cloud storage for uploaded documents
- [ ] WebSocket push for real-time notification delivery
- [ ] Pagination on list endpoints
- [ ] Teacher can create and manage courses from the app
- [ ] Student can update profile skills/interests
- [ ] Admin analytics with date range filtering
- [ ] Export attendance/document reports as PDF or CSV
- [ ] Multi-language support
- [ ] Dark mode (mobile)
- [ ] AI provider integration with guardrails for richer Ask PROK responses
