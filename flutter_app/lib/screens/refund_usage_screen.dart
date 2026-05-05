import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_scope.dart';
import '../widgets/app_shell.dart';

class RefundUsageScreen extends StatelessWidget {
  const RefundUsageScreen({
    super.key,
    required this.regionId,
    required this.residence,
  });

  final int regionId;
  final String residence;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    return AppShell(
      title: '환급액 사용처',
      modeName: controller.modeName,
      child: FutureBuilder(
        future: controller.repository.getRegionDetail(regionId, residence: residence),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final detail = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              SectionCard(
                title: '${detail.region.name} 오프라인 가맹점',
                child: Column(
                  children: detail.merchants
                      .map(
                        (merchant) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(merchant.name),
                          subtitle: Text('${merchant.address}\n${merchant.category}'),
                        ),
                      )
                      .toList(),
                ),
              ),
              SectionCard(
                title: '특산물 온라인몰',
                child: Column(
                  children: detail.onlineMalls
                      .map(
                        (mall) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(mall.name),
                          subtitle: Text(mall.description),
                          trailing: const Icon(Icons.open_in_new),
                          onTap: () => launchUrl(
                            Uri.parse(mall.mallUrl),
                            mode: LaunchMode.externalApplication,
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
}

