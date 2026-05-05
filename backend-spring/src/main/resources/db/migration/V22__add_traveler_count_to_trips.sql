ALTER TABLE trips
    ADD COLUMN traveler_count INT NOT NULL DEFAULT 2 AFTER end_date;
