import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_scope.dart';
import '../data/region_guides.dart';
import '../models/app_models.dart';
import '../widgets/app_shell.dart';

class RegionActionScreen extends StatefulWidget {
  const RegionActionScreen({
    super.key,
    required this.region,
  });

  final RegionSummary region;

  @override
  State<RegionActionScreen> createState() => _RegionActionScreenState();
}

class _RegionActionScreenState extends State<RegionActionScreen> {
  Future<void> _toggleBenefitAlert() async {
    final controller = AppScope.of(context);
    final wasEnabled =
        controller.preopenAlertRegionIds.contains(widget.region.id);

    await controller.togglePreopenAlertRegion(widget.region.id);

    if (!mounted) {
      return;
    }

    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          wasEnabled
              ? '알림을 해제했습니다.'
              : '혜택 오픈 시 알림을 보내드립니다!',
        ),
      ),
    );
  }

  Future<void> _openApplyLink() async {
    final url = widget.region.halfPriceApplyUrl.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('현재 연결된 신청 페이지가 없습니다.')),
      );
      return;
    }

    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  Future<void> _showComingSoon() async {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('준비중입니다.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final alertEnabled =
        controller.preopenAlertRegionIds.contains(widget.region.id);
    final guide = settlementGuideFor(widget.region.name);
    final summaryRows = _buildSummaryRows(widget.region, guide);

    return AppShell(
      title: '지역 상세',
      modeName: controller.modeName,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _RegionHeroCard(
            region: widget.region,
            alertEnabled: alertEnabled,
            onToggleAlert: _toggleBenefitAlert,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _openApplyLink,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Text(
                '반값여행 신청하러 가기',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          _DetailSectionTitle(
            title: '환급 조건',
            subtitle: guide.summary,
          ),
          const SizedBox(height: 12),
          _RuleTable(rows: summaryRows),
          if (widget.region.digitalBenefitAvailable) ...[
            const SizedBox(height: 22),
            const _DetailSectionTitle(
              title: '디지털 관광주민증 혜택',
              subtitle: '혜택 적용 가능 (중복 혜택)',
            ),
            const SizedBox(height: 10),
            _DigitalBenefitCard(
              regionName: widget.region.name,
              onPressed: _showComingSoon,
            ),
          ],
          const SizedBox(height: 22),
          const _DetailSectionTitle(
            title: '지역화폐 앱 안내',
            subtitle: '지역화폐 앱으로 결제 및 사용 내역을 관리할 수 있어요.',
          ),
          const SizedBox(height: 10),
          _LocalCurrencyCard(
            regionName: widget.region.name,
            appName: _localCurrencyAppName(widget.region.name),
            description: _localCurrencyDescription(widget.region.name),
            onPressed: _showComingSoon,
          ),
          const SizedBox(height: 22),
          SectionCard(
            title: '상세 정산 규칙',
            subtitle: '실제 신청 전에 아래 항목을 꼭 확인해 주세요.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _GuideHeader(deadline: guide.deadline),
                const SizedBox(height: 16),
                for (final section in guide.sections) ...[
                  _GuideSection(section: section),
                  const SizedBox(height: 14),
                ],
                if (guide.note != null && guide.note!.trim().isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFFED7AA)),
                    ),
                    child: Text(
                      guide.note!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF9A3412),
                            fontWeight: FontWeight.w600,
                            height: 1.55,
                          ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<_RuleRowData> _buildSummaryRows(
    RegionSummary region,
    RegionSettlementGuide guide,
  ) {
    final guideText = _joinGuideBullets(guide);
    return [
      _RuleRowData(
        label: '결제 수단',
        value: _paymentSummary(region.name, guideText),
      ),
      _RuleRowData(
        label: '인증 조건',
        value: _proofSummary(region.name, guideText),
      ),
      _RuleRowData(
        label: '최소 소비금액',
        value: _minSpendSummary(region.name, guideText),
      ),
      const _RuleRowData(
        label: '환급 비율',
        value: '50%',
        valueColor: Color(0xFF16A34A),
      ),
      _RuleRowData(
        label: '1인 최대 환급액',
        value: '${_formatWon(region.refundConditionAmount)}원',
      ),
    ];
  }
}

class _RegionHeroCard extends StatelessWidget {
  const _RegionHeroCard({
    required this.region,
    required this.alertEnabled,
    required this.onToggleAlert,
  });

  final RegionSummary region;
  final bool alertEnabled;
  final VoidCallback onToggleAlert;

  @override
  Widget build(BuildContext context) {
    final assetPath = _regionHeroAsset(region.name);
    final remaining = region.mockBudgetRemaining.clamp(0, 100);

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: AspectRatio(
        aspectRatio: 1.16,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (assetPath != null)
              Image.asset(
                assetPath,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _HeroFallback(region: region),
              )
            else
              _HeroFallback(region: region),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x1A000000),
                    Color(0x33000000),
                    Color(0xB8000000),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 14,
              right: 14,
              child: Material(
                color: Colors.black.withValues(alpha: 0.26),
                borderRadius: BorderRadius.circular(999),
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: onToggleAlert,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Icon(
                      alertEnabled
                          ? Icons.notifications_active_rounded
                          : Icons.notifications_none_rounded,
                      color: alertEnabled
                          ? const Color(0xFFFFE082)
                          : Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    region.province,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    region.name,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _OverlayBadge(
                        label: _statusLabel(region.statusCode),
                        backgroundColor: _statusBackground(region.statusCode),
                        foregroundColor: _statusForeground(region.statusCode),
                      ),
                      const SizedBox(width: 8),
                      _OverlayBadge(
                        label: '잔여 예산 $remaining%',
                        backgroundColor: Colors.black.withValues(alpha: 0.34),
                        foregroundColor: Colors.white,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroFallback extends StatelessWidget {
  const _HeroFallback({required this.region});

  final RegionSummary region;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFB9E3FF), Color(0xFF5EA8F5)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: 18,
            top: 18,
            child: Text(
              _regionEmoji(region.name),
              style: const TextStyle(fontSize: 56),
            ),
          ),
          Positioned(
            left: 18,
            bottom: 22,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                '배경 사진 파일을 넣으면\n자동으로 지역 카드에 적용됩니다.',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverlayBadge extends StatelessWidget {
  const _OverlayBadge({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foregroundColor,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _DetailSectionTitle extends StatelessWidget {
  const _DetailSectionTitle({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: const Color(0xFF0F172A),
              ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF64748B),
                height: 1.45,
              ),
        ),
      ],
    );
  }
}

class _RuleTable extends StatelessWidget {
  const _RuleTable({required this.rows});

  final List<_RuleRowData> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0F172A),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++)
            _RuleTableRow(
              row: rows[i],
              isLast: i == rows.length - 1,
            ),
        ],
      ),
    );
  }
}

class _RuleTableRow extends StatelessWidget {
  const _RuleTableRow({
    required this.row,
    required this.isLast,
  });

  final _RuleRowData row;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: Color(0xFFE5E7EB)),
              ),
      ),
      child: Row(
        children: [
          Container(
            width: 118,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: const BoxDecoration(
              color: Color(0xFFFAFBFC),
              border: Border(
                right: BorderSide(color: Color(0xFFE5E7EB)),
              ),
            ),
            child: Text(
              row.label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF475569),
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              child: Text(
                row.value,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: row.valueColor ?? const Color(0xFF0F172A),
                      fontWeight: row.valueColor != null
                          ? FontWeight.w900
                          : FontWeight.w700,
                      height: 1.4,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DigitalBenefitCard extends StatelessWidget {
  const _DigitalBenefitCard({
    required this.regionName,
    required this.onPressed,
  });

  final String regionName;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0F172A),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '혜택 적용 가능 (중복 혜택)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF16A34A),
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '$regionName 관광주민증 제시 시 일부 가맹점 할인 혜택',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              '관광주민증 발급받으러 가기',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocalCurrencyCard extends StatelessWidget {
  const _LocalCurrencyCard({
    required this.regionName,
    required this.appName,
    required this.description,
    required this.onPressed,
  });

  final String regionName;
  final String appName;
  final String description;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0F172A),
            blurRadius: 16,
            offset: Offset(0, 8),
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
                  '지역화폐 앱 안내',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF0F172A),
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF64748B),
                      ),
                ),
                const SizedBox(height: 14),
                OutlinedButton(
                  onPressed: onPressed,
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    '앱 바로가기',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _LocalCurrencyVisual(
            regionName: regionName,
            appName: appName,
          ),
        ],
      ),
    );
  }
}

