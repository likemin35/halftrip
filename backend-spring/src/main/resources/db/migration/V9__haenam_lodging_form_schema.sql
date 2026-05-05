UPDATE lodging_form_templates
SET template_schema_json = '[
  {"key":"traveler_name","type":"text","x":24.5,"y":12.3,"width":25.5,"height":5.4,"editable":true,"multiline":false},
  {"key":"traveler_phone_number","type":"text","x":69.0,"y":12.3,"width":17.0,"height":5.4,"editable":true,"multiline":false},
  {"key":"address","type":"text","x":24.5,"y":22.0,"width":61.0,"height":5.8,"editable":true,"multiline":false},
  {"key":"lodging_name","type":"text","x":24.5,"y":31.6,"width":61.0,"height":5.8,"editable":true,"multiline":false},
  {"key":"trip_date_range","type":"text","x":24.5,"y":41.3,"width":24.5,"height":5.8,"editable":true,"multiline":false},
  {"key":"payment_amount","type":"text","x":69.2,"y":41.3,"width":12.8,"height":5.8,"editable":true,"multiline":false},
  {"key":"payment_date","type":"text","x":58.5,"y":57.6,"width":25.0,"height":4.6,"editable":true,"multiline":false},
  {"key":"lodging_name","type":"text","x":62.5,"y":86.8,"width":18.8,"height":2.7,"editable":true,"multiline":false},
  {"key":"address","type":"text","x":62.5,"y":89.8,"width":19.8,"height":2.7,"editable":true,"multiline":false},
  {"key":"representative_name","type":"text","x":62.5,"y":92.8,"width":17.0,"height":2.7,"editable":true,"multiline":false},
  {"key":"signature","type":"signature","x":81.6,"y":90.6,"width":10.4,"height":6.8,"editable":true,"multiline":false}
]',
    data_source_note = 'MANUAL_TEMPLATE',
    preview_subtitle = '실제 해남 PDF 양식 기준 수동 좌표를 사용합니다. 칸을 눌러 바로 입력하고 최종 PDF를 내려받으세요.',
    updated_at = NOW()
WHERE region_id = 4;
