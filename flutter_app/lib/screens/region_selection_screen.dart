import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_scope.dart';
import '../models/app_models.dart';
import '../widgets/app_shell.dart';
import '../widgets/region_eligibility_map.dart';
import 'trip_detail_screen.dart';

enum _RegionViewMode { map, list }

class RegionSelectionScreen extends StatefulWidget {
  const RegionSelectionScreen({super.key, required this.draft});

  final TripDraft draft;

  @override
  State<RegionSelectionScreen> createState() => _RegionSelectionScreenState();
}

class _RegionSelectionScreenState extends State<RegionSelectionScreen> {
  Future<List<RegionSummary>>? _future;
  bool _initialized = false;
  int? _selectedRegionId;
  _RegionViewMode _viewMode = _RegionViewMode.map;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    final controller = AppScope.of(context);
    _future =
        controller.repository.getRegions(residence: widget.draft.residence);
    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    return AppShell(
      title: '나의 반값여행지 찾기',
      modeName: controller.modeName,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: _ViewModeToggle(
            viewMode: _viewMode,
            onChanged: (mode) {
              setState(() => _viewMode = mode);
            },
          ),
        ),
      ],
      child: FutureBuilder<List<RegionSummary>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('지역 목록을 불러오지 못했습니다.\n${snapshot.error}'),
              ),
            );
          }

          final regions = [...snapshot.data ?? const <RegionSummary>[]]
            ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

          if (regions.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  '선택한 거주지 기준으로 표시할 sample 반값여행 지역이 없습니다.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final selectedRegion = regions.firstWhere(
            (item) => item.id == (_selectedRegionId ?? regions.first.id),
            orElse: () => regions.first,
          );

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _ResidenceSummaryBanner(residence: widget.draft.residence),
              const SizedBox(height: 18),
              SectionCard(
                title: _viewMode == _RegionViewMode.map
                    ? '지도형 지역 보기'
                    : '리스트형 지역 보기',
                subtitle: _viewMode == _RegionViewMode.map
                    ? '우측 상단 토글로 리스트 보기로 전환할 수 있습니다. 지도 실루엣과 칩 배치는 sample seed data 기반의 MVP 표현입니다.'
                    : '우측 상단 토글로 지도 보기로 전환할 수 있습니다. 리스트는 sample seed data의 표시 순서를 그대로 따릅니다.',
                child: _viewMode == _RegionViewMode.map
                    ? RegionEligibilityMap(
                        regions: regions,
                        selectedRegionId: selectedRegion.id,
                        onSelect: (region) {
                          setState(() => _selectedRegionId = region.id);
                        },
                      )
                    : Column(
                        children: [
                          for (final region in regions)
                            _RegionListTile(
                              region: region,
                              selected: region.id == selectedRegion.id,
                              onTap: () =>
                                  setState(() => _selectedRegionId = region.id),
                            ),
                        ],
                      ),
              ),
              const SizedBox(height: 18),
              _SelectedRegionPanel(
                region: selectedRegion,
                onHalfPriceApply: () => _launch(selectedRegion.halfPriceApplyUrl),
                onDigitalApply: () =>
                    _launch(selectedRegion.digitalTourCardApplyUrl),
                onCreateTrip: () => _createTrip(selectedRegion),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _launch(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  Future<void> _createTrip(RegionSummary region) async {
    final controller = AppScope.of(context);
    final user = controller.currentUser!;
    final trip = await controller.runTask(
      () => controller.repository.createTrip(
        userId: user.id,
        draft: widget.draft,
        regionId: region.id,
      ),
    );
    await controller.refreshTrips();
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => TripDetailScreen(tripId: trip.id)),
      (route) => route.isFirst,
    );
  }
}

class _ViewModeToggle extends StatelessWidget {
  const _ViewModeToggle({
    required this.viewMode,
    required this.onChanged,
  });

