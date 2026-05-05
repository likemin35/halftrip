import 'package:flutter/material.dart';

import '../core/app_scope.dart';
import '../widgets/app_shell.dart';

class RegionInfoScreen extends StatelessWidget {
  const RegionInfoScreen({
    super.key,
    this.currentTabIndex,
    this.onTabSelected,
  });

  final int? currentTabIndex;
  final ValueChanged<int>? onTabSelected;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);

    return AppShell(
      title: '관광지 정보',
      modeName: controller.modeName,
      currentTabIndex: currentTabIndex,
      onTabSelected: onTabSelected,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '지역별 관광지와 혜택 정보',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 10),
                Text(
                  '각 지역의 지정 관광지, 디지털 관광주민증 혜택 장소, 추천 동선을 이 탭에서 계속 확장할 예정입니다.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF64748B),
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ..._previewCards.map((card) => _RegionPreviewCard(card: card)),
        ],
      ),
    );
  }
}

class _RegionPreviewCard extends StatelessWidget {
  const _RegionPreviewCard({required this.card});

  final _RegionPreview card;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: card.accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(card.icon, color: card.accent, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  card.region,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  card.body,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF64748B),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RegionPreview {
  const _RegionPreview({
    required this.region,
    required this.body,
    required this.icon,
    required this.accent,
  });

  final String region;
  final String body;
  final IconData icon;
  final Color accent;
}

const List<_RegionPreview> _previewCards = [
  _RegionPreview(
    region: '완도',
    body: '해양치유센터, 청해진 유적지, 청산도 축제 등 지정 관광지 데이터를 순차적으로 연결하고 있습니다.',
    icon: Icons.waves_rounded,
    accent: Color(0xFF0EA5E9),
  ),
  _RegionPreview(
    region: '평창',
    body: '반값여행 지정 관광지와 디지털 관광주민증 혜택 장소를 함께 볼 수 있도록 구성할 예정입니다.',
    icon: Icons.terrain_rounded,
    accent: Color(0xFF2563EB),
  ),
  _RegionPreview(
    region: '영광',
    body: '지역별 관광지와 소비 인증 포인트를 지도 중심으로 확인할 수 있게 준비하고 있습니다.',
    icon: Icons.location_on_rounded,
    accent: Color(0xFFF59E0B),
  ),
];
