import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_app/core/models/news_item.dart';
import 'package:my_app/core/models/news_region.dart';
import 'package:my_app/core/models/news_category.dart';
import 'package:my_app/core/services/news_service.dart';

class NewsProvider extends ChangeNotifier {
  static const String _newsArchiveKey = 'news_archive';
  static const String _newsRegionKey = 'news_region';
  static const String _newsCategoryKey = 'news_category';

  final NewsService _newsService = NewsService();
  final Map<DateTime, Map<NewsRegion, List<NewsItem>>> _newsArchive = {};
  bool _isLoading = false;
  String? _error;
  NewsRegion _currentRegion = NewsRegion.world;
  NewsCategory _currentCategory = NewsCategory.all;

  Map<DateTime, Map<NewsRegion, List<NewsItem>>> get newsArchive => _newsArchive;
  bool get isLoading => _isLoading;
  String? get error => _error;
  NewsRegion get currentRegion => _currentRegion;
  NewsCategory get currentCategory => _currentCategory;

  Future<void> init() async {
    await _newsService.init();
    await _loadFromStorage();
  }

  DateTime _getDateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  // Load news from shared preferences
  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load region preference
      final regionString = prefs.getString(_newsRegionKey);
      if (regionString != null) {
        _currentRegion = NewsRegion.values.firstWhere(
          (r) => r.name == regionString,
          orElse: () => NewsRegion.world,
        );
      }

      // Load category preference
      final categoryString = prefs.getString(_newsCategoryKey);
      if (categoryString != null) {
        _currentCategory = NewsCategory.values.firstWhere(
          (c) => c.name == categoryString,
          orElse: () => NewsCategory.all,
        );
      }

      final newsJson = prefs.getString(_newsArchiveKey);

      if (newsJson != null) {
        final Map<String, dynamic> decoded = json.decode(newsJson);

        _newsArchive.clear();
        decoded.forEach((dateString, regionsMap) {
          final date = DateTime.parse(dateString);
          final regionData = regionsMap as Map<String, dynamic>;

          _newsArchive[date] = {};

          regionData.forEach((regionName, newsList) {
            final region = NewsRegion.values.firstWhere(
              (r) => r.name == regionName,
              orElse: () => NewsRegion.world,
            );

            final items = (newsList as List)
                .map((item) => NewsItem.fromJson(item as Map<String, dynamic>))
                .toList();
            _newsArchive[date]![region] = items;
          });
        });

        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading news from storage: $e');
    }
  }

  // Save news to shared preferences
  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save region preference
      await prefs.setString(_newsRegionKey, _currentRegion.name);

      // Save category preference
      await prefs.setString(_newsCategoryKey, _currentCategory.name);

      // Convert the map to JSON-serializable format
      final Map<String, dynamic> toSave = {};
      _newsArchive.forEach((date, regionsMap) {
        final regionData = <String, dynamic>{};
        regionsMap.forEach((region, items) {
          regionData[region.name] = items.map((item) => item.toJson()).toList();
        });
        toSave[date.toIso8601String()] = regionData;
      });

      await prefs.setString(_newsArchiveKey, json.encode(toSave));
    } catch (e) {
      debugPrint('Error saving news to storage: $e');
    }
  }

  Future<void> setRegion(NewsRegion region) async {
    if (_currentRegion == region) return;

    _currentRegion = region;
    await _saveToStorage();
    notifyListeners();
  }

  Future<void> setCategory(NewsCategory category) async {
    if (_currentCategory == category) return;

    _currentCategory = category;
    await _saveToStorage();
    notifyListeners();
  }

  Future<void> fetchLatestNews() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final news = await _newsService.fetchNews(_currentRegion, _currentCategory);

      // Group news by date and region
      final today = _getDateOnly(DateTime.now());

      if (!_newsArchive.containsKey(today)) {
        _newsArchive[today] = {};
      }

      if (_newsArchive[today]!.containsKey(_currentRegion)) {
        _newsArchive[today]![_currentRegion]!.addAll(news);
      } else {
        _newsArchive[today]![_currentRegion] = news;
      }

      _isLoading = false;
      _error = null;

      // Save to storage
      await _saveToStorage();

      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  List<DateTime> getSortedDates() {
    final dates = _newsArchive.keys.toList();
    dates.sort((a, b) => b.compareTo(a)); // Most recent first
    return dates;
  }

  List<NewsItem> getNewsForDate(DateTime date, {NewsRegion? region}) {
    final dateOnly = _getDateOnly(date);
    final targetRegion = region ?? _currentRegion;
    return _newsArchive[dateOnly]?[targetRegion] ?? [];
  }

  bool hasNewsForRegion(DateTime date, NewsRegion region) {
    final dateOnly = _getDateOnly(date);
    return _newsArchive[dateOnly]?.containsKey(region) ?? false;
  }

  // Clear all news (useful for testing)
  Future<void> clearAllNews() async {
    _newsArchive.clear();
    await _saveToStorage();
    notifyListeners();
  }
}
