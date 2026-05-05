UPDATE regions
SET mock_budget_remaining = CASE name
    WHEN '완도' THEN 82
    WHEN '강진' THEN 43
    WHEN '평창' THEN 76
    WHEN '해남' THEN 58
    WHEN '영광' THEN 67
    WHEN '횡성' THEN 71
    WHEN '영월' THEN 39
    WHEN '제천' THEN 52
    WHEN '거창' THEN 47
    WHEN '고창' THEN 28
    WHEN '영암' THEN 64
    WHEN '합천' THEN 74
    WHEN '밀양' THEN 36
    WHEN '하동' THEN 54
    WHEN '남해' THEN 88
    WHEN '고흥' THEN 41
    ELSE mock_budget_remaining
END,
updated_at = NOW()
WHERE name IN (
    '완도', '강진', '평창', '해남', '영광', '횡성', '영월', '제천',
    '거창', '고창', '영암', '합천', '밀양', '하동', '남해', '고흥'
);
