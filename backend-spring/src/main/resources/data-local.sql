INSERT INTO users (id, name, email, phone_number, residence, auth_provider, oauth_subject, created_at, updated_at) VALUES
(1, '샘플 사용자', 'sample@travel-mvp.local', '010-1234-5678', '전라남도', 'GUEST', 'mock-guest-1', CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP());

INSERT INTO user_notification_settings (id, user_id, favorite_region_preopen_alert, trip_end_settlement_alert, created_at, updated_at) VALUES
(1, 1, TRUE, TRUE, CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP());

INSERT INTO regions (id, name, province, eligible_for_residence_match, half_price_apply_url, digital_tour_card_apply_url, refund_condition_amount, mock_budget_remaining, data_source_note, map_center_lat, map_center_lng, created_at, updated_at) VALUES
(1, '완도 샘플권역', '전라남도', TRUE, 'https://www.wandotrip.kr/bbs/apply_date.php', 'https://www.wandotrip.kr/bbs/apply_date.php', 200000, 30, 'SAMPLE_SEED', 34.3119, 126.7551, CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP()),
(2, '강진 샘플권역', '전라남도', TRUE, 'https://www.wandotrip.kr/bbs/apply_date.php', 'https://www.wandotrip.kr/bbs/apply_date.php', 150000, 18, 'SAMPLE_SEED', 34.6421, 126.7672, CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP()),
(3, '태백 샘플권역', '강원특별자치도', TRUE, 'https://www.wandotrip.kr/bbs/apply_date.php', 'https://www.wandotrip.kr/bbs/apply_date.php', 180000, 12, 'SAMPLE_SEED', 37.1640, 128.9857, CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP());

INSERT INTO places (id, region_id, name, address, description, latitude, longitude, eligible_for_refund, created_at, updated_at) VALUES
(1, 1, '완도 샘플 해변', '전라남도 완도군 샘플해변로 1', '반값여행 인정 관광지 샘플 데이터', 34.3180, 126.7590, TRUE, CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP()),
(2, 1, '완도 샘플 수목원', '전라남도 완도군 수목원길 12', 'TODO: 실제 관광공사 데이터 연동 예정', 34.3260, 126.7610, TRUE, CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP()),
(3, 2, '강진 샘플 다원', '전라남도 강진군 다원길 21', '샘플 환급 인정 관광지', 34.6445, 126.7782, TRUE, CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP()),
(4, 3, '태백 샘플 전망대', '강원특별자치도 태백시 전망로 7', '샘플 환급 인정 관광지', 37.1702, 128.9901, TRUE, CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP());

INSERT INTO digital_tour_card_places (id, region_id, name, address, discount_description, latitude, longitude, created_at, updated_at) VALUES
(1, 1, '완도 샘플 카페', '전라남도 완도군 카페거리 10', '디지털관광주민증 할인 샘플', 34.3172, 126.7574, CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP()),
(2, 1, '완도 샘플 체험관', '전라남도 완도군 체험길 2', 'TODO: 실제 할인처 연동 예정', 34.3201, 126.7540, CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP()),
(3, 2, '강진 샘플 미술관', '전라남도 강진군 미술관로 8', '입장료 할인 샘플', 34.6400, 126.7720, CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP()),
(4, 3, '태백 샘플 박물관', '강원특별자치도 태백시 박물관길 4', '기념품 할인 샘플', 37.1615, 128.9803, CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP());

INSERT INTO merchants (id, region_id, name, address, category, created_at, updated_at) VALUES
(1, 1, '완도 샘플 수산상회', '전라남도 완도군 중앙시장길 5', '오프라인 가맹점', CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP()),
(2, 1, '완도 샘플 로컬푸드', '전라남도 완도군 농산물로 3', '오프라인 가맹점', CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP()),
(3, 2, '강진 샘플 특산관', '전라남도 강진군 읍내길 9', '오프라인 가맹점', CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP()),
(4, 3, '태백 샘플 몰', '강원특별자치도 태백시 중앙로 1', '오프라인 가맹점', CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP());

INSERT INTO online_malls (id, region_id, name, mall_url, description, created_at, updated_at) VALUES
(1, 1, '완도 샘플 온라인몰', 'https://example.com/wando', '특산물 온라인몰 샘플 링크', CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP()),
(2, 2, '강진 샘플 온라인몰', 'https://example.com/gangjin', 'TODO: 실제 온라인몰 연동 예정', CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP()),
(3, 3, '태백 샘플 온라인몰', 'https://example.com/taebaek', '특산물 온라인몰 샘플 링크', CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP());

INSERT INTO trips (id, user_id, region_id, applicant_name, phone_number, residence, start_date, end_date, status, refund_condition_amount, total_spent_amount, settlement_applied, settlement_applied_at, created_at, updated_at) VALUES
(1, 1, 1, '샘플 사용자', '010-1234-5678', '전라남도', DATE '2026-04-20', DATE '2026-04-26', 'TRAVELING', 200000, 120000, FALSE, NULL, CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP()),
(2, 1, 2, '샘플 사용자', '010-1234-5678', '전라남도', DATE '2026-04-01', DATE '2026-04-05', 'SETTLEMENT_READY', 150000, 150000, TRUE, CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP());

INSERT INTO trip_places (id, trip_id, place_type, reference_place_id, place_name, address, visit_order, latitude, longitude, checked, created_at, updated_at) VALUES
(1, 1, 'HALF_PRICE', 1, '완도 샘플 해변', '전라남도 완도군 샘플해변로 1', 1, 34.3180, 126.7590, TRUE, CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP()),
(2, 1, 'DIGITAL_TOUR_CARD', 1, '완도 샘플 카페', '전라남도 완도군 카페거리 10', 2, 34.3172, 126.7574, TRUE, CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP());

INSERT INTO user_favorite_regions (id, user_id, region_id, created_at, updated_at) VALUES
(1, 1, 1, CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP()),
(2, 1, 2, CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP());
