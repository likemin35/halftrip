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

  Future<void> _addPlaceToPlanner(
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
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${place.name}을(를) 플래너에 추가했습니다.')),
      );
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${place.name}은(는) 이미 플래너에 담겨 있습니다.')),
    );
  }

  List<PlaceMapMarkerData> _buildMarkers(
    String regionName,
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
            regionLabel: regionName,
            imageAssetPath: _placePhotoAsset(place.name),
            actionLabel: '플래너에 추가',
          ),
        )
        .toList();
  }

  PlaceItem? _resolveFocusedPlace(List<PlaceItem> places) {
    if (places.isEmpty) return null;
    if (_focusedPlace == null) return null;
    return places.cast<PlaceItem?>().firstWhere(
          (item) => item?.id == _focusedPlace!.id,
          orElse: () => null,
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
          final markers = _buildMarkers(
            tripDetail.trip.regionName,
            places,
            tripDetail.selectedPlaces,
          );

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              const _IntroCard(),
              const SizedBox(height: 16),
              SectionCard(
                title: '지도에서 장소 고르기',
                subtitle: '카카오맵 마커를 누르면 장소 정보가 지도 위 카드로 열리고, 바로 플래너에 추가할 수 있어요.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PlaceMapView(
                      markers: markers,
                      emptyMessage: '표시할 관광지 좌표가 아직 없습니다.',
                      kakaoEnabled: config.canUseKakaoMap,
                      highlightedMarkerId: focusedPlace?.id,
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
                      onMarkerDoubleTap: (placeId) {
                        final selected = places.cast<PlaceItem?>().firstWhere(
                              (item) => item?.id == placeId,
                              orElse: () => null,
                            );
                        if (selected == null) return;
                        setState(() {
                          _focusedPlace = selected;
                        });
                      },
                      onMarkerAction: (placeId) async {
                        final selected = places.cast<PlaceItem?>().firstWhere(
                              (item) => item?.id == placeId,
                              orElse: () => null,
                            );
                        if (selected == null) return;
                        setState(() {
                          _focusedPlace = selected;
                        });
                        await _addPlaceToPlanner(tripDetail, selected);
                      },
                      height: 500,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _openPlanner,
                        icon: const Icon(Icons.route_rounded),
                        label: Text(
                          '플래너 보기${tripDetail.selectedPlaces.isNotEmpty ? ' (${tripDetail.selectedPlaces.length})' : ''}',
                        ),
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
            '카카오맵 마커를 눌러 원하는 관광지를 보고, 플래너에 담아 여행 동선을 완성해 보세요.',
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

String? _placePhotoAsset(String placeName) {
  const mapping = <String, String>{
    '완도타워': 'assets/spot/wando/wandotower.jpg',
  };
  return mapping[placeName];
}
