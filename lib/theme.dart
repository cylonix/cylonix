import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'utils/utils.dart';

final _lightTheme = ThemeData.light(useMaterial3: enableMaterial3());
final _darkTheme = ThemeData.dark(useMaterial3: enableMaterial3());
const lighCupertinoTheme = CupertinoThemeData(
  brightness: Brightness.light,
  scaffoldBackgroundColor: CupertinoColors.systemBackground,
);
final darkCupertinoTheme = CupertinoThemeData(
  brightness: Brightness.dark,
  //barBackgroundColor: CupertinoColors.systemBackground.darkColor,
  //scaffoldBackgroundColor: CupertinoColors.systemBackground.darkColor,
  textTheme: CupertinoTextThemeData(
    // Extend from default text theme and only override colors
    textStyle: const DefaultTextStyle.fallback().style.copyWith(
          color: CupertinoColors.white,
        ),
    actionTextStyle: const CupertinoTextThemeData()
        .actionTextStyle
        .copyWith(color: CupertinoColors.white),
    navTitleTextStyle: const CupertinoTextThemeData()
        .navTitleTextStyle
        .copyWith(color: CupertinoColors.white),
    navLargeTitleTextStyle: const CupertinoTextThemeData()
        .navLargeTitleTextStyle
        .copyWith(color: CupertinoColors.white),
    tabLabelTextStyle: const CupertinoTextThemeData()
        .tabLabelTextStyle
        .copyWith(color: CupertinoColors.white),
  ),
);

final List<ThemeData> themeList = [
  _lightTheme.copyWith(
    cupertinoOverrideTheme: lighCupertinoTheme,
    listTileTheme: _lightTheme.listTileTheme.copyWith(
      titleTextStyle: (_lightTheme.listTileTheme.titleTextStyle ??
              _lightTheme.textTheme.titleMedium)
          ?.copyWith(
        fontWeight: FontWeight.w500,
      ),
    ),
  ),
  _darkTheme.copyWith(
    cupertinoOverrideTheme: darkCupertinoTheme,
    extensions: [
      CupertinoListTileData(
        backgroundColor: CupertinoColors.systemBackground.darkColor,
        titleTextStyle: const TextStyle(
          color: CupertinoColors.white,
          fontSize: 17,
        ),
        subtitleTextStyle: const TextStyle(
          color: CupertinoColors.systemGrey,
          fontSize: 15,
        ),
      ),
    ],
  ),
];

// Add this extension to handle CupertinoListTile theming
class CupertinoListTileData extends ThemeExtension<CupertinoListTileData> {
  final Color? backgroundColor;
  final TextStyle? titleTextStyle;
  final TextStyle? subtitleTextStyle;

  const CupertinoListTileData({
    this.backgroundColor,
    this.titleTextStyle,
    this.subtitleTextStyle,
  });

  @override
  ThemeExtension<CupertinoListTileData> copyWith({
    Color? backgroundColor,
    TextStyle? titleTextStyle,
    TextStyle? subtitleTextStyle,
  }) {
    return CupertinoListTileData(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      titleTextStyle: titleTextStyle ?? this.titleTextStyle,
      subtitleTextStyle: subtitleTextStyle ?? this.subtitleTextStyle,
    );
  }

  @override
  ThemeExtension<CupertinoListTileData> lerp(
    covariant ThemeExtension<CupertinoListTileData>? other,
    double t,
  ) {
    if (other is! CupertinoListTileData) return this;
    return CupertinoListTileData(
      backgroundColor: Color.lerp(backgroundColor, other.backgroundColor, t),
      titleTextStyle: TextStyle.lerp(titleTextStyle, other.titleTextStyle, t),
      subtitleTextStyle:
          TextStyle.lerp(subtitleTextStyle, other.subtitleTextStyle, t),
    );
  }
}
