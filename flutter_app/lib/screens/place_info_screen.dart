import 'package:flutter/material.dart';

import '../core/app_config.dart';
import '../core/app_scope.dart';
import '../models/app_models.dart';
import '../widgets/app_shell.dart';
import '../widgets/place_map_view.dart';
import 'planner_screen.dart';

class PlaceInfoScreen extends StatefulWidget {
  const PlaceInfoScreen({super.key, required this.tripId});

  final int tripId;

  @override
  State<PlaceInfoScreen> createState() => _PlaceInfoScreenState();
}

class _PlaceInfoScreenState extends State<PlaceInfoScreen> {
  Future<(TripDetail, RegionDetail)>? _future;
  bool _initialized = false;
  PlaceItem? _focusedPlace;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _future = _loadBundle();
    _initialized = true;
  }

  Future<(TripDetail, RegionDetail)> _loadBundle() async {
    final controller = AppScope.of(context);
    final tripDetail = await controller.repository.getTripDetail(widget.tripId);
    final regionDetail = await controller.repository.getRegionDetail(
      tripDetail.trip.regionId,
      residence: controller.currentUser?.residence,
    );
    final places = regionDetail.halfPricePlaces
        .where((place) => place.latitude != null && place.longitude != null)
        .toList();
    _focusedPlace ??= places.isEmpty ? null : places.first;
    return (tripDetail, regionDetail);
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _loadBundle();
    });
  }

  Future<void> _openPlanner() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlannerScreen(tripId: widget.tripId),
      ),
    );
    await _refresh();
  }

  Future<void> _addPlaceAndOpenPlanner(
    TripDetail tripDetail,
    PlaceItem place,
  ) async {
    final controller = AppScope.of(context);
    final alreadyExists = tripDetail.selectedPlaces.any(
      (item) =>
          item.placeType == PlaceCategory.halfPrice &&
          item.referencePlaceId == place.id,
    );

    if (!alreadyExists) {
      final nextOrder = tripDetail.selectedPlaces.isEmpty
          ? 1
          : tripDetail.selectedPlaces
                  .map((item) => item.visitOrder)
                  .reduce((a, b) => a > b ? a : b) +
              1;

      final payload = [
        ...tripDetail.selectedPlaces,
        TripPlaceItem(
          id: 0,
          placeType: PlaceCategory.halfPrice,
          referencePlaceId: place.id,
          placeName: place.name,
          address: place.address,
          visitOrder: nextOrder,
          latitude: place.latitude,
          longitude: place.longitude,
          checked: true,
        ),
      ];

      await controller.runTask(
        () => controller.repository.replaceTripPlaces(widget.tripId, payload),
      );
      await controller.refreshTrips();
    }

    if (!mounted) return;
    await _openPlanner();
  }

  List<PlaceMapMarkerData> _buildMarkers(
    List<PlaceItem> places,
    List<TripPlaceItem> selectedPlaces,
  ) {
    return places
        .where((place) => place.latitude != null && place.longitude != null)
        .map(
          (place) => PlaceMapMarkerData(
            id: place.id,
            name: place.name,
            address: place.address,
            latitude: place.latitude!,
            longitude: place.longitude!,
            selected: selectedPlaces.any(
              (item) =>
                  item.placeType == PlaceCategory.halfPrice &&
                  item.referencePlaceId == place.id,
            ),
          ),
        )
        .toList();
  }

  PlaceItem? _resolveFocusedPlace(List<PlaceItem> places) {
    if (places.isEmpty) return null;
    if (_focusedPlace == null) return places.first;
    return places.cast<PlaceItem?>().firstWhere(
          (item) => item?.id == _focusedPlace!.id,
          orElse: () => places.first,
        );
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final config = AppConfig.fromEnvironment();

    return AppShell(
      title: '직접 코스 만들기',
      modeName: controller.modeName,
      child: FutureBuilder<(TripDetail, RegionDetail)>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final tripDetail = snapshot.data!.$1;
          final regionDetail = snapshot.data!.$2;
          final places = regionDetail.halfPricePlaces
              .where((place) => place.latitude != null && place.longitude != null)
              .toList();
          final focusedPlace = _resolveFocusedPlace(places);
          final markers = _buildMarkers(places, tripDetail.selectedPlaces);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              const _IntroCard(),
              const SizedBox(height: 16),
              _MapSection(
                regionName: tripDetail.trip.regionName,
                kakaoEnabled: config.canUseKakaoMap,
                markers: markers,
                focusedPlace: focusedPlace,
                onMarkerTap: (placeId) {
                  final selected = places.cast<PlaceItem?>().firstWhere(
                        (item) => item?.id == placeId,
                        orElse: () => null,
                      );
                  if (selected == null) return;
                  setState(() {
                    _focusedPlace = selected;
                  });
                },
                onDetail: focusedPlace == null
                    ? null
                    : () {
                        showDialog<void>(
                          context: context,
                          builder: (dialogContext) => AlertDialog(
                            title: Text(focusedPlace.name),
                            content: Text(focusedPlace.address),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(dialogContext).pop(),
                                child: const Text('닫기'),
                              ),
                            ],
                          ),
                        );
                      },
                onAdd: focusedPlace == null
                    ? null
                    : () => _addPlaceAndOpenPlanner(tripDetail, focusedPlace),
              ),
              const SizedBox(height: 16),
              _PlannerEntryCard(
                count: tripDetail.selectedPlaces.length,
                onOpenPlanner: _openPlanner,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FFFB),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD7FBE8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '직접 코스 만들기',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: const Color(0xFF111827),
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '마커를 눌러 관광지를 선택하고 코스에 담아보세요.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF64748B),
                  height: 1.45,
                ),
          ),
        ],
      ),
    );
  }
}