class _LocalCurrencyVisual extends StatelessWidget {
  const _LocalCurrencyVisual({
    required this.regionName,
    required this.appName,
  });

  final String regionName;
  final String appName;

  @override
  Widget build(BuildContext context) {
    if (regionName == '영암') {
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.asset(
          'assets/localmoney/youngam.jpg',
          width: 102,
          height: 112,
          fit: BoxFit.cover,
        ),
      );
    }

    return Container(
      width: 102,
      height: 112,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF1F8FF), Color(0xFFDCEEFF)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 14,
            child: Icon(
              Icons.phone_android_rounded,
              size: 38,
              color: const Color(0xFF2563EB).withValues(alpha: 0.9),
            ),
          ),
          Positioned(
            left: 10,
            right: 10,
            bottom: 18,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                appName,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF1E3A8A),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  height: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideHeader extends StatelessWidget {
  const _GuideHeader({required this.deadline});

  final String deadline;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF4FF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD7E5FF)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.schedule_rounded,
              color: Color(0xFF2563EB),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '신청 기한',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: const Color(0xFF2563EB),
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  deadline,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF0F172A),
                        fontWeight: FontWeight.w900,
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

class _GuideSection extends StatelessWidget {
  const _GuideSection({required this.section});

  final RegionRuleSection section;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                ),
          ),
          const SizedBox(height: 12),
          for (final bullet in section.bullets)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(top: 8),
                    decoration: const BoxDecoration(
                      color: Color(0xFF2563EB),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      bullet,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF334155),
                            height: 1.55,
                          ),
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

