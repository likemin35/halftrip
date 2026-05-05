import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/app_scope.dart';
import '../models/app_models.dart';
import '../widgets/app_shell.dart';

class EvidenceUploadScreen extends StatefulWidget {
  const EvidenceUploadScreen({super.key, required this.tripId});

  final int tripId;

  @override
  State<EvidenceUploadScreen> createState() => _EvidenceUploadScreenState();
}

class _EvidenceUploadScreenState extends State<EvidenceUploadScreen> {
  Future<TripDetail>? _future;
  bool _initialized = false;
  bool _uploadingReceipt = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    _reload();
    _initialized = true;
  }

  void _reload() {
    _future = AppScope.of(context).repository.getTripDetail(widget.tripId);
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final currency = NumberFormat.decimalPattern('ko_KR');

    return AppShell(
      title: '증빙서류',
      modeName: controller.modeName,
      child: FutureBuilder<TripDetail>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final detail = snapshot.data!;
          final trip = detail.trip;
          final spent = detail.settlementSummary.totalSpentAmount;
          final target = detail.settlementSummary.refundConditionAmount;
          final progress = target == 0 ? 0.0 : spent / target;
          final safeProgress = progress.clamp(0.0, 1.0);
          final percent = (safeProgress * 100).round();
          final remaining = detail.settlementSummary.remainingAmount;
          final checklist = _buildChecklist(detail);
          final uploadedFilesById = {
            for (final item in detail.uploadedFiles) item.id: item,
          };

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '반값여행',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '인구감소지역 여행경비 50% 환급',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: const Color(0xFF94A3B8),
                                  ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          size: 18,
                          color: Color(0xFFEF4444),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          trip.regionName,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _EvidenceSectionCard(
                title: '소비 현황',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: Theme.of(context).textTheme.headlineMedium,
                        children: [
                          TextSpan(
                            text: '${currency.format(spent)}원',
                            style: const TextStyle(
                              color: Color(0xFF10B981),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          TextSpan(
                            text: ' / 목표 ${currency.format(target)}원',
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: safeProgress,
                        minHeight: 12,
                        backgroundColor: const Color(0xFFE5E7EB),
                        valueColor: const AlwaysStoppedAnimation(
                          Color(0xFF10B981),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '$percent% 달성 · ${currency.format(remaining)}원 남음',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: const Color(0xFF64748B),
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _EvidenceSectionCard(
                title: '인증 체크리스트',
                child: Column(
                  children: checklist
                      .map(
                        (item) => _ChecklistTile(
                          title: item.title,
                          checked: item.checked,
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _FeatureActionCard(
                      emoji: '📷',
                      label: '인증샷 업로드',
                      loading: false,
                      onTap: () => _showPreparing(context),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _FeatureActionCard(
                      emoji: '🧾',
                      label: '영수증 스캔',
                      loading: _uploadingReceipt,
                      onTap: _uploadingReceipt ? null : _handleReceiptUpload,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _EvidenceSectionCard(
                title: '영수증 심사 결과',
                child: detail.receipts.isEmpty
                    ? Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '영수증을 업로드하면 결제수단, 인정 여부, 인정 금액을 자동으로 심사합니다.',
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: const Color(0xFF64748B),
                                    height: 1.5,
                                  ),
                        ),
                      )
                    : Column(
                        children: detail.receipts
                            .map(
                              (receipt) => Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: _ReceiptReviewCard(
                                  receipt: receipt,
                                  fileName: uploadedFilesById[receipt.uploadedFileId]
                                          ?.originalFileName ??
                                      'uploaded-receipt',
                                  currency: currency,
                                ),
                              ),
                            )
                            .toList(),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<_ChecklistItem> _buildChecklist(TripDetail detail) {
    final hasAuthPhoto = detail.uploadedFiles.any(
      (file) => file.fileCategory == FileCategory.authPhoto,
    );
    final hasApprovedReceipt = detail.receipts.any(
      (receipt) => receipt.reviewStatus == ReceiptReviewStatus.approved,
    );

    return [
      _ChecklistItem(
        title: '대표 관광지 방문 인증',
        checked: detail.selectedPlaces.isNotEmpty,
      ),
      _ChecklistItem(
        title: '추가 관광지 방문 인증',
        checked: hasAuthPhoto,
      ),
      _ChecklistItem(
        title: '필수 소비 인증',
        checked: hasApprovedReceipt,
      ),
    ];
  }

  Future<void> _handleReceiptUpload() async {
    final repository = AppScope.of(context).repository;
    final usageScope = await _pickReceiptUsageScope(context);
    if (usageScope == null) {
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf'],
    );
    if (result == null || result.files.isEmpty) {
      return;
    }

    final selected = result.files.single;
    if (selected.bytes == null || selected.bytes!.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('파일을 읽지 못했습니다. 다시 시도해 주세요.')),
      );
      return;
    }

    setState(() {
      _uploadingReceipt = true;
    });

    try {
      final uploaded = await repository.uploadFile(
        tripId: widget.tripId,
        category: FileCategory.receiptImage,
        file: UploadBinary(
          fileName: selected.name,
          bytes: selected.bytes!,
          mimeType: _guessMimeType(selected.extension),
        ),
      );
      final receipt = await repository.analyzeReceipt(
        tripId: widget.tripId,
        uploadedFileId: uploaded.id,
        usageScope: usageScope,
      );

      if (!mounted) {
        return;
      }
      setState(() {
        _reload();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            receipt.reviewStatus == ReceiptReviewStatus.approved
                ? '영수증이 심사를 통과했습니다.'
                : '영수증이 자동 심사에서 인정되지 않았습니다.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('영수증 심사에 실패했습니다: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _uploadingReceipt = false;
        });
      }
    }
  }

  Future<ReceiptUsageScope?> _pickReceiptUsageScope(BuildContext context) {
    return showModalBottomSheet<ReceiptUsageScope>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '영수증 종류 선택',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                '완도는 숙박 결제일 때만 현금영수증이 인정됩니다.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF64748B),
                    ),
              ),
              const SizedBox(height: 18),
              _UsageScopeTile(
                title: '일반 결제 영수증',
                subtitle: '카드 영수증, 온라인 결제 영수증용',
                onTap: () => Navigator.of(context).pop(ReceiptUsageScope.general),
              ),
              const SizedBox(height: 12),
              _UsageScopeTile(
                title: '숙박 결제 영수증',
                subtitle: '숙박업소 결제 영수증용',
                onTap: () => Navigator.of(context).pop(ReceiptUsageScope.lodging),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _guessMimeType(String? extension) {
    return switch ((extension ?? '').toLowerCase()) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'pdf' => 'application/pdf',
      _ => 'application/octet-stream',
    };
  }

  void _showPreparing(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('준비중입니다. 추후에는 갤러리와 카메라 업로드를 연결할 예정입니다.'),
      ),
    );
  }
}

class _EvidenceSectionCard extends StatelessWidget {
  const _EvidenceSectionCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 22),
          child,
        ],
      ),
    );
  }
}

