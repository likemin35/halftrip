import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_scope.dart';
import '../models/app_models.dart';
import '../widgets/app_shell.dart';
import 'lodging_form_screen.dart';
import 'submission_package_screen.dart';

class SettlementScreen extends StatefulWidget {
  const SettlementScreen({super.key, required this.tripId});

  final int tripId;

  @override
  State<SettlementScreen> createState() => _SettlementScreenState();
}

class _SettlementScreenState extends State<SettlementScreen> {
  Future<(TripDetail, LodgingFormData?)>? _future;
  bool _initialized = false;

  static const Map<String, String> _settlementUrlsByRegion = {
    '평창': 'https://www.wandotrip.kr/bbs/apply_date.php',
    '횡성': 'https://www.wandotrip.kr/bbs/apply_date.php',
    '영월': 'https://halftour.kr/application/1',
    '제천': 'https://www.jctour.kr/menu2/1',
    '거창': 'https://geochangtour.kr/content/expenses_info',
    '고창': 'https://gochangtrip.co.kr/',
    '합천': 'https://hctour.kr/bbs/content.php?co_id=expenses_info',
    '영광': 'https://www.yeonggwang.go.kr/subpage/?site=travel&mn=16095',
    '밀양': 'https://mybanhada.com/',
    '영암': 'https://www.yeongam.go.kr/oneplusone',
    '하동': 'https://hadongtrip.kr/bbs/content.php?co_id=expenses_info',
    '강진': 'https://www.gangjintour.com/main/main.html?',
    '남해': 'https://www.namhae.go.kr/tour/01057/01058.web',
    '해남': 'https://www.haenam50.kr/',
    '고흥':
        'https://tour.goheung.go.kr/front/M0000361/content/view.do',
    '완도': 'https://www.wandotrip.kr/bbs/apply_date.php',
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    _future = _load();
    _initialized = true;
  }

  Future<(TripDetail, LodgingFormData?)> _load() async {
    final repo = AppScope.of(context).repository;
    final detail = await repo.getTripDetail(widget.tripId);
    LodgingFormData? formData;
    try {
      formData = await repo.getLodgingFormData(widget.tripId);
    } catch (_) {
      formData = null;
    }
    return (detail, formData);
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    return AppShell(
      title: '정산 신청',
      modeName: controller.modeName,
      child: FutureBuilder<(TripDetail, LodgingFormData?)>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final detail = snapshot.data!.$1;
          final formData = snapshot.data!.$2;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              SectionCard(
                title: '정산 상태',
                child: Text(detail.settlementSummary.statusMessage),
              ),
              SectionCard(
                title: '지역별 정산 페이지 이동',
                subtitle:
                    '${detail.trip.regionName} 지역 정산 사이트로 이동해 제출을 이어갈 수 있습니다.',
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => _openSettlementSite(detail.trip.regionName),
                    child: const Text('정산 신청하러 가기'),
                  ),
                ),
              ),
              SectionCard(
                title: '제출물 준비',
                subtitle: '모은 파일을 합친 PDF를 내려받거나 숙박확인서를 이어서 작성할 수 있습니다.',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: () => _openSubmissionPackage(detail),
                      child: const Text('제출물 내려받기'),
                    ),
                    OutlinedButton(
                      onPressed: _openLodgingForm,
                      child: const Text('숙박확인서 작성'),
                    ),
                    if (formData != null)
                      OutlinedButton(
                        onPressed: _downloadLodgingPdf,
                        child: const Text('숙박확인서 PDF'),
                      ),
                  ],
                ),
              ),
              SectionCard(
                title: '정산 상태 반영',
                subtitle: 'MVP 단계에서는 내부 상태를 정산 신청 완료로 먼저 바꿔볼 수 있습니다.',
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonal(
                    onPressed:
                        detail.trip.settlementApplied ? null : _applySettlement,
                    child: Text(
                      detail.trip.settlementApplied
                          ? '정산 신청 완료'
                          : '정산 신청 완료로 표시',
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openSettlementSite(String regionName) async {
    final url =
        _settlementUrlsByRegion[regionName] ?? _settlementUrlsByRegion['완도']!;
    final uri = Uri.parse(url);
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!mounted) {
      return;
    }

    if (!launched) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$regionName 정산 페이지를 열지 못했습니다.')),
      );
    }
  }

  Future<void> _openSubmissionPackage(TripDetail detail) async {
    final hasEvidence =
        detail.uploadedFiles.isNotEmpty || detail.lodgingInfo?.uploadedFileId != null;

    if (!mounted) {
      return;
    }

    if (!hasEvidence) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제출할 증빙이 아직 없습니다.')),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SubmissionPackageScreen(
          tripId: widget.tripId,
          detail: detail,
          showSettlementButton: false,
        ),
      ),
    );
  }

  Future<void> _downloadBundle(TripDetail detail) async {
    final controller = AppScope.of(context);
    final path = await controller.runTask(
      () => controller.repository.downloadMergedPdf(
        widget.tripId,
        detail.uploadedFiles.map((file) => file.id).toList(),
      ),
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('제출물 파일 위치: $path')),
    );
  }

  Future<void> _downloadLodgingPdf() async {
    final controller = AppScope.of(context);
    final path = await controller.runTask(
      () => controller.repository.downloadLodgingFormPdf(widget.tripId),
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('숙박확인서 PDF 위치: $path')),
    );
  }

  Future<void> _openLodgingForm() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LodgingFormScreen(tripId: widget.tripId),
      ),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _future = _load();
    });
  }

  Future<void> _applySettlement() async {
    final controller = AppScope.of(context);
    await controller.runTask(
      () => controller.repository.applySettlement(widget.tripId),
    );
    await controller.refreshTrips();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('정산 신청 완료 상태로 반영했습니다.')),
    );
    setState(() {
      _future = _load();
    });
  }
}
