--
-- Schema selection
--
-- The teachers logic was recicled here, if the schema is being run by pgAdmin or by Laravel will target
-- "different" databases
--

--
-- Schema (re)creation
-- The DO block is needed because identifiers (schema names) cannot be parameterized.
--


DO $do$
DECLARE
  s text := COALESCE(current_setting('app.schema', true), 'lbaw2545');
BEGIN
  -- identifiers require dynamic SQL
  EXECUTE format('DROP SCHEMA IF EXISTS %I CASCADE', s);
  EXECUTE format('CREATE SCHEMA IF NOT EXISTS %I', s);

  -- set search_path for the rest of the script
  PERFORM set_config('search_path', format('%I, public', s), false);
END
$do$ LANGUAGE plpgsql;

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
    id              INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
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
    id         INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    author_id  INTEGER NOT NULL REFERENCES blocked_user(id) ON DELETE CASCADE,
    whining    TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ADMIN
CREATE TABLE IF NOT EXISTS admin (
    id              INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    email           TEXT NOT NULL UNIQUE,
    password        TEXT NOT NULL
);

-- CATEGORY
CREATE TABLE IF NOT EXISTS category (
    id              INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    name            TEXT NOT NULL UNIQUE
);


-- CAMPAIGN
CREATE TABLE IF NOT EXISTS campaign (
    id              INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
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
    id              INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    type            notification_type NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    content         TEXT NOT NULL,
    link            TEXT NOT NULL
);

-- NOTIFICATION_RECEIVED
CREATE TABLE IF NOT EXISTS notification_received (
    id              INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    is_read         BOOLEAN NOT NULL DEFAULT FALSE,
    snoozed_until   TIMESTAMPTZ,
    notification_id INTEGER NOT NULL REFERENCES notification(id) ON DELETE CASCADE,
    user_id         INTEGER NOT NULL REFERENCES user_account(id) ON DELETE CASCADE,
    UNIQUE (notification_id, user_id)
);

-- COMMENT
CREATE TABLE IF NOT EXISTS comment (
    id              INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    content         TEXT NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    author_id       INTEGER REFERENCES user_account(id) ON DELETE SET NULL,
    campaign_id     INTEGER NOT NULL REFERENCES campaign(id),
    parent_id       INTEGER REFERENCES comment(id),
    notification_id INTEGER REFERENCES notification(id) 
);

-- TRANSACTION
CREATE TABLE IF NOT EXISTS transaction (
    id              INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
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
    id              INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    content         TEXT NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    campaign_id     INTEGER NOT NULL REFERENCES campaign(id) ON DELETE CASCADE,
    notification_id INTEGER UNIQUE REFERENCES notification(id)
);

