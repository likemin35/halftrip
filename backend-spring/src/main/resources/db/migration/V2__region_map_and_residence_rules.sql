ALTER TABLE regions
    ADD COLUMN status_code VARCHAR(30) NOT NULL DEFAULT 'PREPARING' AFTER data_source_note,
    ADD COLUMN digital_benefit_available BIT NOT NULL DEFAULT b'0' AFTER status_code,
    ADD COLUMN display_order INT NOT NULL DEFAULT 0 AFTER digital_benefit_available,
    ADD COLUMN restricted_residence_tokens VARCHAR(500) NULL AFTER display_order,
    ADD COLUMN residence_restriction_note VARCHAR(255) NULL AFTER restricted_residence_tokens,
    ADD COLUMN map_top_percent DOUBLE NULL AFTER residence_restriction_note,
    ADD COLUMN map_left_percent DOUBLE NULL AFTER map_top_percent;

UPDATE users
SET name = '샘플 사용자',
    residence = '전라남도 완도군',
    updated_at = NOW()
WHERE id = 1;

UPDATE trips
SET applicant_name = '샘플 사용자',
    residence = '전라남도 완도군',
    updated_at = NOW()
WHERE user_id = 1;

DELETE FROM trip_places;
DELETE FROM digital_tour_card_places;
DELETE FROM places;
DELETE FROM merchants;
DELETE FROM online_malls;

UPDATE regions
SET name = '완도',
    province = '전라남도',
    eligible_for_residence_match = b'1',
    refund_condition_amount = 200000,
    mock_budget_remaining = 11,
    data_source_note = 'SAMPLE_SEED',
    status_code = 'APPLYING',
    digital_benefit_available = b'1',
    display_order = 1,
    restricted_residence_tokens = '완도군,강진군,해남군,고흥군',
    residence_restriction_note = 'sample adjacency rule: selected residence and nearby sample tokens are excluded.',
    map_top_percent = 92,
    map_left_percent = 55,
    map_center_lat = 34.3119,
    map_center_lng = 126.7551,
    updated_at = NOW()
WHERE id = 1;

UPDATE regions
SET name = '강진',
    province = '전라남도',
    eligible_for_residence_match = b'1',
    refund_condition_amount = 180000,
    mock_budget_remaining = 24,
    data_source_note = 'SAMPLE_SEED',
    status_code = 'PREPARING',
    digital_benefit_available = b'1',
    display_order = 2,
    restricted_residence_tokens = '강진군,영암군,장흥군,해남군,완도군',
    residence_restriction_note = 'sample adjacency rule: selected residence and nearby sample tokens are excluded.',
    map_top_percent = 86,
    map_left_percent = 25,
    map_center_lat = 34.6421,
    map_center_lng = 126.7672,
    updated_at = NOW()
WHERE id = 2;

UPDATE regions
SET name = '평창',
    province = '강원특별자치도',
    eligible_for_residence_match = b'1',
    refund_condition_amount = 220000,
    mock_budget_remaining = 18,
    data_source_note = 'SAMPLE_SEED',
    status_code = 'PREPARING',
    digital_benefit_available = b'1',
    display_order = 3,
    restricted_residence_tokens = '평창군,횡성군,강릉시,정선군',
    residence_restriction_note = 'sample adjacency rule: selected residence and nearby sample tokens are excluded.',
    map_top_percent = 18,
    map_left_percent = 74,
    map_center_lat = 37.3705,
    map_center_lng = 128.3902,
    updated_at = NOW()
WHERE id = 3;

