import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_app/core/models/news_category.dart';
import 'package:my_app/core/models/news_item.dart';
import 'package:my_app/core/models/news_region.dart';
import 'package:my_app/core/services/news_service.dart';

class NewsState {
  static const _unset = Object();
  final Map<DateTime, Map<NewsRegion, List<NewsItem>>> newsArchive;
  final bool isLoading;
  final String? error;
  final NewsRegion currentRegion;
  final NewsCategory currentCategory;

  const NewsState({
    required this.newsArchive,
    required this.isLoading,
    required this.error,
    required this.currentRegion,
    required this.currentCategory,
  });

  factory NewsState.initial() {
    return const NewsState(
      newsArchive: {},
      isLoading: false,
      error: null,
      currentRegion: NewsRegion.world,
      currentCategory: NewsCategory.all,
    );
  }

  NewsState copyWith({
    Map<DateTime, Map<NewsRegion, List<NewsItem>>>? newsArchive,
    bool? isLoading,
    Object? error = _unset,
    NewsRegion? currentRegion,
    NewsCategory? currentCategory,
  }) {
    return NewsState(
      newsArchive: newsArchive ?? this.newsArchive,
      isLoading: isLoading ?? this.isLoading,
      error: error == _unset ? this.error : error as String?,
      currentRegion: currentRegion ?? this.currentRegion,
      currentCategory: currentCategory ?? this.currentCategory,
    );
  }
}

class NewsCubit extends Cubit<NewsState> {
  static const String _newsArchiveKey = 'news_archive';
  static const String _newsRegionKey = 'news_region';
  static const String _newsCategoryKey = 'news_category';

  final NewsService _newsService;

  NewsCubit({NewsService? newsService})
      : _newsService = newsService ?? NewsService(),
        super(NewsState.initial());

  Future<void> init() async {
    await _newsService.init();
    await _loadFromStorage();
  }

  DateTime _getDateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  Map<DateTime, Map<NewsRegion, List<NewsItem>>> _cloneArchive(
    Map<DateTime, Map<NewsRegion, List<NewsItem>>> archive,
  ) {
    final Map<DateTime, Map<NewsRegion, List<NewsItem>>> cloned = {};
    for (final entry in archive.entries) {
      final Map<NewsRegion, List<NewsItem>> regionMap = {};
      for (final regionEntry in entry.value.entries) {
        regionMap[regionEntry.key] = List<NewsItem>.from(regionEntry.value);
      }
      cloned[entry.key] = regionMap;
    }
    return cloned;
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      var currentRegion = state.currentRegion;
      var currentCategory = state.currentCategory;

      final regionString = prefs.getString(_newsRegionKey);
      if (regionString != null) {
        currentRegion = NewsRegion.values.firstWhere(
          (r) => r.name == regionString,
          orElse: () => NewsRegion.world,
        );
      }

      final categoryString = prefs.getString(_newsCategoryKey);
      if (categoryString != null) {
        currentCategory = NewsCategory.values.firstWhere(
          (c) => c.name == categoryString,
          orElse: () => NewsCategory.all,
        );
      }

      final newsJson = prefs.getString(_newsArchiveKey);
      final Map<DateTime, Map<NewsRegion, List<NewsItem>>> archive = {};

      if (newsJson != null) {
        final Map<String, dynamic> decoded = json.decode(newsJson);
        decoded.forEach((dateString, regionsMap) {
          final date = DateTime.parse(dateString);
          final regionData = regionsMap as Map<String, dynamic>;
          final Map<NewsRegion, List<NewsItem>> parsedRegions = {};

          regionData.forEach((regionName, newsList) {
            final region = NewsRegion.values.firstWhere(
              (r) => r.name == regionName,
              orElse: () => NewsRegion.world,
            );

            final items = (newsList as List)
                .map((item) => NewsItem.fromJson(item as Map<String, dynamic>))
                .toList();
            parsedRegions[region] = items;
          });

          archive[date] = parsedRegions;
        });
      }

      emit(
        state.copyWith(
          newsArchive: archive,
          currentRegion: currentRegion,
          currentCategory: currentCategory,
          error: null,
          isLoading: false,
        ),
      );
    } catch (e) {
      debugPrint('Error loading news from storage: $e');
    }
  }

  Future<void> _saveToStorage(NewsState targetState) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(_newsRegionKey, targetState.currentRegion.name);
      await prefs.setString(_newsCategoryKey, targetState.currentCategory.name);

      final Map<String, dynamic> toSave = {};
      targetState.newsArchive.forEach((date, regionsMap) {
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
    if (state.currentRegion == region) return;
    final nextState = state.copyWith(currentRegion: region, error: null);
    emit(nextState);
    await _saveToStorage(nextState);
  }

  Future<void> setCategory(NewsCategory category) async {
    if (state.currentCategory == category) return;
    final nextState = state.copyWith(currentCategory: category, error: null);
    emit(nextState);
    await _saveToStorage(nextState);
  }

  Future<void> fetchLatestNews() async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      final news = await _newsService.fetchNews(
        state.currentRegion,
        state.currentCategory,
      );

      final updatedArchive = _cloneArchive(state.newsArchive);
      final today = _getDateOnly(DateTime.now());
      final regionMap = updatedArchive[today] ?? <NewsRegion, List<NewsItem>>{};
      final existing = List<NewsItem>.from(regionMap[state.currentRegion] ?? []);
      existing.addAll(news);
      regionMap[state.currentRegion] = existing;
      updatedArchive[today] = regionMap;

      final nextState = state.copyWith(
        newsArchive: updatedArchive,
        isLoading: false,
        error: null,
      );

      emit(nextState);
      await _saveToStorage(nextState);
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
      rethrow;
    }
  }

  void clearError() {
    emit(state.copyWith(error: null));
  }

  List<DateTime> getSortedDates() {
    final dates = state.newsArchive.keys.toList();
    dates.sort((a, b) => b.compareTo(a));
    return dates;
  }

  List<NewsItem> getNewsForDate(DateTime date, {NewsRegion? region}) {
    final dateOnly = _getDateOnly(date);
    final targetRegion = region ?? state.currentRegion;
    return state.newsArchive[dateOnly]?[targetRegion] ?? [];
  }

  bool hasNewsForRegion(DateTime date, NewsRegion region) {
    final dateOnly = _getDateOnly(date);
    return state.newsArchive[dateOnly]?.containsKey(region) ?? false;
  }

  Future<void> clearAllNews() async {
    final nextState = state.copyWith(
      newsArchive: {},
      error: null,
      isLoading: false,
    );
    emit(nextState);
    await _saveToStorage(nextState);
  }
}