-- RESOURCE
CREATE TABLE IF NOT EXISTS resource (
    id              INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
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

-- TRIGGER10:
-- Block DELETE of campaigns whose state is not 'unfunded'
CREATE OR REPLACE FUNCTION prevent_campaign_delete_unless_unfunded()
RETURNS TRIGGER AS
$BODY$
BEGIN
  IF OLD.state <> 'unfunded' THEN
    RAISE EXCEPTION 'Cannot delete campaign %: state is %, only "unfunded" campaigns can be deleted.', OLD.id, OLD.state;
  END IF;
  RETURN OLD;
END
$BODY$
LANGUAGE plpgsql;

CREATE TRIGGER prevent_campaign_delete_unless_unfunded
BEFORE DELETE ON lbaw2545.campaign
FOR EACH ROW
EXECUTE FUNCTION prevent_campaign_delete_unless_unfunded();


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



-- Transaction in function format

CREATE OR REPLACE FUNCTION anonymize_user(p_user_id INT)
RETURNS VOID AS $$
BEGIN
  UPDATE comment SET author_id = NULL WHERE author_id = p_user_id;
  UPDATE "transaction" SET author_id = NULL WHERE author_id = p_user_id;
  DELETE FROM lbaw2545.campaign_collaborator WHERE user_id = p_user_id;
  DELETE FROM lbaw2545.oauth_account WHERE user_id = p_user_id;
  DELETE FROM lbaw2545.user_account WHERE id = p_user_id;
END;
$$ LANGUAGE plpgsql;






-------------------------------------------------
-- USERS 
-------------------------------------------------
INSERT INTO user_account (email, name, password, profile_picture, created_at) VALUES
  ( 'alice@example.com',   'Alice Martins',   'hash_pw_alice',   NULL, NOW() - INTERVAL '60 days'),
  ( 'bruno@example.com',   'Bruno Rocha',     'hash_pw_bruno',   NULL, NOW() - INTERVAL '50 days'),
  ( 'carla@example.com',   'Carla Lopes',     'hash_pw_carla',   NULL, NOW() - INTERVAL '45 days'),
  ( 'diogo@example.com',   'Diogo Sousa',     'hash_pw_diogo',   NULL, NOW() - INTERVAL '40 days'),
  ( 'eva@example.com',     'Eva Ferreira',    'hash_pw_eva',     NULL, NOW() - INTERVAL '35 days'),
  ( 'francisco@example.com','Francisco Pires','hash_pw_franc',   NULL, NOW() - INTERVAL '30 days'),
  ( 'gabriela@example.com','Gabriela Dias',   'hash_pw_gabi',    NULL, NOW() - INTERVAL '25 days'),
  ( 'henrique@example.com','Henrique Matos',  'hash_pw_hen',     NULL, NOW() - INTERVAL '20 days'),
  ( 'ines@example.com',    'Inês Ribeiro',    'hash_pw_ines',    NULL, NOW() - INTERVAL '15 days'),
  ('joao@example.com',    'João Figueiredo', 'hash_pw_joao',    NULL, NOW() - INTERVAL '10 days'),
  ('lara@example.com',    'Lara Antunes',    'hash_pw_lara',    NULL, NOW() - INTERVAL '8 days'),
  ('miguel@example.com',  'Miguel Tavares',  'hash_pw_miguel',  NULL, NOW() - INTERVAL '5 days');

INSERT INTO blocked_user (id, reason, datetime)
VALUES (9, 'Repeated guideline violations in comments', NOW() - INTERVAL '7 days');

INSERT INTO appeal (author_id, whining, created_at)
VALUES (9, 'I believe the block was a misunderstanding; I will follow the rules going forward.', NOW() - INTERVAL '6 days');

-------------------------------------------------
-- ADMINS
-------------------------------------------------
INSERT INTO admin ( email, password) VALUES
  ( 'admin@fundbridge.org', 'admin_pass_hash'),
  ( 'mod@fundbridge.org',   'mod_pass_hash');

-------------------------------------------------
-- CATEGORIES
-------------------------------------------------
INSERT INTO category ( name) VALUES
  ( 'Health'),
  ( 'Education'),
  ( 'Environment'),
  ( 'Technology'),
  ( 'Arts'),
  ( 'Emergency');

-------------------------------------------------
-- CAMPAIGNS 
-------------------------------------------------
INSERT INTO campaign ( name, description, funded, goal, start_date, end_date, close_date, state, category_id) VALUES
  ( 'Community Clinic Renovation',
     'Renovate and equip the local clinic to improve access to care.',
     0, 5000,
     NOW() - INTERVAL '20 days', NULL, NOW() + INTERVAL '12 days',
     'unfunded', 1),

  ( 'Scholarships for STEM',
    'Provide 10 micro-scholarships for underserved students.',
    0, 3000,
    NOW() - INTERVAL '25 days', NOW() - INTERVAL '2 days', NOW() + INTERVAL '1 day',
    'unfunded', 2),
  ( 'Tree-Planting Weekend',
    'Plant 800 native trees in the city green belt.',
    0, 800,
    NOW() - INTERVAL '5 days', NULL, NULL,
    'unfunded', 3),
  ( 'Makerspace 3D Printers',
    'Acquire two reliable 3D printers for the public makerspace.',
    0, 10000,
    NOW() - INTERVAL '30 days', NULL, NOW() + INTERVAL '20 days',
    'suspended', 4),
  ( 'Community Mural',
    'Commission a local artist to paint a mural celebrating diversity.',
    0, 1200,
    NOW() - INTERVAL '12 days', NULL, NOW() + INTERVAL '7 days',
    'paused', 5),
  ( 'Flood Relief Kits',
    'Emergency kits for 50 affected families.',
     0, 2500,
     NOW() - INTERVAL '3 days', NULL, NULL,
     'unfunded', 6);

-------------------------------------------------
-- COLLABORATORS
-------------------------------------------------
INSERT INTO campaign_collaborator (campaign_id, user_id) VALUES
  (1, 1), (1, 3),
  (2, 2),
  (3, 5), (3, 6),
  (5, 7), (5, 5),    
  (6, 8), (6, 11);

-------------------------------------------------
-- FOLLOWERS
-------------------------------------------------
INSERT INTO campaign_follower (user_id, campaign_id) VALUES
  (2, 1), (4, 1), (5, 1), (8, 1), (12, 1),
  (1, 2), (3, 2), (4, 2), (7, 2),
  (2, 3), (8, 3), (10, 3),
  (3, 5), (4, 5), (12, 5),
  (1, 6), (2, 6), (3, 6), (5, 6), (10, 6);

-------------------------------------------------
-- UPDATES 
-------------------------------------------------
INSERT INTO campaign_update ( campaign_id, content, created_at) VALUES
  ( 1, 'We secured a discount on medical equipment. Thank you all!', NOW() - INTERVAL '9 days'),
  ( 2, 'First two scholarships pre-approved pending funds.', NOW() - INTERVAL '5 days'),
  ( 5, 'Artist sketch approved by the community board!', NOW() - INTERVAL '3 days');

-------------------------------------------------
-- COMMENTS
-------------------------------------------------
INSERT INTO comment ( campaign_id, author_id, content, created_at) VALUES
  ( 1, 4, 'Great initiative—how will funds be allocated?', NOW() - INTERVAL '8 days'),
  ( 2, 1, 'Congrats! What is the selection criteria?', NOW() - INTERVAL '4 days'),
  ( 5, 12,'Can volunteers help with painting day?', NOW() - INTERVAL '2 days');

INSERT INTO comment ( campaign_id, author_id, parent_id, content, created_at) VALUES
  (1, 1, 1, 'Hi Diogo! 70% equipment, 30% renovation work.', NOW() - INTERVAL '7 days'),
  (2, 2, 2, 'Criteria: academic merit + need; details on the page.', NOW() - INTERVAL '3 days'),
  (5, 7, 3, 'Yes! We will post a sign-up form tomorrow.', NOW() - INTERVAL '36 hours');

-------------------------------------------------
-- TRANSACTIONS 
-------------------------------------------------
INSERT INTO "transaction" ( campaign_id, author_id, amount, created_at) VALUES
  ( 1, 2, 1000, NOW() - INTERVAL '10 days'),
  ( 1, 4, 1500, NOW() - INTERVAL '6 days'),
  ( 1, 12, 2000, NOW() - INTERVAL '2 days'),

  ( 2, 3, 1000, NOW() - INTERVAL '7 days'),
  ( 2, 4, 500,  NOW() - INTERVAL '6 days'),
  ( 2, 5, 1500, NOW() - INTERVAL '5 days'),

  ( 3, NULL, 200, NOW() - INTERVAL '1 day'),

  ( 5, 10, 100, NOW() - INTERVAL '18 hours'),

  ( 6, 1,  400, NOW() - INTERVAL '12 hours'),
  (6, 2, 350, NOW() - INTERVAL '9 hours'),
  (6, 3, 250, NOW() - INTERVAL '6 hours');
UPDATE "transaction" SET is_valid = FALSE WHERE id = 7;

-------------------------------------------------
-- RESOURCES
-------------------------------------------------
INSERT INTO resource ( name, path, ordering, campaign_id) VALUES
  ( 'Clinic Floorplan', '/res/c1/floorplan.pdf', 1, 1),
  ( 'Clinic Photos',    '/res/c1/photos.zip',    2, 1);

INSERT INTO resource ( name, path, ordering, update_id) VALUES
  ( 'Equipment Quote',  '/res/u/1/quote.pdf',    1, 1),
  ( 'Artist Sketch',    '/res/u/3/sketch.png',   1, 3);