INSERT INTO regions (
    id, name, province, eligible_for_residence_match, half_price_apply_url, digital_tour_card_apply_url,
    refund_condition_amount, mock_budget_remaining, data_source_note, status_code, digital_benefit_available,
    display_order, restricted_residence_tokens, residence_restriction_note, map_top_percent, map_left_percent,
    map_center_lat, map_center_lng, created_at, updated_at
) VALUES
(4, '해남', '전라남도', b'1', 'https://www.wandotrip.kr/bbs/apply_date.php', 'https://www.wandotrip.kr/bbs/apply_date.php', 180000, 16, 'SAMPLE_SEED', 'PREPARING', b'1', 4, '해남군,강진군,완도군,영암군,진도군', 'sample adjacency rule: selected residence and nearby sample tokens are excluded.', 95, 14, 34.5732, 126.5989, NOW(), NOW()),
(5, '영광', '전라남도', b'1', 'https://www.wandotrip.kr/bbs/apply_date.php', 'https://www.wandotrip.kr/bbs/apply_date.php', 170000, 20, 'SAMPLE_SEED', 'PREPARING', b'1', 5, '영광군,고창군,함평군,장성군', 'sample adjacency rule: selected residence and nearby sample tokens are excluded.', 76, 13, 35.2770, 126.5128, NOW(), NOW()),
(6, '횡성', '강원특별자치도', b'1', 'https://www.wandotrip.kr/bbs/apply_date.php', 'https://www.wandotrip.kr/bbs/apply_date.php', 210000, 19, 'SAMPLE_SEED', 'PREPARING', b'1', 6, '횡성군,원주시,평창군,홍천군', 'sample adjacency rule: selected residence and nearby sample tokens are excluded.', 24, 57, 37.4919, 127.9850, NOW(), NOW()),
(7, '영월', '강원특별자치도', b'1', 'https://www.wandotrip.kr/bbs/apply_date.php', 'https://www.wandotrip.kr/bbs/apply_date.php', 190000, 7, 'SAMPLE_SEED', 'CLOSED', b'1', 7, '영월군,제천시,단양군,정선군', 'sample adjacency rule: selected residence and nearby sample tokens are excluded.', 34, 69, 37.1836, 128.4617, NOW(), NOW()),
(8, '제천', '충청북도', b'1', 'https://www.wandotrip.kr/bbs/apply_date.php', 'https://www.wandotrip.kr/bbs/apply_date.php', 200000, 5, 'SAMPLE_SEED', 'CLOSED', b'1', 8, '제천시,영월군,충주시,단양군', 'sample adjacency rule: selected residence and nearby sample tokens are excluded.', 40, 55, 37.1326, 128.1909, NOW(), NOW()),
(9, '거창', '경상남도', b'1', 'https://www.wandotrip.kr/bbs/apply_date.php', 'https://www.wandotrip.kr/bbs/apply_date.php', 160000, 4, 'SAMPLE_SEED', 'CLOSED', b'1', 9, '거창군,합천군,함양군,산청군', 'sample adjacency rule: selected residence and nearby sample tokens are excluded.', 60, 48, 35.6867, 127.9095, NOW(), NOW()),
(10, '고창', '전북특별자치도', b'1', 'https://www.wandotrip.kr/bbs/apply_date.php', 'https://www.wandotrip.kr/bbs/apply_date.php', 165000, 6, 'SAMPLE_SEED', 'CLOSED', b'1', 10, '고창군,영광군,정읍시,부안군', 'sample adjacency rule: selected residence and nearby sample tokens are excluded.', 69, 18, 35.4358, 126.7019, NOW(), NOW()),
(11, '영암', '전라남도', b'1', 'https://www.wandotrip.kr/bbs/apply_date.php', 'https://www.wandotrip.kr/bbs/apply_date.php', 175000, 8, 'SAMPLE_SEED', 'CLOSED', b'0', 11, '영암군,강진군,해남군,목포시', 'sample adjacency rule: selected residence and nearby sample tokens are excluded.', 81, 18, 34.8003, 126.6967, NOW(), NOW()),
(12, '합천', '경상남도', b'1', 'https://www.wandotrip.kr/bbs/apply_date.php', 'https://www.wandotrip.kr/bbs/apply_date.php', 175000, 12, 'SAMPLE_SEED', 'PREPARING', b'1', 12, '합천군,거창군,산청군,의령군', 'sample adjacency rule: selected residence and nearby sample tokens are excluded.', 73, 49, 35.5666, 128.1658, NOW(), NOW()),
(13, '밀양', '경상남도', b'1', 'https://www.wandotrip.kr/bbs/apply_date.php', 'https://www.wandotrip.kr/bbs/apply_date.php', 185000, 9, 'SAMPLE_SEED', 'PREPARING', b'1', 13, '밀양시,창녕군,청도군,양산시', 'sample adjacency rule: selected residence and nearby sample tokens are excluded.', 73, 74, 35.5039, 128.7464, NOW(), NOW()),
(14, '하동', '경상남도', b'1', 'https://www.wandotrip.kr/bbs/apply_date.php', 'https://www.wandotrip.kr/bbs/apply_date.php', 175000, 14, 'SAMPLE_SEED', 'PREPARING', b'1', 14, '하동군,광양시,진주시,남해군,사천시', 'sample adjacency rule: selected residence and nearby sample tokens are excluded.', 84, 50, 35.0672, 127.7513, NOW(), NOW()),
(15, '남해', '경상남도', b'1', 'https://www.wandotrip.kr/bbs/apply_date.php', 'https://www.wandotrip.kr/bbs/apply_date.php', 190000, 15, 'SAMPLE_SEED', 'PREPARING', b'1', 15, '남해군,하동군,사천시,통영시', 'sample adjacency rule: selected residence and nearby sample tokens are excluded.', 92, 55, 34.8378, 127.8924, NOW(), NOW()),
(16, '고흥', '전라남도', b'1', 'https://www.wandotrip.kr/bbs/apply_date.php', 'https://www.wandotrip.kr/bbs/apply_date.php', 180000, 3, 'SAMPLE_SEED', 'CLOSED', b'0', 16, '고흥군,보성군,순천시,여수시', 'sample adjacency rule: selected residence and nearby sample tokens are excluded.', 95, 68, 34.6111, 127.2850, NOW(), NOW());

