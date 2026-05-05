import 'package:flutter/material.dart';

import '../models/app_models.dart';

class MapPlaceholder extends StatelessWidget {
  const MapPlaceholder({
    super.key,
    required this.items,
    required this.title,
    required this.usingKakaoStructure,
  });

  final List<TripPlaceItem> items;
  final String title;
  final bool usingKakaoStructure;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 260,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFFDFF3F0), Color(0xFFF9F4E4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _MapPainter(items),
            ),
          ),
          Positioned(
            left: 16,
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                usingKakaoStructure
                    ? '$title\n카카오맵 SDK 구조로 설계되어 있으며 현재는 placeholder가 표시됩니다.'
                    : '$title\n지도가 설정되지 않아 placeholder가 표시됩니다.',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  _MapPainter(this.items);

  final List<TripPlaceItem> items;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFB7D5CE)
      ..strokeWidth = 1.0;

    for (var i = 0; i < 8; i++) {
      final dy = size.height / 8.0 * i;
      canvas.drawLine(Offset(0.0, dy), Offset(size.width, dy), gridPaint);
    }

    for (var i = 0; i < 8; i++) {
      final dx = size.width / 8.0 * i;
      canvas.drawLine(Offset(dx, 0.0), Offset(dx, size.height), gridPaint);
    }

    if (items.isEmpty) {
      final textPainter = TextPainter(
        text: const TextSpan(
          text: '선택한 장소가 없습니다.\n장소를 체크하면 순서에 따라 마커와 연결선이 표시됩니다.',
          style: TextStyle(
            color: Color(0xFF355C53),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout(maxWidth: size.width - 48.0);

      textPainter.paint(
        canvas,
        Offset(
          (size.width - textPainter.width) / 2.0,
          (size.height - textPainter.height) / 2.0,
        ),
      );
      return;
    }

    final positions = <Offset>[];
    for (var i = 0; i < items.length; i++) {
      final dx = 36.0 + (i % 4) * (size.width - 72.0) / 3.0;
      final dy = 90.0 + (i ~/ 4) * 70.0;
      positions.add(Offset(dx, dy));
    }

    final linePaint = Paint()
      ..color = const Color(0xFF215347)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < positions.length - 1; i++) {
      canvas.drawLine(positions[i], positions[i + 1], linePaint);
    }

    for (var i = 0; i < positions.length; i++) {
      final markerPaint = Paint()..color = const Color(0xFFE15C37);
      canvas.drawCircle(positions[i], 14.0, markerPaint);

      final labelPainter = TextPainter(
        text: TextSpan(
          text: '${i + 1}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      labelPainter.paint(
        canvas,
        positions[i] -
            Offset(
              labelPainter.width / 2.0,
              labelPainter.height / 2.0,
            ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MapPainter oldDelegate) {
    return oldDelegate.items != items;
  }
}
