UPDATE lodging_form_templates
SET render_asset_path = 'templates/lodging_forms/rendered/stay_confirm_wando.pdf',
    updated_at = NOW()
WHERE region_id = 1;

UPDATE lodging_form_templates
SET render_asset_path = 'templates/lodging_forms/rendered/stay_confirm_gangjin.pdf',
    updated_at = NOW()
WHERE region_id = 2;

UPDATE lodging_form_templates
SET render_asset_path = 'templates/lodging_forms/rendered/stay_confirm_pyoungchang.pdf',
    updated_at = NOW()
WHERE region_id = 3;

UPDATE lodging_form_templates
SET render_asset_path = 'templates/lodging_forms/rendered/stay_confirm_haenam.pdf',
    updated_at = NOW()
WHERE region_id = 4;

UPDATE lodging_form_templates
SET render_asset_path = 'templates/lodging_forms/rendered/stay_confirm_yeonggwang.pdf',
    updated_at = NOW()
WHERE region_id = 5;

UPDATE lodging_form_templates
SET render_asset_path = 'templates/lodging_forms/rendered/stay_confirm_geochang.pdf',
    updated_at = NOW()
WHERE region_id = 9;

UPDATE lodging_form_templates
SET render_asset_path = 'templates/lodging_forms/rendered/stay_confirm_gochang.pdf',
    updated_at = NOW()
WHERE region_id = 10;

UPDATE lodging_form_templates
SET render_asset_path = 'templates/lodging_forms/rendered/stay_confirm_yeongam.pdf',
    updated_at = NOW()
WHERE region_id = 11;

UPDATE lodging_form_templates
SET render_asset_path = 'templates/lodging_forms/rendered/stay_confirm_hapcheon.pdf',
    updated_at = NOW()
WHERE region_id = 12;

UPDATE lodging_form_templates
SET render_asset_path = 'templates/lodging_forms/rendered/stay_confirm_milyang.pdf',
    updated_at = NOW()
WHERE region_id = 13;

UPDATE lodging_form_templates
SET render_asset_path = 'templates/lodging_forms/rendered/stay_confirm_hadong.pdf',
    updated_at = NOW()
WHERE region_id = 14;

UPDATE lodging_form_templates
SET render_asset_path = 'templates/lodging_forms/rendered/stay_confirm_namhae.pdf',
    updated_at = NOW()
WHERE region_id = 15;

UPDATE lodging_form_templates
SET render_asset_path = NULL,
    updated_at = NOW()
WHERE region_id IN (6, 7, 8, 16);