INSERT INTO places (id, region_id, name, address, description, latitude, longitude, eligible_for_refund, created_at, updated_at) VALUES
(1, 1, '완도 해양치유센터', '전라남도 완도군 해양치유길 10', '반값여행 환급 인정 관광지 sample data', 34.3180, 126.7590, b'1', NOW(), NOW()),
(2, 2, '강진만 생태공원', '전라남도 강진군 강진만길 20', '반값여행 환급 인정 관광지 sample data', 34.6445, 126.7782, b'1', NOW(), NOW()),
(3, 3, '평창 로컬투어 라운지', '강원특별자치도 평창군 관광로 7', '반값여행 환급 인정 관광지 sample data', 37.3705, 128.3902, b'1', NOW(), NOW()),
(4, 4, '해남 땅끝전망대', '전라남도 해남군 땅끝해안로 12', '반값여행 환급 인정 관광지 sample data', 34.3010, 126.5252, b'1', NOW(), NOW()),
(5, 5, '영광 백수해안길', '전라남도 영광군 해안로 55', '반값여행 환급 인정 관광지 sample data', 35.2770, 126.5128, b'1', NOW(), NOW()),
(6, 6, '횡성 한우체험관', '강원특별자치도 횡성군 한우리길 11', '반값여행 환급 인정 관광지 sample data', 37.4919, 127.9850, b'1', NOW(), NOW()),
(7, 7, '영월 별마로공원', '강원특별자치도 영월군 별마로길 6', '반값여행 환급 인정 관광지 sample data', 37.1836, 128.4617, b'1', NOW(), NOW()),
(8, 8, '제천 의림지 산책로', '충청북도 제천시 의림대로 9', '반값여행 환급 인정 관광지 sample data', 37.1326, 128.1909, b'1', NOW(), NOW()),
(9, 9, '거창 창포원', '경상남도 거창군 창포원길 4', '반값여행 환급 인정 관광지 sample data', 35.6867, 127.9095, b'1', NOW(), NOW()),
(10, 10, '고창 고인돌마을', '전북특별자치도 고창군 고인돌길 3', '반값여행 환급 인정 관광지 sample data', 35.4358, 126.7019, b'1', NOW(), NOW()),
(11, 11, '영암 월출산 로컬센터', '전라남도 영암군 월출로 31', '반값여행 환급 인정 관광지 sample data', 34.8003, 126.6967, b'1', NOW(), NOW()),
(12, 12, '합천 영상테마파크', '경상남도 합천군 촬영로 88', '반값여행 환급 인정 관광지 sample data', 35.5666, 128.1658, b'1', NOW(), NOW()),
(13, 13, '밀양 영남루 광장', '경상남도 밀양시 영남루길 16', '반값여행 환급 인정 관광지 sample data', 35.5039, 128.7464, b'1', NOW(), NOW()),
(14, 14, '하동 십리벚꽃길', '경상남도 하동군 벚꽃로 27', '반값여행 환급 인정 관광지 sample data', 35.0672, 127.7513, b'1', NOW(), NOW()),
(15, 15, '남해 독일마을 광장', '경상남도 남해군 독일로 41', '반값여행 환급 인정 관광지 sample data', 34.8378, 127.8924, b'1', NOW(), NOW()),
(16, 16, '고흥 우주전망대', '전라남도 고흥군 우주로 12', '반값여행 환급 인정 관광지 sample data', 34.6111, 127.2850, b'1', NOW(), NOW());

