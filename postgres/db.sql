CREATE SCHEMA IF NOT EXISTS lbaw2545;
SET search_path TO lbaw2545;

-- ENUM TYPE
CREATE TYPE campaign_state AS ENUM (
    'unfunded',
    'ongoing',
    'completed',
    'paused',
    'suspended'
);

CREATE TYPE notification_type AS ENUM (
    'update',
    'transaction',
    'comment'
);

-- USER ACCOUNT
CREATE TABLE IF NOT EXISTS user_account (
    id              SERIAL PRIMARY KEY,
    email           TEXT NOT NULL UNIQUE,
    name            TEXT NOT NULL,
    password        TEXT NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    profile_picture TEXT
);

-- CATEGORY
CREATE TABLE IF NOT EXISTS category (
    id              SERIAL PRIMARY KEY,
    name            TEXT NOT NULL UNIQUE
);

-- CAMPAIGN
CREATE TABLE IF NOT EXISTS campaign (
    id              SERIAL PRIMARY KEY,
    name            TEXT NOT NULL,
    description     TEXT NOT NULL,
    funded          NUMERIC NOT NULL,
    goal            NUMERIC NOT NULL,
    start_date      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    end_date        TIMESTAMPTZ,
    close_date      TIMESTAMPTZ,
    state           campaign_state NOT NULL,
    creator_id      INTEGER REFERENCES user_account(id) ON DELETE SET NULL,
    category_id     INTEGER NOT NULL REFERENCES category(id),
    CHECK (funded <= goal),
    CHECK (end_date IS NULL OR end_date >= start_date),
    CHECK (close_date IS NULL OR close_date >= start_date),
    CHECK (end_date IS NULL OR close_date IS NULL OR end_date <= close_date)
);

-- ADMIN
CREATE TABLE IF NOT EXISTS admin (
    id              SERIAL PRIMARY KEY,
    email           TEXT NOT NULL UNIQUE,
    password        TEXT NOT NULL
);

-- BLOCKED USER
CREATE TABLE IF NOT EXISTS blocked_user (
    id        INTEGER NOT NULL PRIMARY KEY REFERENCES user_account(id) ON DELETE CASCADE,
    datetime  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    reason    TEXT NOT NULL
);

-- APPEAL
CREATE TABLE IF NOT EXISTS appeal (
    id        SERIAL PRIMARY KEY,
    author_id INTEGER NOT NULL REFERENCES blocked_user(id) ON DELETE CASCADE,
    whining   TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- NOTIFICATION
CREATE TABLE IF NOT EXISTS notification (
    id              SERIAL PRIMARY KEY,
    type            notification_type NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    content         TEXT NOT NULL,
    link            TEXT NOT NULL
);

-- NOTIFICATION_RECEIVED
-- trigger to snoozed !
CREATE TABLE IF NOT EXISTS notification_received (
    id              SERIAL PRIMARY KEY,
    is_read         BOOLEAN NOT NULL DEFAULT FALSE,
    snoozed_until   TIMESTAMPTZ,
    notification_id INTEGER NOT NULL REFERENCES notification(id) ON DELETE CASCADE,
    user_id         INTEGER NOT NULL REFERENCES user_account(id) ON DELETE CASCADE,
);

-- COMMENT
CREATE TABLE IF NOT EXISTS comment (
    id              SERIAL PRIMARY KEY,
    content         TEXT NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    author_id       INTEGER REFERENCES user_account(id) ON DELETE SET NULL,
    campaign_id     INTEGER NOT NULL REFERENCES campaign(id),
    parent_id       INTEGER REFERENCES comment(id),
    notification_id INTEGER REFERENCES notification(id) 
);

-- TRANSACTION
CREATE TABLE IF NOT EXISTS transaction (
    id              SERIAL PRIMARY KEY,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    amount          NUMERIC NOT NULL,
    author_id       INTEGER REFERENCES user_account(id) ON DELETE SET NULL,
    campaign_id     INTEGER NOT NULL REFERENCES campaign(id),
    notification_id INTEGER REFERENCES notification(id),
    CHECK (amount > 0)
);

-- CAMPAIGN UPDATE
CREATE TABLE IF NOT EXISTS campaign_update (
    id              SERIAL PRIMARY KEY,
    content         TEXT NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    campaign_id     INTEGER NOT NULL REFERENCES campaign(id),
    notification_id INTEGER REFERENCES notification(id)
);

-- RESOURCE
CREATE TABLE IF NOT EXISTS resource (
    id              SERIAL PRIMARY KEY,
    name            TEXT NOT NULL,
    path            TEXT NOT NULL,
    ordering        INTEGER NOT NULL,
    campaign_id     INTEGER REFERENCES campaign(id),
    update_id       INTEGER REFERENCES campaign_update(id),
    CHECK (
        (campaign_id IS NOT NULL AND update_id IS NULL)
        OR (update_id IS NOT NULL AND campaign_id IS NULL)
    )
);


CREATE TABLE IF NOT EXISTS campaign_collaborator (
    campaign_id INTEGER NOT NULL REFERENCES campaign(id) ON DELETE SET CASCADE,
    user_id INTEGER NOT NULL REFERENCES user_account(id) ON SET NULL,
    PRIMARY KEY (campaign_id, user_id)
);


CREATE TABLE IF NOT EXISTS campaign_follower (
    user_id INTEGER NOT NULL REFERENCES user_account(id) ON DELETE CASCADE,
    campaign_id INTEGER NOT NULL REFERENCES campaign(id) ON DELETE CASCADE,
    PRIMARY KEY (user_id, campaign_id)
);