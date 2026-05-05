class ResidenceProvinceOption {
  const ResidenceProvinceOption({
    required this.province,
    required this.districts,
  });

  final String province;
  final List<String> districts;
}

const residencePickerOptions = <ResidenceProvinceOption>[
  ResidenceProvinceOption(
    province: '서울특별시',
    districts: ['강남구', '강동구', '강서구', '관악구', '마포구', '서초구', '송파구', '영등포구', '종로구', '중구'],
  ),
  ResidenceProvinceOption(
    province: '부산광역시',
    districts: ['강서구', '금정구', '남구', '동래구', '부산진구', '사하구', '수영구', '연제구', '해운대구'],
  ),
  ResidenceProvinceOption(
    province: '대구광역시',
    districts: ['남구', '달서구', '달성군', '동구', '북구', '서구', '수성구', '중구'],
  ),
  ResidenceProvinceOption(
    province: '인천광역시',
    districts: ['강화군', '계양구', '남동구', '미추홀구', '부평구', '서구', '연수구', '중구'],
  ),
  ResidenceProvinceOption(
    province: '광주광역시',
    districts: ['광산구', '남구', '동구', '북구', '서구'],
  ),
  ResidenceProvinceOption(
    province: '대전광역시',
    districts: ['대덕구', '동구', '서구', '유성구', '중구'],
  ),
  ResidenceProvinceOption(
    province: '울산광역시',
    districts: ['남구', '동구', '북구', '울주군', '중구'],
  ),
  ResidenceProvinceOption(
    province: '세종특별자치시',
    districts: ['세종시'],
  ),
  ResidenceProvinceOption(
    province: '경기도',
    districts: ['고양시', '과천시', '광명시', '광주시', '구리시', '김포시', '부천시', '성남시', '수원시', '안산시', '안양시', '용인시', '의정부시', '파주시', '평택시', '화성시'],
  ),
  ResidenceProvinceOption(
    province: '강원특별자치도',
    districts: ['강릉시', '동해시', '삼척시', '속초시', '원주시', '정선군', '철원군', '춘천시', '태백시', '평창군', '홍천군', '횡성군', '영월군'],
  ),
  ResidenceProvinceOption(
    province: '충청북도',
    districts: ['괴산군', '단양군', '보은군', '영동군', '옥천군', '음성군', '제천시', '증평군', '진천군', '청주시', '충주시'],
  ),
  ResidenceProvinceOption(
    province: '충청남도',
    districts: ['계룡시', '공주시', '금산군', '논산시', '당진시', '보령시', '부여군', '서산시', '서천군', '아산시', '예산군', '천안시', '청양군', '태안군', '홍성군'],
  ),
  ResidenceProvinceOption(
    province: '전북특별자치도',
    districts: ['고창군', '군산시', '김제시', '남원시', '무주군', '부안군', '순창군', '완주군', '익산시', '임실군', '장수군', '전주시', '정읍시', '진안군'],
  ),
  ResidenceProvinceOption(
    province: '전라남도',
    districts: ['강진군', '고흥군', '곡성군', '광양시', '구례군', '나주시', '담양군', '목포시', '무안군', '보성군', '순천시', '여수시', '영광군', '영암군', '완도군', '장성군', '장흥군', '진도군', '함평군', '해남군'],
  ),
  ResidenceProvinceOption(
    province: '경상북도',
    districts: ['경산시', '경주시', '고령군', '구미시', '김천시', '문경시', '상주시', '성주군', '안동시', '영덕군', '영주시', '영천시', '예천군', '포항시'],
  ),
  ResidenceProvinceOption(
    province: '경상남도',
    districts: ['거제시', '거창군', '고성군', '김해시', '남해군', '밀양시', '사천시', '산청군', '양산시', '의령군', '진주시', '창녕군', '창원시', '통영시', '하동군', '함안군', '함양군', '합천군'],
  ),
  ResidenceProvinceOption(
    province: '제주특별자치도',
    districts: ['서귀포시', '제주시'],
  ),
];
