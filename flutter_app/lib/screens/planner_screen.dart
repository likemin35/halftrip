import 'package:flutter/material.dart';

import '../core/app_config.dart';
import '../core/app_scope.dart';
import '../models/app_models.dart';
import '../widgets/app_shell.dart';
import '../widgets/place_map_view.dart';

class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key, required this.tripId});

  final int tripId;

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  Future<TripDetail>? _future;
  bool _initialized = false;
  int? _highlightedPlaceId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _future = AppScope.of(context).repository.getTripDetail(widget.tripId);
    _initialized = true;
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    setState(() {
      _future = AppScope.of(context).repository.getTripDetail(widget.tripId);
    });
  }

  List<TripPlaceItem> _rebuildPlaces(List<TripPlaceItem> places) {
    return places.asMap().entries.map((entry) {
      final item = entry.value;
      return TripPlaceItem(
        id: item.id,
        placeType: item.placeType,
        referencePlaceId: item.referencePlaceId,
        placeName: item.placeName,
        address: item.address,
        visitOrder: entry.key + 1,
        latitude: item.latitude,
        longitude: item.longitude,
        checked: item.checked,
      );
    }).toList();
  }

  Future<void> _savePlaces(
    List<TripPlaceItem> places, {
    required String snackBarMessage,
  }) async {
    final controller = AppScope.of(context);
    final payload = _rebuildPlaces(places);
    await controller.runTask(
      () => controller.repository.replaceTripPlaces(widget.tripId, payload),
    );
    await controller.refreshTrips();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(snackBarMessage)),
    );
    await _refresh();
  }

  Future<void> _removePlace(
    List<TripPlaceItem> places,
    TripPlaceItem target,
  ) async {
    final updated = places
        .where(
          (item) =>
              !(item.placeType == target.placeType &&
                  item.referencePlaceId == target.referencePlaceId),
        )
        .toList();

    if (_highlightedPlaceId == target.referencePlaceId) {
      setState(() {
        _highlightedPlaceId = updated.isEmpty ? null : updated.first.referencePlaceId;
      });
    }

    await _savePlaces(updated, snackBarMessage: '플래너에서 장소를 제거했습니다.');
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final config = AppConfig.fromEnvironment();

    return AppShell(
      title: '여행 동선',
      modeName: controller.modeName,
      child: FutureBuilder<TripDetail>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final tripDetail = snapshot.data!;
          final places = [...tripDetail.selectedPlaces]
            ..sort((a, b) => a.visitOrder.compareTo(b.visitOrder));

          final markers = places
              .where((item) => item.latitude != null && item.longitude != null)
              .map(
                (item) => PlaceMapMarkerData(
                  id: item.referencePlaceId,
                  name: item.placeName,
                  address: item.address,
                  latitude: item.latitude!,
                  longitude: item.longitude!,
                  selected: true,
                ),
              )
              .toList();

          final routeMarkers = places
              .where((item) => item.latitude != null && item.longitude != null)
              .map(
                (item) => PlaceMapRoutePoint(
                  id: item.referencePlaceId,
                  latitude: item.latitude!,
                  longitude: item.longitude!,
                ),
              )
              .toList();

          final highlightedMarker = markers.cast<PlaceMapMarkerData?>().firstWhere(
                (item) => item?.id == _highlightedPlaceId,
                orElse: () => markers.isEmpty ? null : markers.first,
              );

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              _PlannerHeaderCard(trip: tripDetail.trip, count: places.length),
              const SizedBox(height: 16),
              const _DayTabs(),
              const SizedBox(height: 16),
              SectionCard(
                title: '지도',
                child: Column(
                  children: [
                    PlaceMapView(
                      markers: markers,
                      routeMarkers: routeMarkers,
                      connectSequentially: true,
                      emptyMessage: '아직 추가된 장소가 없습니다. 코스 만들기에서 먼저 장소를 담아 주세요.',
                      kakaoEnabled: config.canUseKakaoMap,
                      highlightedMarkerId: highlightedMarker?.id,
                      onMarkerTap: (placeId) {
                        setState(() {
                          _highlightedPlaceId = placeId;
                        });
                      },
                      onMarkerDoubleTap: (placeId) {
                        setState(() {
                          _highlightedPlaceId = placeId;
                        });
                      },
                      height: 380,
                    ),
                    if (highlightedMarker != null) ...[
                      const SizedBox(height: 14),
                      _SelectedPlaceCard(
                        marker: highlightedMarker,
                        regionName: tripDetail.trip.regionName,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SectionCard(
                title: '방문 순서',
                child: Column(
                  children: [
                    if (places.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Text(
                          '아직 추가된 일정이 없습니다. 직접 코스 만들기에서 장소를 먼저 담아 주세요.',
                        ),
                      )
                    else
                      ReorderableListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: places.length,
                        onReorder: (oldIndex, newIndex) async {
                          if (newIndex > oldIndex) {
                            newIndex -= 1;
                          }

                          final reordered = [...places];
                          final moved = reordered.removeAt(oldIndex);
                          reordered.insert(newIndex, moved);

                          await _savePlaces(
                            reordered,
                            snackBarMessage: '여행 동선 순서를 저장했습니다.',
                          );
                        },
                        itemBuilder: (context, index) {
                          final item = places[index];
                          final isHighlighted =
                              item.referencePlaceId == _highlightedPlaceId;

                          return Container(
                            key: ValueKey(
                              '${item.placeType.wireName}_${item.referencePlaceId}',
                            ),
                            margin: const EdgeInsets.only(bottom: 10),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(18),
                              onTap: () {
                                setState(() {
                                  _highlightedPlaceId = item.referencePlaceId;
                                });
                              },
                              child: Ink(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isHighlighted
                                      ? const Color(0xFFEFF6FF)
                                      : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: isHighlighted
                                        ? const Color(0xFF93C5FD)
                                        : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: const Color(0xFF7C3AED),
                                      foregroundColor: Colors.white,
                                      child: Text('${index + 1}'),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.placeName,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w800,
                                                  color: const Color(0xFF111827),
                                                ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            item.address,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: const Color(0xFF64748B),
                                                  height: 1.45,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => _removePlace(places, item),
                                      icon: const Icon(Icons.close_rounded),
                                      tooltip: '제거',
                                    ),
                                    const Icon(
                                      Icons.drag_handle_rounded,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.route_outlined),
                        label: const Text('직접 코스 만들기로 돌아가기'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PlannerHeaderCard extends StatelessWidget {
  const _PlannerHeaderCard({
    required this.trip,
    required this.count,
  });

  final TripSummary trip;
  final int count;

  @override
  Widget build(BuildContext context) {
    final period =
        '${trip.startDate.year}.${trip.startDate.month}.${trip.startDate.day} - '
        '${trip.endDate.year}.${trip.endDate.month}.${trip.endDate.day}';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${trip.regionName} 여행',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            period,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.78),
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MetricChip(
                icon: Icons.route_rounded,
                label: '선택 장소 $count곳',
              ),
              _MetricChip(
                icon: Icons.group_outlined,
                label: '여행 인원 ${trip.travelerCount}명',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _DayTabs extends StatelessWidget {
  const _DayTabs();

  @override
  Widget build(BuildContext context) {
    final labels = ['DAY 1', 'DAY 2', 'DAY 3'];
    return Row(
      children: labels.asMap().entries.map((entry) {
        final index = entry.key;
        final label = entry.value;
        final selected = index == 0;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index == labels.length - 1 ? 0 : 10),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF0F172A) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : const Color(0xFF475569),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SelectedPlaceCard extends StatelessWidget {
  const _SelectedPlaceCard({
    required this.marker,
    required this.regionName,
  });

  final PlaceMapMarkerData marker;
  final String regionName;

  @override
  Widget build(BuildContext context) {
    final imageAsset = _placePhotoAsset(marker.name);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoBadge(
                label: regionName,
                backgroundColor: const Color(0xFFE7F8EF),
                textColor: const Color(0xFF15803D),
              ),
              const _InfoBadge(
                label: '선택된 장소',
                backgroundColor: Color(0xFFF1F5F9),
                textColor: Color(0xFF475569),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            marker.name,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: const Color(0xFF111827),
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            marker.address,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF64748B),
                  height: 1.45,
                ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: AspectRatio(
              aspectRatio: 16 / 7,
              child: imageAsset != null
                  ? Image.asset(imageAsset, fit: BoxFit.cover)
                  : Container(
                      color: const Color(0xFFF8FAFC),
                      alignment: Alignment.center,
                      child: Text(
                        '사진 없음',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: const Color(0xFF94A3B8),
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  const _InfoBadge({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

String? _placePhotoAsset(String placeName) {
  const mapping = <String, String>{
    '완도타워': 'assets/spot/wando/wandotower.jpg',
  };
  return mapping[placeName];
}
