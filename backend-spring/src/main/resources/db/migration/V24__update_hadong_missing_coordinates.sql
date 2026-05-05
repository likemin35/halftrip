UPDATE places
SET latitude = 34.9295724400833,
    longitude = 127.831833815361,
    description = '하동 반값여행 지정관광지 sample data',
    updated_at = NOW()
WHERE region_id = 14
  AND name = '대도 파라다이스';

UPDATE places
SET latitude = 35.1138939978233,
    longitude = 127.890049836457,
    description = '하동 반값여행 지정관광지 sample data',
    updated_at = NOW()
WHERE region_id = 14
  AND name = '나림생태공원';
