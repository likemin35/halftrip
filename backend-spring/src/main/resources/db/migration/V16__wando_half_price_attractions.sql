-- Wando half-price travel target attractions from the user-provided reference image.
-- Coordinates are intentionally nullable until Kakao Places/geocoding integration
-- verifies each exact map point.

ALTER TABLE places
    MODIFY latitude DOUBLE NULL,
    MODIFY longitude DOUBLE NULL;

ALTER TABLE digital_tour_card_places
    MODIFY latitude DOUBLE NULL,
    MODIFY longitude DOUBLE NULL;

ALTER TABLE trip_places
    MODIFY latitude DOUBLE NULL,
    MODIFY longitude DOUBLE NULL;

DELETE FROM places
WHERE region_id = 1;

INSERT INTO places (
    id, region_id, name, address, description, latitude, longitude, eligible_for_refund, created_at, updated_at
) VALUES
(1001, 1, '완도해양치유센터', '상세주소 확인 예정', '완도반값여행 대상 관광지. TODO: Kakao Places API로 주소/좌표 검증 후 저장.', NULL, NULL, b'1', NOW(), NOW()),
(1002, 1, '완도타워', '상세주소 확인 예정', '완도반값여행 대상 관광지. TODO: Kakao Places API로 주소/좌표 검증 후 저장.', NULL, NULL, b'1', NOW(), NOW()),
(1003, 1, '완도청해진유적지', '상세주소 확인 예정', '완도반값여행 대상 관광지. TODO: Kakao Places API로 주소/좌표 검증 후 저장.', NULL, NULL, b'1', NOW(), NOW()),
(1004, 1, '국립완도난대수목원', '상세주소 확인 예정', '완도반값여행 대상 관광지. TODO: Kakao Places API로 주소/좌표 검증 후 저장.', NULL, NULL, b'1', NOW(), NOW()),
(1005, 1, '보길도 윤선도 원림', '상세주소 확인 예정', '완도반값여행 대상 관광지. TODO: Kakao Places API로 주소/좌표 검증 후 저장.', NULL, NULL, b'1', NOW(), NOW()),
(1006, 1, '슬로시티 청산도', '상세주소 확인 예정', '완도반값여행 대상 관광지. TODO: Kakao Places API로 주소/좌표 검증 후 저장.', NULL, NULL, b'1', NOW(), NOW()),
(1007, 1, '청해포구 촬영장', '상세주소 확인 예정', '완도반값여행 대상 관광지. TODO: Kakao Places API로 주소/좌표 검증 후 저장.', NULL, NULL, b'1', NOW(), NOW()),
(1008, 1, '신지명사십리 해수욕장', '상세주소 확인 예정', '완도반값여행 대상 관광지. TODO: Kakao Places API로 주소/좌표 검증 후 저장.', NULL, NULL, b'1', NOW(), NOW()),
(1009, 1, '금당 8경', '상세주소 확인 예정', '완도반값여행 대상 관광지. TODO: Kakao Places API로 주소/좌표 검증 후 저장.', NULL, NULL, b'1', NOW(), NOW()),
(1010, 1, '어촌민속전시관', '상세주소 확인 예정', '완도반값여행 대상 관광지. TODO: Kakao Places API로 주소/좌표 검증 후 저장.', NULL, NULL, b'1', NOW(), NOW()),
(1011, 1, '해양생태전시관', '상세주소 확인 예정', '완도반값여행 대상 관광지. TODO: Kakao Places API로 주소/좌표 검증 후 저장.', NULL, NULL, b'1', NOW(), NOW()),
(1012, 1, '장보고 기념관', '상세주소 확인 예정', '완도반값여행 대상 관광지. TODO: Kakao Places API로 주소/좌표 검증 후 저장.', NULL, NULL, b'1', NOW(), NOW()),
(1013, 1, '스마트치유센터', '상세주소 확인 예정', '완도반값여행 대상 관광지. TODO: Kakao Places API로 주소/좌표 검증 후 저장.', NULL, NULL, b'1', NOW(), NOW()),
(1014, 1, '충무사', '상세주소 확인 예정', '완도반값여행 대상 관광지. TODO: Kakao Places API로 주소/좌표 검증 후 저장.', NULL, NULL, b'1', NOW(), NOW()),
(1015, 1, '완도이순신기념관', '상세주소 확인 예정', '완도반값여행 대상 관광지. TODO: Kakao Places API로 주소/좌표 검증 후 저장.', NULL, NULL, b'1', NOW(), NOW()),
(1016, 1, '약산해안치유의 숲', '상세주소 확인 예정', '완도반값여행 대상 관광지. TODO: Kakao Places API로 주소/좌표 검증 후 저장.', NULL, NULL, b'1', NOW(), NOW());
