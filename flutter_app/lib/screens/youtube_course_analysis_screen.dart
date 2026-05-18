import 'package:flutter/material.dart';

import '../core/app_config.dart';
import '../core/app_scope.dart';
import '../models/app_models.dart';
import '../services/youtube_course_analysis_service.dart';
import '../widgets/app_shell.dart';
import 'region_course_builder_screen.dart';

class YoutubeCourseAnalysisScreen extends StatefulWidget {
  const YoutubeCourseAnalysisScreen({
    super.key,
    required this.tripDetail,
    required this.youtubeUrl,
    required this.themes,
  });

  final TripDetail tripDetail;
  final String youtubeUrl;
  final List<String> themes;

  @override
  State<YoutubeCourseAnalysisScreen> createState() =>
      _YoutubeCourseAnalysisScreenState();
}

class _YoutubeCourseAnalysisScreenState
    extends State<YoutubeCourseAnalysisScreen> {
  Future<_YoutubeCoursePreparedResult>? _future;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _future = _prepare();
    _initialized = true;
  }

  Future<_YoutubeCoursePreparedResult> _prepare() async {
    final controller = AppScope.of(context);
    final regionDetail = await controller.repository.getRegionDetail(
      widget.tripDetail.trip.regionId,
      residence: controller.currentUser?.residence,
    );

    final analysis = await controller.runTask(
      () => YoutubeCourseAnalysisService(AppConfig.fromEnvironment()).analyze(
        url: widget.youtubeUrl,
        regionName: widget.tripDetail.trip.regionName,
        themes: widget.themes,
      ),
    );

    final matchedStops = _selectYoutubeStops(
      detail: regionDetail,
      themes: widget.themes,
      analysis: analysis,
    );

    final initialCourse = SavedCourse(
      id: 'youtube-${widget.tripDetail.trip.id}-${DateTime.now().millisecondsSinceEpoch}',
      regionId: widget.tripDetail.trip.regionId,
      regionName: widget.tripDetail.trip.regionName,
      title: analysis.title?.isNotEmpty == true
          ? '${widget.tripDetail.trip.regionName} 유튜브 추천 코스'
          : '${widget.tripDetail.trip.regionName} AI 추천 코스',
      preferences: widget.themes,
      stops: matchedStops,
      createdAt: DateTime.now(),
    );

    return _YoutubeCoursePreparedResult(
      regionDetail: regionDetail,
      analysis: analysis,
      initialCourse: initialCourse,
    );
  }

  List<SavedCourseStop> _selectYoutubeStops({
    required RegionDetail detail,
    required List<String> themes,
    required YoutubeCourseAnalysisResult analysis,
  }) {
    final scored = detail.halfPricePlaces
        .where((place) => place.latitude != null && place.longitude != null)
        .map(
          (place) => (
            place: place,
            score: _scoreYoutubePlace(place, themes, analysis),
          ),
        )
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    final selected = <PlaceItem>[];
    for (final item in scored) {
      if (item.score <= 0) {
        continue;
      }
      if (selected.any((element) => element.id == item.place.id)) {
        continue;
      }
      selected.add(item.place);
      if (selected.length >= 4) {
        break;
      }
    }

    if (selected.length < 2) {
      final fallback = detail.halfPricePlaces
          .where((place) => place.latitude != null && place.longitude != null)
          .take(3)
          .toList();
      selected
        ..clear()
        ..addAll(fallback);
    }

    return selected
        .map(
          (place) => SavedCourseStop(
            placeId: place.id,
            name: place.name,
            address: place.address,
            latitude: place.latitude ?? 0,
            longitude: place.longitude ?? 0,
            sourceType: PlaceCategory.halfPrice.wireName,
          ),
        )
        .toList();
  }

  int _scoreYoutubePlace(
    PlaceItem place,
    List<String> themes,
    YoutubeCourseAnalysisResult analysis,
  ) {
    final text = '${place.name} ${place.address} ${place.description}'.toLowerCase();
    var total = 0;

    for (final theme in themes) {
      if (_placeTags(place).contains(theme)) {
        total += 20;
      }
    }

    for (final keyword in analysis.keywords) {
      final normalized = keyword.toLowerCase().trim();
      if (normalized.isNotEmpty && text.contains(normalized)) {
        total += 28;
      }
    }

    for (final candidate in analysis.suggestedPlaceNames) {
      final normalized = candidate.toLowerCase().trim();
      if (normalized.isEmpty) continue;
      if (text.contains(normalized) ||
          normalized.contains(place.name.toLowerCase())) {
        total += 120;
      }
    }

    return total;
  }

  Set<String> _placeTags(PlaceItem place) {
    final text = '${place.name} ${place.address} ${place.description}';
    final tags = <String>{};
    if (_containsAny(text, ['해수욕장', '해안', '섬', '수목원', '생태', '산', '공원', '숲'])) {
      tags.addAll(['자연', '힐링']);
    }
    if (_containsAny(text, ['박물관', '기념관', '전시관', '유적', '향교', '서원', '관아'])) {
      tags.addAll(['문화', '체험']);
    }
    if (_containsAny(text, ['체험', '치유', '모노레일', '케이블카', '전망대', '타워', '축제'])) {
      tags.addAll(['체험', '사진']);
    }
    if (_containsAny(text, ['시장', '몰', '카페', '맛', '먹', '식당'])) {
      tags.add('맛집');
    }
    if (tags.isEmpty) {
      tags.addAll(['자연', '문화']);
    }
    return tags;
  }

  bool _containsAny(String source, List<String> keywords) {
    return keywords.any(source.contains);
  }

  Future<void> _openBuilder(_YoutubeCoursePreparedResult prepared) async {
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => RegionCourseBuilderScreen(
          regionId: widget.tripDetail.trip.regionId,
          regionName: widget.tripDetail.trip.regionName,
          initialCourse: prepared.initialCourse,
          tripId: widget.tripDetail.trip.id,
          initialTripPlaces: widget.tripDetail.selectedPlaces,
          initialMode: CourseBuildMode.ai,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: '영상 분석 코스 생성',
      modeName: AppScope.of(context).modeName,
      child: FutureBuilder<_YoutubeCoursePreparedResult>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              children: const [
                _YoutubeAnalysisLoadingCard(),
              ],
            );
          }

          final prepared = snapshot.data!;
          final analysis = prepared.analysis;
          final extractedPlaces = analysis.suggestedPlaceNames;
          final matchedStops = prepared.initialCourse.stops;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            children: [
              _YoutubeAnalysisSummaryCard(
                title: analysis.title,
                youtubeUrl: widget.youtubeUrl,
                usedTranscript: analysis.usedTranscript,
                usedThumbnailOcr: analysis.usedThumbnailOcr,
                usedFrameOcr: analysis.usedFrameOcr,
                frameCount: analysis.frameCount,
              ),
              const SizedBox(height: 16),
              _PlaceListCard(
                title: '영상에서 추출한 장소 정보',
                subtitle: '자막과 영상 프레임에서 읽은 관광지/식당 후보입니다.',
                items: extractedPlaces,
                emptyMessage: '영상에서 직접 추출된 장소명이 없어 지역 관광지 데이터와 테마를 기준으로 추천합니다.',
              ),
              const SizedBox(height: 16),
              _PlaceListCard(
                title: '현재 지역 데이터와 매칭된 추천 코스',
                subtitle: '추출된 장소 단서를 현재 지역 지정관광지 목록과 맞춰 코스 초안을 만들었습니다.',
                items: matchedStops.map((item) => item.name).toList(),
                emptyMessage: '직접 매칭된 장소가 부족해 기본 추천 코스로 채웠습니다.',
              ),
              if (analysis.warnings.isNotEmpty) ...[
                const SizedBox(height: 16),
                _WarningCard(warnings: analysis.warnings),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => _openBuilder(prepared),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  backgroundColor: const Color(0xFF16A34A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text(
                  '이 정보로 코스 구성하기',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _YoutubeCoursePreparedResult {
  const _YoutubeCoursePreparedResult({
    required this.regionDetail,
    required this.analysis,
    required this.initialCourse,
  });

  final RegionDetail regionDetail;
  final YoutubeCourseAnalysisResult analysis;
  final SavedCourse initialCourse;
}

class _YoutubeAnalysisLoadingCard extends StatelessWidget {
  const _YoutubeAnalysisLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          const SizedBox(
            width: 42,
            height: 42,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(height: 18),
          Text(
            '영상 분석 중입니다',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: const Color(0xFF111827),
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            '유튜브 자막을 먼저 읽고, 부족한 장면은 썸네일과 추출 프레임을 OCR/비전 분석해서 장소 정보를 모으고 있어요.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF64748B),
                  height: 1.6,
                ),
          ),
        ],
      ),
    );
  }
}

