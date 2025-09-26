CREATE TABLE IF NOT EXISTS fundraisers (
                                           id SERIAL PRIMARY KEY,
                                           title TEXT NOT NULL,
                                           purpose TEXT NOT NULL,
                                           description TEXT,
                                           target_amount NUMERIC NOT NULL,
                                           collected_amount NUMERIC DEFAULT 0,
                                           created_by TEXT NOT NULL,
                                           deadline TIMESTAMP WITH TIME ZONE NULL,
                                           status TEXT DEFAULT 'active'
);

CREATE TABLE IF NOT EXISTS donations (
                                         id SERIAL PRIMARY KEY,
                                         fundraiser_id INT NOT NULL REFERENCES fundraisers(id) ON DELETE CASCADE,
                                         username TEXT NOT NULL,
                                         amount NUMERIC NOT NULL
);

INSERT INTO fundraisers (title, purpose, description, target_amount, collected_amount, created_by, deadline, status)
VALUES
    ('School Renovation', 'Build new classrooms', 'Fundraising for renovating local school', 10000, 2000, 'admin1', NOW() + INTERVAL '30 days', 'active'),
    ('Medical Aid', 'Help John with surgery', 'Raising money for surgery expenses', 5000, 5000, 'admin2', NOW() + INTERVAL '10 days', 'completed');

INSERT INTO donations (fundraiser_id, username, amount)
VALUES
    (1, 'alice', 500),
    (1, 'bob', 1500),
    (2, 'carol', 2500),
    (2, 'dave', 2500);
