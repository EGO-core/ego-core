-- =============================================================================
-- egocore.ai — Database Schema
-- Architecture: 3 SQLite databases (WAL mode)
-- =============================================================================
-- 1. users.db    — user profiles, skills, memory, availability
-- 2. chat_log.db — conversation history, bot state
-- 3. orders.db   — service requests, executor matches, ratings
-- =============================================================================


-- =============================================================================
-- DATABASE 1: users.db
-- User identity (Telegram + MAX), skills, memory facts, availability
-- =============================================================================

PRAGMA journal_mode=WAL;
PRAGMA foreign_keys=ON;

-- Core user profile (unified across messengers via phone number)
CREATE TABLE IF NOT EXISTS users (
  id           TEXT PRIMARY KEY,
  tg_user_id   INTEGER UNIQUE,           -- Telegram user ID
  max_user_id  TEXT UNIQUE,              -- MAX Messenger user ID
  max_chat_id  TEXT,                     -- MAX chat ID for notifications
  tg_username  TEXT,
  display_name TEXT,
  phone        TEXT,
  city         TEXT,
  district     TEXT,
  role         TEXT DEFAULT 'client',    -- client | executor | both
  created_at   INTEGER NOT NULL,
  updated_at   INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_users_tg    ON users(tg_user_id);
CREATE INDEX IF NOT EXISTS idx_users_max   ON users(max_user_id);
CREATE INDEX IF NOT EXISTS idx_users_phone ON users(phone);

-- Long-term memory: facts learned about the user via conversation
CREATE TABLE IF NOT EXISTS memory_facts (
  id         TEXT PRIMARY KEY,
  user_id    TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  key        TEXT NOT NULL,
  value      TEXT NOT NULL,
  confidence REAL DEFAULT 0.8,
  source     TEXT,
  created_at INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_mf_user ON memory_facts(user_id);

-- Executor skills (self-claimed, verified via ratings)
CREATE TABLE IF NOT EXISTS skills (
  id             TEXT PRIMARY KEY,
  user_id        TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  skill_code     TEXT NOT NULL,          -- e.g. plumbing.basic, electrical.advanced
  level          TEXT,                   -- beginner | intermediate | pro
  self_claimed   INTEGER DEFAULT 1,
  verified_count INTEGER DEFAULT 0,
  created_at     INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_skills_user ON skills(user_id);
CREATE INDEX IF NOT EXISTS idx_skills_code ON skills(skill_code);

-- Executor availability schedule
CREATE TABLE IF NOT EXISTS availability (
  id         TEXT PRIMARY KEY,
  user_id    TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  pattern    TEXT NOT NULL,              -- e.g. "weekdays 9-18", "weekends"
  notes      TEXT,
  created_at INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_avail_user ON availability(user_id);


-- =============================================================================
-- DATABASE 2: chat_log.db
-- Conversation history and FSM state per user
-- =============================================================================

PRAGMA journal_mode=WAL;

-- Full conversation log (all messages with the AI)
CREATE TABLE IF NOT EXISTS conversation_log (
  id         TEXT PRIMARY KEY,
  user_id    TEXT NOT NULL,
  role       TEXT NOT NULL,              -- user | assistant | system | tool
  content    TEXT,
  modality   TEXT,                       -- text | voice | photo
  tool_calls TEXT,                       -- JSON array of tool calls made
  created_at INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_conv_user    ON conversation_log(user_id);
CREATE INDEX IF NOT EXISTS idx_conv_created ON conversation_log(created_at);

-- Bot FSM state (onboarding steps, awaiting responses, etc.)
CREATE TABLE IF NOT EXISTS user_state (
  user_id    TEXT PRIMARY KEY,
  state      TEXT NOT NULL,              -- e.g. onboarding_phone, onboarding_city
  state_data TEXT,                       -- JSON (context for current state)
  updated_at INTEGER NOT NULL
);


-- =============================================================================
-- DATABASE 3: orders.db
-- Service requests, executor matching, ratings
-- =============================================================================

PRAGMA journal_mode=WAL;
PRAGMA foreign_keys=OFF;  -- cross-db refs not supported in SQLite

-- Service requests created by clients
CREATE TABLE IF NOT EXISTS requests (
  id                TEXT PRIMARY KEY,
  requester_id      TEXT NOT NULL,       -- references users.id
  category          TEXT,                -- e.g. plumbing.basic, electrical.advanced
  title             TEXT,
  description       TEXT,
  location_district TEXT,
  time_window       TEXT,
  budget_work       INTEGER,             -- work cost in RUB
  budget_materials  INTEGER,             -- materials cost in RUB
  choice_mode       TEXT,                -- self | executor | assistant
  materials_list    TEXT,                -- JSON array
  photos            TEXT,                -- JSON array of Telegram file_ids
  risk_flags        TEXT,
  client_name       TEXT,
  client_phone      TEXT,
  address           TEXT,
  state             TEXT NOT NULL DEFAULT 'draft',  -- draft | open | matched | in_progress | done | cancelled
  created_at        INTEGER NOT NULL,
  updated_at        INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_req_requester ON requests(requester_id);
CREATE INDEX IF NOT EXISTS idx_req_state     ON requests(state);
CREATE INDEX IF NOT EXISTS idx_req_category  ON requests(category);

-- Executor matches (proposed by dispatcher, accepted/declined by executor)
CREATE TABLE IF NOT EXISTS matches (
  id                TEXT PRIMARY KEY,
  request_id        TEXT NOT NULL REFERENCES requests(id) ON DELETE CASCADE,
  executor_id       TEXT NOT NULL,       -- references users.id
  proposed_at       INTEGER NOT NULL,
  notified_at       INTEGER,             -- NULL = notification not yet delivered
  executor_response TEXT DEFAULT 'pending',  -- pending | accept | decline
  decline_reason    TEXT,
  confirmed_at      INTEGER,
  state             TEXT DEFAULT 'proposed',  -- proposed | accepted | declined | requester_notified
  created_at        INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_match_request  ON matches(request_id);
CREATE INDEX IF NOT EXISTS idx_match_executor ON matches(executor_id);
CREATE INDEX IF NOT EXISTS idx_match_response ON matches(executor_response);

-- Ratings left after job completion
CREATE TABLE IF NOT EXISTS ratings (
  id             TEXT PRIMARY KEY,
  target_user_id TEXT NOT NULL,          -- who is being rated
  role           TEXT NOT NULL,          -- client | executor
  request_id     TEXT REFERENCES requests(id) ON DELETE SET NULL,
  score          INTEGER NOT NULL,       -- 1-5
  comment        TEXT,
  created_at     INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_ratings_target ON ratings(target_user_id);
