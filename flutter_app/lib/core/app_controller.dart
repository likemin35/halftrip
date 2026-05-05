import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_models.dart';
import '../repositories/travel_repository.dart';

class AppController extends ChangeNotifier {
  AppController({required TravelRepository repository})
      : _repository = repository;

  final TravelRepository _repository;
  bool isBusy = false;
  String? errorMessage;
  AppUser? currentUser;
  List<TripSummary> trips = const [];
  List<SavedCourse> savedCourses = const [];
  Set<int> preopenAlertRegionIds = const <int>{};
  Set<int> appliedTripIds = const <int>{};

  static const _savedCoursesKey = 'saved_courses_v1';
  static const _preopenAlertsKey = 'preopen_alert_regions_v1';
  static const _appliedTripsKey = 'applied_trip_ids_v1';

  TravelRepository get repository => _repository;
  String get modeName => _repository.modeName;
  bool get isLoggedIn => currentUser != null;

  Future<void> login(LoginProvider provider) async {
    await _runBusy(() async {
      final authUser = await _repository.mockLogin(provider);
      currentUser = await _repository.getUser(authUser.id);
      trips = await _repository.getTrips(authUser.id);
      await _loadLocalDashboardData();
    });
  }

  Future<void> loginWithCredentials({
    required String loginId,
    required String password,
  }) async {
    await _runBusy(() async {
      final authUser = await _repository.localLogin(
        loginId: loginId,
        password: password,
      );
      currentUser = await _repository.getUser(authUser.id);
      trips = await _repository.getTrips(authUser.id);
      await _loadLocalDashboardData();
    });
  }

  Future<void> signUpWithCredentials({
    required String name,
    required String loginId,
    required String password,
    required String phoneNumber,
    required String residence,
  }) async {
    await _runBusy(() async {
      final authUser = await _repository.localSignUp(
        name: name,
        loginId: loginId,
        password: password,
        phoneNumber: phoneNumber,
        residence: residence,
      );
      currentUser = await _repository.getUser(authUser.id);
      trips = await _repository.getTrips(authUser.id);
      await _loadLocalDashboardData();
    });
  }

  Future<void> refreshTrips() async {
    final user = currentUser;
    if (user == null) {
      return;
    }
    await _runBusy(() async {
      trips = await _repository.getTrips(user.id);
    }, resetError: false);
  }

  Future<AppUser> refreshCurrentUser() async {
    final user = currentUser;
    if (user == null) {
      throw StateError('User is not logged in');
    }

    late final AppUser refreshed;
    await _runBusy(() async {
      refreshed = await _repository.getUser(user.id);
      currentUser = refreshed;
    }, resetError: false);
    return refreshed;
  }

  Future<void> updateSettings(NotificationSettings settings) async {
    final user = currentUser;
    if (user == null) {
      return;
    }
    await _runBusy(() async {
      final updated = await _repository.updateNotificationSettings(
        user.id,
        settings,
      );
      currentUser = user.copyWith(notificationSettings: updated);
    });
  }

  Future<void> toggleFavoriteRegion(RegionSummary region) async {
    final user = currentUser;
    if (user == null) {
      return;
    }
    await _runBusy(() async {
      final isFavorite = user.favoriteRegions.any((item) => item.id == region.id);
      final updatedFavorites = isFavorite
          ? await _repository.removeFavoriteRegion(user.id, region.id)
          : await _repository.addFavoriteRegion(user.id, region.id);
      currentUser = user.copyWith(favoriteRegions: updatedFavorites);
    }, resetError: false);
  }

  Future<void> togglePreopenAlertRegion(int regionId) async {
    final next = {...preopenAlertRegionIds};
    if (next.contains(regionId)) {
      next.remove(regionId);
    } else {
      next.add(regionId);
    }
    preopenAlertRegionIds = next;
    await _persistLocalDashboardData();
    notifyListeners();
  }

  Future<void> saveCourse(SavedCourse course) async {
    final next = [...savedCourses];
    next.removeWhere((item) => item.id == course.id);
    next.insert(0, course);
    savedCourses = next;
    await _persistLocalDashboardData();
    notifyListeners();
  }

  Future<void> deleteCourse(String courseId) async {
    savedCourses = savedCourses.where((item) => item.id != courseId).toList();
    await _persistLocalDashboardData();
    notifyListeners();
  }

  Future<void> setTripApplicationStatus(int tripId, bool applied) async {
    final next = {...appliedTripIds};
    if (applied) {
      next.add(tripId);
    } else {
      next.remove(tripId);
    }
    appliedTripIds = next;
    await _persistLocalDashboardData();
    notifyListeners();
  }

  Future<T> runTask<T>(Future<T> Function() task) async {
    errorMessage = null;
    notifyListeners();
    try {
      return await task();
    } catch (error) {
      errorMessage = error.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> _runBusy(
    Future<void> Function() task, {
    bool resetError = true,
  }) async {
    isBusy = true;
    if (resetError) {
      errorMessage = null;
    }
    notifyListeners();
    try {
      await task();
    } catch (error) {
      errorMessage = error.toString();
      rethrow;
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  Future<void> _loadLocalDashboardData() async {
    final preferences = await SharedPreferences.getInstance();
    final rawCourses = preferences.getStringList(_savedCoursesKey) ?? const [];
    savedCourses = rawCourses
        .map((item) => SavedCourse.fromJson(jsonDecode(item) as Map<String, dynamic>))
        .toList();
    preopenAlertRegionIds = (preferences.getStringList(_preopenAlertsKey) ?? const [])
        .map(int.tryParse)
        .whereType<int>()
        .toSet();
    appliedTripIds = (preferences.getStringList(_appliedTripsKey) ?? const [])
        .map(int.tryParse)
        .whereType<int>()
        .toSet();
  }

  Future<void> _persistLocalDashboardData() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(
      _savedCoursesKey,
      savedCourses.map((item) => jsonEncode(item.toJson())).toList(),
    );
    await preferences.setStringList(
      _preopenAlertsKey,
      preopenAlertRegionIds.map((item) => item.toString()).toList(),
    );
    await preferences.setStringList(
      _appliedTripsKey,
      appliedTripIds.map((item) => item.toString()).toList(),
    );
  }
}
