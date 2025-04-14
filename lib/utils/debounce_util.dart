import 'dart:async';

/// 防止按钮重复点击工具类
class DebounceUtil {
  static Map<String, Timer> _timers = {};

  /// 防抖函数，避免0.7秒内的重复点击
  ///
  /// [id] 唯一标识，用于区分不同的按钮
  /// [callback] 需要执行的回调函数
  /// [milliseconds] 毫秒数，默认700ms
  static void debounce(String id, Function callback, {int milliseconds = 700}) {
    // 如果正在冷却期，则直接返回
    if (_timers.containsKey(id)) {
      return;
    }

    // 执行回调
    callback();

    // 创建定时器，指定时间后可以再次点击
    _timers[id] = Timer(Duration(milliseconds: milliseconds), () {
      _timers.remove(id);
    });
  }

  /// 清除特定id的定时器
  static void clear(String id) {
    if (_timers.containsKey(id)) {
      _timers[id]?.cancel();
      _timers.remove(id);
    }
  }

  /// 清除所有定时器
  static void clearAll() {
    _timers.forEach((key, timer) => timer.cancel());
    _timers.clear();
  }
}

/// 防抖按钮的包装函数
class DebounceButton {
  /// 包装函数，用于包装按钮的点击回调
  static Function(Function callback) get onPressed => (Function callback) {
        return () {
          DebounceUtil.debounce('button', () {
            callback();
          });
        };
      };

  /// 带ID的包装函数，用于区分不同的按钮
  static Function(String id, Function callback) get onPressedWithId =>
      (String id, Function callback) {
        return () {
          DebounceUtil.debounce(id, () {
            callback();
          });
        };
      };
}
