class RegionRuleSection {
  const RegionRuleSection({
    required this.title,
    required this.bullets,
  });

  final String title;
  final List<String> bullets;
}

class RegionSettlementGuide {
  const RegionSettlementGuide({
    required this.summary,
    required this.deadline,
    required this.sections,
    this.note,
  });

  final String summary;
  final String deadline;
  final List<RegionRuleSection> sections;
  final String? note;
}

String settlementRuleSummary(String regionName) {
  return settlementGuideFor(regionName).summary;
}

String settlementRuleDeadline(String regionName) {
  return settlementGuideFor(regionName).deadline;
}

List<RegionRuleSection> settlementRuleSections(String regionName) {
  return settlementGuideFor(regionName).sections;
}

String? settlementRuleNote(String regionName) {
  return settlementGuideFor(regionName).note;
}

RegionSettlementGuide settlementGuideFor(String regionName) {
  return _guides[regionName] ?? _fallbackGuide;
}

const _fallbackGuide = RegionSettlementGuide(
  summary: '정산 규칙이 아직 정리되지 않았습니다.',
  deadline: '정산 규칙 업데이트 예정',
  sections: [
    RegionRuleSection(
      title: '안내',
      bullets: ['현재 지역별 정산 규칙을 정리 중입니다.'],
    ),
  ],
);

