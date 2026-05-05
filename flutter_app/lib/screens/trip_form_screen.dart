import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_scope.dart';
import '../models/app_models.dart';
import '../widgets/app_shell.dart';
import 'trip_detail_screen.dart';

enum _RegionFilter { all, applying, preparing, closed }

class TripFormScreen extends StatefulWidget {
  const TripFormScreen({super.key});

  @override
  State<TripFormScreen> createState() => _TripFormScreenState();
}

class _TripFormScreenState extends State<TripFormScreen> {
  Future<_TravelApplyViewData>? _future;
  bool _initialized = false;
  _RegionFilter _selectedFilter = _RegionFilter.all;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    _future = _loadData();
    _initialized = true;
  }

  Future<_TravelApplyViewData> _loadData() async {
    final controller = AppScope.of(context);
    final latestUser = await controller.refreshCurrentUser();
    final regions = await controller.repository.getRegions(
      residence: latestUser.residence,
    );

    final eligibleRegions = regions
        .where(
          (region) =>
              latestUser.residence.trim().isEmpty || region.matchedByResidence,
        )
        .toList()
      ..sort((a, b) {
        final priority = _statusPriority(a.statusCode).compareTo(
          _statusPriority(b.statusCode),
        );
        if (priority != 0) {
          return priority;
        }
        final budgetOrder = b.mockBudgetRemaining.compareTo(
          a.mockBudgetRemaining,
        );
        if (budgetOrder != 0) {
          return budgetOrder;
        }
        return a.displayOrder.compareTo(b.displayOrder);
      });

    return _TravelApplyViewData(user: latestUser, regions: eligibleRegions);
  }

  List<RegionSummary> _filterRegions(List<RegionSummary> regions) {
    return regions.where((region) {
      switch (_selectedFilter) {
        case _RegionFilter.all:
          return true;
        case _RegionFilter.applying:
          return region.statusCode.toUpperCase() == 'APPLYING';
        case _RegionFilter.preparing:
          return region.statusCode.toUpperCase() == 'PREPARING';
        case _RegionFilter.closed:
          return region.statusCode.toUpperCase() == 'CLOSED';
      }
    }).toList();
  }

  Future<void> _openApplyLink(RegionSummary region) async {
    final uriText = region.halfPriceApplyUrl.trim();
    final statusCode = region.statusCode.toUpperCase();

    if (uriText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${region.name} 신청 페이지는 아직 준비 중입니다.')),
      );
      return;
    }

    if (statusCode != 'APPLYING') {
      final message = statusCode == 'PREPARING'
          ? '${region.name}은 현재 오픈 예정 상태입니다.'
          : '${region.name}은 현재 1차 마감 상태입니다.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      return;
    }

    await launchUrl(
      Uri.parse(uriText),
      mode: LaunchMode.externalApplication,
    );
  }

  Future<void> _addTripToMyTrips(RegionSummary region) async {
    final controller = AppScope.of(context);
    final user = controller.currentUser;
    if (user == null) {
      return;
    }

    final selectedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(
        start: DateTime.now().add(const Duration(days: 7)),
        end: DateTime.now().add(const Duration(days: 9)),
      ),
      helpText: '${region.name} 여행 일정 선택',
      saveText: '추가',
      locale: const Locale('ko', 'KR'),
    );
    if (selectedRange == null || !mounted) {
      return;
    }

    final travelerCount = await _selectTravelerCount();
    if (travelerCount == null || !mounted) {
      return;
    }

    final trip = await controller.runTask(
      () => controller.repository.createTrip(
        userId: user.id,
        draft: TripDraft(
          applicantName: user.name,
          phoneNumber: user.phoneNumber,
          residence: user.residence,
          startDate: selectedRange.start,
          endDate: selectedRange.end,
          travelerCount: travelerCount,
        ),
        regionId: region.id,
      ),
    );
    await controller.refreshTrips();
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${region.name} 여행이 내 여행에 추가되었습니다.')),
    );
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TripDetailScreen(tripId: trip.id)),
    );
  }

  Future<int?> _selectTravelerCount() async {
    var selectedCount = 2;
    return showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('여행 인원 선택'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('이번 여행에 몇 명이 함께 가는지 선택해 주세요.'),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: selectedCount,
                    decoration: const InputDecoration(
                      labelText: '여행 인원',
                      border: OutlineInputBorder(),
                    ),
                    items: List.generate(
                      10,
                      (index) => DropdownMenuItem(
                        value: index + 1,
                        child: Text('${index + 1}명'),
                      ),
                    ),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setDialogState(() => selectedCount = value);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('취소'),
                ),
                FilledButton(
                  onPressed: () =>
                      Navigator.of(dialogContext).pop(selectedCount),
                  child: const Text('등록'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);

    return AppShell(
      title: '여행 신청',
      modeName: controller.modeName,
      child: FutureBuilder<_TravelApplyViewData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  '신청 가능 지역을 불러오지 못했습니다.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final data = snapshot.data!;
          final filteredRegions = _filterRegions(data.regions);

          return RefreshIndicator(
            onRefresh: () async {
              setState(() => _future = _loadData());
              await _future!;
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              children: [
                _TravelApplyHeader(user: data.user),
                const SizedBox(height: 18),
                _ProfileSummaryCard(user: data.user),
                const SizedBox(height: 18),
                _FilterBar(
                  selectedFilter: _selectedFilter,
                  onChanged: (filter) {
                    setState(() => _selectedFilter = filter);
                  },
                ),
                const SizedBox(height: 18),
                if (filteredRegions.isEmpty)
                  _EmptyRegionState(filter: _selectedFilter)
                else
                  LayoutBuilder(
                    builder: (context, constraints) {
                      const spacing = 18.0;
                      final crossAxisCount = math.max(
                        1,
                        (constraints.maxWidth / 280).floor(),
                      );
                      final itemWidth = (constraints.maxWidth -
                              (crossAxisCount - 1) * spacing) /
                          crossAxisCount;

                      return Wrap(
                        spacing: spacing,
                        runSpacing: spacing,
                        children: [
                          for (final region in filteredRegions)
                            SizedBox(
                              width: itemWidth,
                              child: _RegionApplyCard(
                                region: region,
                                onOpenApplyPage: () => _openApplyLink(region),
                                onAddToMyTrips: () => _addTripToMyTrips(region),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TravelApplyViewData {
  const _TravelApplyViewData({
    required this.user,
    required this.regions,
  });

  final AppUser user;
  final List<RegionSummary> regions;
}

class _TravelApplyHeader extends StatelessWidget {
  const _TravelApplyHeader({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F4ED),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '반값여행',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF111827),
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  '회원정보의 거주지를 기준으로 신청 가능한 지역만 자동으로 보여줍니다.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFF98A2B3),
                        height: 1.4,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Text(
              '📍 ${_shortResidence(user.residence)}',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: Color(0xFF344054),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _shortResidence(String residence) {
    final parts = residence.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) {
      return '미설정';
    }
    return parts.length >= 2 ? parts[1] : parts.first;
  }
}

class _ProfileSummaryCard extends StatelessWidget {
  const _ProfileSummaryCard({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE6EAF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '내 회원정보',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 14),
          _ProfileRow(label: '이름', value: user.name),
          const SizedBox(height: 10),
          _ProfileRow(label: '전화번호', value: user.phoneNumber),
          const SizedBox(height: 10),
          _ProfileRow(label: '거주지', value: user.residence),
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF98A2B3),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? '-' : value,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.selectedFilter,
    required this.onChanged,
  });

  final _RegionFilter selectedFilter;
  final ValueChanged<_RegionFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final filter in _RegionFilter.values)
          ChoiceChip(
            label: Text(_filterLabel(filter)),
            selected: selectedFilter == filter,
            onSelected: (_) => onChanged(filter),
            selectedColor: const Color(0xFFE8FFF4),
            backgroundColor: Colors.white,
            side: BorderSide(
              color: selectedFilter == filter
                  ? const Color(0xFF12B76A)
                  : const Color(0xFFE5E7EB),
            ),
            labelStyle: TextStyle(
              fontWeight: FontWeight.w800,
              color: selectedFilter == filter
                  ? const Color(0xFF039855)
                  : const Color(0xFF667085),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
      ],
    );
  }

  String _filterLabel(_RegionFilter filter) {
    switch (filter) {
      case _RegionFilter.all:
        return '전체';
      case _RegionFilter.applying:
        return '접수중';
      case _RegionFilter.preparing:
        return '오픈 예정';
      case _RegionFilter.closed:
        return '1차 마감';
    }
  }
}

class _RegionApplyCard extends StatelessWidget {
  const _RegionApplyCard({
    required this.region,
    required this.onOpenApplyPage,
    required this.onAddToMyTrips,
  });

  final RegionSummary region;
  final VoidCallback onOpenApplyPage;
  final VoidCallback onAddToMyTrips;

  @override
  Widget build(BuildContext context) {
    final budgetPercent = region.mockBudgetRemaining.clamp(0, 100);
    final progressColor = budgetPercent >= 60
        ? const Color(0xFF12B76A)
        : budgetPercent >= 35
            ? const Color(0xFFF79009)
            : const Color(0xFFEF4444);
    final statusColors = _statusColors(region.statusCode);
    final canOpen = region.halfPriceApplyUrl.trim().isNotEmpty;
    final cardBackground = region.statusCode.toUpperCase() == 'APPLYING'
        ? const Color(0xFFF9FFFB)
        : Colors.white;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFD9F2E3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F101828),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.circular(18),
                ),
                alignment: Alignment.center,
                child: Text(
                  _regionEmoji(region.name),
                  style: const TextStyle(fontSize: 28),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (region.digitalBenefitAvailable)
                      Align(
                        alignment: Alignment.topRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F4FF),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            '관광주민증',
                            style: TextStyle(
                              color: Color(0xFF5B5BD6),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    Text(
                      region.name,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            height: 1.05,
                            color: const Color(0xFF111827),
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _provinceShort(region.province),
                      style: const TextStyle(
                        color: Color(0xFF98A2B3),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: statusColors.$1,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: statusColors.$2),
            ),
            child: Text(
              _statusLabel(region.statusCode),
              style: TextStyle(
                color: statusColors.$3,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text(
                '잔여 예산',
                style: TextStyle(
                  color: Color(0xFF667085),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '$budgetPercent%',
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 10,
            decoration: BoxDecoration(
              color: const Color(0xFFEAEEF4),
              borderRadius: BorderRadius.circular(999),
            ),
            clipBehavior: Clip.antiAlias,
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: budgetPercent / 100,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [progressColor.withOpacity(0.86), progressColor],
                    ),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '환급 조건 ${_won.format(region.refundConditionAmount)}원',
            style: const TextStyle(
              color: Color(0xFF98A2B3),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: canOpen ? onOpenApplyPage : null,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(
                      color: canOpen
                          ? const Color(0xFFBFE6CC)
                          : const Color(0xFFE5E7EB),
                    ),
                    foregroundColor: canOpen
                        ? const Color(0xFF16A34A)
                        : const Color(0xFF98A2B3),
                  ),
                  child: Text(canOpen ? '신청 페이지' : '준비중'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: onAddToMyTrips,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: const Color(0xFF16A34A),
                  ),
                  child: const Text('내 여행에 추가'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static final NumberFormat _won = NumberFormat.decimalPattern('ko_KR');

  (Color, Color, Color) _statusColors(String statusCode) {
    switch (statusCode.toUpperCase()) {
      case 'APPLYING':
        return (
          const Color(0xFFEAFBF2),
          const Color(0xFF9BE7BF),
          const Color(0xFF039855),
        );
      case 'CLOSED':
        return (
          const Color(0xFFF3F4F6),
          const Color(0xFFE5E7EB),
          const Color(0xFF667085),
        );
      default:
        return (
          const Color(0xFFF8FAFC),
          const Color(0xFFE5E7EB),
          const Color(0xFF475467),
        );
    }
  }

  String _statusLabel(String statusCode) {
    switch (statusCode.toUpperCase()) {
      case 'APPLYING':
        return '접수중';
      case 'CLOSED':
        return '1차 마감';
      default:
        return '오픈 예정';
    }
  }

  String _provinceShort(String province) {
    if (province.contains('강원')) return '강원';
    if (province.contains('충청북도')) return '충북';
    if (province.contains('충청남도')) return '충남';
    if (province.contains('전라남도')) return '전남';
    if (province.contains('전라북도')) return '전북';
    if (province.contains('경상남도')) return '경남';
    if (province.contains('경상북도')) return '경북';
    return province;
  }

  String _regionEmoji(String regionName) {
    switch (regionName) {
      case '평창':
        return '🏔️';
      case '영월':
        return '🌊';
      case '제천':
        return '⛰️';
      case '강진':
        return '🍵';
      case '횡성':
        return '🥩';
      case '완도':
        return '🏝️';
      case '남해':
        return '⛵';
      case '하동':
        return '🍃';
      case '영광':
        return '🐟';
      case '합천':
        return '🖼️';
      case '거창':
        return '🌄';
      case '고창':
        return '🪁';
      case '해남':
        return '🌾';
      case '영암':
        return '🏁';
      case '고흥':
        return '🚀';
      case '밀양':
        return '🌿';
      default:
        return '📍';
    }
  }
}

class _EmptyRegionState extends StatelessWidget {
  const _EmptyRegionState({required this.filter});

  final _RegionFilter filter;

  @override
  Widget build(BuildContext context) {
    final message = switch (filter) {
      _RegionFilter.all => '현재 회원정보 기준으로 표시할 지역이 없습니다.',
      _RegionFilter.applying => '지금은 접수중인 지역이 없습니다.',
      _RegionFilter.preparing => '오픈 예정 지역이 없습니다.',
      _RegionFilter.closed => '1차 마감 지역이 없습니다.',
    };

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE6EAF0)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.travel_explore_outlined,
            size: 42,
            color: Color(0xFF98A2B3),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFF667085),
                ),
          ),
        ],
      ),
    );
  }
}

int _statusPriority(String statusCode) {
  switch (statusCode.toUpperCase()) {
    case 'APPLYING':
      return 0;
    case 'PREPARING':
      return 1;
    case 'CLOSED':
      return 2;
    default:
      return 3;
  }
}
