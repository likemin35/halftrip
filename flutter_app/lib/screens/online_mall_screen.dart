import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_scope.dart';
import '../widgets/app_shell.dart';

class OnlineMallScreen extends StatelessWidget {
  const OnlineMallScreen({
    super.key,
    this.currentTabIndex,
    this.onTabSelected,
  });

  final int? currentTabIndex;
  final ValueChanged<int>? onTabSelected;

  static const _walletAmount = 100000;
  static const _usedAmount = 25000;
  static const _remainingAmount = 75000;
  static const _currencyName = '월출페이';
  static const _regionName = '영암';
  static const _mallName = '영암몰';
  static const _mallUrl = 'https://yeongam.jnmall.kr/';
  static const _expiresAt = '2026.12.31';

  static const List<_MerchantGuideItem> _merchantGuides = [
    _MerchantGuideItem(
      icon: Icons.store_mall_directory_rounded,
      name: '영암 5일장',
      category: '전통시장',
      accent: Color(0xFF16A34A),
    ),
    _MerchantGuideItem(
      icon: Icons.restaurant_rounded,
      name: '월출산 맛거리',
      category: '음식점',
      accent: Color(0xFFF97316),
    ),
    _MerchantGuideItem(
      icon: Icons.local_cafe_rounded,
      name: '기찬 카페거리',
      category: '카페',
      accent: Color(0xFF8B5CF6),
    ),
    _MerchantGuideItem(
      icon: Icons.shopping_bag_rounded,
      name: '영암 특산품관',
      category: '로컬 굿즈',
      accent: Color(0xFF2563EB),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final formatter = NumberFormat.decimalPattern('ko_KR');

    return AppShell(
      title: '온라인몰',
      modeName: controller.modeName,
      currentTabIndex: currentTabIndex,
      onTabSelected: onTabSelected,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
        children: [
          _WalletHeroCard(
            amountText: '${formatter.format(_walletAmount)}원',
            subtitle: '$_regionName $_currencyName · $_expiresAt 까지 사용',
          ),
          const SizedBox(height: 16),
          _UsageGuideCard(items: _merchantGuides),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.map_outlined,
                  title: '가맹점 지도',
                  subtitle: '사용 가능 매장 찾기',
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.shopping_bag_outlined,
                  title: '온라인몰 바로가기',
                  subtitle: '$_mallName 이동',
                  onTap: () => launchUrl(
                    Uri.parse(_mallUrl),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _MerchantMapCard(items: _merchantGuides),
          const SizedBox(height: 16),
          _UsageSummaryCard(
            usedAmountText: '${formatter.format(_usedAmount)}원',
            remainingAmountText: '${formatter.format(_remainingAmount)}원',
          ),
        ],
      ),
    );
  }
}

class _WalletHeroCard extends StatelessWidget {
  const _WalletHeroCard({
    required this.amountText,
    required this.subtitle,
  });

  final String amountText;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [Color(0xFFFF7A18), Color(0xFFFF5B00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22FF7A18),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '환급 지역화폐',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 10),
                Text(
                  amountText,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                      SizedBox(width: 8),
                      Text(
                        '사용기한 D-250',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 108,
            height: 108,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              color: Colors.white.withValues(alpha: 0.08),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.18),
              ),
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              color: Color(0xFFFFC9A5),
              size: 58,
            ),
          ),
        ],
      ),
    );
  }
}

class _UsageGuideCard extends StatelessWidget {
  const _UsageGuideCard({
    required this.items,
  });

