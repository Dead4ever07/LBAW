DROP SCHEMA IF EXISTS lbaw2545 CASCADE;
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

-- BLOCKED USER
CREATE TABLE IF NOT EXISTS blocked_user (
    id        INTEGER NOT NULL PRIMARY KEY REFERENCES user_account(id) ON DELETE CASCADE,
    datetime  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    reason    TEXT NOT NULL
);

-- APPEAL
CREATE TABLE IF NOT EXISTS appeal (
    id         SERIAL PRIMARY KEY,
    author_id  INTEGER NOT NULL REFERENCES blocked_user(id) ON DELETE CASCADE,
    whining    TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ADMIN
CREATE TABLE IF NOT EXISTS admin (
    id              SERIAL PRIMARY KEY,
    email           TEXT NOT NULL UNIQUE,
    password        TEXT NOT NULL
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
    funded          NUMERIC NOT NULL DEFAULT 0,
    goal            NUMERIC NOT NULL,
    start_date      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    end_date        TIMESTAMPTZ,
    close_date      TIMESTAMPTZ,
    state           campaign_state NOT NULL,
    category_id     INTEGER NOT NULL REFERENCES category(id),
    CHECK (goal > 0),
    CHECK (funded >= 0),
    CHECK (funded <= goal),
    CHECK (end_date IS NULL OR end_date >= start_date),
    CHECK (close_date IS NULL OR close_date >= start_date),
    CHECK (end_date IS NULL OR close_date IS NULL OR end_date <= close_date)
);


CREATE TABLE IF NOT EXISTS campaign_collaborator (
    campaign_id INTEGER NOT NULL REFERENCES campaign(id) ON DELETE CASCADE,
    user_id     INTEGER NOT NULL REFERENCES user_account(id) ON DELETE CASCADE,
    PRIMARY KEY (campaign_id, user_id)
);

CREATE TABLE IF NOT EXISTS campaign_follower (
    user_id     INTEGER NOT NULL REFERENCES user_account(id) ON DELETE CASCADE,
    campaign_id INTEGER NOT NULL REFERENCES campaign(id) ON DELETE CASCADE,
    PRIMARY KEY (user_id, campaign_id)
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
CREATE TABLE IF NOT EXISTS notification_received (
    id              SERIAL PRIMARY KEY,
    is_read         BOOLEAN NOT NULL DEFAULT FALSE,
    snoozed_until   TIMESTAMPTZ,
    notification_id INTEGER NOT NULL REFERENCES notification(id) ON DELETE CASCADE,
    user_id         INTEGER NOT NULL REFERENCES user_account(id) ON DELETE CASCADE,
    UNIQUE (notification_id, user_id)
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
    is_valid        BOOLEAN NOT NULL DEFAULT TRUE,
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
    campaign_id     INTEGER NOT NULL REFERENCES campaign(id) ON DELETE CASCADE,
    notification_id INTEGER UNIQUE REFERENCES notification(id)
);

-- RESOURCE
CREATE TABLE IF NOT EXISTS resource (
    id              SERIAL PRIMARY KEY,
    name            TEXT NOT NULL,
    path            TEXT NOT NULL,
    ordering        INTEGER NOT NULL,
    campaign_id     INTEGER REFERENCES campaign(id) ON DELETE CASCADE,
    update_id       INTEGER REFERENCES campaign_update(id) ON DELETE CASCADE,
    CHECK (
        (campaign_id IS NOT NULL AND update_id IS NULL) OR 
        (update_id IS NOT NULL AND campaign_id IS NULL)
    )
);

--TRIGGERS

-- TRIGGER01
-- New transaction: increase campaign funded
-- dont alow it to go over campaign goal
CREATE OR REPLACE FUNCTION transaction_add_to_funded() RETURNS TRIGGER AS
$BODY$
DECLARE
  v_goal   NUMERIC;
  v_funded NUMERIC;
BEGIN
    SELECT goal, funded
        INTO v_goal, v_funded
        FROM lbaw2545.campaign
    WHERE id = NEW.campaign_id
    FOR UPDATE;

    IF v_funded + NEW.amount > v_goal THEN
        RAISE EXCEPTION 'This contribution would exceed the campaign goal.';
    END IF;

    UPDATE lbaw2545.campaign
        SET funded = funded + NEW.amount
    WHERE id = NEW.campaign_id;

    RETURN NEW;
END
$BODY$
LANGUAGE plpgsql;

CREATE TRIGGER transaction_add_to_funded
    AFTER INSERT ON lbaw2545.transaction
    FOR EACH ROW
    EXECUTE PROCEDURE transaction_add_to_funded();


-- TRIGGER02
-- campaign.funded updated:
--   funded = 0: state = 'unfunded'
--   funded = goal: state = 'completed'
--   funded ≠ 0 && funded ≠ goal: state = 'ongoing'
CREATE OR REPLACE FUNCTION campaign_state_from_funded() RETURNS TRIGGER AS
$BODY$
BEGIN
    IF TG_OP = 'UPDATE' AND NEW.funded IS NOT DISTINCT FROM OLD.funded THEN RETURN NEW; END IF;
    IF OLD.state IN ('paused','suspended') OR NEW.state IN ('paused','suspended') THEN RETURN NEW; END IF;

    IF NEW.funded = 0 THEN NEW.state := 'unfunded';
    ELSIF NEW.funded = NEW.goal THEN NEW.state := 'completed';
    ELSE NEW.state := 'ongoing';
    END IF;

    RETURN NEW;
END
$BODY$
LANGUAGE plpgsql;

CREATE TRIGGER campaign_state_from_funded
    BEFORE UPDATE OF funded ON lbaw2545.campaign
    FOR EACH ROW
    EXECUTE PROCEDURE campaign_state_from_funded();


-- TRIGGER03
-- If the author of a transaction becomes NULL
-- and the campaign is not 'completed', the transaction becomes invalid.
CREATE OR REPLACE FUNCTION transaction_author_null_invalidate() RETURNS TRIGGER AS
$BODY$
DECLARE
    v_state campaign_state;
BEGIN
    IF NEW.author_id IS DISTINCT FROM OLD.author_id AND NEW.author_id IS NULL THEN
        SELECT state INTO v_state FROM lbaw2545.campaign WHERE id = NEW.campaign_id;
        IF v_state <> 'completed' THEN NEW.is_valid := FALSE; END IF;
    END IF;
    RETURN NEW;
END
$BODY$
LANGUAGE plpgsql;

CREATE TRIGGER transaction_author_null_invalidate
    BEFORE UPDATE OF author_id ON lbaw2545.transaction
    FOR EACH ROW
    EXECUTE PROCEDURE transaction_author_null_invalidate();


-- TRIGGER04
-- is_valid updated: change campaign funded(+amount or -amount)
CREATE OR REPLACE FUNCTION transaction_validity_delta() RETURNS TRIGGER AS
$BODY$
DECLARE
  v_goal   NUMERIC;
  v_funded NUMERIC;
BEGIN
    IF NEW.is_valid IS DISTINCT FROM OLD.is_valid THEN
        -- add
        IF NEW.is_valid = TRUE THEN
            SELECT goal, funded INTO v_goal, v_funded
            FROM lbaw2545.campaign
            WHERE id = NEW.campaign_id
            FOR UPDATE;
            
            IF v_funded + NEW.amount > v_goal THEN RAISE EXCEPTION 'Re-validating this contribution would exceed the campaign goal.'; END IF;

        UPDATE lbaw2545.campaign SET funded = funded + NEW.amount WHERE id = NEW.campaign_id;
        END IF;

        -- sub
        IF NEW.is_valid = FALSE THEN
        UPDATE lbaw2545.campaign SET funded = funded - OLD.amount WHERE id = OLD.campaign_id;
        END IF;

    END IF;
    RETURN NEW;
END
$BODY$
LANGUAGE plpgsql;

CREATE TRIGGER transaction_validity_delta
    AFTER UPDATE ON lbaw2545.transaction
    FOR EACH ROW
    EXECUTE PROCEDURE transaction_validity_delta();


-- TRIGGER05
-- If a campaign has no collaborators, set state = 'suspended'
CREATE OR REPLACE FUNCTION campaign_suspend_if_no_owner() RETURNS TRIGGER AS
$BODY$
DECLARE
    v_has_collab  BOOLEAN;
    v_campaign_id INTEGER := COALESCE(NEW.campaign_id, OLD.campaign_id);
BEGIN
    SELECT EXISTS ( 
        SELECT 1
        FROM lbaw2545.campaign_collaborator
        WHERE campaign_id = v_campaign_id )
    INTO v_has_collab;

    IF v_has_collab = FALSE THEN
        UPDATE lbaw2545.campaign SET state = 'suspended' WHERE id = v_campaign_id;
    END IF;

    RETURN COALESCE(NEW, OLD);
END
$BODY$
LANGUAGE plpgsql;

CREATE TRIGGER campaign_suspend_if_no_collab
    AFTER DELETE ON lbaw2545.campaign_collaborator
    FOR EACH ROW
    EXECUTE PROCEDURE campaign_suspend_if_no_owner();


-- TRIGGER06
-- INSERT on campaign_update: create notification(type='update')
-- deliver to: all followers of that campaign
CREATE OR REPLACE FUNCTION campaign_update_auto_notification() RETURNS TRIGGER AS
$BODY$
DECLARE
    v_notif_id INTEGER;
    v_name     TEXT;
BEGIN
    -- campaign name 
    SELECT name INTO v_name
    FROM lbaw2545.campaign
    WHERE id = NEW.campaign_id;
    
    -- create the notification
    INSERT INTO lbaw2545.notification(type, content, link)
    VALUES ('update',
        CONCAT('New update on campaign ', v_name),
        CONCAT('/campaigns/', NEW.campaign_id, '#update-', NEW.id) -- might be changed in the future
    )
    RETURNING id INTO v_notif_id;

    -- attach to the update
    UPDATE lbaw2545.campaign_update
        SET notification_id = v_notif_id
    WHERE id = NEW.id;

    -- send the notifications
    INSERT INTO lbaw2545.notification_received(notification_id, user_id)
    SELECT v_notif_id, f.user_id
        FROM lbaw2545.campaign_follower f
    WHERE f.campaign_id = NEW.campaign_id AND f.user_id IS NOT NULL
    ON CONFLICT (notification_id, user_id) DO NOTHING;

    RETURN NEW;
END
$BODY$
LANGUAGE plpgsql;

CREATE TRIGGER campaign_update_auto_notification
    AFTER INSERT ON lbaw2545.campaign_update
    FOR EACH ROW
    EXECUTE PROCEDURE campaign_update_auto_notification();


-- TRIGGER07
-- INSERT on comment: create notification(type='comment')
-- deliver to: campaign collaborators and parent comment author
CREATE OR REPLACE FUNCTION comment_auto_notification() RETURNS TRIGGER AS
$BODY$
DECLARE
    v_notif_id INTEGER;
    v_name     TEXT;
BEGIN
    -- campaign name 
    SELECT name INTO v_name
    FROM lbaw2545.campaign
    WHERE id = NEW.campaign_id;

    -- create the notification
    INSERT INTO lbaw2545.notification(type, content, link)
    VALUES ( 'comment',
        CONCAT('New comment on campaign ', v_name),
        CONCAT('/campaigns/', NEW.campaign_id, '#comment-', NEW.id) -- might be changed in the future
    )
    RETURNING id INTO v_notif_id;

    -- attach to the comment
    UPDATE lbaw2545.comment
        SET notification_id = v_notif_id
    WHERE id = NEW.id;

   
    WITH recipients AS (
        SELECT cc.user_id
            FROM lbaw2545.campaign_collaborator cc
            WHERE cc.campaign_id = NEW.campaign_id
        UNION
        SELECT p.author_id
            FROM lbaw2545.comment p
            WHERE NEW.parent_id IS NOT NULL AND p.id = NEW.parent_id
    )

     -- send the notifications
    INSERT INTO lbaw2545.notification_received (notification_id, user_id)
    SELECT v_notif_id, r.user_id
        FROM recipients r
    WHERE r.user_id IS NOT NULL
    ON CONFLICT (notification_id, user_id) DO NOTHING;


    RETURN NEW;
END
$BODY$
LANGUAGE plpgsql;

CREATE TRIGGER comment_auto_notification
    AFTER INSERT ON lbaw2545.comment
    FOR EACH ROW
    EXECUTE PROCEDURE comment_auto_notification();


-- TRIGGER08
-- INSERT on transaction: create notification(type='transaction')
-- deliver to: campaign collaborators
CREATE OR REPLACE FUNCTION transaction_auto_notification() RETURNS TRIGGER AS
$BODY$
DECLARE
  v_notif_id INTEGER;
  v_name     TEXT;
BEGIN
    -- campaign name
    SELECT name INTO v_name
        FROM lbaw2545.campaign
    WHERE id = NEW.campaign_id;

    -- create the notification
    INSERT INTO lbaw2545.notification(type, content, link)
    VALUES ('transaction',
        CONCAT('New contribution to campaign ', v_name),
        CONCAT('/campaigns/', NEW.campaign_id, '#transaction-', NEW.id) -- might be changed in the future
    )
    RETURNING id INTO v_notif_id;

    -- attach to the transaction
    UPDATE lbaw2545.transaction
        SET notification_id = v_notif_id
    WHERE id = NEW.id;


    WITH recipients AS (
        SELECT cc.user_id
            FROM lbaw2545.campaign_collaborator cc
        WHERE cc.campaign_id = NEW.campaign_id
    )

    -- send the notifications
    INSERT INTO lbaw2545.notification_received (notification_id, user_id)
    SELECT v_notif_id, r.user_id
        FROM recipients r
    WHERE r.user_id IS NOT NULL
    ON CONFLICT (notification_id, user_id) DO NOTHING;

    RETURN NEW;
END
$BODY$
LANGUAGE plpgsql;

CREATE TRIGGER transaction_auto_notification
    AFTER INSERT ON lbaw2545.transaction
    FOR EACH ROW
    EXECUTE PROCEDURE transaction_auto_notification();



-- TRIGGER09:
-- A user listed as a collaborator of a campaign cannot donate to that campaign.
CREATE OR REPLACE FUNCTION forbid_self_donation() RETURNS TRIGGER AS
$body$
DECLARE
    v_is_collab BOOLEAN;
BEGIN
    -- If no author skip.
    IF NEW.author_id IS NULL THEN RETURN NEW; END IF;

    SELECT EXISTS (
        SELECT 1
        FROM lbaw2545.campaign_collaborator cc
        WHERE cc.campaign_id = NEW.campaign_id AND cc.user_id = NEW.author_id
    ) INTO v_is_collab;

    IF v_is_collab THEN RAISE EXCEPTION 'You cannot donate to your own campaign.'; END IF;

    RETURN NEW;
END
$body$
LANGUAGE plpgsql;

CREATE TRIGGER forbid_self_donation
    BEFORE INSERT ON lbaw2545.transaction
    FOR EACH ROW
    EXECUTE PROCEDURE forbid_self_donation();


-- Indexes
CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE INDEX idx_campaign_state_start
    ON lbaw2545.campaign (state, start_date DESC);

CREATE INDEX idx_comment_parent_created
ON lbaw2545.comment (parent_id, created_at);

CREATE INDEX idx_user_notification_active
  ON lbaw2545.notification_received (user_id, snoozed_until)
  WHERE is_read = FALSE;

-- FTS-Table
ALTER TABLE lbaw2545.campaign
ADD COLUMN IF NOT EXISTS search_vector tsvector;

-- FTS-Index
CREATE INDEX idx_campaign_search_vector
ON lbaw2545.campaign USING GIN (search_vector);

ALTER TABLE lbaw2545.campaign
ADD COLUMN IF NOT EXISTS search_text TEXT;

-- Fuzzy seach index
CREATE INDEX idx_campaign_search_text_trgm
ON lbaw2545.campaign USING GIN (search_text gin_trgm_ops);


CREATE OR REPLACE FUNCTION update_campaign_search_vector()
RETURNS TRIGGER AS $$
DECLARE
  cid INT;
BEGIN
  IF TG_TABLE_NAME = 'campaign' THEN
    cid := NEW.id;

  ELSIF TG_TABLE_NAME = 'campaign_update' THEN
    cid := COALESCE(NEW.campaign_id, OLD.campaign_id);

  ELSIF TG_TABLE_NAME = 'comment' THEN
    cid := COALESCE(NEW.campaign_id, OLD.campaign_id);

  ELSE
    RETURN NEW;  
  END IF;


  UPDATE lbaw2545.campaign 
    SET 
    search_vector =
        setweight(to_tsvector('english', coalesce(name, '')), 'A') ||
        setweight(to_tsvector('english', coalesce(description, '')), 'B') ||
        setweight((
            SELECT to_tsvector('english', coalesce(string_agg(content, ' '), ''))
            FROM lbaw2545.campaign_update
            WHERE campaign_update.campaign_id = cid
        ), 'C') ||
        setweight((
            SELECT to_tsvector('english', coalesce(string_agg(content, ' '), ''))
            FROM lbaw2545.comment
            WHERE comment.campaign_id = cid
        ), 'D')
  WHERE id = cid;
  UPDATE lbaw2545.campaign 
    SET 
    search_text = concat_ws(' ', name, description)
  WHERE id = cid;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;


DROP TRIGGER IF EXISTS trg_campaign_search_update ON lbaw2545.campaign;

CREATE TRIGGER trg_campaign_search_update
AFTER INSERT OR UPDATE OF name, description ON lbaw2545.campaign
FOR EACH ROW
EXECUTE FUNCTION update_campaign_search_vector();


DROP TRIGGER IF EXISTS trg_update_search_update ON lbaw2545.campaign_update;

CREATE TRIGGER trg_update_search_update
AFTER INSERT OR DELETE OR UPDATE OF content ON lbaw2545.campaign_update
FOR EACH ROW
EXECUTE FUNCTION update_campaign_search_vector();


DROP TRIGGER IF EXISTS trg_comment_search_update ON lbaw2545.comment;

CREATE TRIGGER trg_comment_search_update
AFTER INSERT OR DELETE OR UPDATE OF content ON lbaw2545.comment
FOR EACH ROW
EXECUTE FUNCTION update_campaign_search_vector();
