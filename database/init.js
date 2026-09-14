// MongoDB initialization script
// Runs automatically via docker-entrypoint-initdb.d when the container first starts

db = db.getSiblingDB('prok_db');

// ── Collections with schema validation ────────────────────────────────────────

db.createCollection('users', {
  validator: {
    $jsonSchema: {
      bsonType: 'object',
      required: ['name', 'email', 'hashed_password', 'role'],
      properties: {
        name:            { bsonType: 'string' },
        email:           { bsonType: 'string' },
        hashed_password: { bsonType: 'string' },
        role:            { bsonType: 'string', enum: ['student', 'teacher', 'admin'] },
        is_active:       { bsonType: 'bool' },
        college_id:      { bsonType: ['string', 'null'] },
      },
    },
  },
});

// Collections for Stage 2 — pre-created so indexes are ready
db.createCollection('attendance');
db.createCollection('documents');
db.createCollection('scholarships');
db.createCollection('courses');
db.createCollection('chat_sessions');

// ── Indexes ────────────────────────────────────────────────────────────────────
db.users.createIndex({ email: 1 }, { unique: true });
db.attendance.createIndex({ student_id: 1, date: 1 });
db.documents.createIndex({ owner_id: 1 });
db.scholarships.createIndex({ tags: 1 });

// ── Seed admin account ─────────────────────────────────────────────────────────
// Password hash for 'admin1234' (bcrypt, cost 12)
// Replace with a proper hash in production!
db.users.insertOne({
  name: 'PROK Admin',
  email: 'admin@prok.edu',
  // bcrypt hash of 'admin1234' -- generated offline, never stored in plain text
  hashed_password: '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj/RK.s5uOEW',
  role: 'admin',
  is_active: true,
  college_id: 'ADMIN001',
});

print('PROK database initialised.');
