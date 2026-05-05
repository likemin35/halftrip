UPDATE lodging_form_templates
SET template_schema_json = '[
  {"key":"traveler_name","label":"고객명(여행대표자)","helperText":"여행 대표자 성명을 입력하세요.","type":"text","x":22.0,"y":14.8,"width":16.8,"height":2.8,"editable":true,"multiline":false},
  {"key":"traveler_phone_number","label":"연락처(핸드폰)","helperText":"휴대전화 번호를 입력하세요.","type":"text","x":72.8,"y":14.8,"width":12.2,"height":2.8,"editable":true,"multiline":false},
  {"key":"address","label":"주소","helperText":"숙박업소 주소를 입력하세요.","type":"text","x":22.2,"y":25.8,"width":65.8,"height":3.2,"editable":true,"multiline":false},
  {"key":"lodging_name","label":"숙박업소명","helperText":"숙박업소명을 입력하세요.","type":"text","x":22.2,"y":36.2,"width":65.8,"height":3.2,"editable":true,"multiline":false},
  {"key":"trip_date_range","label":"숙박기간","helperText":"예: 2026-04-26 ~ 2026-04-28","type":"text","x":19.0,"y":50.1,"width":12.8,"height":2.8,"editable":true,"multiline":false},
  {"key":"payment_amount","label":"실제결제금액","helperText":"숫자만 입력하세요.","type":"text","x":75.4,"y":50.1,"width":9.4,"height":2.8,"editable":true,"multiline":false},
  {"key":"confirmation_date","label":"확인일자","helperText":"예: 2026년 4월 26일","type":"text","x":70.0,"y":63.8,"width":14.8,"height":2.6,"editable":true,"multiline":false},
  {"key":"applicant_signature","label":"신청인 서명","helperText":"신청인 서명 또는 인을 입력하세요.","type":"signature","x":75.0,"y":70.8,"width":11.8,"height":4.6,"editable":true,"multiline":false},
  {"key":"confirmation_date","label":"확인일자","helperText":"아래 확인란에도 동일하게 표시됩니다.","type":"text","x":70.0,"y":91.5,"width":14.8,"height":2.6,"editable":false,"multiline":false},
  {"key":"lodging_name","label":"숙박업소명","helperText":"하단 확인영역에도 동일하게 표시됩니다.","type":"text","x":67.2,"y":102.7,"width":12.4,"height":2.0,"editable":false,"multiline":false},
  {"key":"address","label":"주소","helperText":"하단 확인영역에도 동일하게 표시됩니다.","type":"text","x":67.2,"y":105.8,"width":12.4,"height":2.0,"editable":false,"multiline":false},
  {"key":"representative_name","label":"대표자","helperText":"숙박업소 대표자명을 입력하세요.","type":"text","x":67.2,"y":108.8,"width":10.6,"height":2.0,"editable":true,"multiline":false},
  {"key":"host_signature","label":"대표자 확인","helperText":"숙박업소 대표 확인 서명 또는 인을 입력하세요.","type":"signature","x":83.8,"y":108.0,"width":7.2,"height":4.8,"editable":true,"multiline":false}
]',
    data_source_note = 'MANUAL_TEMPLATE_HAENAM_V5',
    preview_subtitle = '해남 원본 PDF 고정 양식 기준 수동 좌표 V5입니다.',
    updated_at = NOW()
WHERE region_id = 4;