const Map<String, RegionSettlementGuide> _guides = {
  '평창': RegionSettlementGuide(
    summary: '7일 이내 신청, 유료 지정 관광지 1곳 이상 방문, 최소 10만 원 이상 소비가 필요합니다.',
    deadline: '여행 종료일로부터 7일 이내',
    sections: [
      RegionRuleSection(
        title: '관광지',
        bullets: [
          '유료 지정 관광지 1개소 이상 방문이 필수입니다.',
          '참여자 전체가 포함되고 관광지 랜드마크나 간판이 노출된 사진이 필요합니다.',
        ],
      ),
      RegionRuleSection(
        title: '경비',
        bullets: [
          '여행경비 총 소비금액은 최소 10만 원 이상이어야 합니다.',
          '모바일 평창사랑상품권 QR결제 또는 개인신용카드 결제만 인정됩니다.',
          '평창사랑상품권이라도 지류형 및 카드형 결제는 인정하지 않습니다.',
          '모바일 평창사랑상품권 QR결제 내역은 지역화폐 시스템을 통해 평창군이 직접 확인합니다.',
          '현금영수증, N Pay 같은 Pay결제, 간이영수증, 계좌이체 내역서는 인정되지 않습니다.',
          '주유소, 금은방, 카센터, 학원, 유흥업소, 골프장 결제는 제외됩니다.',
          '관광 소비 내역에 숙박비만 있는 경우 지원이 불가합니다.',
        ],
      ),
      RegionRuleSection(
        title: '숙박',
        bullets: [
          '숙박 시설 이용 시 숙박 이용 확인서를 제출해야 합니다.',
          '개별여행은 숙박요금 최대 10만 원까지만 소비금액으로 인정됩니다.',
          '2인 이상 단체여행은 숙박요금 최대 20만 원까지만 소비금액으로 인정됩니다.',
        ],
      ),
    ],
  ),
  '횡성': RegionSettlementGuide(
    summary: '현재 홈페이지가 아직 열리지 않았습니다.',
    deadline: '홈페이지 미오픈',
    sections: [
      RegionRuleSection(
        title: '안내',
        bullets: ['횡성 지역의 정산 규칙은 공식 홈페이지 오픈 후 확인 가능합니다.'],
      ),
    ],
  ),
  '영월': RegionSettlementGuide(
    summary: '15일 이내 신청, 최소 10만 원 이상 소비와 전통시장·지역화폐 조건이 함께 적용됩니다.',
    deadline: '여행 종료 다음 날부터 15일 이내',
    sections: [
      RegionRuleSection(
        title: '전통시장',
        bullets: ['전통시장 소비는 신용카드 지출 영수증으로 증빙합니다.'],
      ),
      RegionRuleSection(
        title: '경비',
        bullets: [
          '최소 소비 금액은 10만 원입니다.',
          '관내 전통시장 소비와 지역화폐 실물 카드 수령이 필요합니다.',
          '개인 신용카드, 체크카드, 지역화폐, 현금영수증을 인정합니다.',
          '계좌이체와 현금 결제는 지원 제외입니다.',
          '주유소, 카센터, 금은방, 보습학원, 유흥시설은 지원 제외 업종입니다.',
          '신청자 명의 지역화폐 실물 카드(영월별빛고운카드) 16자리 번호를 제출해야 합니다.',
        ],
      ),
      RegionRuleSection(
        title: '숙박',
        bullets: [
          '신청자 명의 신용카드 영수증이 필요합니다.',
          '온라인 숙박 예약사이트 이용 카드 결제 내역도 여행경비로 인정됩니다.',
          '참여자 전원 얼굴이 포함된 숙박시설 이용 전·후 인증사진을 제출해야 합니다.',
        ],
      ),
    ],
  ),
  '제천': RegionSettlementGuide(
    summary: '10일 이내 신청, 제천화폐가 우선이며 일반 카드 결제는 일부 분야만 인정됩니다.',
    deadline: '여행 종료 다음날부터 10일 이내 / 경비 사용 후 2주 이내 환급신청 인정',
    sections: [
      RegionRuleSection(
        title: '제천화폐',
        bullets: [
          '카드형 제천화폐와 모바일 제천화폐 결제는 시스템으로 직접 확인합니다.',
          '지류형 제천화폐 결제는 인정하지 않습니다.',
        ],
      ),
      RegionRuleSection(
        title: '일반 결제',
        bullets: [
          '숙박업 전체에서 일반 카드 결제를 인정하되 에어비앤비는 제외됩니다.',
          '케이블카(모노레일), 유람선(크루즈), 제천 시티투어, 관광택시, 가스트로투어 결제만 일반 카드 결제가 가능합니다.',
          '일반결제를 인정하는 분야 외 모든 결제는 카드형·모바일 제천화폐만 인정됩니다.',
          '가전·통신, 부동산, 자전거·자동차, 주유소, 학원·교육, 주방·가전·인테리어는 불인정 카테고리입니다.',
        ],
      ),
      RegionRuleSection(
        title: '숙박',
        bullets: [
          '카드 결제 영수증 또는 숙박 일정이 표기된 숙박 플랫폼 결제 내역을 제출해야 합니다.',
          '제천화폐 숙박 결제는 시스템으로 직접 확인합니다.',
        ],
      ),
    ],
  ),
  '거창': RegionSettlementGuide(
    summary: '10일 이내 신청, 지정 관광지 2곳 이상과 거창 정책발행용 상품권 사용이 핵심입니다.',
    deadline: '여행 종료 다음날부터 10일 이내 신청',
    sections: [
      RegionRuleSection(
        title: '관광지',
        bullets: [
          '거창군 지정 관광지 2개소 이상 방문 사진 인증이 필요합니다.',
          '신청대표자와 구성원 얼굴 모두 확인 가능한 사진을 제출해야 합니다.',
        ],
      ),
      RegionRuleSection(
        title: '경비',
        bullets: [
          '제로페이 가맹점 2개소 이상에서 모바일 거창반값여행 정책발행용 상품권 사용 영수증을 제출해야 합니다.',
          '최소 소비액은 10만 원 이상입니다.',
          '반드시 신청대표자 본인 명의의 증빙서류만 제출 가능합니다.',
          '모바일 거창반값여행 정책발행용 상품권 사용분만 환급 대상입니다.',
          '전자영수증 캡처본과 제로페이 시스템 결제 내역이 일치해야 합니다.',
          '개인카드와 현금 사용분은 불인정입니다.',
        ],
      ),
      RegionRuleSection(
        title: '숙박',
        bullets: [
          '신용카드와 현금영수증을 인정합니다.',
          '국세청에 신고되는 카드 결제 영수증, 현금영수증, 온라인 결제 영수증만 인정합니다.',
          '숙소명, 금액, 숙박일자가 반드시 기재되어야 합니다.',
          '숙박영수증, 숙박예약 또는 이용완료 내역, 숙박업소 이용 확인서를 함께 제출해야 합니다.',
        ],
      ),
    ],
  ),
  '고창': RegionSettlementGuide(
    summary: '7일 이내 신청, 관광지 2곳 이상 방문과 10만 원 이상 소비가 필요합니다.',
    deadline: '여행종료 다음날부터 7일 이내 신청',
    sections: [
      RegionRuleSection(
        title: '관광지',
        bullets: ['관내 관광지 2개소 이상 방문 사진이 필요합니다.'],
      ),
      RegionRuleSection(
        title: '경비',
        bullets: [
          '관내 소비금액 10만 원 이상 사용 영수증을 제출해야 합니다.',
          '개인 신용카드와 고창사랑카드 지출만 환급 대상입니다.',
          '고창사랑카드 사용 영수증 또는 모바일 영수증 캡처본을 제출해야 합니다.',
        ],
      ),
      RegionRuleSection(
        title: '숙박',
        bullets: [
          '인터넷 숙박 예약 결제 시 숙박완료 화면 캡처, 결제영수증, 숙박 확인증을 함께 제출해야 합니다.',
          '신청대표자 명의 결제만 인정됩니다.',
        ],
      ),
    ],
  ),
  '합천': RegionSettlementGuide(
    summary: '10일 이내 신청, 합천 모바일 상품권 사용과 지정 관광지 방문이 핵심입니다.',
    deadline: '여행 종료 다음날부터 10일 이내 신청',
    sections: [
      RegionRuleSection(
        title: '관광지',
        bullets: [
          '신청대표자와 구성원 얼굴 모두 나온 사진을 제출해야 합니다.',
        ],
      ),
      RegionRuleSection(
        title: '경비',
        bullets: [
          '합천군 관내 제로페이 가맹점 2개소 이상에서 모바일 합천반값여행 상품권 사용 인증이 필요합니다.',
          '최소 소비액은 5만 원 이상입니다.',
          '신청 대표자 휴대폰의 합천반값여행상품권 사용내역만 인정됩니다.',
          '모바일 합천반값여행 상품권 사용분만 환급 대상입니다.',
          '제로페이 사용앱(비플페이 등) 이용내역 영수증 캡처가 필요합니다.',
          '개인카드, 현금 사용분은 숙박을 제외하고 불인정입니다.',
        ],
      ),
      RegionRuleSection(
        title: '숙박',
        bullets: [
          '국세청에 신고되는 카드 결제 영수증, 현금영수증, 온라인 결제 영수증만 인정합니다.',
          '숙소명, 금액, 숙박일자가 반드시 기재되어야 합니다.',
          '결제영수증과 숙박이용 확인서를 함께 제출해야 합니다.',
        ],
      ),
    ],
  ),
  '영광': RegionSettlementGuide(
    summary: '7일 이내 신청, 관광지 2곳 방문과 대표자 명의 소비 증빙이 필요합니다.',
    deadline: '여행 종료 다음날부터 7일 이내 신청',
    sections: [
      RegionRuleSection(
        title: '관광지',
        bullets: [
          '영광 관광지 2개소 이상 방문사진이 필요합니다.',
          '반드시 신청대표자와 신청구성원 얼굴이 모두 나와야 합니다.',
          '관광지 사진은 영광군 문화관광 홈페이지에 게재된 관광지에 한정됩니다.',
        ],
      ),
      RegionRuleSection(
        title: '경비',
        bullets: [
          '총 합산 최소 10만 원 이상 지출 영수증이 필요합니다.',
          '신청 대표자 명의 카드 영수증을 인정합니다.',
          '신청 대표자 휴대폰번호가 기재된 현금 영수증을 인정합니다.',
          '신청 대표자 그리고 앱 또는 카드 거래내역 영수증을 인정합니다.',
          '법인·사업자·타인 명의 영수증은 인정하지 않습니다.',
          '연 매출 30억 원 이상 정책가맹점 결제비용은 지원 제외입니다.',
        ],
      ),
      RegionRuleSection(
        title: '숙박',
        bullets: [
          '숙소를 예약하여 선결제한 경우 숙소 이용완료 내역과 결제 영수증을 함께 제출해야 합니다.',
        ],
      ),
    ],
  ),
  '밀양': RegionSettlementGuide(
    summary: '10일 이내 신청, 지정 관광지 2곳 방문과 모바일 밀양사랑상품권 사용이 기본입니다.',
    deadline: '여행 종료 다음날부터 10일 이내 신청',
    sections: [
      RegionRuleSection(
        title: '관광지',
        bullets: [
          '지정관광지 2개소 이상 방문 사진이 필요합니다.',
          '여행 팀원 전원 얼굴과 장소가 식별 가능해야 하며 휴대폰 기본카메라 촬영본이어야 합니다.',
        ],
      ),
      RegionRuleSection(
        title: '경비',
        bullets: [
          '10만 원 이상 모바일 밀양사랑상품권(제로페이) 사용 영수증을 제출해야 합니다.',
          '신청 대표자 본인명의 휴대폰 제로페이 사용내역만 인증 가능합니다.',
          '카드영수증, 간이영수증, 계좌이체내역서는 증빙서류로 인정되지 않습니다.',
        ],
      ),
      RegionRuleSection(
        title: '숙박',
        bullets: [
          '인터넷 숙박 예약 결제 시 숙박완료 화면 캡처, 카드 결제 영수증, 숙소 이용 완료 내역서를 제출해야 합니다.',
          '여행기간이 4일(3박) 이상이면 숙박 이용이 필수입니다.',
          '전화 예약 후 현장 결제한 경우 모바일 밀양사랑상품권 결제건만 인정됩니다.',
        ],
      ),
    ],
  ),
  '영암': RegionSettlementGuide(
    summary: '14일 이내 신청, 관광지 1곳 방문과 개인/팀 기준 최소 소비액 충족이 필요합니다.',
    deadline: '여행 종료 후 14일 이내 신청',
    sections: [
      RegionRuleSection(
        title: '관광지',
        bullets: [
          '영암 관광지(축제장 포함) 1개소 이상 방문 사진이 필요합니다.',
          '일행 전체 얼굴 식별 가능한 사진이어야 합니다.',
        ],
      ),
      RegionRuleSection(
        title: '경비',
        bullets: [
          '개인당 5만 원 이상, 팀(2인 이상)은 10만 원 이상 소비 시 지원됩니다.',
          '현금영수증, 카드영수증, 월출페이 지출내역을 인정합니다.',
          '월출페이 카드 결제 시 월출페이 앱 이용내역 상세 화면 캡처를 제출해야 합니다.',
          '정책수당으로 결제한 월출페이는 인정되지 않습니다.',
          '연 30억 원 이상 매출업소 결제 비용은 지원 제외입니다.',
        ],
      ),
      RegionRuleSection(
        title: '숙박',
        bullets: [
          '숙소를 예약하여 선결제한 경우 숙박 이용 확인서와 결제 영수증을 함께 제출해야 합니다.',
        ],
      ),
    ],
  ),
  '하동': RegionSettlementGuide(
    summary: '10일 이내 신청, 지정 관광지 2곳 방문과 모바일 하동반값여행 정책발행용 사용이 필요합니다.',
    deadline: '여행 종료 다음날부터 10일 이내 신청',
    sections: [
      RegionRuleSection(
        title: '관광지',
        bullets: [
          '지정 관광지 2개소 이상 방문 사진 인증이 필요합니다.',
          '신청대표자와 구성원 얼굴 모두 나온 사진을 제출해야 합니다.',
          '지정축제와 지정 핫플레이스도 인증 대상에 포함됩니다.',
        ],
      ),
      RegionRuleSection(
        title: '경비',
        bullets: [
          '최소 소비액은 10만 원 이상입니다.',
          '2개소 이상 사용 영수증 인증이 필요합니다.',
          '신청 대표자 휴대폰의 제로페이 거래내역 사용만 인정됩니다.',
          '모바일 하동반값여행 정책발행용 지출만 환급 대상입니다.',
          '비플페이 등 제로페이 전자영수증 캡처가 필요합니다.',
          '개인카드와 현금 사용분은 불인정입니다.',
        ],
      ),
      RegionRuleSection(
        title: '숙박',
        bullets: [
          '국세청에 신고되는 카드 결제 영수증, 현금영수증, 온라인 결제 영수증만 인정합니다.',
          '숙소명, 금액, 숙박일자가 반드시 기재되어야 합니다.',
          '결제영수증, 숙박예약 또는 이용완료 내역, 숙박확인서를 함께 제출해야 합니다.',
        ],
      ),
    ],
  ),
  '강진': RegionSettlementGuide(
    summary: '7일 이내 신청, 관광지 2곳 방문과 대표자 명의 지출 증빙이 필요합니다.',
    deadline: '여행 종료 다음날부터 7일 이내 신청',
    sections: [
      RegionRuleSection(
        title: '관광지',
        bullets: [
          '강진 관광지 2개소 이상 방문 사진이 필요합니다.',
          '반드시 신청대표자와 신청구성원 얼굴이 모두 나와야 합니다.',
        ],
      ),
      RegionRuleSection(
        title: '경비',
        bullets: [
          '총 합산 개인 신청자 3만 원 이상, 팀(2인 이상) 신청자 5만 원 이상 지출 영수증이 필요합니다.',
          '신청대표자 명의 카드영수증을 인정합니다.',
          '신청대표자 휴대폰번호가 기재된 현금영수증을 인정합니다.',
          '신청대표자 휴대폰번호가 기재된 CHAK 거래내역 영수증을 인정합니다.',
          '연 30억 원 이상 매출 업소 결제 비용은 지원 제외입니다.',
        ],
      ),
      RegionRuleSection(
        title: '숙박',
        bullets: [
          '숙소를 예약하여 선결제한 경우 숙소 이용 완료 내역서와 결제 영수증을 함께 제출해야 합니다.',
        ],
      ),
    ],
  ),
  '남해': RegionSettlementGuide(
    summary: '10일 이내 신청, 관광지 2곳 방문과 반반남해 상품권 또는 숙박 증빙이 필요합니다.',
    deadline: '여행 종료 다음날부터 10일 이내 신청',
    sections: [
      RegionRuleSection(
        title: '관광지',
        bullets: [
          '남해 관광지 2개소 이상 방문 사진이 필요합니다.',
          '반드시 신청대표자와 신청구성원 얼굴이 모두 나와야 합니다.',
        ],
      ),
      RegionRuleSection(
        title: '경비',
        bullets: [
          '신청대표자 비플페이 반반남해 전용 지역사랑 상품권 거래내역을 제출해야 합니다.',
          '비플페이 앱 공공상품권 이용내역에서 상품권 종류와 기간을 설정해 조회한 화면 캡처가 필요합니다.',
        ],
      ),
      RegionRuleSection(
        title: '숙박',
        bullets: [
          '신청대표자 명의의 카드 결제 또는 숙박 결제 플랫폼 영수증 내역을 인정합니다.',
          '숙박 완료를 인증할 수 있는 내역 또는 숙박업체 대표명·상호명 도장이 있는 이용완료 내역서가 필요합니다.',
          '단순 결제 내역이 아니라 사용완료가 인정되어 환불 불가한 내역만 가능합니다.',
          '사우스케이프오너스 클럽, 쏠비치 호텔(빌라) 남해, 아난티 남해, 스포츠파크 호텔, 라피스 호텔은 인정 제외입니다.',
        ],
      ),
    ],
  ),
  '해남': RegionSettlementGuide(
    summary: '5일 이내 신청, 관광지 2곳 방문과 개인/팀 기준 최소 소비액 충족이 필요합니다.',
    deadline: '여행 종료 다음날부터 5일 이내 신청',
    sections: [
      RegionRuleSection(
        title: '관광지',
        bullets: [
          '해남 관광지(축제 포함) 2개소 이상 사진이 필요합니다.',
          '일행 전체 얼굴이 식별 가능한 사진이어야 합니다.',
        ],
      ),
      RegionRuleSection(
        title: '경비',
        bullets: [
          '개인 신청자 5만 원 이상, 팀(2인 이상) 신청자 10만 원 이상 소비 시 지원됩니다.',
          '대표 신청자와 신청 구성원 모두 개인당 총 2회까지만 신청 가능합니다.',
          '신청대표자 명의 카드 영수증 또는 현금영수증 또는 휴대폰번호가 기재된 CHAK 거래내역을 인정합니다.',
          '연매출 30억 원 초과 정책가맹점은 지원 제외입니다.',
        ],
      ),
      RegionRuleSection(
        title: '숙박',
        bullets: [
          '숙소를 예약하여 선결제한 경우 숙소 이용확인서와 결제 영수증을 함께 제출해야 합니다.',
        ],
      ),
    ],
  ),
  '고흥': RegionSettlementGuide(
    summary: '7일 이내 신청, 관광지 2곳 사진과 모바일 고흥사랑상품권 사용 증빙이 필요합니다.',
    deadline: '여행종료 후 7일 이내 신청',
    sections: [
      RegionRuleSection(
        title: '관광지',
        bullets: [
          '고흥 관광지 2개소에서 찍은 사진이 필요합니다.',
          '신청자 전원의 얼굴이 식별 가능해야 하며 날짜 워터마크가 필수입니다.',
        ],
      ),
      RegionRuleSection(
        title: '경비',
        bullets: [
          '신청 대표자 휴대전화가 기재된 지역사랑상품권 CHAK 거래내역 영수증이 필요합니다.',
          '모바일 고흥사랑상품권(QR결제, 카드결제)을 이용한 관광소비액만 인정됩니다.',
          '지류형 고흥사랑상품권 이용금액은 정산신청이 불가합니다.',
        ],
      ),
      RegionRuleSection(
        title: '숙박',
        bullets: [
          '숙박업소 영수증에 한하여 고흥사랑상품권 이외의 카드영수증 제출이 가능합니다.',
          '숙박영수증 제출 시 이용확인증도 함께 제출해야 합니다.',
        ],
      ),
    ],
  ),
  '완도': RegionSettlementGuide(
    summary: '10일 이내 신청, 관광지 인증샷 2장 이상과 소비금액 구간별 영수증 수 요건이 있습니다.',
    deadline: '여행 종료 다음날부터 10일 이내 신청',
    sections: [
      RegionRuleSection(
        title: '관광지',
        bullets: [
          '완도군 관광지에서 신청대표자와 신청 구성원이 포함된 인증샷 2장 이상이 필요합니다.',
          '축제와 박람회 사진도 인정됩니다.',
        ],
      ),
      RegionRuleSection(
        title: '경비',
        bullets: [
          '사전신청한 여행 시작일부터 발급된 영수증만 인정합니다.',
          '카드결제 영수증과 온라인 결제 영수증을 인정합니다.',
          '현금영수증, 간이영수증, 계좌이체는 일반 소비 증빙으로 인정되지 않습니다.',
          '카드결제 영수증은 신청자의 1개 카드 사용분만 인정합니다.',
          '영수증 총합 10만 원 이상부터는 1개소 이상 영수증 첨부가 필수입니다.',
          '영수증 총합 15만 원 이상부터는 2개소 이상 영수증 첨부가 필수입니다.',
          '영수증 총합 20만 원 이상부터는 3개소 이상 영수증 첨부가 필수입니다.',
        ],
      ),
      RegionRuleSection(
        title: '숙박',
        bullets: [
          '숙박확인서와 결제한 영수증을 함께 증빙자료로 필수 제출해야 합니다.',
          '숙박 이용 결제분에 한해서는 현금영수증도 가능합니다.',
        ],
      ),
    ],
  ),
};
