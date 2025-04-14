import 'dart:convert';

// Model for a single news article
class ArticleModel {
  final int id; // Assuming there might be an ID from the API
  final String title;
  final String publishTime; // Keep as String for now, format as needed in UI
  final String content;
  final String source;
  final String? cover; // Optional cover image URL

  ArticleModel({
    required this.id,
    required this.title,
    required this.publishTime,
    required this.content,
    required this.source,
    this.cover,
  });

  factory ArticleModel.fromJson(Map<String, dynamic> json) {
    // Helper function for safe string conversion
    String getStringValue(dynamic value) => value?.toString() ?? '';
    int getIntValue(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      return int.tryParse(value.toString()) ?? 0;
    }

    return ArticleModel(
      id: getIntValue(json['id']), // Assuming API provides an 'id'
      title: getStringValue(json['title']),
      // Assuming API uses 'publish_time' or similar - adjust if needed
      publishTime: getStringValue(json['publish_time'] ?? json['created_at']),
      content: getStringValue(json['content']),
      source: getStringValue(
          json['source'] ?? json['author']), // Assuming 'source' or 'author'
      cover: json['cover']
          as String?, // Assuming 'cover' is the key for the image URL
    );
  }
}

// Model for the API response containing a list of articles and pagination info
class NewsResponse {
  final List<ArticleModel> articles;
  final int totalCount; // Assuming API provides total count for pagination
  final int currentPage; // Assuming API provides current page
  final int pageSize; // Assuming API provides page size

  NewsResponse({
    required this.articles,
    required this.totalCount,
    required this.currentPage,
    required this.pageSize,
  });

  factory NewsResponse.fromJson(Map<String, dynamic> json) {
    int getIntValue(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      return int.tryParse(value.toString()) ?? 0;
    }

    final List<dynamic> list = json['data']?['list'] ?? [];
    final List<ArticleModel> articles =
        list.map((item) => ArticleModel.fromJson(item)).toList();

    // Assuming pagination info is directly under 'data' or adjust as needed
    final paginationData = json['data'] ?? {};

    return NewsResponse(
      articles: articles,
      totalCount: getIntValue(paginationData['total_count']),
      currentPage: getIntValue(paginationData['current_page']),
      pageSize: getIntValue(paginationData['per_page']),
    );
  }
}
