import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomTabBar extends StatefulWidget {
  final List<String> tabs;
  final TabController controller;
  final Function(int) onTabChanged;
  final Function() onMiddleButtonPressed;
  final Color backgroundColor;
  final Color indicatorColor;
  final Color selectedTextColor;
  final Color unselectedTextColor;
  final Color middleButtonColor;
  final IconData middleButtonIcon;
  final String middleButtonLabel;

  const CustomTabBar({
    Key? key,
    required this.tabs,
    required this.controller,
    required this.onTabChanged,
    required this.onMiddleButtonPressed,
    this.backgroundColor = Colors.white,
    this.indicatorColor = Colors.black,
    this.selectedTextColor = Colors.black,
    this.unselectedTextColor = Colors.grey,
    this.middleButtonColor = Colors.black,
    this.middleButtonIcon = Icons.swap_horiz,
    this.middleButtonLabel = "Trade",
  }) : super(key: key);

  @override
  _CustomTabBarState createState() => _CustomTabBarState();
}

class _CustomTabBarState extends State<CustomTabBar> {
  @override
  Widget build(BuildContext context) {
    // Calculate number of tabs on each side of the middle button
    final int halfLength = (widget.tabs.length / 2).ceil();
    final leftTabs = widget.tabs.sublist(0, halfLength);
    final rightTabs = widget.tabs.sublist(halfLength);

    // Get theme colors based on brightness
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Get safe area insets
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;

    return Container(
      height: 80.h + safeAreaBottom, // Add safe area padding
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
            width: 0.5,
          ),
        ),
      ),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // The tab bar row
          Padding(
            padding: EdgeInsets.only(bottom: safeAreaBottom),
            child: Container(
              height: 55.h,
              alignment: Alignment.bottomCenter,
              child: Row(
                children: [
                  // Left side tabs
                  Expanded(
                    child: _buildTabSection(leftTabs, 0),
                  ),

                  // Middle space for button
                  SizedBox(width: 80.w),

                  // Right side tabs
                  Expanded(
                    child: _buildTabSection(rightTabs, halfLength),
                  ),
                ],
              ),
            ),
          ),

          // Middle raised button
          Positioned(
            top: 0,
            child: GestureDetector(
              onTap: widget.onMiddleButtonPressed,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 65.w,
                    height: 65.w,
                    decoration: BoxDecoration(
                      color: widget.middleButtonColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          spreadRadius: 2,
                          offset: const Offset(0, 3),
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 12,
                          spreadRadius: 1,
                          offset: const Offset(0, 6),
                        ),
                      ],
                      border: Border.all(
                        color:
                            isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      widget.middleButtonIcon,
                      color: isDarkMode
                          ? widget.middleButtonColor.withOpacity(0.9)
                          : Colors.white,
                      size: 30.sp,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    widget.middleButtonLabel,
                    style: TextStyle(
                      color: widget.selectedTextColor,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSection(List<String> tabs, int startIndex) {
    // Create tab widgets without using TabBar
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: tabs.asMap().entries.map((entry) {
        final int tabIndex = entry.key + startIndex;
        final String tabText = entry.value;
        final bool isSelected = widget.controller.index == tabIndex;

        return Expanded(
          child: InkWell(
            onTap: () => widget.onTabChanged(tabIndex),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _getIconForTab(tabIndex, isSelected),
                SizedBox(height: 4.h),
                Text(
                  tabText,
                  style: TextStyle(
                    color: isSelected
                        ? widget.selectedTextColor
                        : widget.unselectedTextColor,
                    fontSize: 12.sp,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _getIconForTab(int index, bool isSelected) {
    IconData iconData;
    switch (index) {
      case 0:
        iconData = Icons.home;
        break;
      case 1:
        iconData = Icons.stacked_line_chart;
        break;
      case 2:
        iconData = Icons.newspaper;
        break;
      case 3:
        iconData = Icons.person;
        break;
      default:
        iconData = Icons.circle;
        break;
    }

    return Icon(
      iconData,
      size: 24.sp,
      color: isSelected ? widget.selectedTextColor : widget.unselectedTextColor,
    );
  }
}
