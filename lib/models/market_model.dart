class MarketModel {
  final int id;
  final String code;
  final String? code2;
  final String name;
  final String nameCode;
  final String type;
  final String img;
  final int digit;
  final String lever;
  final String change;
  final int changeStatus;
  final double price;
  final double? changeValue;
  final double? high24h;
  final double? low24h;

  MarketModel({
    required this.id,
    required this.code,
    this.code2,
    required this.name,
    required this.nameCode,
    required this.type,
    required this.img,
    required this.digit,
    required this.lever,
    required this.change,
    required this.changeStatus,
    required this.price,
    this.changeValue,
    this.high24h,
    this.low24h,
  });

  factory MarketModel.fromJson(Map<String, dynamic> json) {
    return MarketModel(
      id: json['id'] ?? 0,
      code: json['code'] ?? '',
      code2: json['code2'],
      name: json['name'] ?? '',
      nameCode: json['name_code'] ?? '',
      type: json['type'] ?? '',
      img: json['img'] ?? '',
      digit: json['digit'] ?? 2,
      lever: json['lever'] ?? '1',
      change: json['change'] ?? '0',
      changeStatus: json['change_status'] ?? 1,
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      changeValue: double.tryParse(json['change_value']?.toString() ?? '0'),
      high24h: double.tryParse(json['high_24h']?.toString() ?? '0'),
      low24h: double.tryParse(json['low_24h']?.toString() ?? '0'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'code2': code2,
      'name': name,
      'name_code': nameCode,
      'type': type,
      'img': img,
      'digit': digit,
      'lever': lever,
      'change': change,
      'change_status': changeStatus,
      'price': price,
      'change_value': changeValue,
      'high_24h': high24h,
      'low_24h': low24h,
    };
  }

  String get displayName => name.isNotEmpty ? name : code;

  bool get isUp => changeStatus == 1 || changeStatus == 2;

  String get changePercentage {
    if (changeValue == null || changeValue == 0) return '0.00%';
    final percentage = (changeValue! / (price - changeValue!)) * 100;
    final sign = percentage >= 0 ? '+' : '';
    return '$sign${percentage.toStringAsFixed(2)}%';
  }
}

class MarketCategory {
  final int id;
  final String title;
  final int sort;
  final List<MarketModel> symbols;

  MarketCategory({
    required this.id,
    required this.title,
    required this.sort,
    required this.symbols,
  });

  factory MarketCategory.fromJson(Map<String, dynamic> json) {
    final List<dynamic> symbolsJson = json['symbols'] ?? [];
    final symbols = symbolsJson
        .map((symbolJson) => MarketModel.fromJson(symbolJson))
        .toList();

    return MarketCategory(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      sort: json['sort'] ?? 0,
      symbols: symbols,
    );
  }
}

class MarketResponse {
  final List<MarketCategory> categories;

  MarketResponse({required this.categories});

  factory MarketResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> categoriesJson = json['data'] ?? [];
    final categories = categoriesJson
        .map((categoryJson) => MarketCategory.fromJson(categoryJson))
        .toList();

    return MarketResponse(categories: categories);
  }
}
