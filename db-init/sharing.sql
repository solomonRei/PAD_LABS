CREATE TABLE IF NOT EXISTS items (
                                     id SERIAL PRIMARY KEY,
                                     name TEXT NOT NULL,
                                     owner TEXT NOT NULL,
                                     ownership_type TEXT NOT NULL CHECK (ownership_type IN ('private', 'common')),
                                     status TEXT NOT NULL DEFAULT 'available' CHECK (status IN ('available', 'in_use')),
                                     condition TEXT NOT NULL DEFAULT 'good' CHECK (condition IN ('good', 'broken', 'needs cleaning')),
                                     usage_status TEXT,
                                     borrower TEXT,
                                     borrowed_at TIMESTAMP WITH TIME ZONE,
                                     rent_start TIMESTAMP WITH TIME ZONE,
                                     rent_end TIMESTAMP WITH TIME ZONE
);

CREATE TABLE IF NOT EXISTS notifications (
                                             id SERIAL PRIMARY KEY,
                                             owner TEXT NOT NULL,
                                             item_id INT NOT NULL REFERENCES items(id) ON DELETE CASCADE,
                                             message TEXT NOT NULL,
                                             time TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS debts (
                                     id SERIAL PRIMARY KEY,
                                     username TEXT NOT NULL,
                                     item TEXT NOT NULL,
                                     damage TEXT NOT NULL CHECK (damage IN ('broken','needs cleaning')),
                                     date TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

INSERT INTO items (name, owner, ownership_type, status, condition, usage_status)
VALUES
    ('Chess Set', 'alice', 'private', 'available', 'good', NULL),
    ('Coffee Machine', 'FAFCab', 'common', 'in_use', 'good', 'needs cleaning'),
    ('Guitar', 'bob', 'private', 'available', 'broken', NULL);

-- Insert demo notifications
INSERT INTO notifications (owner, item_id, message)
VALUES
    ('alice', 1, 'Your item Chess Set is being borrowed by bob'),
    ('FAFCab', 2, 'Coffee Machine is currently in use');

INSERT INTO debts (username, item, damage)
VALUES
    ('carol', 'Guitar', 'broken'),
    ('dave', 'Coffee Machine', 'needs cleaning');
