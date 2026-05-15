import 'dart:math' as math;
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/app_scope.dart';
import '../models/app_models.dart';
import '../widgets/app_shell.dart';

class ReceiptEvidenceScreen extends StatefulWidget {
  const ReceiptEvidenceScreen({super.key, required this.tripId});

  final int tripId;

  @override
  State<ReceiptEvidenceScreen> createState() => _ReceiptEvidenceScreenState();
}

class _ReceiptEvidenceScreenState extends State<ReceiptEvidenceScreen> {
  Future<TripDetail>? _future;
  bool _initialized = false;
  bool _uploading = false;

  Uint8List? _draftPreviewBytes;
  String? _draftPreviewFileName;
  ReceiptItem? _draftReceipt;
  UploadedFileItem? _draftUploadedFile;

  final Map<int, Uint8List> _savedPreviewBytesByFileId = {};
  final Map<int, String> _savedPreviewFileNamesByFileId = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _future = _load();
    _initialized = true;
  }

  Future<TripDetail> _load() async {
    final repository = AppScope.of(context).repository;
    final detail = await repository.getTripDetail(widget.tripId);
    await _hydrateSavedReceiptPreviews(detail);
    return detail;
  }

  Future<void> _hydrateSavedReceiptPreviews(TripDetail detail) async {
    final repository = AppScope.of(context).repository;
    final receiptFileIds = detail.receipts.map((item) => item.uploadedFileId).toSet();
    final imageFiles = detail.uploadedFiles.where(
      (file) =>
          receiptFileIds.contains(file.id) &&
          file.fileCategory == FileCategory.receiptImage &&
          !_savedPreviewBytesByFileId.containsKey(file.id),
    );

    for (final file in imageFiles) {
      try {
        final bytes = await repository.downloadUploadedFileBytes(
          tripId: widget.tripId,
          uploadedFileId: file.id,
        );
        _savedPreviewBytesByFileId[file.id] = bytes;
        _savedPreviewFileNamesByFileId.putIfAbsent(file.id, () => file.originalFileName);
      } catch (_) {
        // Preview load failure should not block the rest of the screen.
      }
    }
  }

  Future<void> _reload() async {
    setState(() {
      _future = _load();
    });
    await AppScope.of(context).refreshTrips();
  }

  Future<void> _pickAndAnalyzeReceipt() async {
    final repository = AppScope.of(context).repository;
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png'],
    );
    if (result == null || result.files.isEmpty) {
      return;
    }

    final selected = result.files.single;
    if (selected.bytes == null || selected.bytes!.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이미지 파일을 읽지 못했습니다. 다시 시도해 주세요.')),
      );
      return;
    }

    setState(() {
      _uploading = true;
      _draftPreviewBytes = selected.bytes;
      _draftPreviewFileName = selected.name;
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
        usageScope: ReceiptUsageScope.general,
      );

      if (!mounted) return;
      setState(() {
        _draftUploadedFile = uploaded;
        _draftReceipt = receipt;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('영수증 분석에 실패했습니다: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _uploading = false;
        });
      }
    }
  }

  Future<void> _commitDraftReceipt() async {
    final draftReceipt = _draftReceipt;
    final draftUploadedFile = _draftUploadedFile;
    final draftPreviewBytes = _draftPreviewBytes;
    if (draftReceipt == null || draftUploadedFile == null) {
      return;
    }

    if (draftPreviewBytes != null) {
      _savedPreviewBytesByFileId[draftUploadedFile.id] = draftPreviewBytes;
    }
    if (_draftPreviewFileName != null) {
      _savedPreviewFileNamesByFileId[draftUploadedFile.id] = _draftPreviewFileName!;
    }

    setState(() {
      _draftReceipt = null;
      _draftUploadedFile = null;
      _draftPreviewBytes = null;
      _draftPreviewFileName = null;
    });

    await _reload();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('영수증을 추가했습니다.')),
    );
  }

  Future<void> _deleteReceipt(int uploadedFileId) async {
    await AppScope.of(context).repository.deleteUploadedFile(
      tripId: widget.tripId,
      uploadedFileId: uploadedFileId,
    );
    _savedPreviewBytesByFileId.remove(uploadedFileId);
    _savedPreviewFileNamesByFileId.remove(uploadedFileId);
    await _reload();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('영수증을 삭제했습니다.')),
    );
  }

  String _guessMimeType(String? extension) {
    return switch ((extension ?? '').toLowerCase()) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      _ => 'application/octet-stream',
    };
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.decimalPattern('ko_KR');

    return AppShell(
      title: '영수증 추가',
      modeName: AppScope.of(context).modeName,
      child: FutureBuilder<TripDetail>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final detail = snapshot.data!;
          final uploadedFilesById = {
            for (final item in detail.uploadedFiles) item.id: item,
          };
          final receipts = [...detail.receipts]..sort((a, b) => b.id.compareTo(a.id));

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            children: [
              _EvidenceStatusHeader(
                title: '영수증 증빙 (${receipts.length}건)',
                icon: Icons.receipt_long_rounded,
                completed: receipts.isNotEmpty,
                subtitle: '영수증 사진을 올리면 OCR 결과와 함께 목록에 저장됩니다.',
              ),
              const SizedBox(height: 18),
              _DashedUploadBox(
                loading: _uploading,
                onTap: _uploading ? null : _pickAndAnalyzeReceipt,
              ),
              if (_draftReceipt != null && _draftUploadedFile != null) ...[
                const SizedBox(height: 18),
                const _ReceiptOcrBanner(),
                const SizedBox(height: 18),
                _ReceiptImagePreview(
                  previewBytes: _draftPreviewBytes,
                  fileName: _draftPreviewFileName ?? _draftUploadedFile!.originalFileName,
                ),
                const SizedBox(height: 18),
                _ReceiptInfoCard(
                  receipt: _draftReceipt!,
                  currency: currency,
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: _commitDraftReceipt,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(58),
                    backgroundColor: const Color(0xFF16A34A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    '추가 완료',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
              const SizedBox(height: 22),
              Text(
                '추가된 영수증',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: const Color(0xFF111827),
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 14),
              if (receipts.isEmpty)
                const _EmptyEvidenceBlock(message: '아직 추가된 영수증이 없습니다.')
              else
                ...receipts.map((receipt) {
                  final uploadedFile = uploadedFilesById[receipt.uploadedFileId];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _SavedReceiptCard(
                      receipt: receipt,
                      uploadedFile: uploadedFile,
                      previewBytes: _savedPreviewBytesByFileId[receipt.uploadedFileId],
                      previewFileName:
                          _savedPreviewFileNamesByFileId[receipt.uploadedFileId] ??
                              uploadedFile?.originalFileName,
                      currency: currency,
                      onDelete: () => _deleteReceipt(receipt.uploadedFileId),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}

class _EvidenceStatusHeader extends StatelessWidget {
  const _EvidenceStatusHeader({
    required this.title,
    required this.icon,
    required this.completed,
    required this.subtitle,
  });

  final String title;
  final IconData icon;
  final bool completed;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: const Color(0xFF0F172A)),
          ),
          const SizedBox(width: 14),
          Expanded(
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
                        height: 1.45,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: completed ? const Color(0xFFE8F8EE) : const Color(0xFFFFF3E8),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              completed ? '완료' : '등록 대기',
              style: TextStyle(
                color: completed ? const Color(0xFF16A34A) : const Color(0xFFEA580C),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedUploadBox extends StatelessWidget {
  const _DashedUploadBox({
    required this.loading,
    required this.onTap,
  });

  final bool loading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: const Color(0xFFCBD5E1),
          radius: 28,
        ),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            children: [
              loading
                  ? const SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    )
                  : Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F7F5),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Icon(
                        Icons.receipt_long_rounded,
                        size: 34,
                        color: Color(0xFF16A34A),
                      ),
                    ),
              const SizedBox(height: 16),
              Text(
                '영수증 사진을 업로드 하세요',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: const Color(0xFF111827),
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                '업로드하면 OCR로 금액과 영수증 정보를 읽어와 저장 목록으로 옮겨둡니다.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF64748B),
                      height: 1.5,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({
    required this.color,
    required this.radius,
  });

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rect);

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      const dash = 10.0;
      const gap = 7.0;
      while (distance < metric.length) {
        final next = math.min(distance + dash, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}

class _ReceiptOcrBanner extends StatelessWidget {
  const _ReceiptOcrBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF2FBF5),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD6F1DE)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFB9E7C9)),
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Color(0xFF16A34A),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'OCR 인식 완료',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: const Color(0xFF111827),
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '영수증 정보를 확인하고 추가 완료를 눌러 주세요.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF64748B),
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

class _ReceiptImagePreview extends StatelessWidget {
  const _ReceiptImagePreview({
    required this.previewBytes,
    required this.fileName,
  });

  final Uint8List? previewBytes;
  final String? fileName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F5),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: previewBytes != null
            ? Image.memory(previewBytes!, fit: BoxFit.cover)
            : Container(
                height: 220,
                color: Colors.white,
                alignment: Alignment.center,
                child: Text(
                  fileName ?? '영수증 미리보기',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
      ),
    );
  }
}

class _SavedReceiptCard extends StatelessWidget {
  const _SavedReceiptCard({
    required this.receipt,
    required this.uploadedFile,
    required this.previewBytes,
    required this.previewFileName,
    required this.currency,
    required this.onDelete,
  });

  final ReceiptItem receipt;
  final UploadedFileItem? uploadedFile;
  final Uint8List? previewBytes;
  final String? previewFileName;
  final NumberFormat currency;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final approved = receipt.reviewStatus == ReceiptReviewStatus.approved;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: previewBytes != null
                ? AspectRatio(
                    aspectRatio: 1.5,
                    child: Image.memory(previewBytes!, fit: BoxFit.cover),
                  )
                : Container(
                    height: 180,
                    width: double.infinity,
                    color: const Color(0xFFF8FAFC),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.receipt_long_rounded,
                      color: Color(0xFF94A3B8),
                      size: 34,
                    ),
                  ),
          ),
          const SizedBox(height: 14),
          Text(
            previewFileName ?? uploadedFile?.originalFileName ?? '영수증',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF111827),
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '결제 금액 ${currency.format(receipt.amount ?? receipt.eligibleAmount)}원',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF475569),
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            '결제 수단 ${receipt.paymentType.label}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF64748B),
                ),
          ),
          const SizedBox(height: 12),
          _ReceiptInfoCard(
            receipt: receipt,
            currency: currency,
            compact: true,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: approved ? const Color(0xFFE8F8EE) : const Color(0xFFFDECEC),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  approved ? '인정 가능' : '확인 필요',
                  style: TextStyle(
                    color: approved ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('삭제'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFDC2626),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReceiptInfoCard extends StatelessWidget {
  const _ReceiptInfoCard({
    required this.receipt,
    required this.currency,
    this.compact = false,
  });

  final ReceiptItem receipt;
  final NumberFormat currency;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final approved = receipt.reviewStatus == ReceiptReviewStatus.approved;
    final statusText = approved
        ? '환급 조건에 부합하는 영수증입니다.'
        : receipt.reviewReason.isEmpty
            ? '검토 결과를 다시 확인해 주세요.'
            : receipt.reviewReason;

    return Container(
      padding: EdgeInsets.all(compact ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '인식된 정보',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: const Color(0xFF111827),
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 14),
          _InfoRow(
            label: '결제 금액',
            value: '${currency.format(receipt.amount ?? receipt.eligibleAmount)}원',
          ),
          _InfoRow(
            label: '결제 일시',
            value: _formatPaymentDateTime(receipt.paymentDateTime) ?? '확인되지 않음',
          ),
          _InfoRow(
            label: '결제 수단',
            value: receipt.paymentType.label,
            hideDivider: true,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                '환급 인정 여부',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: const Color(0xFF111827),
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: approved ? const Color(0xFFE8F8EE) : const Color(0xFFFDECEC),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  approved ? '인정 가능' : '확인 필요',
                  style: TextStyle(
                    color: approved ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            statusText,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF64748B),
                  height: 1.45,
                ),
          ),
        ],
      ),
    );
  }

  String? _formatPaymentDateTime(DateTime? value) {
    if (value == null) return null;
    return DateFormat('yyyy.MM.dd HH:mm').format(value);
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.hideDivider = false,
  });

  final String label;
  final String value;
  final bool hideDivider;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: hideDivider
            ? null
            : const Border(
                bottom: BorderSide(color: Color(0xFFF1F5F9)),
              ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF475569),
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF111827),
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyEvidenceBlock extends StatelessWidget {
  const _EmptyEvidenceBlock({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
