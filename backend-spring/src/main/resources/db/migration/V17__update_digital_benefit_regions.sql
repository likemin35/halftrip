UPDATE regions
SET digital_benefit_available = b'0',
    updated_at = NOW();

UPDATE regions
SET digital_benefit_available = b'1',
    updated_at = NOW()
WHERE id IN (3, 4, 5, 7, 8, 9, 10, 12, 13, 14);

DELETE FROM digital_tour_card_places
WHERE region_id NOT IN (3, 4, 5, 7, 8, 9, 10, 12, 13, 14);
