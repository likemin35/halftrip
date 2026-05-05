UPDATE regions
SET half_price_apply_url = 'https://tour.pc.go.kr/Home/index',
    digital_tour_card_apply_url = 'https://tour.pc.go.kr/Home/index',
    updated_at = NOW()
WHERE name = '평창';

UPDATE regions
SET half_price_apply_url = '',
    digital_tour_card_apply_url = '',
    updated_at = NOW()
WHERE name = '횡성';

UPDATE regions
SET half_price_apply_url = 'https://geochangtour.kr/bbs/apply_date.php',
    digital_tour_card_apply_url = 'https://geochangtour.kr/bbs/apply_date.php',
    updated_at = NOW()
WHERE name = '거창';

UPDATE regions
SET half_price_apply_url = 'https://halftour.kr/bbs/apply_date.php',
    digital_tour_card_apply_url = 'https://halftour.kr/bbs/apply_date.php',
    updated_at = NOW()
WHERE name = '영월';

UPDATE regions
SET half_price_apply_url = 'https://www.jctour.kr/menu2/1',
    digital_tour_card_apply_url = 'https://www.jctour.kr/menu2/1',
    updated_at = NOW()
WHERE name = '제천';

UPDATE regions
SET half_price_apply_url = 'https://gochangtrip.co.kr/bbs/apply_date.php',
    digital_tour_card_apply_url = 'https://gochangtrip.co.kr/bbs/apply_date.php',
    updated_at = NOW()
WHERE name = '고창';

UPDATE regions
SET half_price_apply_url = 'https://hctour.kr/bbs/content.php?co_id=participation_info',
    digital_tour_card_apply_url = 'https://hctour.kr/bbs/content.php?co_id=participation_info',
    updated_at = NOW()
WHERE name = '합천';

UPDATE regions
SET half_price_apply_url = 'https://www.yeonggwang.go.kr/subpage/?site=travel&mn=16103',
    digital_tour_card_apply_url = 'https://www.yeonggwang.go.kr/subpage/?site=travel&mn=16103',
    updated_at = NOW()
WHERE name = '영광';

UPDATE regions
SET half_price_apply_url = 'https://mybanhada.com/apply/detail',
    digital_tour_card_apply_url = 'https://mybanhada.com/apply/detail',
    updated_at = NOW()
WHERE name = '밀양';

UPDATE regions
SET half_price_apply_url = 'https://www.yeongam.go.kr/oneplusone',
    digital_tour_card_apply_url = 'https://www.yeongam.go.kr/oneplusone',
    updated_at = NOW()
WHERE name = '영암';

UPDATE regions
SET half_price_apply_url = 'https://hadongtrip.kr/bbs/login.php?url=https%3A%2F%2Fhadongtrip.kr%2Fapplication%2Forder_step1.php',
    digital_tour_card_apply_url = 'https://hadongtrip.kr/bbs/login.php?url=https%3A%2F%2Fhadongtrip.kr%2Fapplication%2Forder_step1.php',
    updated_at = NOW()
WHERE name = '하동';

UPDATE regions
SET half_price_apply_url = 'https://www.gangjintour.com/advance/advance_req.html?',
    digital_tour_card_apply_url = 'https://www.gangjintour.com/advance/advance_req.html?',
    updated_at = NOW()
WHERE name = '강진';

UPDATE regions
SET half_price_apply_url = 'https://www.namhae.go.kr/tour/main.web',
    digital_tour_card_apply_url = 'https://www.namhae.go.kr/tour/main.web',
    updated_at = NOW()
WHERE name = '남해';

UPDATE regions
SET half_price_apply_url = 'https://www.haenam50.kr/index',
    digital_tour_card_apply_url = 'https://www.haenam50.kr/index',
    updated_at = NOW()
WHERE name = '해남';

UPDATE regions
SET half_price_apply_url = 'https://tour.goheung.go.kr/front/M0000362/rsvh/list.do',
    digital_tour_card_apply_url = 'https://tour.goheung.go.kr/front/M0000362/rsvh/list.do',
    updated_at = NOW()
WHERE name = '고흥';
