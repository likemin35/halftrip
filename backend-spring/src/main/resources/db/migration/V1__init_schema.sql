CREATE TABLE users (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(120) NOT NULL,
    email VARCHAR(160) NOT NULL UNIQUE,
    phone_number VARCHAR(40),
    residence VARCHAR(120),
    auth_provider VARCHAR(30) NOT NULL,
    oauth_subject VARCHAR(120),
    created_at DATETIME NOT NULL,
    updated_at DATETIME NOT NULL
);

CREATE TABLE user_notification_settings (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL UNIQUE,
    favorite_region_preopen_alert BIT NOT NULL,
    trip_end_settlement_alert BIT NOT NULL,
    created_at DATETIME NOT NULL,
    updated_at DATETIME NOT NULL,
    CONSTRAINT fk_notification_user FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE regions (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    province VARCHAR(100) NOT NULL,
    eligible_for_residence_match BIT NOT NULL,
    half_price_apply_url VARCHAR(255) NOT NULL,
    digital_tour_card_apply_url VARCHAR(255) NOT NULL,
    refund_condition_amount INT NOT NULL,
    mock_budget_remaining INT NOT NULL,
    data_source_note VARCHAR(30) NOT NULL,
    map_center_lat DOUBLE,
    map_center_lng DOUBLE,
    created_at DATETIME NOT NULL,
    updated_at DATETIME NOT NULL
);

CREATE TABLE trips (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    region_id BIGINT NOT NULL,
    applicant_name VARCHAR(100) NOT NULL,
    phone_number VARCHAR(40) NOT NULL,
    residence VARCHAR(120) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    status VARCHAR(40) NOT NULL,
    refund_condition_amount INT NOT NULL,
    total_spent_amount INT NOT NULL DEFAULT 0,
    settlement_applied BIT NOT NULL DEFAULT 0,
    settlement_applied_at DATETIME NULL,
    created_at DATETIME NOT NULL,
    updated_at DATETIME NOT NULL,
    CONSTRAINT fk_trip_user FOREIGN KEY (user_id) REFERENCES users(id),
    CONSTRAINT fk_trip_region FOREIGN KEY (region_id) REFERENCES regions(id)
);

CREATE TABLE places (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    region_id BIGINT NOT NULL,
    name VARCHAR(150) NOT NULL,
    address VARCHAR(255) NOT NULL,
    description VARCHAR(500),
    latitude DOUBLE NOT NULL,
    longitude DOUBLE NOT NULL,
    eligible_for_refund BIT NOT NULL,
    created_at DATETIME NOT NULL,
    updated_at DATETIME NOT NULL,
    CONSTRAINT fk_place_region FOREIGN KEY (region_id) REFERENCES regions(id)
);

CREATE TABLE digital_tour_card_places (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    region_id BIGINT NOT NULL,
    name VARCHAR(150) NOT NULL,
    address VARCHAR(255) NOT NULL,
    discount_description VARCHAR(500),
    latitude DOUBLE NOT NULL,
    longitude DOUBLE NOT NULL,
    created_at DATETIME NOT NULL,
    updated_at DATETIME NOT NULL,
    CONSTRAINT fk_digital_place_region FOREIGN KEY (region_id) REFERENCES regions(id)
);

CREATE TABLE trip_places (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    trip_id BIGINT NOT NULL,
    place_type VARCHAR(40) NOT NULL,
    reference_place_id BIGINT NOT NULL,
    place_name VARCHAR(150) NOT NULL,
    address VARCHAR(255) NOT NULL,
    visit_order INT NOT NULL,
    latitude DOUBLE NOT NULL,
    longitude DOUBLE NOT NULL,
    checked BIT NOT NULL,
    created_at DATETIME NOT NULL,
    updated_at DATETIME NOT NULL,
    CONSTRAINT fk_trip_place_trip FOREIGN KEY (trip_id) REFERENCES trips(id)
);

CREATE TABLE uploaded_files (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    trip_id BIGINT NOT NULL,
    file_category VARCHAR(40) NOT NULL,
    original_file_name VARCHAR(255) NOT NULL,
    storage_path VARCHAR(255) NOT NULL,
    file_size BIGINT NOT NULL,
    mime_type VARCHAR(120) NOT NULL,
    created_at DATETIME NOT NULL,
    updated_at DATETIME NOT NULL,
    CONSTRAINT fk_uploaded_file_trip FOREIGN KEY (trip_id) REFERENCES trips(id)
);

CREATE TABLE receipts (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    uploaded_file_id BIGINT NOT NULL UNIQUE,
    payment_type VARCHAR(40) NOT NULL,
    amount INT NULL,
    raw_text VARCHAR(500),
    created_at DATETIME NOT NULL,
    updated_at DATETIME NOT NULL,
    CONSTRAINT fk_receipt_uploaded_file FOREIGN KEY (uploaded_file_id) REFERENCES uploaded_files(id)
);

CREATE TABLE lodging_infos (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    trip_id BIGINT NOT NULL,
    uploaded_file_id BIGINT NULL,
    lodging_name VARCHAR(150),
    representative_name VARCHAR(100),
    phone_number VARCHAR(40),
    address VARCHAR(255),
    signature_svg_path TEXT,
    agreed_personal_info BIT NOT NULL,
    agreed_stay_proof BIT NOT NULL,
    created_at DATETIME NOT NULL,
    updated_at DATETIME NOT NULL,
    CONSTRAINT fk_lodging_trip FOREIGN KEY (trip_id) REFERENCES trips(id),
    CONSTRAINT fk_lodging_uploaded_file FOREIGN KEY (uploaded_file_id) REFERENCES uploaded_files(id)
);

CREATE TABLE merchants (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    region_id BIGINT NOT NULL,
    name VARCHAR(150) NOT NULL,
    address VARCHAR(255) NOT NULL,
    category VARCHAR(100),
    created_at DATETIME NOT NULL,
    updated_at DATETIME NOT NULL,
    CONSTRAINT fk_merchant_region FOREIGN KEY (region_id) REFERENCES regions(id)
);

CREATE TABLE online_malls (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    region_id BIGINT NOT NULL,
    name VARCHAR(150) NOT NULL,
    mall_url VARCHAR(255) NOT NULL,
    description VARCHAR(255),
    created_at DATETIME NOT NULL,
    updated_at DATETIME NOT NULL,
    CONSTRAINT fk_online_mall_region FOREIGN KEY (region_id) REFERENCES regions(id)
);

CREATE TABLE user_favorite_regions (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    region_id BIGINT NOT NULL,
    created_at DATETIME NOT NULL,
    updated_at DATETIME NOT NULL,
    CONSTRAINT fk_favorite_user FOREIGN KEY (user_id) REFERENCES users(id),
    CONSTRAINT fk_favorite_region FOREIGN KEY (region_id) REFERENCES regions(id),
    CONSTRAINT uk_user_region UNIQUE (user_id, region_id)
);

INSERT INTO users (id, name, email, phone_number, residence, auth_provider, oauth_subject, created_at, updated_at) VALUES
(1, '샘플 사용자', 'sample@travel-mvp.local', '010-1234-5678', '전라남도', 'GUEST', 'mock-guest-1', NOW(), NOW());

INSERT INTO user_notification_settings (id, user_id, favorite_region_preopen_alert, trip_end_settlement_alert, created_at, updated_at) VALUES
(1, 1, b'1', b'1', NOW(), NOW());

INSERT INTO regions (id, name, province, eligible_for_residence_match, half_price_apply_url, digital_tour_card_apply_url, refund_condition_amount, mock_budget_remaining, data_source_note, map_center_lat, map_center_lng, created_at, updated_at) VALUES
(1, '완도 샘플권역', '전라남도', b'1', 'https://www.wandotrip.kr/bbs/apply_date.php', 'https://www.wandotrip.kr/bbs/apply_date.php', 200000, 30, 'SAMPLE_SEED', 34.3119, 126.7551, NOW(), NOW()),
(2, '강진 샘플권역', '전라남도', b'1', 'https://www.wandotrip.kr/bbs/apply_date.php', 'https://www.wandotrip.kr/bbs/apply_date.php', 150000, 18, 'SAMPLE_SEED', 34.6421, 126.7672, NOW(), NOW()),
(3, '태백 샘플권역', '강원특별자치도', b'1', 'https://www.wandotrip.kr/bbs/apply_date.php', 'https://www.wandotrip.kr/bbs/apply_date.php', 180000, 12, 'SAMPLE_SEED', 37.1640, 128.9857, NOW(), NOW());

INSERT INTO places (id, region_id, name, address, description, latitude, longitude, eligible_for_refund, created_at, updated_at) VALUES
(1, 1, '완도 샘플 해변', '전라남도 완도군 샘플해변로 1', '반값여행 인정 관광지 샘플 데이터', 34.3180, 126.7590, b'1', NOW(), NOW()),
(2, 1, '완도 샘플 수목원', '전라남도 완도군 수목원길 12', 'TODO: 실제 관광공사 데이터 연동 예정', 34.3260, 126.7610, b'1', NOW(), NOW()),
(3, 2, '강진 샘플 다원', '전라남도 강진군 다원길 21', '샘플 환급 인정 관광지', 34.6445, 126.7782, b'1', NOW(), NOW()),
(4, 3, '태백 샘플 전망대', '강원특별자치도 태백시 전망로 7', '샘플 환급 인정 관광지', 37.1702, 128.9901, b'1', NOW(), NOW());

INSERT INTO digital_tour_card_places (id, region_id, name, address, discount_description, latitude, longitude, created_at, updated_at) VALUES
(1, 1, '완도 샘플 카페', '전라남도 완도군 카페거리 10', '디지털관광주민증 할인 샘플', 34.3172, 126.7574, NOW(), NOW()),
(2, 1, '완도 샘플 체험관', '전라남도 완도군 체험길 2', 'TODO: 실제 할인처 연동 예정', 34.3201, 126.7540, NOW(), NOW()),
(3, 2, '강진 샘플 미술관', '전라남도 강진군 미술관로 8', '입장료 할인 샘플', 34.6400, 126.7720, NOW(), NOW()),
(4, 3, '태백 샘플 박물관', '강원특별자치도 태백시 박물관길 4', '기념품 할인 샘플', 37.1615, 128.9803, NOW(), NOW());

INSERT INTO merchants (id, region_id, name, address, category, created_at, updated_at) VALUES
(1, 1, '완도 샘플 수산상회', '전라남도 완도군 중앙시장길 5', '오프라인 가맹점', NOW(), NOW()),
(2, 1, '완도 샘플 로컬푸드', '전라남도 완도군 농산물로 3', '오프라인 가맹점', NOW(), NOW()),
(3, 2, '강진 샘플 특산관', '전라남도 강진군 읍내길 9', '오프라인 가맹점', NOW(), NOW()),
(4, 3, '태백 샘플 몰', '강원특별자치도 태백시 중앙로 1', '오프라인 가맹점', NOW(), NOW());

INSERT INTO online_malls (id, region_id, name, mall_url, description, created_at, updated_at) VALUES
(1, 1, '완도 샘플 온라인몰', 'https://example.com/wando', '특산물 온라인몰 샘플 링크', NOW(), NOW()),
(2, 2, '강진 샘플 온라인몰', 'https://example.com/gangjin', 'TODO: 실제 온라인몰 연동 예정', NOW(), NOW()),
(3, 3, '태백 샘플 온라인몰', 'https://example.com/taebaek', '특산물 온라인몰 샘플 링크', NOW(), NOW());

INSERT INTO trips (id, user_id, region_id, applicant_name, phone_number, residence, start_date, end_date, status, refund_condition_amount, total_spent_amount, settlement_applied, settlement_applied_at, created_at, updated_at) VALUES
(1, 1, 1, '샘플 사용자', '010-1234-5678', '전라남도', '2026-04-20', '2026-04-26', 'TRAVELING', 200000, 120000, b'0', NULL, NOW(), NOW()),
(2, 1, 2, '샘플 사용자', '010-1234-5678', '전라남도', '2026-04-01', '2026-04-05', 'SETTLEMENT_READY', 150000, 150000, b'1', NOW(), NOW(), NOW());

INSERT INTO trip_places (id, trip_id, place_type, reference_place_id, place_name, address, visit_order, latitude, longitude, checked, created_at, updated_at) VALUES
(1, 1, 'HALF_PRICE', 1, '완도 샘플 해변', '전라남도 완도군 샘플해변로 1', 1, 34.3180, 126.7590, b'1', NOW(), NOW()),
(2, 1, 'DIGITAL_TOUR_CARD', 1, '완도 샘플 카페', '전라남도 완도군 카페거리 10', 2, 34.3172, 126.7574, b'1', NOW(), NOW());

INSERT INTO user_favorite_regions (id, user_id, region_id, created_at, updated_at) VALUES
(1, 1, 1, NOW(), NOW()),
(2, 1, 2, NOW(), NOW());