class _MapSection extends StatelessWidget {
  const _MapSection({
    required this.regionName,
    required this.kakaoEnabled,
    required this.markers,
    required this.focusedPlace,
    required this.onMarkerTap,
    required this.onDetail,
    required this.onAdd,
  });

  final String regionName;
  final bool kakaoEnabled;
  final List<PlaceMapMarkerData> markers;
  final PlaceItem? focusedPlace;
  final ValueChanged<int> onMarkerTap;
  final VoidCallback? onDetail;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: '지도에서 장소 고르기',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: focusedPlace == null ? 430 : 620,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: PlaceMapView(
                    markers: markers,
                    emptyMessage: '표시할 관광지 좌표가 아직 없습니다.',
                    kakaoEnabled: kakaoEnabled,
                    highlightedMarkerId: focusedPlace?.id,
                    onMarkerTap: onMarkerTap,
                    onMarkerDoubleTap: onMarkerTap,
                    height: 430,
                  ),
                ),
                if (focusedPlace != null)
                  Positioned(
                    left: 14,
                    right: 14,
                    bottom: 0,
                    child: _FocusedPlaceCard(
                      regionName: regionName,
                      place: focusedPlace!,
                      onDetail: onDetail,
                      onAdd: onAdd,
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

class _FocusedPlaceCard extends StatelessWidget {
  const _FocusedPlaceCard({
    required this.regionName,
    required this.place,
    required this.onDetail,
    required this.onAdd,
  });

  final String regionName;
  final PlaceItem place;
  final VoidCallback? onDetail;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final imageAsset = _placePhotoAsset(place.name);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x180F172A),
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
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
              _InfoBadge(
                label: place.eligibleForRefund ? '환급 인증 가능' : '일반 관광지',
                backgroundColor: place.eligibleForRefund
                    ? const Color(0xFFFFF3E8)
                    : const Color(0xFFF1F5F9),
                textColor: place.eligibleForRefund
                    ? const Color(0xFFEA580C)
                    : const Color(0xFF475569),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            place.name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: const Color(0xFF111827),
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            place.address,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF64748B),
                  height: 1.45,
                ),
          ),
          if (place.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              place.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF94A3B8),
                    height: 1.4,
                  ),
            ),
          ],
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
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onDetail,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    side: const BorderSide(color: Color(0xFFD7DEE8)),
                  ),
                  child: const Text(
                    '상세 보기',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: onAdd,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                    backgroundColor: const Color(0xFF16A34A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    '코스에 추가',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlannerEntryCard extends StatelessWidget {
  const _PlannerEntryCard({
    required this.count,
    required this.onOpenPlanner,
  });

  final int count;
  final VoidCallback onOpenPlanner;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: '플래너',
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: onOpenPlanner,
          icon: const Icon(Icons.route_rounded),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF0F172A),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          label: Text('플래너 보기${count > 0 ? ' ($count)' : ''}'),
        ),
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