  final List<_MerchantGuideItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '사용처 안내',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: const Color(0xFF111827),
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 14),
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: index == items.length - 1
                        ? Colors.transparent
                        : const Color(0xFFF1F5F9),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: item.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(item.icon, color: item.accent),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: const Color(0xFF111827),
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.category,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: const Color(0xFF64748B),
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF94A3B8),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1F0),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              '대형마트 · 유흥업소 · 일부 프랜차이즈는 사용 제한',
              style: TextStyle(
                color: Color(0xFFEF4444),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: const Color(0xFF0F172A)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: const Color(0xFF111827),
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MerchantMapCard extends StatelessWidget {
  const _MerchantMapCard({
    required this.items,
  });

  final List<_MerchantGuideItem> items;

  @override
  Widget build(BuildContext context) {
    final positions = <Offset>[
      const Offset(0.18, 0.28),
      const Offset(0.68, 0.22),
      const Offset(0.38, 0.56),
      const Offset(0.8, 0.62),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '가맹점 지도',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: const Color(0xFF111827),
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '월출페이 사용 가능 매장을 한눈에 볼 수 있는 목업 지도입니다.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF64748B),
                  height: 1.45,
                ),
          ),
          const SizedBox(height: 14),
          Container(
            height: 240,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                colors: [Color(0xFFE8F4EE), Color(0xFFF8F4E8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _MerchantMapPainter(),
                      ),
                    ),
                    ...items.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      final position = positions[index];
                      return Positioned(
                        left: constraints.maxWidth * position.dx,
                        top: constraints.maxHeight * position.dy,
                        child: _MerchantMarker(
                          index: index + 1,
                          color: item.accent,
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _UsageSummaryCard extends StatelessWidget {
  const _UsageSummaryCard({
    required this.usedAmountText,
    required this.remainingAmountText,
  });

  final String usedAmountText;
  final String remainingAmountText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '사용 내역',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: const Color(0xFF111827),
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const Spacer(),
              Text(
                '영암 지역화폐 기준',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF94A3B8),
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _MetricBox(
                  label: '총 사용 금액',
                  value: usedAmountText,
                  valueColor: const Color(0xFFFF6B00),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricBox(
                  label: '남은 잔액',
                  value: remainingAmountText,
                  valueColor: const Color(0xFF111827),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricBox extends StatelessWidget {
  const _MetricBox({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: valueColor,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ],
      ),
    );
  }
}

class _MerchantMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFFC7DDD2)
      ..strokeWidth = 1.2;

    for (var i = 1; i < 5; i++) {
      final dy = size.height / 5 * i;
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), linePaint);
    }
    for (var i = 1; i < 4; i++) {
      final dx = size.width / 4 * i;
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), linePaint);
    }

    final roadPaint = Paint()
      ..color = const Color(0x66FFFFFF)
      ..strokeWidth = 18
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final roadLinePaint = Paint()
      ..color = const Color(0xFFBFD5CA)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final roadPath = Path()
      ..moveTo(size.width * 0.08, size.height * 0.74)
      ..quadraticBezierTo(
        size.width * 0.28,
        size.height * 0.52,
        size.width * 0.46,
        size.height * 0.56,
      )
      ..quadraticBezierTo(
        size.width * 0.68,
        size.height * 0.6,
        size.width * 0.9,
        size.height * 0.34,
      );
    canvas.drawPath(roadPath, roadPaint);
    canvas.drawPath(roadPath, roadLinePaint);

    final riverPaint = Paint()
      ..color = const Color(0xFFB9E2FF)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final riverPath = Path()
      ..moveTo(size.width * 0.1, size.height * 0.14)
      ..quadraticBezierTo(
        size.width * 0.34,
        size.height * 0.28,
        size.width * 0.58,
        size.height * 0.18,
      )
      ..quadraticBezierTo(
        size.width * 0.8,
        size.height * 0.08,
        size.width * 0.92,
        size.height * 0.16,
      );
    canvas.drawPath(riverPath, riverPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MerchantMarker extends StatelessWidget {
  const _MerchantMarker({
    required this.index,
    required this.color,
  });

  final int index;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(
                color: Color(0x220F172A),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            '$index',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Container(
          width: 8,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(8),
            ),
          ),
        ),
      ],
    );
  }
}

class _MerchantGuideItem {
  const _MerchantGuideItem({
    required this.icon,
    required this.name,
    required this.category,
    required this.accent,
  });

  final IconData icon;
  final String name;
  final String category;
  final Color accent;
}
