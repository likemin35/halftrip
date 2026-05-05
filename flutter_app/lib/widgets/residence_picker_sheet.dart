import 'package:flutter/material.dart';

import '../data/residence_picker_data.dart';

class ResidencePickerResult {
  const ResidencePickerResult({
    required this.province,
    required this.district,
  });

  final String province;
  final String district;

  String get displayName => '$province $district';
}

class ResidencePickerSheet extends StatefulWidget {
  const ResidencePickerSheet({
    super.key,
    this.initialProvince,
    this.initialDistrict,
  });

  final String? initialProvince;
  final String? initialDistrict;

  static Future<ResidencePickerResult?> show(
    BuildContext context, {
    String? initialProvince,
    String? initialDistrict,
  }) {
    return showModalBottomSheet<ResidencePickerResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ResidencePickerSheet(
        initialProvince: initialProvince,
        initialDistrict: initialDistrict,
      ),
    );
  }

  @override
  State<ResidencePickerSheet> createState() => _ResidencePickerSheetState();
}

class _ResidencePickerSheetState extends State<ResidencePickerSheet> {
  late int _provinceIndex;
  late int _districtIndex;
  FixedExtentScrollController? _wheelController;

  ResidenceProvinceOption get _province => residencePickerOptions[_provinceIndex];

  @override
  void initState() {
    super.initState();
    _provinceIndex = _findProvinceIndex(widget.initialProvince);
    _districtIndex = _findDistrictIndex(_province, widget.initialDistrict);
    _wheelController = FixedExtentScrollController(initialItem: _districtIndex);
  }

  @override
  void dispose() {
    _wheelController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.82,
        minChildSize: 0.55,
        maxChildSize: 0.92,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF7F4EC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              children: [
                Center(
                  child: Container(
                    width: 56,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '나의 거주 지역 선택',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  '광역시/도는 버튼으로, 시/군/구는 스크롤로 선택합니다. 인접 지역 제외 규칙은 sample seed data 기준입니다.',
                ),
                const SizedBox(height: 24),
                Text(
                  '광역시/도',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (var index = 0;
                        index < residencePickerOptions.length;
                        index++)
                      ChoiceChip(
                        label: Text(residencePickerOptions[index].province),
                        selected: index == _provinceIndex,
                        onSelected: (_) => _selectProvince(index),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  '시/군/구',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 220,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFD8D2C6)),
                  ),
                  child: ListWheelScrollView.useDelegate(
                    controller: _wheelController,
                    itemExtent: 52,
                    perspective: 0.003,
                    diameterRatio: 1.4,
                    physics: const FixedExtentScrollPhysics(),
                    onSelectedItemChanged: (index) {
                      setState(() => _districtIndex = index);
                    },
                    childDelegate: ListWheelChildBuilderDelegate(
                      childCount: _province.districts.length,
                      builder: (context, index) {
                        final district = _province.districts[index];
                        final selected = index == _districtIndex;
                        return Center(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 180),
                            style: theme.textTheme.titleMedium!.copyWith(
                              fontWeight:
                                  selected ? FontWeight.w800 : FontWeight.w500,
                              color: selected
                                  ? const Color(0xFF0E4F42)
                                  : Colors.black54,
                            ),
                            child: Text(district),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F0FB),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '선택한 거주지',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_province.province} ${_province.districts[_districtIndex]}',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        '선택하신 거주지 및 sample adjacency rule 기준 인접 토큰을 제외한 반값여행지가 표시됩니다.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    backgroundColor: const Color(0xFF155EEF),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(
                      ResidencePickerResult(
                        province: _province.province,
                        district: _province.districts[_districtIndex],
                      ),
                    );
                  },
                  child: const Text('확인'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _selectProvince(int index) {
    setState(() {
      _provinceIndex = index;
      _districtIndex = 0;
      _wheelController?.dispose();
      _wheelController = FixedExtentScrollController(initialItem: 0);
    });
  }

  int _findProvinceIndex(String? province) {
    if (province == null || province.isEmpty) {
      return residencePickerOptions.indexWhere(
        (item) => item.province == '전라남도',
      );
    }
    final index = residencePickerOptions.indexWhere(
      (item) => province.contains(item.province),
    );
    return index < 0 ? 0 : index;
  }

  int _findDistrictIndex(ResidenceProvinceOption province, String? district) {
    if (district == null || district.isEmpty) {
      return 0;
    }
    final index = province.districts.indexWhere(
      (item) => district.contains(item),
    );
    return index < 0 ? 0 : index;
  }
}
