UPDATE lodging_form_templates
SET template_schema_json = '[
  {"key":"traveler_name","label":"고객명(여행대표자)","helperText":"여행 대표자 성명을 입력하세요.","type":"text","x":18.4,"y":10.1,"width":26.6,"height":4.8,"editable":true,"multiline":false},
  {"key":"traveler_phone_number","label":"연락처(핸드폰)","helperText":"휴대전화 번호를 입력하세요.","type":"text","x":69.0,"y":10.1,"width":18.0,"height":4.8,"editable":true,"multiline":false},
  {"key":"address","label":"주소","helperText":"숙박업소 주소를 입력하세요.","type":"text","x":18.4,"y":20.8,"width":68.8,"height":4.9,"editable":true,"multiline":false},
  {"key":"lodging_name","label":"숙박업소명","helperText":"숙박업소명을 입력하세요.","type":"text","x":18.4,"y":31.0,"width":68.8,"height":4.9,"editable":true,"multiline":false},
  {"key":"trip_date_range","label":"숙박기간","helperText":"예: 2026-04-26 ~ 2026-04-28","type":"text","x":18.4,"y":41.5,"width":25.2,"height":5.0,"editable":true,"multiline":false},
  {"key":"payment_amount","label":"실제결제금액","helperText":"숫자만 입력하세요.","type":"text","x":69.0,"y":41.5,"width":16.8,"height":5.0,"editable":true,"multiline":false},
  {"key":"confirmation_date","label":"확인일자","helperText":"예: 2026년 4월 26일","type":"text","x":63.8,"y":55.8,"width":20.0,"height":3.8,"editable":true,"multiline":false},
  {"key":"applicant_signature","label":"신청인 서명","helperText":"신청인 서명 또는 인을 입력하세요.","type":"signature","x":71.5,"y":61.8,"width":15.0,"height":5.8,"editable":true,"multiline":false},
  {"key":"lodging_name","label":"숙박업소명","helperText":"하단 확인영역에도 동일하게 표시됩니다.","type":"text","x":61.8,"y":87.0,"width":20.2,"height":2.5,"editable":false,"multiline":false},
  {"key":"address","label":"주소","helperText":"하단 확인영역에도 동일하게 표시됩니다.","type":"text","x":61.8,"y":90.0,"width":20.2,"height":2.5,"editable":false,"multiline":false},
  {"key":"representative_name","label":"대표자","helperText":"숙박업소 대표자명을 입력하세요.","type":"text","x":61.8,"y":93.0,"width":16.4,"height":2.5,"editable":true,"multiline":false},
  {"key":"host_signature","label":"대표자 확인","helperText":"숙박업소 대표 확인 서명 또는 인을 입력하세요.","type":"signature","x":83.2,"y":91.2,"width":10.0,"height":6.2,"editable":true,"multiline":false}
]',
    data_source_note = 'MANUAL_TEMPLATE_HAENAM_V2',
    preview_subtitle = '해남 원본 PDF 고정 양식 기준 수동 좌표입니다. 지역별 PDF는 이 방식으로 각각 따로 맞춥니다.',
    updated_at = NOW()
WHERE region_id = 4;
