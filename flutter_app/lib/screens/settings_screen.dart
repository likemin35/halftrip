import 'package:flutter/material.dart';

import '../core/app_scope.dart';
import '../models/app_models.dart';
import '../widgets/app_shell.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late NotificationSettings _settings;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _settings = AppScope.of(context).currentUser!.notificationSettings;
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    return AppShell(
      title: '설정',
      modeName: controller.modeName,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SwitchListTile(
            value: _settings.favoriteRegionPreopenAlert,
            onChanged: (value) => setState(() {
              _settings = _settings.copyWith(favoriteRegionPreopenAlert: value);
            }),
            title: const Text('관심 지역 사전신청 오픈 알림'),
          ),
          SwitchListTile(
            value: _settings.tripEndSettlementAlert,
            onChanged: (value) => setState(() {
              _settings = _settings.copyWith(tripEndSettlementAlert: value);
            }),
            title: const Text('여행 종료 시 정산 신청 알림'),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () async {
              await controller.updateSettings(_settings);
              if (!context.mounted) {
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('설정을 저장했습니다.')),
              );
              Navigator.of(context).pop();
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }
}
