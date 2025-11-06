INSERT INTO
    user_account (email, name, password, profile_picture)
VALUES
    (
        'john.doe@example.com',
        'John Doe',
        'securepassword123',
        'https://example.com/images/john_doe.png'
    );

INSERT INTO
    lbaw2545.category (name)
values
    ('environment');

INSERT INTO
    lbaw2545.campaign (
        name,
        description,
        funded,
        goal,
        end_date,
        close_date,
        state,
        category_id
    )
VALUES
    (
        'Clean Oceans Initiative',
        'A campaign to fund ocean cleanup drones that collect floating plastic waste.',
        0, -- funded so far
        5000, -- goal
        NOW () + INTERVAL '30 days', -- end_date (30 days from now)
        NULL, -- close_date (still open)
        'unfunded', -- assuming "active" is a valid value of campaign_state
        1 -- assuming category with id = 1 exists
    );

INSERT INTO
    lbaw2545.campaign_collaborator (campaign_id, user_id)
values
    (1, 1);
