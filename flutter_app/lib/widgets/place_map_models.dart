class PlaceMapMarkerData {
  const PlaceMapMarkerData({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.selected,
  });

  final int id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final bool selected;
}

class PlaceMapRoutePoint {
  const PlaceMapRoutePoint({
    required this.id,
    required this.latitude,
    required this.longitude,
  });

  final int id;
  final double latitude;
  final double longitude;
}
