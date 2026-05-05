import 'package:flutter/material.dart';

import '../models/app_models.dart';

class RegionEligibilityMap extends StatelessWidget {
  const RegionEligibilityMap({
    super.key,
    required this.regions,
    required this.selectedRegionId,
    required this.onSelect,
  });

  final List<RegionSummary> regions;
  final int? selectedRegionId;
  final ValueChanged<RegionSummary> onSelect;

  @override
  Widget build(BuildContext context) {
    const legendWidth = 168.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final legend = SizedBox(
          width: legendWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              _LegendHeader(),
              SizedBox(height: 18),
              _LegendRail(
                items: [
                  _LegendItemData(
                    color: Color(0xFFEAF2FF),
                    borderColor: Color(0xFF3A86FF),
                    label: '준비중',
                    icon: Icons.schedule_rounded,
                  ),
                  _LegendItemData(
                    color: Color(0xFFFFF1E7),
                    borderColor: Color(0xFFFF7A00),
                    label: '신청접수중',
                    icon: Icons.edit_square,
                  ),
                  _LegendItemData(
                    color: Color(0xFFF2F2F2),
                    borderColor: Color(0xFF9B9B9B),
                    label: '마감',
                    icon: Icons.lock_outline,
                  ),
                ],
              ),
              SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.star_rounded, color: Color(0xFFF5B700), size: 18),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '디지털 관광주민증 혜택 지역',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );

        final mapWidth = constraints.maxWidth < 980
            ? constraints.maxWidth
            : constraints.maxWidth - legendWidth - 24;
        final mapHeight = mapWidth * 1.22;

        final map = Container(
          width: mapWidth,
          height: mapHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            gradient: const LinearGradient(
              colors: [Color(0xFFF9F8F4), Color(0xFFF3F1EA)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _KoreaSilhouettePainter(),
                ),
              ),
              for (final region in regions)
                Positioned(
                  left: (mapWidth - 132) * (region.mapLeftPercent / 100),
                  top: (mapHeight - 48) * (region.mapTopPercent / 100),
                  child: _RegionChip(
                    region: region,
                    selected: region.id == selectedRegionId,
                    onTap: () => onSelect(region),
                  ),
                ),
            ],
          ),
        );

        if (constraints.maxWidth < 880) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              legend,
              const SizedBox(height: 18),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: map,
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            legend,
            const SizedBox(width: 24),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: map,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LegendHeader extends StatelessWidget {
  const _LegendHeader();

  @override
  Widget build(BuildContext context) {
    return Text(
      '지역별 진행 현황\n(예산 소진 시 자동 마감)',
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            height: 1.35,
          ),
    );
  }
}

class _LegendRail extends StatelessWidget {
  const _LegendRail({required this.items});

  final List<_LegendItemData> items;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 40,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: 12,
                  bottom: 12,
                  child: Container(
                    width: 1.4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1CDC4),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (final item in items)
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: item.color,
                          border: Border.all(color: item.borderColor),
                        ),
                        child: Icon(item.icon, color: item.borderColor, size: 18),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final item in items)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      item.label,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
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

class _LegendItemData {
  const _LegendItemData({
    required this.color,
    required this.borderColor,
    required this.label,
    required this.icon,
  });

  final Color color;
  final Color borderColor;
  final String label;
  final IconData icon;
}

class _RegionChip extends StatelessWidget {
  const _RegionChip({
    required this.region,
    required this.selected,
    required this.onTap,
  });