class _ChecklistTile extends StatelessWidget {
  const _ChecklistTile({
    required this.title,
    required this.checked,
  });

  final String title;
  final bool checked;

  @override
  Widget build(BuildContext context) {
    final activeColor =
        checked ? const Color(0xFF10B981) : const Color(0xFFF1F5F9);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFF1F5F9)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: activeColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: checked
                ? const Icon(Icons.check_rounded, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: checked
                        ? const Color(0xFF64748B)
                        : const Color(0xFF0F172A),
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          Text(
            checked ? '완료' : '확인 필요',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: checked
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF22C55E),
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _FeatureActionCard extends StatelessWidget {
  const _FeatureActionCard({
    required this.emoji,
    required this.label,
    required this.onTap,
    required this.loading,
  });

  final String emoji;
  final String label;
  final VoidCallback? onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 34, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            loading
                ? const SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  )
                : Text(emoji, style: const TextStyle(fontSize: 36)),
            const SizedBox(height: 18),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0F172A),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UsageScopeTile extends StatelessWidget {
  const _UsageScopeTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            const Icon(Icons.receipt_long_rounded, color: Color(0xFF10B981)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF64748B),
                        ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

class _ReceiptReviewCard extends StatelessWidget {
  const _ReceiptReviewCard({
    required this.receipt,
    required this.fileName,
    required this.currency,
  });

  final ReceiptItem receipt;
  final String fileName;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (receipt.reviewStatus) {
      ReceiptReviewStatus.approved => const Color(0xFF10B981),
      ReceiptReviewStatus.rejected => const Color(0xFFEF4444),
      ReceiptReviewStatus.pending => const Color(0xFFF59E0B),
    };

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  fileName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  receipt.reviewStatus.label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MetaChip(label: receipt.usageScope.label),
              _MetaChip(label: receipt.paymentType.label),
              if (receipt.amount != null)
                _MetaChip(label: '결제금액 ${currency.format(receipt.amount)}원'),
              _MetaChip(label: '인정금액 ${currency.format(receipt.eligibleAmount)}원'),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            receipt.reviewReason.isEmpty
                ? '심사 사유가 아직 없습니다.'
                : receipt.reviewReason,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF475569),
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: const Color(0xFF334155),
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _ChecklistItem {
  const _ChecklistItem({
    required this.title,
    required this.checked,
  });

  final String title;
  final bool checked;
}
