import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_scope.dart';
import '../models/app_models.dart';
import '../widgets/app_shell.dart';
import 'trip_detail_screen.dart';

class TripListScreen extends StatefulWidget {
  const TripListScreen({
    super.key,
    this.currentTabIndex,
    this.onTabSelected,
  });

  final int? currentTabIndex;
  final ValueChanged<int>? onTabSelected;

  @override
  State<TripListScreen> createState() => _TripListScreenState();
}

class _TripListScreenState extends State<TripListScreen> {
  Future<void> _refresh() async {
    await AppScope.of(context).refreshTrips();
    if (mounted) setState(() {});
  }

  Future<void> _createTrip() async {
    final controller = AppScope.of(context);
    final user = controller.currentUser;
    if (user == null) return;

    final regions = await controller.repository.getRegions(
      residence: user.residence,
    );
    final eligibleRegions = regions
        .where((region) {
          return user.residence.trim().isEmpty || region.matchedByResidence;
        })
        .toList()
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

    if (!mounted || eligibleRegions.isEmpty) return;

    final selectedRegion = await _showRegionApplicationSheet(eligibleRegions);
    if (!mounted || selectedRegion == null) return;

    final selection = await _showTripInfoSheet(selectedRegion);
    if (!mounted || selection == null) return;

    final trip = await controller.runTask(
      () => controller.repository.createTrip(
        userId: user.id,
        draft: TripDraft(
          applicantName: user.name,
          phoneNumber: user.phoneNumber,
          residence: user.residence,
          startDate: selection.dateRange.start,
          endDate: selection.dateRange.end,
          travelerCount: selection.travelerCount,
        ),
        regionId: selectedRegion.id,
      ),
    );

    await controller.setTripApplicationStatus(trip.id, true);
    await controller.refreshTrips();
    if (!mounted) return;
    setState(() {});

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TripDetailScreen(tripId: trip.id),
      ),
    );
  }

  Future<RegionSummary?> _showRegionApplicationSheet(
    List<RegionSummary> regions,
  ) async {
    RegionSummary selectedRegion = regions.first;

    return showModalBottomSheet<RegionSummary>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '반값여행 신청 하셨나요?',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF0F172A),
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '먼저 여행할 지역을 고른 뒤 신청하러 가거나, 이미 신청을 마쳤다면 다음 단계에서 일정과 인원을 등록해 주세요.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF64748B),
                          height: 1.5,
                        ),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<RegionSummary>(
                    initialValue: selectedRegion,
                    decoration: const InputDecoration(
                      labelText: '여행 지역',
                      border: OutlineInputBorder(),
                    ),
                    items: regions
                        .map(
                          (region) => DropdownMenuItem(
                            value: region,
                            child: Text('${region.name} · ${region.province}'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setSheetState(() => selectedRegion = value);
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final url = selectedRegion.halfPriceApplyUrl.trim();
                            if (url.isNotEmpty) {
                              await launchUrl(
                                Uri.parse(url),
                                mode: LaunchMode.externalApplication,
                              );
                            }
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${selectedRegion.name} 신청 페이지로 이동했습니다. 신청 완료 후 다시 여행을 추가해 주세요.',
                                ),
                              ),
                            );
                            Navigator.of(sheetContext).pop(null);
                          },
                          child: const Text('신청하러가기'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            Navigator.of(sheetContext).pop(selectedRegion);
                          },
                          child: const Text('신청완료'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<_TripCreateSelection?> _showTripInfoSheet(RegionSummary region) {
    int travelerCount = 2;
    DateTimeRange selectedRange = DateTimeRange(
      start: DateTime.now().add(const Duration(days: 7)),
      end: DateTime.now().add(const Duration(days: 8)),
    );

    return showModalBottomSheet<_TripCreateSelection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${region.name} 여행 추가',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF0F172A),
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '신청을 완료한 여행만 일정과 인원을 등록할 수 있습니다.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF64748B),
                          height: 1.5,
                        ),
                  ),
                  const SizedBox(height: 20),
                  InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () async {
                      final picked = await showDateRangePicker(
                        context: sheetContext,
                        firstDate: DateTime.now().subtract(
                          const Duration(days: 30),
                        ),
                        lastDate: DateTime.now().add(
                          const Duration(days: 365),
                        ),
                        initialDateRange: selectedRange,
                        locale: const Locale('ko', 'KR'),
                        helpText: '여행 일정 선택',
                        saveText: '선택',
                      );
                      if (picked != null) {
                        setSheetState(() => selectedRange = picked);
                      }
                    },
                    child: Ink(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month_rounded),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '${DateFormat('yyyy.MM.dd').format(selectedRange.start)} - ${DateFormat('yyyy.MM.dd').format(selectedRange.end)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    initialValue: travelerCount,
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
                      if (value == null) return;
                      setSheetState(() => travelerCount = value);
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(sheetContext).pop(
                          _TripCreateSelection(
                            dateRange: selectedRange,
                            travelerCount: travelerCount,
                          ),
                        );
                      },
                      child: const Text('내 여행 추가'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final trips = controller.trips;

    return AppShell(
      title: '내 여행',
      modeName: controller.modeName,
      currentTabIndex: widget.currentTabIndex,
      onTabSelected: widget.onTabSelected,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: IconButton(
            onPressed: _createTrip,
            icon: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF16A34A),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(Icons.add_rounded, color: Colors.white),
            ),
          ),
        ),
      ],
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
          children: [
            if (trips.isEmpty)
              SectionCard(
                title: '아직 등록한 여행이 없어요',
                subtitle: '오른쪽 위 + 버튼으로 새 여행을 추가해 보세요.',
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _createTrip,
                    child: const Text('새 여행 추가'),
                  ),
                ),
              )
            else
              ...trips.map(
                (trip) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _TripCard(
                    trip: trip,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => TripDetailScreen(tripId: trip.id),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({
    required this.trip,
    required this.onTap,
  });

  final TripSummary trip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final nights = trip.endDate.difference(trip.startDate).inDays;
    final days = nights + 1;
    final now = DateTime.now();
    final start = DateTime(trip.startDate.year, trip.startDate.month, trip.startDate.day);
    final diffDays = start.difference(DateTime(now.year, now.month, now.day)).inDays;
    final statusLabel = diffDays > 0 ? '여행 전' : (diffDays == 0 ? '여행 중' : '여행 종료');
    final dLabel = diffDays > 0 ? 'D-$diffDays' : (diffDays == 0 ? 'D-Day' : '종료');

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$statusLabel — ${trip.regionName} ${nights}박${days}일 $dLabel',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF0F172A),
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                '${DateFormat('yyyy.MM.dd').format(trip.startDate)} - ${DateFormat('yyyy.MM.dd').format(trip.endDate)} · ${trip.travelerCount}명',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF64748B),
                    ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    '소비 현황',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const Spacer(),
                  Text(
                    _formatWon(trip.totalSpentAmount),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: const Color(0xFF16A34A),
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TripCreateSelection {
  const _TripCreateSelection({
    required this.dateRange,
    required this.travelerCount,
  });

  final DateTimeRange dateRange;
  final int travelerCount;
}

String _formatWon(int value) {
  final buffer = StringBuffer();
  final text = value.toString();
  for (var i = 0; i < text.length; i++) {
    final reversedIndex = text.length - i;
    buffer.write(text[i]);
    if (reversedIndex > 1 && reversedIndex % 3 == 1) {
      buffer.write(',');
    }
  }
  return '${buffer.toString()}원';
}
