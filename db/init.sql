-- Kit Tracker database schema and seed data.
-- Runs only on first start, when the Postgres data volume is empty.

BEGIN;

-- productions
CREATE TABLE productions (
    id          INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name        VARCHAR(100) NOT NULL UNIQUE,
    start_date  DATE,
    end_date    DATE,
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT now(),

    CONSTRAINT productions_dates_valid
        CHECK (end_date IS NULL OR start_date IS NULL OR end_date >= start_date)
);

-- crew
CREATE TABLE crew (
    id          INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    full_name   VARCHAR(100) NOT NULL,
    role        VARCHAR(50),
    email       VARCHAR(255) UNIQUE,
    active      BOOLEAN      NOT NULL DEFAULT true,   -- set false instead of deleting
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT now()
);

-- kit
CREATE TABLE kit (
    id             INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    asset_tag      VARCHAR(20)  NOT NULL UNIQUE,      -- internal label, e.g. KT-0001
    serial_number  VARCHAR(100) UNIQUE,               -- manufacturer serial, optional
    name           VARCHAR(100) NOT NULL,
    category       VARCHAR(30)  NOT NULL,
    status         VARCHAR(20)  NOT NULL DEFAULT 'available',
    notes          TEXT,
    created_at     TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at     TIMESTAMPTZ  NOT NULL DEFAULT now(),   -- set by the app on update

    CONSTRAINT kit_category_valid
        CHECK (category IN ('camera', 'audio', 'lighting', 'computing', 'comms', 'other')),
    CONSTRAINT kit_status_valid
        CHECK (status IN ('available', 'checked_out', 'in_repair', 'retired'))
);

-- checkouts
CREATE TABLE checkouts (
    id              INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    kit_id          INT NOT NULL REFERENCES kit(id)         ON DELETE RESTRICT,
    crew_id         INT NOT NULL REFERENCES crew(id)        ON DELETE RESTRICT,
    production_id   INT NOT NULL REFERENCES productions(id) ON DELETE RESTRICT,
    checked_out_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    due_back        DATE,
    returned_at     TIMESTAMPTZ,                      -- NULL while checked out
    return_notes    TEXT,

    CONSTRAINT checkouts_return_after_checkout
        CHECK (returned_at IS NULL OR returned_at >= checked_out_at)
);

-- indexes
CREATE UNIQUE INDEX checkouts_one_open_per_kit
    ON checkouts (kit_id)
    WHERE returned_at IS NULL;

-- Postgres does not index foreign keys automatically
CREATE INDEX checkouts_kit_id_idx        ON checkouts (kit_id);
CREATE INDEX checkouts_crew_id_idx       ON checkouts (crew_id);
CREATE INDEX checkouts_production_id_idx ON checkouts (production_id);

-- seed data
INSERT INTO crew (full_name, role, email) VALUES
    ('Test User A', 'Camera Operator', 'test.user.a@example.com'),
    ('Test User B', 'Sound Assistant', 'test.user.b@example.com');

INSERT INTO productions (name, start_date, end_date) VALUES
    ('Daytime Live',      '2026-09-01', NULL),
    ('Weekend Cookalong', '2026-10-05', '2026-12-20');

INSERT INTO kit (asset_tag, serial_number, name, category, status) VALUES
    ('KT-0001', 'FX6-1029384', 'Sony FX6 Camera',            'camera',    'available'),
    ('KT-0002', 'FX6-1029391', 'Sony FX6 Camera',            'camera',    'available'),
    ('KT-0003', 'SEN-77812',   'Sennheiser EW-DX Radio Mic', 'audio',     'available'),
    ('KT-0004', NULL,          'Aputure 300d Light',         'lighting',  'in_repair'),
    ('KT-0005', 'MBP-C02XK1',  'MacBook Pro 14"',            'computing', 'available');

-- IDs are looked up by unique values rather than hard-coded
INSERT INTO checkouts (kit_id, crew_id, production_id, due_back)
SELECT k.id, c.id, p.id, '2026-12-01'
FROM kit k, crew c, productions p
WHERE k.asset_tag = 'KT-0003'
  AND c.email     = 'test.user.a@example.com'
  AND p.name      = 'Daytime Live';

UPDATE kit SET status = 'checked_out', updated_at = now()
WHERE asset_tag = 'KT-0003';

COMMIT;