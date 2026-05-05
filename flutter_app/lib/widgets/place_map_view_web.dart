// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

import 'place_map_models.dart';

class PlaceMapView extends StatefulWidget {
  const PlaceMapView({
    super.key,
    required this.markers,
    required this.emptyMessage,
    required this.kakaoEnabled,
    this.routeMarkers = const [],
    this.connectSequentially = false,
    this.highlightedMarkerId,
    this.onMarkerTap,
    this.onMarkerDoubleTap,
    this.height = 420,
  });

  final List<PlaceMapMarkerData> markers;
  final String emptyMessage;
  final bool kakaoEnabled;
  final List<PlaceMapRoutePoint> routeMarkers;
  final bool connectSequentially;
  final int? highlightedMarkerId;
  final ValueChanged<int>? onMarkerTap;
  final ValueChanged<int>? onMarkerDoubleTap;
  final double height;

  @override
  State<PlaceMapView> createState() => _PlaceMapViewState();
}

class _PlaceMapViewState extends State<PlaceMapView> {
  static int _nextId = 0;
  static Future<void>? _sdkLoader;

  late final String _viewType;
  late final html.DivElement _container;
  late final html.EventListener _markerClickListener;
  late final html.EventListener _markerDoubleClickListener;
  late final html.EventListener _visibilityChangeListener;
  StreamSubscription<html.Event>? _resizeSubscription;
  Timer? _relayoutTimer;
  js.JsObject? _map;
  js.JsObject? _bounds;
  js.JsObject? _polyline;
  String? _statusMessage = '카카오맵을 불러오는 중입니다.';

