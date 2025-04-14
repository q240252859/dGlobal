import 'package:flutter/foundation.dart';
import '../models/news_model.dart';
import '../services/news_service.dart';

class NewsProvider with ChangeNotifier {
  final NewsService _newsService = NewsService();

  List<ArticleModel> _articles = [];
  int _currentPage = 1;
  final int _pageSize = 20;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _error;

  // Getters
  List<ArticleModel> get articles => _articles;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get error => _error;

  // Constructor - Initial load
  NewsProvider() {
    loadNews(refresh: true);
  }

  Future<void> loadNews({bool refresh = false}) async {
    if (_isLoading || (_isLoadingMore && !refresh)) return;

    if (refresh) {
      _isLoading = true;
      _currentPage = 1;
      _hasMore = true;
      _error = null;
      // Notify listeners immediately for refresh to show initial loader
      notifyListeners();
    } else {
      _isLoadingMore = true;
      // Don't clear error when loading more
      // Notify listeners to potentially show loading more indicator
      notifyListeners();
    }

    try {
      final response = await _newsService.getNews(
        page: _currentPage,
        pageSize: _pageSize,
      );

      if (refresh) {
        _articles = response.articles;
      } else {
        _articles.addAll(response.articles);
      }

      _currentPage++;
      _hasMore = response.articles.length == _pageSize;
    } catch (e) {
      _error = e.toString();
      // If it was a refresh attempt and it failed, clear articles
      if (refresh) {
        _articles = [];
      }
      print('Error loading news: $e');
    } finally {
      if (refresh) {
        _isLoading = false;
      } else {
        _isLoadingMore = false;
      }
      // Always notify after attempting to load data
      notifyListeners();
    }
  }

  // Method specifically for pull-to-refresh
  Future<void> refreshNews() async {
    await loadNews(refresh: true);
  }

  // Method specifically for load more
  Future<void> loadMoreNews() async {
    if (_hasMore && !_isLoadingMore) {
      await loadNews(refresh: false);
    }
  }

  // Clear data (e.g., on logout)
  void clear() {
    _articles = [];
    _currentPage = 1;
    _isLoading = false;
    _isLoadingMore = false;
    _hasMore = true;
    _error = null;
    notifyListeners();
  }
}