class _YoutubeAnalysisSummaryCard extends StatelessWidget {
  const _YoutubeAnalysisSummaryCard({
    required this.title,
    required this.youtubeUrl,
    required this.usedTranscript,
    required this.usedThumbnailOcr,
    required this.usedFrameOcr,
    required this.frameCount,
  });

  final String? title;
  final String youtubeUrl;
  final bool usedTranscript;
  final bool usedThumbnailOcr;
  final bool usedFrameOcr;
  final int frameCount;

  @override
  Widget build(BuildContext context) {
    final chips = <String>[
      if (usedTranscript) '자막 사용',
      if (usedThumbnailOcr) '썸네일 OCR',
      if (usedFrameOcr) '프레임 OCR ${frameCount}장',
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title?.isNotEmpty == true ? title! : '유튜브 영상 분석 결과',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: const Color(0xFF111827),
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            youtubeUrl,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF64748B),
                  height: 1.5,
                ),
          ),
          if (chips.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: chips
                  .map(
                    (chip) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: Text(
                        chip,
                        style: const TextStyle(
                          color: Color(0xFF15803D),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _PlaceListCard extends StatelessWidget {
  const _PlaceListCard({
    required this.title,
    required this.subtitle,
    required this.items,
    required this.emptyMessage,
  });

  final String title;
  final String subtitle;
  final List<String> items;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: const Color(0xFF111827),
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF64748B),
                  height: 1.5,
                ),
          ),
          const SizedBox(height: 14),
          if (items.isEmpty)
            Text(
              emptyMessage,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
            )
          else
            ...items.asMap().entries.map(
                  (entry) => Padding(
                    padding: EdgeInsets.only(bottom: entry.key == items.length - 1 ? 0 : 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE8F8EE),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${entry.key + 1}',
                            style: const TextStyle(
                              color: Color(0xFF16A34A),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            entry.value,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: const Color(0xFF111827),
                                  fontWeight: FontWeight.w700,
                                  height: 1.45,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

class _WarningCard extends StatelessWidget {
  const _WarningCard({required this.warnings});

  final List<String> warnings;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '분석 참고 메모',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF92400E),
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 10),
          ...warnings.map(
            (warning) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '• $warning',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF92400E),
                      height: 1.5,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