  @override
  void initState() {
    super.initState();
    _viewType = 'kakao-place-map-${_nextId++}';
    _container = html.DivElement()
      ..id = _viewType
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.border = '0'
      ..style.borderRadius = '24px'
      ..style.overflow = 'hidden'
      ..style.backgroundColor = '#f8fafc';

    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int _) {
      return _container;
    });

    _markerClickListener = (event) {
      if (event is! html.CustomEvent) {
        return;
      }
      final detail = event.detail;
      if (detail is! Map || detail['viewId'] != _viewType) {
        return;
      }
      final placeId = detail['placeId'];
      if (placeId is int) {
        widget.onMarkerTap?.call(placeId);
      }
    };

    _markerDoubleClickListener = (event) {
      if (event is! html.CustomEvent) {
        return;
      }
      final detail = event.detail;
      if (detail is! Map || detail['viewId'] != _viewType) {
        return;
      }
      final placeId = detail['placeId'];
      if (placeId is int) {
        widget.onMarkerDoubleTap?.call(placeId);
      }
    };

    html.window.addEventListener(
      'travel-support-kakao-marker-click',
      _markerClickListener,
    );
    html.window.addEventListener(
      'travel-support-kakao-marker-double-click',
      _markerDoubleClickListener,
    );
    _visibilityChangeListener = (_) => _scheduleRelayout();
    html.document.addEventListener(
      'visibilitychange',
      _visibilityChangeListener,
    );
    _resizeSubscription = html.window.onResize.listen((_) {
      _scheduleRelayout();
    });

    scheduleMicrotask(_renderMap);
  }

  @override
  void didUpdateWidget(covariant PlaceMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    scheduleMicrotask(_renderMap);
  }

  @override
  void dispose() {
    _relayoutTimer?.cancel();
    _resizeSubscription?.cancel();
    html.window.removeEventListener(
      'travel-support-kakao-marker-click',
      _markerClickListener,
    );
    html.window.removeEventListener(
      'travel-support-kakao-marker-double-click',
      _markerDoubleClickListener,
    );
    html.document.removeEventListener(
      'visibilitychange',
      _visibilityChangeListener,
    );
    super.dispose();
  }

  Future<void> _renderMap() async {
    if (!mounted) {
      return;
    }

    if (widget.markers.isEmpty) {
      _showMessage(widget.emptyMessage);
      return;
    }

    if (!widget.kakaoEnabled) {
      _showMessage(
        '카카오맵 키가 연결되지 않았습니다. MAP_PROVIDER=kakao 와 KAKAO_MAP_APP_KEY 값을 확인해 주세요.',
      );
      return;
    }

    try {
      _showOverlay('카카오맵을 불러오는 중입니다.');
      await _ensureSdkLoaded();
      if (!mounted) {
        return;
      }

      final kakaoObject = js.context['kakao'];
      if (kakaoObject == null) {
        _showMessage(
          '카카오맵 SDK를 불러오지 못했습니다. JavaScript 키와 Web 도메인을 확인해 주세요.',
        );
        return;
      }

      final kakao = kakaoObject as js.JsObject;
      final maps = kakao['maps'] as js.JsObject?;
      if (maps == null) {
        _showMessage(
          '카카오맵 SDK는 로드됐지만 maps 객체를 찾지 못했습니다. JavaScript 키와 Web 도메인을 다시 확인해 주세요.',
        );
        return;
      }

      maps.callMethod('load', [
        js.allowInterop(() {
          _buildMap(kakao);
          if (mounted) {
            setState(() {
              _statusMessage = null;
            });
          }
        }),
      ]);
    } catch (error) {
      _showMessage(
        '카카오맵을 표시하는 중 오류가 발생했습니다.\n$error',
      );
    }
  }

  Future<void> _ensureSdkLoaded() {
    _sdkLoader ??= _loadSdk();
    return _sdkLoader!;
  }

  Future<void> _loadSdk() {
    final completer = Completer<void>();
    final existingKakao = js.context['kakao'];
    if (existingKakao != null) {
      completer.complete();
      return completer.future;
    }

    final script = html.ScriptElement()
      ..id = 'travel-support-kakao-sdk'
      ..src =
          'https://dapi.kakao.com/v2/maps/sdk.js?appkey=${const String.fromEnvironment('KAKAO_MAP_APP_KEY')}&autoload=false'
      ..async = true;

    script.onLoad.listen((_) {
      completer.complete();
    });
    script.onError.listen((_) {
      completer.completeError(
        StateError('Failed to load Kakao Map SDK'),
      );
    });

    html.document.head?.append(script);
    return completer.future;
  }

  void _buildMap(js.JsObject kakao) {
    final maps = kakao['maps'] as js.JsObject;
    final markers = widget.markers;
    if (markers.isEmpty) {
      _showMessage(widget.emptyMessage);
      return;
    }

    _container.children.clear();
    _polyline = null;

    final centerMarker = markers.first;
    final center = js.JsObject(
      maps['LatLng'] as js.JsFunction,
      [centerMarker.latitude, centerMarker.longitude],
    );
    final mapOptions = js.JsObject.jsify({
      'center': center,
      'level': 10,
    });
    final map = js.JsObject(
      maps['Map'] as js.JsFunction,
      [_container, mapOptions],
    );

    final bounds = js.JsObject(maps['LatLngBounds'] as js.JsFunction);
    final markerImageCtor = maps['MarkerImage'] as js.JsFunction;
    final sizeCtor = maps['Size'] as js.JsFunction;
    final pointCtor = maps['Point'] as js.JsFunction;
    final eventApi = maps['event'] as js.JsObject;

    for (var index = 0; index < markers.length; index++) {
      final markerData = markers[index];
      DateTime? lastMarkerTapAt;
      Timer? singleTapTimer;
      final position = js.JsObject(
        maps['LatLng'] as js.JsFunction,
        [markerData.latitude, markerData.longitude],
      );
      bounds.callMethod('extend', [position]);

      final image = js.JsObject(
        markerImageCtor,
        [
          _markerSvg(
            label: '${index + 1}',
            selected: markerData.selected,
          ),
          js.JsObject(sizeCtor, [42, 54]),
          js.JsObject.jsify({
            'offset': js.JsObject(pointCtor, [21, 54]),
          }),
        ],
      );

      final marker = js.JsObject(
        maps['Marker'] as js.JsFunction,
        [
          js.JsObject.jsify({
            'position': position,
            'map': map,
            'title': markerData.name,
            'image': image,
          }),
        ],
      );

      final infoWindow = js.JsObject(
        maps['InfoWindow'] as js.JsFunction,
        [
          js.JsObject.jsify({
            'content': _infoWindowHtml(markerData),
          }),
        ],
      );

      eventApi.callMethod('addListener', [
        marker,
        'click',
        js.allowInterop(() {
          infoWindow.callMethod('open', [map, marker]);
          final now = DateTime.now();
          final isDoubleTap = lastMarkerTapAt != null &&
              now.difference(lastMarkerTapAt!).inMilliseconds < 260;
          if (isDoubleTap) {
            singleTapTimer?.cancel();
            lastMarkerTapAt = null;
            html.window.dispatchEvent(
              html.CustomEvent(
                'travel-support-kakao-marker-double-click',
                detail: {
                  'viewId': _viewType,
                  'placeId': markerData.id,
                },
              ),
            );
            return;
          }

          lastMarkerTapAt = now;
          singleTapTimer?.cancel();
          singleTapTimer = Timer(const Duration(milliseconds: 230), () {
            html.window.dispatchEvent(
              html.CustomEvent(
                'travel-support-kakao-marker-click',
                detail: {
                  'viewId': _viewType,
                  'placeId': markerData.id,
                },
              ),
            );
          });
        }),
      ]);

      if (widget.highlightedMarkerId == markerData.id) {
        infoWindow.callMethod('open', [map, marker]);
      }
    }

    _map = map;
    _bounds = bounds;

    if (widget.connectSequentially && widget.routeMarkers.length >= 2) {
      final path = widget.routeMarkers
          .map(
            (point) => js.JsObject(
              maps['LatLng'] as js.JsFunction,
              [point.latitude, point.longitude],
            ),
          )
          .toList();

      _polyline = js.JsObject(
        maps['Polyline'] as js.JsFunction,
        [
          js.JsObject.jsify({
            'map': map,
            'path': js.JsArray.from(path),
            'strokeWeight': 4,
            'strokeColor': '#7C3AED',
            'strokeOpacity': 0.9,
            'strokeStyle': 'dash',
          }),
        ],
      );
    }

    map.callMethod('setBounds', [bounds]);
    _scheduleRelayout();
  }

  String _markerSvg({
    required String label,
    required bool selected,
  }) {
    final fill = selected ? '#0F766E' : '#2563EB';
    final stroke = selected ? '#064E3B' : '#1D4ED8';
    final svg = '''
<svg xmlns="http://www.w3.org/2000/svg" width="42" height="54" viewBox="0 0 42 54">
  <path d="M21 2C10.5066 2 2 10.5066 2 21C2 35.25 21 52 21 52C21 52 40 35.25 40 21C40 10.5066 31.4934 2 21 2Z" fill="$fill" stroke="$stroke" stroke-width="2"/>
  <circle cx="21" cy="21" r="11" fill="white"/>
  <text x="21" y="25" text-anchor="middle" font-size="12" font-weight="700" fill="$fill" font-family="Arial, sans-serif">$label</text>
</svg>
''';
    return 'data:image/svg+xml;charset=UTF-8,${Uri.encodeComponent(svg)}';
  }

  void _scheduleRelayout() {
    _relayoutTimer?.cancel();
    _relayoutTimer = Timer(const Duration(milliseconds: 80), _relayoutMap);
    Timer(const Duration(milliseconds: 250), _relayoutMap);
    Timer(const Duration(milliseconds: 700), _relayoutMap);
  }

  void _relayoutMap() {
    if (!mounted || _map == null || _bounds == null) {
      return;
    }
    if (_container.clientWidth == 0 || _container.clientHeight == 0) {
      return;
    }

    try {
      _map!.callMethod('relayout');
      _map!.callMethod('setBounds', [_bounds!]);
    } catch (_) {
      // Retry timers will handle temporary tab/layout issues.
    }
  }

  String _infoWindowHtml(PlaceMapMarkerData marker) {
    final name = _escapeHtml(marker.name);
    final address = _escapeHtml(marker.address);
    return '''
<div style="padding:14px 16px; min-width:220px; max-width:260px; font-family:Arial,sans-serif;">
  <div style="font-size:16px; font-weight:800; color:#111827; margin-bottom:6px;">$name</div>
  <div style="font-size:13px; line-height:1.5; color:#475569; margin-bottom:10px;">$address</div>
  <div style="display:inline-flex; align-items:center; gap:6px; padding:6px 10px; border-radius:999px; background:#eff6ff; color:#2563eb; font-size:12px; font-weight:700;">
    한 번 클릭: 위치 확인
  </div>
  <div style="height:8px;"></div>
  <div style="display:inline-flex; align-items:center; gap:6px; padding:6px 10px; border-radius:999px; background:#ecfdf5; color:#16a34a; font-size:12px; font-weight:700;">
    두 번 클릭: 여행동선 추가
  </div>
</div>
''';
  }

  String _escapeHtml(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  void _showOverlay(String message) {
    if (!mounted) {
      return;
    }
    setState(() {
      _statusMessage = message;
    });
  }

  void _showMessage(String message) {
    if (mounted) {
      setState(() {
        _statusMessage = message;
      });
    }

    _container.children.clear();
    _container.text = '';
    final paragraph = html.ParagraphElement()
      ..text = message
      ..style.margin = '0'
      ..style.padding = '24px'
      ..style.textAlign = 'center'
      ..style.color = '#475569'
      ..style.fontSize = '14px'
      ..style.lineHeight = '1.6'
      ..style.whiteSpace = 'pre-line';
    _container.append(paragraph);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          clipBehavior: Clip.antiAlias,
          child: HtmlElementView(viewType: _viewType),
        ),
        if (_statusMessage != null)
          Positioned(
            left: 12,
            right: 12,
            top: 12,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  _statusMessage!,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                    height: 1.45,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
