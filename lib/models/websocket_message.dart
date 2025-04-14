class WebSocketMessage {
  final String type;
  final dynamic data;

  WebSocketMessage({
    required this.type,
    required this.data,
  });

  factory WebSocketMessage.fromJson(Map<String, dynamic> json) {
    return WebSocketMessage(
      type: json['type'] ?? '',
      data: json['data'],
    );
  }
}

class MarketData {
  final double lastPrice;
  final double high24h;
  final double low24h;
  final double priceChange24h;
  final double volume24h;

  MarketData({
    required this.lastPrice,
    required this.high24h,
    required this.low24h,
    required this.priceChange24h,
    required this.volume24h,
  });

  factory MarketData.fromJson(Map<String, dynamic> json) {
    // 定义可能的字段名映射，增强兼容性
    const lastPriceFields = [
      'last_price',
      'close',
      'price',
      'lastPrice',
      'current'
    ];
    const high24hFields = ['high_24h', 'high', 'high24h', 'dayHigh'];
    const low24hFields = ['low_24h', 'low', 'low24h', 'dayLow'];
    const priceChangeFields = [
      'price_change_24h',
      'change',
      'priceChange24h',
      'changeAmount'
    ];
    const volumeFields = [
      'volume_24h',
      'vol',
      'volume',
      'amount',
      'totalVolume'
    ];

    // 尝试从不同字段名获取数据
    double getValueFromFields(List<String> fieldNames, double defaultValue) {
      for (final field in fieldNames) {
        if (json.containsKey(field) && json[field] != null) {
          // 尝试转换可能的多种数据格式
          final value = json[field];
          if (value is num) {
            return value.toDouble();
          } else if (value is String) {
            return double.tryParse(value) ?? defaultValue;
          }
          return double.tryParse(value.toString()) ?? defaultValue;
        }
      }
      return defaultValue;
    }

    return MarketData(
      lastPrice: getValueFromFields(lastPriceFields, 0.0),
      high24h: getValueFromFields(high24hFields, 0.0),
      low24h: getValueFromFields(low24hFields, 0.0),
      priceChange24h: getValueFromFields(priceChangeFields, 0.0),
      volume24h: getValueFromFields(volumeFields, 0.0),
    );
  }

  @override
  String toString() {
    return 'MarketData{lastPrice: $lastPrice, high24h: $high24h, low24h: $low24h, priceChange24h: $priceChange24h, volume24h: $volume24h}';
  }
}
