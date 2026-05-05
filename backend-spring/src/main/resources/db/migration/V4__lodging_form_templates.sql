CREATE TABLE lodging_form_templates (
    id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    region_id BIGINT NOT NULL,
    template_key VARCHAR(80) NOT NULL,
    template_name VARCHAR(150) NOT NULL,
    source_format VARCHAR(40) NOT NULL DEFAULT 'PDF_PLACEHOLDER',
    source_file_path VARCHAR(255) NULL,
    render_asset_path VARCHAR(255) NULL,
    preview_title VARCHAR(120) NOT NULL,
    preview_subtitle VARCHAR(255) NULL,
    template_schema_json LONGTEXT NOT NULL,
    data_source_note VARCHAR(40) NOT NULL DEFAULT 'SAMPLE_SEED',
    is_active BIT NOT NULL DEFAULT b'1',
    created_at DATETIME NOT NULL,
    updated_at DATETIME NOT NULL,
    CONSTRAINT fk_lodging_form_templates_region
        FOREIGN KEY (region_id) REFERENCES regions (id),
    CONSTRAINT uk_lodging_form_templates_region UNIQUE (region_id),
    CONSTRAINT uk_lodging_form_templates_key UNIQUE (template_key)
);

CREATE TABLE lodging_form_instances (
    id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    trip_id BIGINT NOT NULL,
    template_id BIGINT NOT NULL,
    template_snapshot_json LONGTEXT NOT NULL,
    payload_json LONGTEXT NOT NULL,
    status VARCHAR(40) NOT NULL DEFAULT 'DRAFT',
    rendered_pdf_file_name VARCHAR(255) NULL,
    last_rendered_at DATETIME NULL,
    created_at DATETIME NOT NULL,
    updated_at DATETIME NOT NULL,
    CONSTRAINT fk_lodging_form_instances_trip
        FOREIGN KEY (trip_id) REFERENCES trips (id),
    CONSTRAINT fk_lodging_form_instances_template
        FOREIGN KEY (template_id) REFERENCES lodging_form_templates (id),
    CONSTRAINT uk_lodging_form_instances_trip UNIQUE (trip_id)
);

INSERT INTO lodging_form_templates (
    region_id,
    template_key,
    template_name,
    source_format,
    preview_title,
    preview_subtitle,
    template_schema_json,
    data_source_note,
    is_active,
    created_at,
    updated_at
)
SELECT
    id,
    CONCAT('region-', id, '-lodging-form'),
    CONCAT('regional_lodging_confirmation_', id, '.pdf'),
    'PDF_PLACEHOLDER',
    '숙박확인서',
    '실제 지역별 PDF/HWP 원본 수신 전까지 공통 레이아웃으로 동작합니다.',
    '[{"key":"traveler_name","type":"text","x":8,"y":12,"width":24,"height":8,"editable":false,"multiline":false},{"key":"traveler_phone_number","type":"text","x":36,"y":12,"width":24,"height":8,"editable":false,"multiline":false},{"key":"region_name","type":"text","x":64,"y":12,"width":28,"height":8,"editable":false,"multiline":false},{"key":"trip_date_range","type":"text","x":8,"y":24,"width":40,"height":8,"editable":false,"multiline":false},{"key":"residence","type":"text","x":52,"y":24,"width":40,"height":8,"editable":false,"multiline":false},{"key":"lodging_name","type":"text","x":8,"y":40,"width":84,"height":8,"editable":true,"multiline":false},{"key":"representative_name","type":"text","x":8,"y":52,"width":38,"height":8,"editable":true,"multiline":false},{"key":"phone_number","type":"text","x":54,"y":52,"width":38,"height":8,"editable":true,"multiline":false},{"key":"address","type":"text","x":8,"y":64,"width":84,"height":12,"editable":true,"multiline":true},{"key":"agreed_personal_info","type":"checkbox","x":8,"y":80,"width":40,"height":6,"editable":true,"multiline":false},{"key":"agreed_stay_proof","type":"checkbox","x":52,"y":80,"width":40,"height":6,"editable":true,"multiline":false},{"key":"signature","type":"signature","x":58,"y":88,"width":34,"height":10,"editable":true,"multiline":false}]',
    'SAMPLE_SEED',
    b'1',
    NOW(),
    NOW()
FROM regions
WHERE NOT EXISTS (
    SELECT 1
    FROM lodging_form_templates existing
    WHERE existing.region_id = regions.id
);
