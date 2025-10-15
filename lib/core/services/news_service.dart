import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:my_app/core/models/news_item.dart';
import 'package:my_app/core/models/news_region.dart';
import 'package:my_app/core/models/news_category.dart';

class NewsService {
  static const String _apiUrl = 'https://newsapi.org/v2/top-headlines';
  String? _apiKey;

  Future<void> init() async {
    // Load API key from config file
    try {
      final configString = await rootBundle.loadString('assets/config.json');
      final config = json.decode(configString) as Map<String, dynamic>;
      _apiKey = config['news_api_key'] as String?;
    } catch (e) {
      debugPrint('Error loading API key: $e');
      debugPrint('Please create assets/config.json with your NewsAPI key');
    }
  }

  Future<List<NewsItem>> fetchNews(NewsRegion region, NewsCategory category) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      throw Exception(
        'API key not configured. Please add your NewsAPI key to assets/config.json',
      );
    }

    try {
      // Build query parameters based on region and category
      final Map<String, String> queryParams = {
        'apiKey': _apiKey!,
        'pageSize': '10', // Get 10 news items
      };

      // Add region-specific parameters
      if (region == NewsRegion.ukraine) {
        queryParams['country'] = 'ua'; // Ukraine country code
      } else {
        // For world news, get top headlines from multiple major countries
        // We'll use 'us' for general world news
        queryParams['country'] = 'us';
      }

      // Add category-specific parameters
      if (category != NewsCategory.all) {
        // Map our categories to NewsAPI categories
        switch (category) {
          case NewsCategory.sports:
            queryParams['category'] = 'sports';
            break;
          case NewsCategory.politics:
            queryParams['category'] = 'general'; // NewsAPI doesn't have politics, using general
            queryParams['q'] = 'politics'; // Add search query
            break;
          case NewsCategory.finance:
            queryParams['category'] = 'business';
            break;
          case NewsCategory.science:
            queryParams['category'] = 'science';
            break;
          case NewsCategory.all:
            queryParams['category'] = 'general';
            break;
        }
      } else {
        queryParams['category'] = 'general';
      }

      // Build URL with query parameters
      final uri = Uri.parse(_apiUrl).replace(queryParameters: queryParams);

      // Make GET request to NewsAPI
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body) as Map<String, dynamic>;

        // Check if request was successful
        if (responseData['status'] != 'ok') {
          throw Exception('NewsAPI returned error status');
        }

        final articles = responseData['articles'] as List<dynamic>;

        // Convert NewsAPI format to our NewsItem format
        return articles.map((article) {
          final articleMap = article as Map<String, dynamic>;

          return NewsItem(
            title: articleMap['title'] as String? ?? 'No title',
            description: articleMap['description'] as String? ?? 'No description',
            date: DateTime.parse(articleMap['publishedAt'] as String? ?? DateTime.now().toIso8601String()),
            source: (articleMap['source'] as Map<String, dynamic>?)?['name'] as String?,
            url: articleMap['url'] as String?,
          );
        }).toList();
      } else {
        final errorData = json.decode(response.body) as Map<String, dynamic>;
        throw Exception(
          'NewsAPI Error: ${response.statusCode} - ${errorData['message'] ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('Failed to parse news data: Invalid JSON format');
      }
      rethrow;
    }
  }
}
