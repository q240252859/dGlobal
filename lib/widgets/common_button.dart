import 'package:flutter/material.dart';
import '../utils/debounce_util.dart';

/// 通用按钮组件，封装了防抖功能
class CommonButton extends StatelessWidget {
  /// 按钮文本
  final String? text;

  /// 按钮图标
  final IconData? icon;

  /// 点击回调
  final VoidCallback? onPressed;

  /// 按钮宽度
  final double? width;

  /// 按钮高度
  final double? height;

  /// 按钮颜色
  final Color? color;

  /// 文本颜色
  final Color? textColor;

  /// 边框颜色
  final Color? borderColor;

  /// 字体大小
  final double? fontSize;

  /// 图标大小
  final double? iconSize;

  /// 边框圆角
  final double? borderRadius;

  /// 内边距
  final EdgeInsetsGeometry? padding;

  /// 按钮唯一ID，用于防抖
  final String? id;

  /// 禁用状态
  final bool disabled;

  /// 显示加载状态
  final bool loading;

  const CommonButton({
    Key? key,
    this.text,
    this.icon,
    this.onPressed,
    this.width,
    this.height,
    this.color,
    this.textColor,
    this.borderColor,
    this.fontSize,
    this.iconSize,
    this.borderRadius,
    this.padding,
    this.id,
    this.disabled = false,
    this.loading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonId = id ?? 'common_button_${hashCode}';

    // 根据是否禁用或加载中，决定点击回调
    final VoidCallback? handlePress = (disabled || loading || onPressed == null)
        ? null
        : () => DebounceUtil.debounce(buttonId, onPressed!);

    // 构建按钮内容
    Widget content = loading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: iconSize ?? 18,
                  color: textColor ?? Colors.white,
                ),
                if (text != null) const SizedBox(width: 8),
              ],
              if (text != null)
                Text(
                  text!,
                  style: TextStyle(
                    fontSize: fontSize ?? 16,
                    fontWeight: FontWeight.w600,
                    color: textColor ?? Colors.white,
                  ),
                ),
            ],
          );

    return Container(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: handlePress,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? theme.primaryColor,
          foregroundColor: textColor ?? Colors.white,
          disabledBackgroundColor:
              (color ?? theme.primaryColor).withOpacity(0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius ?? 8),
            side: BorderSide(
              color: borderColor ?? Colors.transparent,
              width: borderColor != null ? 1 : 0,
            ),
          ),
          padding: padding ??
              const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
          elevation: 0,
        ),
        child: content,
      ),
    );
  }
}

/// 主要按钮
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final double? width;
  final double? height;
  final bool disabled;
  final bool loading;
  final IconData? icon;

  const PrimaryButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.width,
    this.height,
    this.disabled = false,
    this.loading = false,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CommonButton(
      text: text,
      onPressed: onPressed,
      width: width,
      height: height,
      color: theme.primaryColor,
      textColor: Colors.white,
      disabled: disabled,
      loading: loading,
      icon: icon,
      id: 'primary_${text.hashCode}',
    );
  }
}

/// 次要按钮
class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final double? width;
  final double? height;
  final bool disabled;
  final bool loading;
  final IconData? icon;

  const SecondaryButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.width,
    this.height,
    this.disabled = false,
    this.loading = false,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CommonButton(
      text: text,
      onPressed: onPressed,
      width: width,
      height: height,
      color: Colors.transparent,
      textColor: theme.primaryColor,
      borderColor: theme.primaryColor,
      disabled: disabled,
      loading: loading,
      icon: icon,
      id: 'secondary_${text.hashCode}',
    );
  }
}

/// 文本按钮
class TextActionButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final double? fontSize;
  final bool disabled;
  final IconData? icon;
  final Color? color;

  const TextActionButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.fontSize,
    this.disabled = false,
    this.icon,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonId = 'text_${text.hashCode}';

    final handlePress = (disabled || onPressed == null)
        ? null
        : () => DebounceUtil.debounce(buttonId, onPressed!);

    return TextButton(
      onPressed: handlePress,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 16,
              color: color ?? theme.primaryColor,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: fontSize ?? 14,
              color: color ?? theme.primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// 图标按钮
class IconActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double? size;
  final Color? color;
  final Color? backgroundColor;
  final bool disabled;

  const IconActionButton({
    Key? key,
    required this.icon,
    this.onPressed,
    this.size,
    this.color,
    this.backgroundColor,
    this.disabled = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonId = 'icon_${icon.hashCode}';

    final handlePress = (disabled || onPressed == null)
        ? null
        : () => DebounceUtil.debounce(buttonId, onPressed!);

    return IconButton(
      onPressed: handlePress,
      icon: Icon(
        icon,
        size: size ?? 24,
        color: color ?? theme.primaryColor,
      ),
      padding: EdgeInsets.zero,
      splashRadius: (size ?? 24) + 8,
      style: IconButton.styleFrom(
        backgroundColor: backgroundColor,
      ),
    );
  }
}