class _RuleRowData {
  const _RuleRowData({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;
}

String _statusLabel(String statusCode) => switch (statusCode.toUpperCase()) {
      'APPLYING' => '접수중',
      'CLOSED' => '1차 마감',
      _ => '오픈예정',
    };

Color _statusBackground(String statusCode) => switch (statusCode.toUpperCase()) {
      'APPLYING' => const Color(0xFFE8FFF1),
      'CLOSED' => const Color(0xFFF3F4F6),
      _ => const Color(0xFFEAF1FF),
    };

Color _statusForeground(String statusCode) => switch (statusCode.toUpperCase()) {
      'APPLYING' => const Color(0xFF16A34A),
      'CLOSED' => const Color(0xFF6B7280),
      _ => const Color(0xFF2563EB),
    };

String _formatWon(int amount) {
  final digits = amount.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    final indexFromEnd = digits.length - i;
    buffer.write(digits[i]);
    if (indexFromEnd > 1 && indexFromEnd % 3 == 1) {
      buffer.write(',');
    }
  }
  return buffer.toString();
}

String _regionEmoji(String regionName) => switch (regionName) {
      '평창' => '🏔️',
      '횡성' => '🥩',
      '영월' => '⛪',
      '제천' => '🌊',
      '거창' => '🌉',
      '고창' => '🪨',
      '합천' => '🍁',
      '영광' => '🌅',
      '밀양' => '🏯',
      '영암' => '🧗',
      '하동' => '🍵',
      '강진' => '🪵',
      '남해' => '🌉',
      '해남' => '🌊',
      '고흥' => '🌺',
      '완도' => '🏝️',
      _ => '🧳',
    };

String? _regionHeroAsset(String regionName) => switch (regionName) {
      '평창' => 'assets/region_hero/pyeongchang.jpg',
      '횡성' => 'assets/region_hero/hoengseong.jpg',
      '영월' => 'assets/region_hero/yeongwol.jpg',
      '제천' => 'assets/region_hero/jecheon.jpg',
      '거창' => 'assets/region_hero/geochang.jpg',
      '고창' => 'assets/region_hero/gochang.jpg',
      '합천' => 'assets/region_hero/hapcheon.jpg',
      '영광' => 'assets/region_hero/yeonggwang.jpg',
      '밀양' => 'assets/region_hero/miryang.jpg',
      '영암' => 'assets/region_hero/yeongam.jpg',
      '하동' => 'assets/region_hero/hadong.jpg',
      '강진' => 'assets/region_hero/gangjin.jpg',
      '남해' => 'assets/region_hero/namhae.jpg',
      '해남' => 'assets/region_hero/haenam.jpg',
      '고흥' => 'assets/region_hero/goheung.jpg',
      '완도' => 'assets/region_hero/wando.jpg',
      _ => null,
    };

String _joinGuideBullets(RegionSettlementGuide guide) =>
    guide.sections.expand((section) => section.bullets).join(' ');

String _paymentSummary(String regionName, String guideText) {
  if (guideText.contains('카드') && guideText.contains('간편결제')) {
    return '지역화폐, 카드, 간편결제';
  }
  if (guideText.contains('제로페이')) {
    return '지역화폐, 제로페이, 카드';
  }
  if (guideText.contains('현금영수증')) {
    return '카드, 현금영수증, 지역화폐';
  }
  return '지역화폐, 카드 결제';
}

String _proofSummary(String regionName, String guideText) {
  if (guideText.contains('인증샷') || guideText.contains('사진')) {
    return '영수증 + 여행 인증 사진';
  }
  return '영수증 제출';
}

String _minSpendSummary(String regionName, String guideText) {
  if (guideText.contains('개인 신청자 3만 원')) {
    return '개인 30,000원 / 팀 50,000원 이상';
  }
  if (guideText.contains('개인 신청자 5만원')) {
    return '개인 50,000원 / 팀 100,000원 이상';
  }
  if (guideText.contains('개인당 5만원')) {
    return '개인 50,000원 / 팀 100,000원 이상';
  }
  if (guideText.contains('최소 소비액(여행경비) 5만원')) {
    return '50,000원 이상';
  }
  if (guideText.contains('10만 원') || guideText.contains('10만원')) {
    return '100,000원 이상';
  }
  return '조건 확인 필요';
}

String _localCurrencyAppName(String regionName) => switch (regionName) {
      '평창' => '평창사랑상품권',
      '횡성' => '횡성몰 / 홈페이지',
      '영월' => '영월별빛고운카드',
      '제천' => '제천화폐 Chak',
      '거창' => '거창반값여행 상품권',
      '고창' => '고창사랑카드',
      '합천' => '합천반값여행 상품권',
      '영광' => '그리고',
      '밀양' => '밀양사랑상품권',
      '영암' => '월출페이',
      '하동' => '하동반값여행 상품권',
      '강진' => '강진사랑상품권 Chak',
      '남해' => '비플페이 반반남해',
      '해남' => '해남사랑상품권 Chak',
      '고흥' => '고흥사랑상품권 Chak',
      '완도' => '완도 지역화폐 안내',
      _ => '지역화폐 앱',
    };

String _localCurrencyDescription(String regionName) => switch (regionName) {
      '평창' => '평창사랑상품권 가맹점에서 사용할 수 있어요.',
      '횡성' => '횡성 지역 공지에 따라 사용 앱이 공개될 예정입니다.',
      '영월' => '영월 지역화폐 결제 내역과 카드 정보를 함께 확인해요.',
      '제천' => '제천화폐 사용 내역은 Chak 시스템 기준으로 정산됩니다.',
      '거창' => '거창 반값여행 상품권 사용 내역을 앱에서 확인해요.',
      '고창' => '고창사랑카드 결제 내역을 정산 전에 확인해 주세요.',
      '합천' => '모바일 합천반값여행 상품권 사용 내역이 필요해요.',
      '영광' => '그리고 앱 또는 카드 거래내역을 준비해 주세요.',
      '밀양' => '밀양사랑상품권 제로페이 사용 내역이 필요해요.',
      '영암' => '월출페이 이용내역 상세 화면으로 정산에 활용해요.',
      '하동' => '하동반값여행 상품권 제로페이 전자영수증이 필요해요.',
      '강진' => '강진사랑상품권 Chak 거래내역을 확인할 수 있어요.',
      '남해' => '비플페이 반반남해 상품권 거래내역을 확인해 주세요.',
      '해남' => '카드, 현금영수증, CHAK 거래내역을 함께 준비해 주세요.',
      '고흥' => '고흥사랑상품권 Chak 거래내역이 정산 기준입니다.',
      '완도' => '완도 지역화폐와 카드 결제 영수증 기준을 확인해 보세요.',
      _ => '지역별 정산에 필요한 지역화폐 앱 안내입니다.',
    };
