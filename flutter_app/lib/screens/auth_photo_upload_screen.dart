import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../core/app_scope.dart';
import '../models/app_models.dart';
import '../widgets/app_shell.dart';

class AuthPhotoUploadScreen extends StatefulWidget {
  const AuthPhotoUploadScreen({super.key, required this.tripId});

  final int tripId;

  @override
  State<AuthPhotoUploadScreen> createState() => _AuthPhotoUploadScreenState();
}

class _AuthPhotoUploadScreenState extends State<AuthPhotoUploadScreen> {
  Future<TripDetail>? _future;
  bool _initialized = false;
  bool _uploading = false;
  final Map<int, Uint8List> _previewBytesByFileId = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _future = _loadDetail();
    _initialized = true;
  }

  Future<TripDetail> _loadDetail() async {
    final repository = AppScope.of(context).repository;
    final detail = await repository.getTripDetail(widget.tripId);
    await _hydratePreviews(detail);
    return detail;
  }

  Future<void> _hydratePreviews(TripDetail detail) async {
    final repository = AppScope.of(context).repository;
    final authFiles = detail.uploadedFiles.where(
      (file) =>
          file.fileCategory == FileCategory.authPhoto &&
          !_previewBytesByFileId.containsKey(file.id),
    );

    for (final file in authFiles) {
      try {
        final bytes = await repository.downloadUploadedFileBytes(
          tripId: widget.tripId,
          uploadedFileId: file.id,
        );
        _previewBytesByFileId[file.id] = bytes;
      } catch (_) {
        // Keep the screen usable even if a preview download fails.
      }
    }
  }

  Future<void> _reload() async {
    setState(() {
      _future = _loadDetail();
    });
    await AppScope.of(context).refreshTrips();
  }

  Future<void> _pickAndUploadPhoto(TripDetail detail) async {
    final existingCount = detail.uploadedFiles
        .where((file) => file.fileCategory == FileCategory.authPhoto)
        .length;
    if (existingCount >= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('관광지 인증사진은 최대 2장까지 등록할 수 있어요.')),
      );
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png'],
    );
    if (result == null || result.files.isEmpty) {
      return;
    }

    final file = result.files.single;
    if (file.bytes == null || file.bytes!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이미지 파일을 읽지 못했습니다. 다시 시도해 주세요.')),
      );
      return;
    }

    setState(() {
      _uploading = true;
    });

    try {
      final uploaded = await AppScope.of(context).repository.uploadFile(
        tripId: widget.tripId,
        category: FileCategory.authPhoto,
        file: UploadBinary(
          fileName: file.name,
          bytes: file.bytes!,
          mimeType: _guessMimeType(file.extension),
        ),
      );
      _previewBytesByFileId[uploaded.id] = file.bytes!;

      if (!mounted) return;
      await _reload();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('관광지 인증사진을 등록했습니다. 바로 인증 완료로 처리됩니다.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('관광지 인증사진 업로드에 실패했습니다: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _uploading = false;
        });
      }
    }
  }

  Future<void> _deletePhoto(int uploadedFileId) async {
    await AppScope.of(context).repository.deleteUploadedFile(
      tripId: widget.tripId,
      uploadedFileId: uploadedFileId,
    );
    _previewBytesByFileId.remove(uploadedFileId);
    await _reload();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('관광지 인증사진을 삭제했습니다.')),
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
    return AppShell(
      title: '인증샷 업로드',
      modeName: AppScope.of(context).modeName,
      child: FutureBuilder<TripDetail>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final detail = snapshot.data!;
          final authFiles = detail.uploadedFiles
              .where((file) => file.fileCategory == FileCategory.authPhoto)
              .toList();
          final requiredPlaces = detail.selectedPlaces.take(2).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            children: [
              _EvidenceStatusHeader(
                title: '관광지 인증사진 (${authFiles.length}/2)',
                icon: Icons.photo_camera_back_rounded,
                completed: authFiles.length >= 2,
                subtitle: '필수 관광지 사진을 2장까지 등록해 주세요.',
              ),
              const SizedBox(height: 18),
              _PrimaryUploadBox(
                icon: Icons.add_a_photo_rounded,
                title: _uploading ? '업로드 중입니다' : '관광지 사진 업로드',
                subtitle: '업로드하면 지금은 바로 AI 인증 통과로 처리합니다.',
                loading: _uploading,
                onTap: _uploading ? null : () => _pickAndUploadPhoto(detail),
              ),
              const SizedBox(height: 18),
              const _PhotoGuideCard(),
              const SizedBox(height: 22),
              Text(
                '등록된 인증샷',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: const Color(0xFF111827),
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 14),
              if (authFiles.isEmpty)
                const _EmptyEvidenceBlock(
                  message: '아직 등록된 관광지 인증사진이 없습니다.',
                )
              else
                _EvidencePhotoGrid(
                  items: authFiles.asMap().entries.map((entry) {
                    final index = entry.key;
                    final file = entry.value;
                    final label = index < requiredPlaces.length
                        ? requiredPlaces[index].placeName
                        : '관광지 인증샷 ${index + 1}';
                    return _PreviewTileData(
                      id: file.id,
                      label: label,
                      bytes: _previewBytesByFileId[file.id],
                    );
                  }).toList(),
                  onDelete: _deletePhoto,
                ),
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
              completed ? '완료' : '인증 대기',
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

class _PrimaryUploadBox extends StatelessWidget {
  const _PrimaryUploadBox({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.loading,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool loading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
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
                : Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F7F5),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Icon(icon, size: 34, color: const Color(0xFF16A34A)),
                  ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: const Color(0xFF111827),
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF64748B),
                    height: 1.45,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoGuideCard extends StatelessWidget {
  const _PhotoGuideCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF6FBF7),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFD6F1DE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '간단한 촬영 안내',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: const Color(0xFF111827),
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 14),
          const _GuideLine(text: '배경이 선명하게 나오도록 촬영해 주세요.'),
          const SizedBox(height: 10),
          const _GuideLine(text: '신청자를 포함한 모든 인원이 사진에 함께 나와야 합니다.'),
          const SizedBox(height: 10),
          const _GuideLine(text: '얼굴이 잘 보이도록 정면에 가깝게 찍어 주세요.'),
        ],
      ),
    );
  }
}

