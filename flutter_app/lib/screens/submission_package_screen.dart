import 'package:flutter/material.dart';

import '../models/app_models.dart';
import 'settlement_screen.dart';

class SubmissionPackageScreen extends StatelessWidget {
  const SubmissionPackageScreen({
    super.key,
    required this.tripId,
    required this.detail,
    this.showSettlementButton = true,
  });

  final int tripId;
  final TripDetail detail;
  final bool showSettlementButton;

  @override
  Widget build(BuildContext context) {
    final authPhotoCount = detail.uploadedFiles
        .where((file) => file.fileCategory == FileCategory.authPhoto)
        .length;
    final receiptCount = detail.receipts.length;
    final lodgingCount = detail.uploadedFiles
                .where(
                  (file) => file.fileCategory == FileCategory.lodgingConfirmation,
                )
                .length >
            0 ||
        detail.lodgingInfo?.uploadedFileId != null
        ? 1
        : 0;
    final fileSizeText = _buildEstimatedSize(
      authPhotoCount: authPhotoCount,
      receiptCount: receiptCount,
      lodgingCount: lodgingCount,
    );
    final includedItems =
        '인증사진 ${authPhotoCount}장, 영수증 ${receiptCount}건, 숙박확인서 ${lodgingCount}부';
    final fileName = '${detail.trip.regionName}_반값여행_증빙팩.zip';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                ),
                Expanded(
                  child: Text(
                    '제출용 증빙 팩',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: const Color(0xFF111827),
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
            const SizedBox(height: 22),
            const _PackageHero(),
            const SizedBox(height: 22),
            Text(
              '증빙 팩이 생성 완료되었습니다!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: const Color(0xFF111827),
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '자치체 제출 규격에 맞춰 파일을 생성했어요.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 24),
            _InfoCard(
              rows: [
                ('파일명', fileName),
                ('파일 크기', fileSizeText),
                ('포함 항목', includedItems),
              ],
            ),
            const SizedBox(height: 22),
            OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('파일 다운로드 기능은 다음 단계에서 구현할 예정입니다.'),
                  ),
                );
              },
              icon: const Icon(Icons.download_rounded),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(58),
                side: const BorderSide(color: Color(0xFFD7DEE8)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              label: const Text(
                '파일 다운로드',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            if (showSettlementButton) ...[
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SettlementScreen(tripId: tripId),
                    ),
                  );
                },
                icon: const Icon(Icons.open_in_new_rounded),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(58),
                  backgroundColor: const Color(0xFF16A34A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                label: const Text(
                  '정산 신청 페이지로 이동',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: Color(0xFF64748B),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '다음 단계 안내',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: const Color(0xFF111827),
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '생성한 파일을 정산 신청 페이지에 업로드하면 심사를 거쳐 지역화폐가 지급됩니다.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF64748B),
                          height: 1.6,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '실제 ZIP 생성과 다운로드 기능은 다음 단계에서 구현할 예정입니다.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF64748B),
                          height: 1.6,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildEstimatedSize({
    required int authPhotoCount,
    required int receiptCount,
    required int lodgingCount,
  }) {
    final size =
        1.8 + (authPhotoCount * 2.1) + (receiptCount * 0.9) + (lodgingCount * 0.7);
    return '${size.toStringAsFixed(1)}MB';
  }
}

class _PackageHero extends StatelessWidget {
  const _PackageHero();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 108,
            height: 108,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Icon(
              Icons.description_rounded,
              size: 62,
              color: Color(0xFFE2E8F0),
            ),
          ),
          Positioned(
            right: -6,
            bottom: -4,
            child: Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                color: Color(0xFF16A34A),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
          const Positioned(
            left: -10,
            top: 18,
            child: Icon(
              Icons.auto_awesome,
              color: Color(0xFFB6E6FF),
              size: 18,
            ),
          ),
          const Positioned(
            right: 2,
            top: -2,
            child: Icon(
              Icons.auto_awesome,
              color: Color(0xFFFFD77B),
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.rows});

  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: rows.asMap().entries.map((entry) {
          final index = entry.key;
          final row = entry.value;
          return Padding(
            padding: EdgeInsets.only(bottom: index == rows.length - 1 ? 0 : 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 84,
                  child: Text(
                    row.$1,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: const Color(0xFF475569),
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    row.$2,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: const Color(0xFF111827),
                          fontWeight: FontWeight.w700,
                          height: 1.45,
                        ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
