import 'package:flutter/material.dart';

import '../screens/main_navigation_screen.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.title,
    required this.modeName,
    required this.child,
    this.actions,
    this.floatingActionButton,
    this.currentTabIndex,
    this.onTabSelected,
    this.showBackButton,
    this.onBackPressed,
  });

  final String title;
  final String modeName;
  final Widget child;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final int? currentTabIndex;
  final ValueChanged<int>? onTabSelected;
  final bool? showBackButton;
  final VoidCallback? onBackPressed;

  int _fallbackTabIndex() {
    final normalized = title.toLowerCase();
    if (normalized.contains('커뮤니티')) {
      return 3;
    }
    if (normalized.contains('몰')) {
      return 2;
    }
    if (normalized.contains('홈')) {
      return 0;
    }
    return 1;
  }

  void _handleFallbackTabSelected(BuildContext context, int index) {
    if (index == _fallbackTabIndex()) {
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => MainNavigationScreen(initialIndex: index),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    final shouldShowBackButton = showBackButton ?? canPop;
    final selectedIndex = currentTabIndex ?? _fallbackTabIndex();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F3),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: shouldShowBackButton
            ? IconButton(
                onPressed: onBackPressed ?? () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              )
            : null,
        leadingWidth: shouldShowBackButton ? 56 : null,
        backgroundColor: const Color(0xFFF6F7F3),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 90,
        titleSpacing: 0,
        title: _TopBar(
          actions: actions,
          showBackButton: shouldShowBackButton,
        ),
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: child,
      ),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: SafeArea(
        top: false,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Color(0x080F172A),
                blurRadius: 18,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              child: NavigationBar(
                selectedIndex: selectedIndex,
                onDestinationSelected: onTabSelected ??
                    (index) => _handleFallbackTabSelected(context, index),
                height: 84,
                backgroundColor: Colors.white,
                indicatorColor: const Color(0xFFE7F7F0),
                shadowColor: Colors.transparent,
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home_rounded),
                    label: '홈',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.luggage_outlined),
                    selectedIcon: Icon(Icons.luggage_rounded),
                    label: '내 여행',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.storefront_outlined),
                    selectedIcon: Icon(Icons.storefront_rounded),
                    label: '온라인몰',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.forum_outlined),
                    selectedIcon: Icon(Icons.forum_rounded),
                    label: '커뮤니티',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    this.actions,
    required this.showBackButton,
  });

  final List<Widget>? actions;
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: showBackButton ? 4 : 20, right: 12),
      child: Row(
        children: [
          const _BrandLogo(),
          const Spacer(),
          if (actions != null) ...actions!,
        ],
      ),
    );
  }
}

class _BrandLogo extends StatelessWidget {
  const _BrandLogo();

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(-4, 1),
      child: SizedBox(
        height: 70,
        width: 212,
        child: Image.asset(
          'assets/logo/logo.png',
          fit: BoxFit.contain,
          alignment: Alignment.centerLeft,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    this.subtitle = '',
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

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
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                ),
          ),
          if (subtitle.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF64748B),
                    height: 1.5,
                  ),
            ),
            const SizedBox(height: 18),
          ] else
            const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
