import 'package:flutter/foundation.dart';

class KlineBean {
  final double close;
  final double high;
  final double low;
  final double open;
  final int time;
  final String tm;
  final double turnover;
  final double volume;

  KlineBean({
    required this.close,
    required this.high,
    required this.low,
    required this.open,
    required this.time,
    required this.tm,
    required this.turnover,
    required this.volume,
  });

  factory KlineBean.fromJson(Map<String, dynamic> json) {
    return KlineBean(
      close: double.tryParse(json['close']?.toString() ?? '0') ?? 0,
      high: double.tryParse(json['high']?.toString() ?? '0') ?? 0,
      low: double.tryParse(json['low']?.toString() ?? '0') ?? 0,
      open: double.tryParse(json['open']?.toString() ?? '0') ?? 0,
      time: int.tryParse(json['time']?.toString() ?? '0') ?? 0,
      tm: json['tm']?.toString() ?? '',
      turnover: double.tryParse(json['turnover']?.toString() ?? '0') ?? 0,
      volume: double.tryParse(json['volume']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'close': close,
      'high': high,
      'low': low,
      'open': open,
      'time': time,
      'tm': tm,
      'turnover': turnover,
      'volume': volume,
    };
  }

  @override
  String toString() {
    return 'KlineBean(close: $close, high: $high, low: $low, open: $open, time: $time, tm: $tm, turnover: $turnover, volume: $volume)';
  }
}