INSERT INTO digital_tour_card_places (id, region_id, name, address, discount_description, latitude, longitude, created_at, updated_at) VALUES
(101, 1, '완도 로컬카페', '전라남도 완도군 바다로 8', '디지털 관광주민증 할인 가능 장소 sample data', 34.3172, 126.7574, NOW(), NOW()),
(102, 2, '강진 청자뮤지엄샵', '전라남도 강진군 청자로 18', '디지털 관광주민증 할인 가능 장소 sample data', 34.6400, 126.7720, NOW(), NOW()),
(103, 3, '평창 숲체험센터', '강원특별자치도 평창군 숲길 14', '디지털 관광주민증 할인 가능 장소 sample data', 37.3602, 128.4002, NOW(), NOW()),
(104, 4, '해남 특산품관', '전라남도 해남군 땅끝로 22', '디지털 관광주민증 할인 가능 장소 sample data', 34.3050, 126.5290, NOW(), NOW()),
(105, 5, '영광 식문화관', '전라남도 영광군 백수로 31', '디지털 관광주민증 할인 가능 장소 sample data', 35.2742, 126.5077, NOW(), NOW()),
(106, 6, '횡성 한우마켓', '강원특별자치도 횡성군 시장길 6', '디지털 관광주민증 할인 가능 장소 sample data', 37.4902, 127.9871, NOW(), NOW()),
(107, 7, '영월 별빛굿즈샵', '강원특별자치도 영월군 별마로길 8', '디지털 관광주민증 할인 가능 장소 sample data', 37.1801, 128.4580, NOW(), NOW()),
(108, 8, '제천 약초생활관', '충청북도 제천시 청전로 17', '디지털 관광주민증 할인 가능 장소 sample data', 37.1351, 128.1940, NOW(), NOW()),
(109, 9, '거창 창포카페', '경상남도 거창군 정장로 4', '디지털 관광주민증 할인 가능 장소 sample data', 35.6880, 127.9050, NOW(), NOW()),
(110, 10, '고창 풍천장어센터', '전북특별자치도 고창군 선운로 12', '디지털 관광주민증 할인 가능 장소 sample data', 35.4331, 126.7059, NOW(), NOW()),
(111, 11, '영암 와인숍', '전라남도 영암군 기찬로 3', '디지털 관광주민증 할인 가능 장소 sample data', 34.8041, 126.7011, NOW(), NOW()),
(112, 12, '합천 영상카페', '경상남도 합천군 영상로 9', '디지털 관광주민증 할인 가능 장소 sample data', 35.5672, 128.1681, NOW(), NOW()),
(113, 13, '밀양 로컬북카페', '경상남도 밀양시 중앙로 10', '디지털 관광주민증 할인 가능 장소 sample data', 35.5017, 128.7489, NOW(), NOW()),
(114, 14, '하동 티라운지', '경상남도 하동군 차로 5', '디지털 관광주민증 할인 가능 장소 sample data', 35.0615, 127.7560, NOW(), NOW()),
(115, 15, '남해 바다책방', '경상남도 남해군 독일로 55', '디지털 관광주민증 할인 가능 장소 sample data', 34.8394, 127.8960, NOW(), NOW()),
(116, 16, '고흥 우주기념품점', '전라남도 고흥군 우주로 15', '디지털 관광주민증 할인 가능 장소 sample data', 34.6124, 127.2880, NOW(), NOW());

