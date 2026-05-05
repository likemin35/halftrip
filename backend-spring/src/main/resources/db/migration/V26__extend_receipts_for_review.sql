ALTER TABLE receipts
    ADD COLUMN usage_scope VARCHAR(30) NOT NULL DEFAULT 'GENERAL' AFTER payment_type,
    ADD COLUMN review_status VARCHAR(30) NOT NULL DEFAULT 'PENDING' AFTER usage_scope,
    ADD COLUMN eligible_amount INT NOT NULL DEFAULT 0 AFTER amount,
    ADD COLUMN review_reason VARCHAR(255) NULL AFTER eligible_amount;

UPDATE receipts
SET usage_scope = 'GENERAL',
    review_status = CASE
        WHEN payment_type IN ('CREDIT_CARD', 'CHECK_CARD', 'ONLINE_PAYMENT') THEN 'APPROVED'
        ELSE 'REJECTED'
    END,
    eligible_amount = CASE
        WHEN payment_type IN ('CREDIT_CARD', 'CHECK_CARD', 'ONLINE_PAYMENT') THEN COALESCE(amount, 0)
        ELSE 0
    END,
    review_reason = CASE
        WHEN payment_type IN ('CREDIT_CARD', 'CHECK_CARD', 'ONLINE_PAYMENT')
            THEN '기존 영수증 데이터를 기본 승인 규칙으로 이관했습니다.'
        ELSE '기존 영수증 데이터를 기본 비승인 규칙으로 이관했습니다.'
    END;
