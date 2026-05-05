-- Fixed PDF coordinate templates for user-provided lodging confirmation PDFs.
-- x/y/width/height are PDF-space coordinates based on a 720 x 1018 page,
-- not percentage values. Flutter and FastAPI scale these coordinates to the
-- rendered preview/final PDF size.

SET @simple_lodging_schema = '[
  {"key":"traveler_name","label":"Traveler name","helperText":"Traveler name","type":"text","x":190,"y":128,"width":185,"height":36,"editable":true,"multiline":false},
  {"key":"traveler_phone_number","label":"Traveler phone","helperText":"Traveler phone","type":"text","x":485,"y":128,"width":135,"height":36,"editable":true,"multiline":false},
  {"key":"address","label":"Traveler address","helperText":"Traveler address","type":"text","x":190,"y":222,"width":430,"height":48,"editable":true,"multiline":false},
  {"key":"lodging_name","label":"Lodging name","helperText":"Lodging name","type":"text","x":190,"y":315,"width":430,"height":48,"editable":true,"multiline":false},
  {"key":"trip_date_range","label":"Stay period","helperText":"Stay period","type":"text","x":190,"y":407,"width":205,"height":42,"editable":true,"multiline":false},
  {"key":"payment_amount","label":"Payment amount","helperText":"Payment amount","type":"text","x":520,"y":407,"width":92,"height":42,"editable":true,"multiline":false},
  {"key":"confirmation_date","label":"Confirmation date","helperText":"Confirmation date","type":"text","x":430,"y":552,"width":185,"height":34,"editable":true,"multiline":false},
  {"key":"applicant_signature","label":"Applicant signature","helperText":"Applicant signature","type":"signature","x":570,"y":625,"width":80,"height":48,"editable":true,"multiline":false},
  {"key":"confirmation_date_bottom","label":"Bottom confirmation date","helperText":"Bottom confirmation date","type":"text","x":430,"y":850,"width":185,"height":34,"editable":false,"multiline":false},
  {"key":"lodging_name_bottom","label":"Bottom lodging name","helperText":"Bottom lodging name","type":"text","x":430,"y":915,"width":150,"height":24,"editable":false,"multiline":false},
  {"key":"address_bottom","label":"Bottom lodging address","helperText":"Bottom lodging address","type":"text","x":430,"y":946,"width":150,"height":24,"editable":false,"multiline":false},
  {"key":"representative_name","label":"Representative","helperText":"Representative name","type":"text","x":430,"y":976,"width":125,"height":24,"editable":true,"multiline":false},
  {"key":"host_signature","label":"Host signature","helperText":"Host signature","type":"signature","x":575,"y":962,"width":70,"height":48,"editable":true,"multiline":false}
]';

SET @three_section_schema = '[
  {"key":"lodging_name","label":"Lodging name","helperText":"Lodging name","type":"text","x":214,"y":142,"width":409,"height":31,"editable":true,"multiline":false},
  {"key":"address","label":"Lodging address","helperText":"Lodging address","type":"text","x":214,"y":179,"width":409,"height":31,"editable":true,"multiline":false},
  {"key":"representative_name","label":"Representative","helperText":"Representative name","type":"text","x":214,"y":216,"width":348,"height":31,"editable":true,"multiline":false},
  {"key":"host_signature","label":"Representative signature","helperText":"Representative signature","type":"signature","x":572,"y":216,"width":54,"height":31,"editable":true,"multiline":false},
  {"key":"phone_number","label":"Representative phone","helperText":"Representative phone","type":"text","x":214,"y":253,"width":409,"height":31,"editable":true,"multiline":false},
  {"key":"agreed_personal_info_yes","label":"Top agree","helperText":"Top agree checkbox","type":"checkbox","x":419,"y":315,"width":14,"height":14,"editable":true,"multiline":false},
  {"key":"agreed_personal_info_no","label":"Top disagree","helperText":"Top disagree checkbox","type":"checkbox","x":488,"y":315,"width":14,"height":14,"editable":true,"multiline":false},
  {"key":"traveler_name","label":"Guest name","helperText":"Guest name","type":"text","x":214,"y":392,"width":409,"height":31,"editable":true,"multiline":false},
  {"key":"traveler_phone_number","label":"Guest phone","helperText":"Guest phone","type":"text","x":214,"y":429,"width":409,"height":31,"editable":true,"multiline":false},
  {"key":"residence","label":"Residence","helperText":"Residence","type":"text","x":214,"y":466,"width":409,"height":31,"editable":true,"multiline":false},
  {"key":"trip_date_range","label":"Stay period","helperText":"Stay period","type":"text","x":214,"y":562,"width":235,"height":31,"editable":true,"multiline":false},
  {"key":"occupancy_count","label":"Guest count","helperText":"Guest count","type":"text","x":520,"y":599,"width":62,"height":31,"editable":true,"multiline":false},
  {"key":"payment_amount","label":"Payment amount","helperText":"Payment amount","type":"text","x":395,"y":636,"width":185,"height":31,"editable":true,"multiline":false},
  {"key":"payment_method_lodging_app","label":"Lodging app","helperText":"Lodging app payment","type":"checkbox","x":260,"y":673,"width":14,"height":14,"editable":true,"multiline":false},
  {"key":"payment_method_card","label":"Card","helperText":"Card payment","type":"checkbox","x":342,"y":673,"width":14,"height":14,"editable":true,"multiline":false},
  {"key":"payment_method_other","label":"Other","helperText":"Other payment","type":"checkbox","x":486,"y":673,"width":14,"height":14,"editable":true,"multiline":false},
  {"key":"payment_method_other_text","label":"Other payment text","helperText":"Other payment text","type":"text","x":542,"y":664,"width":80,"height":28,"editable":true,"multiline":false},
  {"key":"payment_date","label":"Payment date","helperText":"Payment date","type":"text","x":323,"y":710,"width":250,"height":31,"editable":true,"multiline":false},
  {"key":"agreed_stay_proof_yes","label":"Bottom agree","helperText":"Bottom agree checkbox","type":"checkbox","x":205,"y":790,"width":14,"height":14,"editable":true,"multiline":false},
  {"key":"agreed_stay_proof_no","label":"Bottom disagree","helperText":"Bottom disagree checkbox","type":"checkbox","x":276,"y":790,"width":14,"height":14,"editable":true,"multiline":false}
]';

