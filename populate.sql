SET search_path TO lbaw2545;

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