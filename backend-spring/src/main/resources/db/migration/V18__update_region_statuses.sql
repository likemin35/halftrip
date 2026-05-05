UPDATE regions
SET status_code = 'CLOSED',
    updated_at = NOW();

UPDATE regions
SET status_code = 'APPLYING',
    updated_at = NOW()
WHERE id = 1;

UPDATE regions
SET status_code = 'PREPARING',
    updated_at = NOW()
WHERE id IN (2, 6);
