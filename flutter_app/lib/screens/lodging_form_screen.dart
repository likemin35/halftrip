import 'package:flutter/material.dart';

import '../core/app_scope.dart';
import '../models/app_models.dart';
import '../widgets/app_shell.dart';
import '../widgets/lodging_form_preview.dart';
import '../widgets/signature_pad.dart';

class LodgingFormScreen extends StatefulWidget {
  const LodgingFormScreen({super.key, required this.tripId});

  final int tripId;

  @override
  State<LodgingFormScreen> createState() => _LodgingFormScreenState();
}

class _LodgingFormScreenState extends State<LodgingFormScreen> {
  Future<LodgingFormData>? _future;
  bool _initialized = false;

  final Map<String, TextEditingController> _textControllers = {};
  final Map<String, bool> _checkboxValues = {};
  final Map<String, String> _signatureValues = {};
  LodgingFormData? _formData;

  String _firstSignatureFieldKey() {
    for (final field
        in _formData?.template.fields ?? const <LodgingFormFieldItem>[]) {
      if (field.isSignature) {
        return field.key;
      }
    }
    return 'signature';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _future = _load();
    _initialized = true;
  }

  @override
  void dispose() {
    for (final controller in _textControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<LodgingFormData> _load() async {
    final repository = AppScope.of(context).repository;
    final formData = await repository.getLodgingFormData(widget.tripId);
    _applyFormData(formData);
    return formData;
  }

  void _applyFormData(LodgingFormData formData) {
    final payload = formData.instance.payload;
    _formData = formData;

    final activeTextKeys = <String>{};
    final activeCheckboxKeys = <String>{};
    final activeSignatureKeys = <String>{};

    for (final field in formData.template.fields) {
      if (field.isSignature) {
        activeSignatureKeys.add(field.key);
        _signatureValues[field.key] = payload[field.key]?.toString() ?? '';
        continue;
      }

      if (field.isCheckbox) {
        activeCheckboxKeys.add(field.key);
        _checkboxValues[field.key] = payload[field.key] as bool? ?? false;
        continue;
      }

      activeTextKeys.add(field.key);
      final controller = _textControllers.putIfAbsent(
        field.key,
        TextEditingController.new,
      );
      controller.text = payload[field.key]?.toString() ?? '';
    }

    final textKeysToRemove = _textControllers.keys
        .where((key) => !activeTextKeys.contains(key))
        .toList();
    for (final key in textKeysToRemove) {
      _textControllers.remove(key)?.dispose();
    }

    final checkboxKeysToRemove = _checkboxValues.keys
        .where((key) => !activeCheckboxKeys.contains(key))
        .toList();
    for (final key in checkboxKeysToRemove) {
      _checkboxValues.remove(key);
    }

    final signatureKeysToRemove = _signatureValues.keys
        .where((key) => !activeSignatureKeys.contains(key))
        .toList();
    for (final key in signatureKeysToRemove) {
      _signatureValues.remove(key);
    }
  }

  Map<String, dynamic> _currentPayload() {
    final source = Map<String, dynamic>.from(
      _formData?.instance.payload ?? const <String, dynamic>{},
    );
    for (final entry in _textControllers.entries) {
      source[entry.key] = entry.value.text.trim();
    }
    for (final entry in _checkboxValues.entries) {
      source[entry.key] = entry.value;
    }
    for (final entry in _signatureValues.entries) {
      source[entry.key] = entry.value;
    }
    return source;
  }

  Future<void> _save() async {
    final controller = AppScope.of(context);
    final saved = await controller.runTask(
      () => controller.repository.saveLodgingForm(
        widget.tripId,
        LodgingFormSaveRequest(payload: _currentPayload(), status: 'DRAFT'),
      ),
    );
    if (!mounted) return;
    setState(() {
      _applyFormData(saved);
      _future = Future.value(saved);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('저장되었습니다.')),
    );
  }

  Future<void> _downloadPdf() async {
    final controller = AppScope.of(context);
    final saved = await controller.runTask(
      () => controller.repository.saveLodgingForm(
        widget.tripId,
        LodgingFormSaveRequest(payload: _currentPayload(), status: 'DRAFT'),
      ),
    );
    if (!mounted) return;
    setState(() {
      _applyFormData(saved);
      _future = Future.value(saved);
    });
    final path = await controller.runTask(
      () => controller.repository.downloadLodgingFormPdf(widget.tripId),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(path)),
    );
  }

  Future<void> _editSignature([String? fieldKey]) async {
    final resolvedFieldKey = fieldKey ?? _firstSignatureFieldKey();
    final signed = await showSignaturePadDialog(
      context,
      initialValue: _signatureValues[resolvedFieldKey] ?? '',
    );
    if (signed == null) return;
    setState(() {
      _signatureValues[resolvedFieldKey] = signed;
    });
  }

  String _fieldHint(LodgingFormFieldItem field) {
    return switch (field.key) {
      'business_number' => '123-45-67890',
      'occupancy_count' => '2',
      'payment_amount' => '180000',
      'payment_date' => '2026-05-03',
      'phone_number' => '010-1234-5678',
      'traveler_phone_number' => '010-1234-5678',
      _ => field.helperText.isEmpty ? '내용을 입력하세요.' : field.helperText,
    };
  }

  Future<void> _editFieldFromPreview(LodgingFormFieldItem field) async {
    if (field.isSignature) {
      await _editSignature(field.key);
      return;
    }
    if (field.isCheckbox) {
      setState(() {
        _checkboxValues[field.key] = !(_checkboxValues[field.key] ?? false);
      });
      return;
    }

    final controller = _textControllers.putIfAbsent(
      field.key,
      TextEditingController.new,
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                field.label,
                style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                maxLines: field.multiline ? 3 : 1,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: _fieldHint(field),
                  helperText:
                      field.helperText.isEmpty ? null : field.helperText,
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  child: const Text('완료'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    return AppShell(
      title: '숙박확인서',
      modeName: controller.modeName,
      child: FutureBuilder<LodgingFormData>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final formData = _formData ?? snapshot.data!;
          final previewData = LodgingFormData(
            tripId: formData.tripId,
            regionName: formData.regionName,
            template: formData.template,
            instance: LodgingFormInstanceItem(
              instanceId: formData.instance.instanceId,
              status: formData.instance.status,
              payload: _currentPayload(),
              lastSavedAt: formData.instance.lastSavedAt,
              renderedPdfFileName: formData.instance.renderedPdfFileName,
            ),
            todos: formData.todos,
          );
          final templatePdfUrl = controller.repository
              .getLodgingFormTemplatePreviewUrl(widget.tripId);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 980),
                  child: LodgingFormPreview(
                    formData: previewData,
                    onTapSignature: _editSignature,
                    templatePdfUrl: templatePdfUrl,
                    onTapField: _editFieldFromPreview,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  backgroundColor: const Color(0xFF16A34A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text(
                  '저장',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _downloadPdf,
                icon: const Icon(Icons.picture_as_pdf_outlined),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                label: const Text(
                  'PDF 내려받기',
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