SET @pyeongchang_schema = '[
  {"key":"lodging_name","label":"Lodging name","helperText":"Lodging name","type":"text","x":214,"y":134,"width":409,"height":28,"editable":true,"multiline":false},
  {"key":"business_number","label":"Business number","helperText":"Business number","type":"text","x":214,"y":169,"width":409,"height":28,"editable":true,"multiline":false},
  {"key":"address","label":"Lodging address","helperText":"Lodging address","type":"text","x":214,"y":204,"width":409,"height":28,"editable":true,"multiline":false},
  {"key":"representative_name","label":"Representative","helperText":"Representative name","type":"text","x":214,"y":239,"width":348,"height":28,"editable":true,"multiline":false},
  {"key":"host_signature","label":"Host signature","helperText":"Host signature","type":"signature","x":560,"y":239,"width":70,"height":28,"editable":true,"multiline":false},
  {"key":"phone_number","label":"Phone","helperText":"Phone","type":"text","x":214,"y":274,"width":409,"height":28,"editable":true,"multiline":false},
  {"key":"traveler_name","label":"Guest name","helperText":"Guest name","type":"text","x":214,"y":392,"width":409,"height":28,"editable":true,"multiline":false},
  {"key":"traveler_phone_number","label":"Guest phone","helperText":"Guest phone","type":"text","x":214,"y":429,"width":409,"height":28,"editable":true,"multiline":false},
  {"key":"residence","label":"Residence","helperText":"Residence","type":"text","x":214,"y":466,"width":409,"height":28,"editable":true,"multiline":false},
  {"key":"trip_date_range","label":"Stay period","helperText":"Stay period","type":"text","x":214,"y":580,"width":250,"height":28,"editable":true,"multiline":false},
  {"key":"occupancy_count","label":"Guest count","helperText":"Guest count","type":"text","x":520,"y":617,"width":62,"height":28,"editable":true,"multiline":false},
  {"key":"payment_amount","label":"Payment amount","helperText":"Payment amount","type":"text","x":395,"y":653,"width":185,"height":28,"editable":true,"multiline":false},
  {"key":"payment_date","label":"Payment date","helperText":"Payment date","type":"text","x":323,"y":690,"width":250,"height":28,"editable":true,"multiline":false},
  {"key":"confirmation_date","label":"Confirmation date","helperText":"Confirmation date","type":"text","x":315,"y":810,"width":250,"height":28,"editable":true,"multiline":false},
  {"key":"applicant_signature","label":"Applicant signature","helperText":"Applicant signature","type":"signature","x":565,"y":875,"width":70,"height":30,"editable":true,"multiline":false}
]';

UPDATE lodging_form_templates
SET
    template_schema_json = @simple_lodging_schema,
    data_source_note = 'MANUAL_TEMPLATE_SIMPLE_FIXED',
    preview_subtitle = 'Fixed PDF coordinate template for the simple lodging confirmation form.',
    updated_at = NOW()
WHERE region_id IN (2, 4, 11, 13, 14, 15);

UPDATE lodging_form_templates
SET
    template_schema_json = @three_section_schema,
    data_source_note = 'MANUAL_TEMPLATE_THREE_SECTION',
    preview_subtitle = 'Fixed PDF coordinate template for the three-section lodging confirmation form.',
    updated_at = NOW()
WHERE region_id IN (5, 9, 10, 12);

UPDATE lodging_form_templates
SET
    template_schema_json = @pyeongchang_schema,
    data_source_note = 'MANUAL_TEMPLATE_PYEONGCHANG',
    preview_subtitle = 'Fixed PDF coordinate template for the Pyeongchang lodging confirmation form.',
    updated_at = NOW()
WHERE region_id = 3;
