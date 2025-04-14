import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/websocket_message.dart';

typedef MarketDataCallback = void Function(MarketData data);

class WebSocketService {
  // 使用prd.mp中指定的WebSocket URL
  static const String _wsUrl = 'wss://deglobalrlspo.top/ws';

  WebSocketChannel? _channel;
  bool _isConnected = false;
  final Map<String, List<MarketDataCallback>> _subscriptions = {};
  Timer? _pingTimer;

  // 添加getter以允许外部访问连接状态
  bool get isConnected => _isConnected;

  // 连接到WebSocket服务器
  Future<void> connect() async {
    if (_isConnected) return;

    try {
      _channel = WebSocketChannel.connect(Uri.parse(_wsUrl));
      _isConnected = true;
      debugPrint('WebSocket 连接成功');

      // 监听消息
      _channel!.stream.listen(
        (message) {
          // debugPrint('收到WebSocket消息: $message');
          _handleMessage(message);
        },
        onError: (error) {
          debugPrint('WebSocket错误: $error');
          _isConnected = false;
          reconnect();
        },
        onDone: () {
          debugPrint('WebSocket连接关闭');
          _isConnected = false;
          reconnect();
        },
      );

      // 定期发送ping消息保持连接
      _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        if (_isConnected) {
          debugPrint('发送WebSocket ping');
          _channel!.sink.add(json.encode({'cmd': 'ping'}));
        }
      });
    } catch (e) {
      debugPrint('WebSocket连接失败: $e');
      _isConnected = false;
      Future.delayed(const Duration(seconds: 5), reconnect);
    }
  }

  // 重新连接
  void reconnect() {
    if (!_isConnected) {
      debugPrint('尝试重新连接WebSocket...');
      connect().then((_) {
        // 重新订阅之前的主题
        for (final topic in _subscriptions.keys) {
          debugPrint('重新订阅: $topic');
          _subscribe(topic);
        }
      });
    }
  }

  // 关闭连接
  void close() {
    _pingTimer?.cancel();
    _pingTimer = null;

    if (_isConnected && _channel != null) {
      _channel!.sink.close();
      _channel = null;
    }
    _isConnected = false;
    _subscriptions.clear();
    debugPrint('WebSocket连接已关闭');
  }

  // 处理收到的消息
  void _handleMessage(dynamic message) {
    try {
      // 记录原始消息
      // debugPrint('收到WebSocket消息: $message');

      // 首先检查消息是否为CSV格式（通常以市场代码开头）
      if (message is String && message.contains(',')) {
        _handleCSVMessage(message);
        return;
      }

      // 如果不是CSV格式，尝试作为JSON处理
      try {
        final Map<String, dynamic> data = json.decode(message);

        // 输出解析的JSON消息
        // debugPrint('解析的WebSocket消息: $data');

        // 处理心跳响应
        if (data.containsKey('ping') || data.containsKey('pong')) {
          debugPrint('收到心跳消息');
          return;
        }

        // 尝试处理不同格式的市场数据更新
        String? symbol;
        Map<String, dynamic>? marketData;

        // 检查常见的WebSocket消息格式
        if (data.containsKey('code') && data.containsKey('data')) {
          // 格式1: {code: SYMBOL, data: {...}}
          symbol = data['code'];
          marketData = data['data'];
          // debugPrint('Format 1 detected: symbol=$symbol');
        } else if (data.containsKey('topic') && data.containsKey('data')) {
          // 格式2: {topic: market.SYMBOL, data: {...}}
          final String topic = data['topic'];
          if (topic.startsWith('market.')) {
            symbol = topic.substring(7); // 移除 "market." 前缀
            marketData = data['data'];
            // debugPrint('Format 2 detected: symbol=$symbol from topic=$topic');
          }
        } else if (data.containsKey('ch') && data.containsKey('tick')) {
          // 格式3: {ch: market.SYMBOL.detail, tick: {...}}
          final String channel = data['ch'];
          if (channel.startsWith('market.') && channel.endsWith('.detail')) {
            final parts = channel.split('.');
            if (parts.length >= 2) {
              symbol = parts[1];
              marketData = data['tick'];
              // debugPrint('Format 3 detected: symbol=$symbol from channel=$channel');
            }
          }
        } else if (data.containsKey('symbol') &&
            (data.containsKey('price') || data.containsKey('lastPrice'))) {
          // 格式4: {symbol: SYMBOL, price/lastPrice: value, ...}
          symbol = data['symbol'];
          marketData = data;
          // debugPrint('Format 4 detected: direct price data for symbol=$symbol');
        } else {
          // Log unrecognized message format
          debugPrint('Unrecognized JSON message format: $data');
        }

        // 如果成功提取了symbol和数据，处理回调
        if (symbol != null && marketData != null) {
          _processMarketData(symbol, marketData);
        }
      } catch (jsonError) {
        debugPrint('JSON解析失败: $jsonError, 尝试处理为其他格式');
      }
    } catch (e) {
      debugPrint('处理WebSocket消息错误: $e, raw message: $message');
    }
  }

  // 处理CSV格式的消息
  void _handleCSVMessage(String message) {
    try {
      // 解析CSV格式的消息
      final parts = message.split(',');
      if (parts.length < 6) {
        debugPrint('CSV消息格式不正确: $message');
        return;
      }

      final symbol = parts[0]; // 第一个字段通常是市场代码

      // 基于CSV的位置创建一个市场数据对象
      // CSV格式假设为: SYMBOL,SYMBOL2,PRICE,HIGH,LOW,CHANGE,...
      final Map<String, dynamic> marketData = {
        'lastPrice': double.tryParse(parts[2]) ?? 0.0,
        'high24h': double.tryParse(parts[3]) ?? 0.0,
        'low24h': double.tryParse(parts[4]) ?? 0.0,
        'priceChange24h': double.tryParse(parts[5]) ?? 0.0,
      };

      // debugPrint('从CSV解析的数据: $symbol, 价格: ${marketData['lastPrice']}');

      // 处理解析出的市场数据
      _processMarketData(symbol, marketData);
    } catch (e) {
      debugPrint('处理CSV消息错误: $e, message: $message');
    }
  }

  // 处理市场数据并通知订阅者
  void _processMarketData(String symbol, Map<String, dynamic> marketData) {
    final topic = 'market.$symbol';
    // debugPrint('处理市场数据更新: $topic, data: $marketData');

    if (_subscriptions.containsKey(topic)) {
      try {
        final marketDataObj = MarketData.fromJson(marketData);
        // debugPrint('市场数据解析成功: $marketDataObj');

        for (final callback in _subscriptions[topic]!) {
          try {
            callback(marketDataObj);
          } catch (callbackError) {
            debugPrint('回调执行失败: $callbackError');
          }
        }
      } catch (e) {
        debugPrint('解析市场数据失败: $e, raw data: $marketData');
      }
    } else {
      // debugPrint('没有找到订阅: $topic (可能是未订阅的市场)');
    }
  }

  // 私有方法，向服务器发送订阅请求
  void _subscribe(String topic) {
    if (_isConnected && _channel != null) {
      final message = {
        'cmd': 'sub',
        'topic': topic,
      };
      // debugPrint('发送订阅请求: $message');
      _channel!.sink.add(json.encode(message));
    } else {
      debugPrint('WebSocket未连接，无法订阅: $topic');
    }
  }

  // 订阅市场数据更新
  void subscribeToMarket(String symbol, MarketDataCallback callback) {
    final topic = 'market.$symbol';
    // debugPrint('订阅市场数据: $topic');

    // 添加回调到订阅列表
    if (!_subscriptions.containsKey(topic)) {
      _subscriptions[topic] = [];
      // 向服务器发送订阅请求
      _subscribe(topic);
    }

    _subscriptions[topic]!.add(callback);
    // debugPrint('当前订阅: ${_subscriptions.keys}');
  }

  // 取消订阅
  void unsubscribe(String topic) {
    debugPrint('取消订阅: $topic');
    if (_subscriptions.containsKey(topic)) {
      _subscriptions.remove(topic);

      if (_isConnected && _channel != null) {
        final message = {
          'cmd': 'unsub',
          'topic': topic,
        };
        _channel!.sink.add(json.encode(message));
      }
    }
  }
}