  final RegionSummary region;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = _chipStyle(region.statusCode, selected);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: style.background,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: style.border, width: selected ? 2.4 : 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: selected ? 0.16 : 0.08),
                blurRadius: selected ? 16 : 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(style.icon, size: 18, color: style.border),
              const SizedBox(width: 6),
              Text(
                region.name,
                style: TextStyle(
                  color: style.text,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (region.digitalBenefitAvailable) ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.star_rounded,
                  size: 16,
                  color: Color(0xFFF5B700),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  _ChipStyle _chipStyle(String statusCode, bool selected) {
    final normalized = statusCode.toUpperCase();
    if (normalized == 'APPLYING') {
      return _ChipStyle(
        background: selected ? const Color(0xFFFFE8D1) : const Color(0xFFFFF4EA),
        border: const Color(0xFFFF7A00),
        text: const Color(0xFF7D3200),
        icon: Icons.edit_square,
      );
    }
    if (normalized == 'CLOSED') {
      return _ChipStyle(
        background: selected ? const Color(0xFFE9E9E9) : const Color(0xFFF7F7F7),
        border: const Color(0xFF8C8C8C),
        text: const Color(0xFF5E5E5E),
        icon: Icons.lock_outline,
      );
    }
    return _ChipStyle(
      background: selected ? const Color(0xFFE3F0FF) : Colors.white,
      border: const Color(0xFF3A86FF),
      text: const Color(0xFF183B67),
      icon: Icons.schedule_rounded,
    );
  }
}

class _ChipStyle {
  const _ChipStyle({
    required this.background,
    required this.border,
    required this.text,
    required this.icon,
  });

  final Color background;
  final Color border;
  final Color text;
  final IconData icon;
}

class _KoreaSilhouettePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final mapRect = Rect.fromLTWH(
      size.width * 0.14,
      size.height * 0.02,
      size.width * 0.72,
      size.height * 0.90,
    );

    final fill = Paint()..color = const Color(0xFFE4E2DE);
    final stroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;
    final divider = Paint()
      ..color = Colors.white.withValues(alpha: 0.95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.4
      ..strokeCap = StrokeCap.round;

    final outline = _buildMainOutline(mapRect);
    final jeju = _buildJeju(mapRect);
    final westIslands = _buildWestIslands(mapRect);
    final eastIsland = _buildEastIsland(mapRect);

    canvas.drawShadow(outline, Colors.black.withValues(alpha: 0.10), 18, false);
    canvas.drawPath(outline, fill);
    canvas.drawPath(outline, stroke);
    canvas.drawPath(jeju, fill);
    canvas.drawPath(jeju, stroke);
    canvas.drawPath(eastIsland, fill);
    canvas.drawPath(eastIsland, stroke);

    for (final island in westIslands) {
      canvas.drawPath(island, fill);
      canvas.drawPath(island, stroke);
    }

    for (final path in _provinceLines(mapRect)) {
      canvas.drawPath(path, divider);
    }
  }

  Path _buildMainOutline(Rect rect) {
    final left = rect.left;
    final top = rect.top;
    final width = rect.width;
    final height = rect.height;

    return Path()
      ..moveTo(left + width * 0.57, top)
      ..quadraticBezierTo(
        left + width * 0.60,
        top + height * 0.03,
        left + width * 0.64,
        top + height * 0.07,
      )
      ..quadraticBezierTo(
        left + width * 0.70,
        top + height * 0.12,
        left + width * 0.73,
        top + height * 0.17,
      )
      ..quadraticBezierTo(
        left + width * 0.78,
        top + height * 0.25,
        left + width * 0.79,
        top + height * 0.33,
      )
      ..quadraticBezierTo(
        left + width * 0.82,
        top + height * 0.43,
        left + width * 0.81,
        top + height * 0.50,
      )
      ..quadraticBezierTo(
        left + width * 0.83,
        top + height * 0.61,
        left + width * 0.80,
        top + height * 0.68,
      )
      ..quadraticBezierTo(
        left + width * 0.77,
        top + height * 0.78,
        left + width * 0.72,
        top + height * 0.85,
      )
      ..quadraticBezierTo(
        left + width * 0.67,
        top + height * 0.93,
        left + width * 0.58,
        top + height * 0.96,
      )
      ..quadraticBezierTo(
        left + width * 0.52,
        top + height * 0.99,
        left + width * 0.44,
        top + height * 0.97,
      )
      ..quadraticBezierTo(
        left + width * 0.37,
        top + height * 0.95,
        left + width * 0.31,
        top + height * 0.89,
      )
      ..quadraticBezierTo(
        left + width * 0.26,
        top + height * 0.82,
        left + width * 0.22,
        top + height * 0.74,
      )
      ..quadraticBezierTo(
        left + width * 0.16,
        top + height * 0.64,
        left + width * 0.15,
        top + height * 0.56,
      )
      ..quadraticBezierTo(
        left + width * 0.13,
        top + height * 0.48,
        left + width * 0.15,
        top + height * 0.40,
      )
      ..quadraticBezierTo(
        left + width * 0.12,
        top + height * 0.31,
        left + width * 0.16,
        top + height * 0.24,
      )
      ..quadraticBezierTo(
        left + width * 0.19,
        top + height * 0.17,
        left + width * 0.26,
        top + height * 0.14,
      )
      ..quadraticBezierTo(
        left + width * 0.33,
        top + height * 0.11,
        left + width * 0.39,
        top + height * 0.12,
      )
      ..quadraticBezierTo(
        left + width * 0.45,
        top + height * 0.11,
        left + width * 0.48,
        top + height * 0.08,
      )
      ..quadraticBezierTo(
        left + width * 0.52,
        top + height * 0.05,
        left + width * 0.57,
        top,
      )
      ..close();
  }

  Path _buildJeju(Rect rect) {
    return Path()
      ..addOval(
        Rect.fromCenter(
          center: Offset(rect.left + rect.width * 0.18, rect.top + rect.height * 1.03),
          width: rect.width * 0.17,
          height: rect.height * 0.05,
        ),
      );
  }

  List<Path> _buildWestIslands(Rect rect) {
    Path island(double x, double y, double w, double h) {
      return Path()
        ..addOval(
          Rect.fromCenter(
            center: Offset(rect.left + rect.width * x, rect.top + rect.height * y),
            width: rect.width * w,
            height: rect.height * h,
          ),
        );
    }

    return [
      island(0.08, 0.34, 0.04, 0.02),
      island(0.05, 0.40, 0.028, 0.016),
      island(0.10, 0.45, 0.022, 0.014),
      island(0.12, 0.53, 0.018, 0.012),
    ];
  }

  Path _buildEastIsland(Rect rect) {
    return Path()
      ..addOval(
        Rect.fromCenter(
          center: Offset(rect.left + rect.width * 0.93, rect.top + rect.height * 0.43),
          width: rect.width * 0.03,
          height: rect.height * 0.02,
        ),
      );
  }

  List<Path> _provinceLines(Rect rect) {
    Path line(List<Offset> points) {
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (var i = 1; i < points.length; i++) {
        final previous = points[i - 1];
        final current = points[i];
        final control = Offset(
          (previous.dx + current.dx) / 2,
          (previous.dy + current.dy) / 2,
        );
        path.quadraticBezierTo(control.dx, control.dy, current.dx, current.dy);
      }
      return path;
    }

    Offset p(double x, double y) =>
        Offset(rect.left + rect.width * x, rect.top + rect.height * y);

    return [
      line([p(0.28, 0.18), p(0.40, 0.16), p(0.53, 0.19), p(0.64, 0.16)]),
      line([p(0.23, 0.33), p(0.34, 0.30), p(0.47, 0.31), p(0.61, 0.28)]),
      line([p(0.20, 0.48), p(0.34, 0.46), p(0.49, 0.44), p(0.66, 0.46)]),
      line([p(0.23, 0.63), p(0.36, 0.59), p(0.49, 0.60), p(0.64, 0.59)]),
      line([p(0.22, 0.78), p(0.35, 0.76), p(0.47, 0.76), p(0.58, 0.81)]),
      line([p(0.38, 0.14), p(0.33, 0.34), p(0.34, 0.55), p(0.33, 0.79)]),
      line([p(0.50, 0.17), p(0.48, 0.33), p(0.49, 0.55), p(0.49, 0.80)]),
      line([p(0.60, 0.19), p(0.59, 0.36), p(0.63, 0.57), p(0.59, 0.75)]),
      line([p(0.26, 0.24), p(0.18, 0.35), p(0.17, 0.49), p(0.21, 0.62)]),
    ];
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
