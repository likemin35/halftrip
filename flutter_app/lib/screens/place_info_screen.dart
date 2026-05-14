import 'package:flutter/material.dart';

import '../core/app_config.dart';
import '../core/app_scope.dart';
import '../models/app_models.dart';
import '../widgets/app_shell.dart';
import '../widgets/place_map_models.dart';
import '../widgets/place_map_view.dart';
import 'planner_screen.dart';

enum _PlaceInfoMapTab { designatedPlaces, merchants }

class PlaceInfoScreen extends StatefulWidget {
  const PlaceInfoScreen({super.key, required this.tripId});

  final int tripId;

  @override
  State<PlaceInfoScreen> createState() => _PlaceInfoScreenState();
}

class _PlaceInfoScreenState extends State<PlaceInfoScreen> {
  Future<(TripDetail, RegionDetail)>? _future;
  bool _initialized = false;
  _PlaceInfoMapTab _selectedTab = _PlaceInfoMapTab.designatedPlaces;
  int? _focusedMarkerId;

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
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => PlannerScreen(tripId: widget.tripId),
      ),
    );
  }

  int _nextVisitOrder(TripDetail tripDetail) {
    if (tripDetail.selectedPlaces.isEmpty) {
      return 1;
    }
    return tripDetail.selectedPlaces
            .map((item) => item.visitOrder)
            .reduce((a, b) => a > b ? a : b) +
        1;
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
      final payload = [
        ...tripDetail.selectedPlaces,
        TripPlaceItem(
          id: 0,
          placeType: PlaceCategory.halfPrice,
          referencePlaceId: place.id,
          placeName: place.name,
          address: place.address,
          visitOrder: _nextVisitOrder(tripDetail),
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
        SnackBar(content: Text('${place.name}를 플래너에 추가했습니다.')),
      );
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${place.name}은 이미 플래너에 담겨 있습니다.')),
    );
  }

  Future<void> _addMerchantToPlanner(
    TripDetail tripDetail,
    MerchantItem merchant,
  ) async {
    final controller = AppScope.of(context);
    final alreadyExists = tripDetail.selectedPlaces.any(
      (item) =>
          item.placeType == PlaceCategory.merchant &&
          item.referencePlaceId == merchant.id,
    );

    if (!alreadyExists) {
      final payload = [
        ...tripDetail.selectedPlaces,
        TripPlaceItem(
          id: 0,
          placeType: PlaceCategory.merchant,
          referencePlaceId: merchant.id,
          placeName: merchant.name,
          address: merchant.address,
          visitOrder: _nextVisitOrder(tripDetail),
          latitude: merchant.latitude,
          longitude: merchant.longitude,
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
        SnackBar(content: Text('${merchant.name}를 플래너에 추가했습니다.')),
      );
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${merchant.name}은 이미 플래너에 담겨 있습니다.')),
    );
  }

  List<PlaceMapMarkerData> _buildPlaceMarkers(
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

  List<MerchantItem> _buildFeaturedMerchants(List<MerchantItem> merchants) {
    final candidates = merchants
        .where((item) => item.latitude != null && item.longitude != null)
        .toList();
    if (candidates.length <= 10) {
      return candidates;
    }

    final anchor = candidates.first;
    candidates.sort((a, b) {
      final aDistance = _distanceScore(
        anchor.latitude!,
        anchor.longitude!,
        a.latitude!,
        a.longitude!,
      );
      final bDistance = _distanceScore(
        anchor.latitude!,
        anchor.longitude!,
        b.latitude!,
        b.longitude!,
      );
      return aDistance.compareTo(bDistance);
    });
    return candidates.take(10).toList();
  }

  double _distanceScore(
    double baseLat,
    double baseLng,
    double targetLat,
    double targetLng,
  ) {
    final latDiff = baseLat - targetLat;
    final lngDiff = baseLng - targetLng;
    return (latDiff * latDiff) + (lngDiff * lngDiff);
  }

  List<PlaceMapMarkerData> _buildMerchantMarkers(
    String regionName,
    List<MerchantItem> merchants,
    List<TripPlaceItem> selectedPlaces,
  ) {
    return merchants
        .where((merchant) => merchant.latitude != null && merchant.longitude != null)
        .map(
          (merchant) => PlaceMapMarkerData(
            id: merchant.id,
            name: merchant.name,
            address: merchant.address,
            latitude: merchant.latitude!,
            longitude: merchant.longitude!,
            selected: selectedPlaces.any(
              (item) =>
                  item.placeType == PlaceCategory.merchant &&
                  item.referencePlaceId == merchant.id,
            ),
            regionLabel: regionName,
            actionLabel: '플래너에 추가',
          ),
        )
        .toList();
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
          final featuredMerchants = _buildFeaturedMerchants(regionDetail.merchants);
          final showingMerchants = _selectedTab == _PlaceInfoMapTab.merchants;

          final markers = showingMerchants
              ? _buildMerchantMarkers(
                  tripDetail.trip.regionName,
                  featuredMerchants,
                  tripDetail.selectedPlaces,
                )
              : _buildPlaceMarkers(
                  tripDetail.trip.regionName,
                  places,
                  tripDetail.selectedPlaces,
                );

          final highlightedMarkerId = markers.any((item) => item.id == _focusedMarkerId)
              ? _focusedMarkerId
              : null;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              const _IntroCard(),
              const SizedBox(height: 16),
              SectionCard(
                title: '지도에서 장소 고르기',
                subtitle: showingMerchants
                    ? '지역 내 대표 지점을 기준으로 가까운 지역화폐 가맹점 10곳만 먼저 보여줍니다. 추후에는 내 위치 기준으로 확장할 수 있어요.'
                    : '카카오맵 마커를 누르면 지정관광지 정보가 지도 위 카드로 열리고, 바로 플래너에 추가할 수 있어요.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PlaceMapTabSwitcher(
                      selectedTab: _selectedTab,
                      onChanged: (tab) {
                        setState(() {
                          _selectedTab = tab;
                          _focusedMarkerId = null;
                        });
                      },
                    ),
                    const SizedBox(height: 14),
                    PlaceMapView(
                      markers: markers,
                      emptyMessage: showingMerchants
                          ? '표시할 지역화폐 가맹점 좌표가 없습니다.'
                          : '표시할 지정관광지 좌표가 아직 없습니다.',
                      kakaoEnabled: config.canUseKakaoMap,
                      highlightedMarkerId: highlightedMarkerId,
                      onMarkerTap: (markerId) {
                        setState(() {
                          _focusedMarkerId = markerId;
                        });
                      },
                      onMarkerDoubleTap: (markerId) {
                        setState(() {
                          _focusedMarkerId = markerId;
                        });
                      },
                      onMarkerAction: (markerId) async {
                        setState(() {
                          _focusedMarkerId = markerId;
                        });

                        if (showingMerchants) {
                          final selected = featuredMerchants.cast<MerchantItem?>().firstWhere(
                                (item) => item?.id == markerId,
                                orElse: () => null,
                              );
                          if (selected == null) return;
                          await _addMerchantToPlanner(tripDetail, selected);
                        } else {
                          final selected = places.cast<PlaceItem?>().firstWhere(
                                (item) => item?.id == markerId,
                                orElse: () => null,
                              );
                          if (selected == null) return;
                          await _addPlaceToPlanner(tripDetail, selected);
                        }
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
            '카카오맵 마커를 눌러 원하는 관광지나 가맹점을 보고, 플래너에 담아 여행 동선을 완성해 보세요.',
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

class _PlaceMapTabSwitcher extends StatelessWidget {
  const _PlaceMapTabSwitcher({
    required this.selectedTab,
    required this.onChanged,
  });

  final _PlaceInfoMapTab selectedTab;
  final ValueChanged<_PlaceInfoMapTab> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget buildTab(_PlaceInfoMapTab tab, String label) {
      final selected = tab == selectedTab;
      return Expanded(
        child: GestureDetector(
          onTap: () => onChanged(tab),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 46,
            decoration: BoxDecoration(
              color: selected ? const Color(0xFF16A34A) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected
                    ? const Color(0xFF16A34A)
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
    }

    return Row(
      children: [
        buildTab(_PlaceInfoMapTab.designatedPlaces, '지정관광지'),
        const SizedBox(width: 10),
        buildTab(_PlaceInfoMapTab.merchants, '지역화폐 가맹점'),
      ],
    );
  }
}

String? _placePhotoAsset(String placeName) {
  const mapping = <String, String>{
    '완도타워': 'assets/spot/wando/wandotower.jpg',
  };
  return mapping[placeName];
}
