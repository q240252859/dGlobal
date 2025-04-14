import 'package:flutter/material.dart';
import 'package:pull_to_refresh_notification/pull_to_refresh_notification.dart';

class PullToRefreshHelper {
  /// Wraps a content widget with pull-to-refresh functionality
  static Widget wrapWithPullToRefresh({
    required Widget child,
    required Future<bool> Function() onRefresh,
    Color? color,
    double maxDragOffset = 100.0,
  }) {
    return PullToRefreshNotification(
      color: color ?? Colors.blue,
      onRefresh: onRefresh,
      maxDragOffset: maxDragOffset,
      child: child,
    );
  }

  /// Creates a pull-to-refresh indicator for sliver lists
  static Widget buildPullToRefreshIndicator() {
    return PullToRefreshContainer((info) {
      return SliverToBoxAdapter(
        child: Center(
          child: Container(
            height: info?.dragOffset ?? 0.0,
            child: info == null
                ? SizedBox()
                : Center(
                    child: CircularProgressIndicator(),
                  ),
          ),
        ),
      );
    });
  }
}