class _GuideLine extends StatelessWidget {
  const _GuideLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: Color(0xFFE8F8EE),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_rounded,
            size: 16,
            color: Color(0xFF16A34A),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFF475569),
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }
}

class _PreviewTileData {
  const _PreviewTileData({
    required this.id,
    required this.label,
    required this.bytes,
  });

  final int id;
  final String label;
  final Uint8List? bytes;
}

class _EvidencePhotoGrid extends StatelessWidget {
  const _EvidencePhotoGrid({
    required this.items,
    required this.onDelete,
  });

  final List<_PreviewTileData> items;
  final ValueChanged<int> onDelete;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final singleColumn = constraints.maxWidth < 360;
        final crossAxisCount = singleColumn ? 1 : 2;
        final aspectRatio = singleColumn ? 1.45 : 0.78;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: aspectRatio,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            return Container(
              padding: const EdgeInsets.all(10),
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
                    child: SizedBox(
                      height: singleColumn ? 150 : 110,
                      width: double.infinity,
                      child: item.bytes != null
                          ? Image.memory(item.bytes!, fit: BoxFit.cover)
                          : Container(
                              color: const Color(0xFFF8FAFC),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.landscape_rounded,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    item.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: const Color(0xFF111827),
                          fontWeight: FontWeight.w800,
                          height: 1.25,
                        ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () => onDelete(item.id),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFDC2626),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: const Text(
                        '삭제',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
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
