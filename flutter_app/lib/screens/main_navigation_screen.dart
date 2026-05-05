import 'package:flutter/material.dart';

import 'community_screen.dart';
import 'home_screen.dart';
import 'online_mall_screen.dart';
import 'trip_list_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({
    super.key,
    this.initialIndex = 0,
  });

  final int initialIndex;

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, 3).toInt();
  }

  void _handleTabSelected(int index) {
    if (_currentIndex == index) {
      return;
    }

    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: _currentIndex,
      children: [
        HomeScreen(
          currentTabIndex: 0,
          onTabSelected: _handleTabSelected,
        ),
        TripListScreen(
          currentTabIndex: 1,
          onTabSelected: _handleTabSelected,
        ),
        OnlineMallScreen(
          currentTabIndex: 2,
          onTabSelected: _handleTabSelected,
        ),
        CommunityScreen(
          currentTabIndex: 3,
          onTabSelected: _handleTabSelected,
        ),
      ],
    );
  }
}