INSERT INTO merchants (id, region_id, name, address, category, created_at, updated_at) VALUES
(201, 1, '완도 특산품 상회', '전라남도 완도군 시장길 5', '오프라인 가맹점', NOW(), NOW()),
(202, 2, '강진 로컬푸드 마켓', '전라남도 강진군 남문로 3', '오프라인 가맹점', NOW(), NOW()),
(203, 3, '평창 여행상점', '강원특별자치도 평창군 관광로 2', '오프라인 가맹점', NOW(), NOW()),
(204, 4, '해남 로컬푸드관', '전라남도 해남군 중앙로 11', '오프라인 가맹점', NOW(), NOW()),
(205, 5, '영광 굴비상점', '전라남도 영광군 굴비로 19', '오프라인 가맹점', NOW(), NOW()),
(206, 6, '횡성 한우정육점', '강원특별자치도 횡성군 시장길 2', '오프라인 가맹점', NOW(), NOW()),
(207, 7, '영월 우주굿즈샵', '강원특별자치도 영월군 읍내길 8', '오프라인 가맹점', NOW(), NOW()),
(208, 8, '제천 약초상회', '충청북도 제천시 풍양로 9', '오프라인 가맹점', NOW(), NOW()),
(209, 9, '거창 산나물가게', '경상남도 거창군 중앙로 4', '오프라인 가맹점', NOW(), NOW()),
(210, 10, '고창 풍천장어몰', '전북특별자치도 고창군 고인돌로 17', '오프라인 가맹점', NOW(), NOW()),
(211, 11, '영암 기찬상점', '전라남도 영암군 군서면로 7', '오프라인 가맹점', NOW(), NOW()),
(212, 12, '합천 영상굿즈샵', '경상남도 합천군 문화로 6', '오프라인 가맹점', NOW(), NOW()),
(213, 13, '밀양 딸기마켓', '경상남도 밀양시 북성로 5', '오프라인 가맹점', NOW(), NOW()),
(214, 14, '하동 녹차상점', '경상남도 하동군 시장길 13', '오프라인 가맹점', NOW(), NOW()),
(215, 15, '남해 멸치상회', '경상남도 남해군 읍로 6', '오프라인 가맹점', NOW(), NOW()),
(216, 16, '고흥 유자상점', '전라남도 고흥군 봉래로 14', '오프라인 가맹점', NOW(), NOW());

INSERT INTO online_malls (id, region_id, name, mall_url, description, created_at, updated_at) VALUES
(301, 1, '완도 온라인몰', 'https://example.com/wando', 'sample seed online mall link', NOW(), NOW()),
(302, 2, '강진 온라인몰', 'https://example.com/gangjin', 'sample seed online mall link', NOW(), NOW()),
(303, 3, '평창 온라인몰', 'https://example.com/pyeongchang', 'sample seed online mall link', NOW(), NOW()),
(304, 4, '해남 온라인몰', 'https://example.com/haenam', 'sample seed online mall link', NOW(), NOW()),
(305, 5, '영광 온라인몰', 'https://example.com/yeonggwang', 'sample seed online mall link', NOW(), NOW()),
(306, 6, '횡성 온라인몰', 'https://example.com/hoengseong', 'sample seed online mall link', NOW(), NOW()),
(307, 7, '영월 온라인몰', 'https://example.com/yeongwol', 'sample seed online mall link', NOW(), NOW()),
(308, 8, '제천 온라인몰', 'https://example.com/jecheon', 'sample seed online mall link', NOW(), NOW()),
(309, 9, '거창 온라인몰', 'https://example.com/geochang', 'sample seed online mall link', NOW(), NOW()),
(310, 10, '고창 온라인몰', 'https://example.com/gochang', 'sample seed online mall link', NOW(), NOW()),
(311, 11, '영암 온라인몰', 'https://example.com/yeongam', 'sample seed online mall link', NOW(), NOW()),
(312, 12, '합천 온라인몰', 'https://example.com/hapcheon', 'sample seed online mall link', NOW(), NOW()),
(313, 13, '밀양 온라인몰', 'https://example.com/miryang', 'sample seed online mall link', NOW(), NOW()),
(314, 14, '하동 온라인몰', 'https://example.com/hadong', 'sample seed online mall link', NOW(), NOW()),
(315, 15, '남해 온라인몰', 'https://example.com/namhae', 'sample seed online mall link', NOW(), NOW()),
(316, 16, '고흥 온라인몰', 'https://example.com/goheung', 'sample seed online mall link', NOW(), NOW());

INSERT INTO trip_places (
    id, trip_id, place_type, reference_place_id, place_name, address, visit_order, latitude, longitude, checked, created_at, updated_at
) VALUES
(1, 1, 'HALF_PRICE', 1, '완도 해양치유센터', '전라남도 완도군 해양치유길 10', 1, 34.3180, 126.7590, b'1', NOW(), NOW()),
(2, 1, 'DIGITAL_TOUR_CARD', 101, '완도 로컬카페', '전라남도 완도군 바다로 8', 2, 34.3172, 126.7574, b'1', NOW(), NOW());