  final _RegionViewMode viewMode;
  final ValueChanged<_RegionViewMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFD7D1C6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleButton(
            icon: Icons.map_outlined,
            selected: viewMode == _RegionViewMode.map,
            onTap: () => onChanged(_RegionViewMode.map),
          ),
          _ToggleButton(
            icon: Icons.view_list_rounded,
            selected: viewMode == _RegionViewMode.list,
            onTap: () => onChanged(_RegionViewMode.list),
          ),
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  const _ToggleButton({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF155EEF) : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Icon(
          icon,
          size: 20,
          color: selected ? Colors.white : const Color(0xFF666666),
        ),
      ),
    );
  }
}

class _ResidenceSummaryBanner extends StatelessWidget {
  const _ResidenceSummaryBanner({required this.residence});

  final String residence;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFFF8FBFF), Color(0xFFF3F8F4)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '나의 거주지',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.black54,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            residence,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 10),
          const Text(
            '거주지(주민등록상 주소지)와 인접한 sample 토큰에 해당하는 지역은 제외하고, 나머지 반값여행지만 표시합니다.',
          ),
        ],
      ),
    );
  }
}

class _SelectedRegionPanel extends StatelessWidget {
  const _SelectedRegionPanel({
    required this.region,
    required this.onHalfPriceApply,
    required this.onDigitalApply,
    required this.onCreateTrip,
  });

  final RegionSummary region;
  final VoidCallback onHalfPriceApply;
  final VoidCallback onDigitalApply;
  final VoidCallback onCreateTrip;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFD8D2C6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                region.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              _StatusPill(
                label: region.statusLabel,
                statusCode: region.statusCode,
              ),
              if (region.digitalBenefitAvailable)
                const Chip(
                  avatar: Icon(
                    Icons.star_rounded,
                    color: Color(0xFFF5B700),
                  ),
                  label: Text('디지털 관광주민증 혜택'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text('${region.province} · 환급 조건 ${region.refundConditionAmount}원'),
          const SizedBox(height: 6),
          Text('sample 잔여 현황 ${region.mockBudgetRemaining}건'),
          if (region.residenceRestrictionNote.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              region.residenceRestrictionNote,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.black54,
                  ),
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.tonal(
                onPressed: region.halfPriceApplyUrl.trim().isEmpty
                    ? null
                    : onHalfPriceApply,
                child: Text(
                  region.halfPriceApplyUrl.trim().isEmpty
                      ? '반값여행 오픈 예정'
                      : '반값여행 신청',
                ),
              ),
              FilledButton.tonal(
                onPressed: region.digitalTourCardApplyUrl.trim().isEmpty
                    ? null
                    : onDigitalApply,
                child: Text(
                  region.digitalTourCardApplyUrl.trim().isEmpty
                      ? '디지털관광주민증 오픈 예정'
                      : '디지털관광주민증 신청',
                ),
              ),
              FilledButton(
                onPressed: onCreateTrip,
                child: const Text('이 지역으로 여행 생성'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '데이터 출처: ${region.dataSourceNote}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _RegionListTile extends StatelessWidget {
  const _RegionListTile({
    required this.region,
    required this.selected,
    required this.onTap,
  });

  final RegionSummary region;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      color: selected ? const Color(0xFFF1F8FF) : null,
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: selected
              ? const Color(0xFFD9ECFF)
              : const Color(0xFFF3F0E9),
          child: Text('${region.displayOrder}'),
        ),
        title: Text(
          region.name,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text('${region.province} · ${region.statusLabel}'),
        trailing: region.digitalBenefitAvailable
            ? const Icon(Icons.star_rounded, color: Color(0xFFF5B700))
            : const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.statusCode,
  });

  final String label;
  final String statusCode;

  @override
  Widget build(BuildContext context) {
    final normalized = statusCode.toUpperCase();
    final background = normalized == 'APPLYING'
        ? const Color(0xFFFFF0E5)
        : normalized == 'CLOSED'
            ? const Color(0xFFF1F1F1)
            : const Color(0xFFEAF2FF);
    final foreground = normalized == 'APPLYING'
        ? const Color(0xFFBE4A00)
        : normalized == 'CLOSED'
            ? const Color(0xFF666666)
            : const Color(0xFF2C5CC5);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
