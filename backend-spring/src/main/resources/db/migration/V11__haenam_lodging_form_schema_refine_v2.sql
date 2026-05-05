UPDATE lodging_form_templates
SET template_schema_json = '[
  {"key":"traveler_name","label":"고객명(여행대표자)","helperText":"여행 대표자 성명을 입력하세요.","type":"text","x":17.2,"y":11.0,"width":24.4,"height":4.0,"editable":true,"multiline":false},
  {"key":"traveler_phone_number","label":"연락처(핸드폰)","helperText":"휴대전화 번호를 입력하세요.","type":"text","x":73.4,"y":11.0,"width":14.6,"height":4.0,"editable":true,"multiline":false},
  {"key":"address","label":"주소","helperText":"숙박업소 주소를 입력하세요.","type":"text","x":17.2,"y":21.1,"width":70.8,"height":4.4,"editable":true,"multiline":false},
  {"key":"lodging_name","label":"숙박업소명","helperText":"숙박업소명을 입력하세요.","type":"text","x":17.2,"y":31.6,"width":70.8,"height":4.4,"editable":true,"multiline":false},
  {"key":"trip_date_range","label":"숙박기간","helperText":"예: 2026-04-26 ~ 2026-04-28","type":"text","x":17.4,"y":42.2,"width":28.5,"height":4.4,"editable":true,"multiline":false},
  {"key":"payment_amount","label":"실제결제금액","helperText":"숫자만 입력하세요.","type":"text","x":73.2,"y":42.2,"width":11.5,"height":4.4,"editable":true,"multiline":false},
  {"key":"confirmation_date","label":"확인일자","helperText":"예: 2026년 4월 26일","type":"text","x":66.5,"y":56.0,"width":18.5,"height":3.2,"editable":true,"multiline":false},
  {"key":"applicant_signature","label":"신청인 서명","helperText":"신청인 서명 또는 인을 입력하세요.","type":"signature","x":75.4,"y":63.1,"width":12.5,"height":5.0,"editable":true,"multiline":false},
  {"key":"confirmation_date","label":"확인일자","helperText":"아래 확인란에도 동일하게 표시됩니다.","type":"text","x":66.5,"y":81.6,"width":18.5,"height":3.2,"editable":false,"multiline":false},
  {"key":"lodging_name","label":"숙박업소명","helperText":"하단 확인영역에도 동일하게 표시됩니다.","type":"text","x":61.4,"y":90.4,"width":18.6,"height":2.4,"editable":false,"multiline":false},
  {"key":"address","label":"주소","helperText":"하단 확인영역에도 동일하게 표시됩니다.","type":"text","x":61.4,"y":93.3,"width":18.6,"height":2.4,"editable":false,"multiline":false},
  {"key":"representative_name","label":"대표자","helperText":"숙박업소 대표자명을 입력하세요.","type":"text","x":61.4,"y":96.2,"width":14.6,"height":2.4,"editable":true,"multiline":false},
  {"key":"host_signature","label":"대표자 확인","helperText":"숙박업소 대표 확인 서명 또는 인을 입력하세요.","type":"signature","x":82.0,"y":95.1,"width":8.8,"height":5.5,"editable":true,"multiline":false}
]',
    data_source_note = 'MANUAL_TEMPLATE_HAENAM_V3',
    preview_subtitle = '해남 원본 PDF 고정 양식 기준 수동 좌표 V3입니다.',
    updated_at = NOW()
WHERE region_id = 4;
