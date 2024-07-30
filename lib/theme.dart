import "package:flutter/material.dart";

class TichuMateTheme {
  const TichuMateTheme();

  static ColorScheme darkScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xffffe4a0),
      surfaceTint: Color(0xfff2c00c),
      onPrimary: Color(0xff3d2f00),
      primaryContainer: Color(0xffe6b600),
      onPrimaryContainer: Color(0xff3b2d00),
      secondary: Color(0xffc8c5cc),
      onSecondary: Color(0xff303035),
      secondaryContainer: Color(0xff131318),
      onSecondaryContainer: Color(0xffa19fa6),
      tertiary: Color(0xff97d59d),
      onTertiary: Color(0xff003915),
      tertiaryContainer: Color(0xff468151),
      onTertiaryContainer: Color(0xffffffff),
      error: Color(0xffffb4ab),
      onError: Color(0xff690005),
      errorContainer: Color(0xff93000a),
      onErrorContainer: Color(0xffffdad6),
      surface: Color(0xff171309),
      onSurface: Color(0xffebe1d0),
      onSurfaceVariant: Color(0xffd2c5ac),
      outline: Color(0xff9a9078),
      outlineVariant: Color(0xff4e4632),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffebe1d0),
      inversePrimary: Color(0xff745b00),
      primaryFixed: Color(0xffffe08e),
      onPrimaryFixed: Color(0xff241a00),
      primaryFixedDim: Color(0xfff2c00c),
      onPrimaryFixedVariant: Color(0xff584400),
      secondaryFixed: Color(0xffe4e1e8),
      onSecondaryFixed: Color(0xff1b1b20),
      secondaryFixedDim: Color(0xffc8c5cc),
      onSecondaryFixedVariant: Color(0xff47464c),
      tertiaryFixed: Color(0xffb2f2b8),
      onTertiaryFixed: Color(0xff00210a),
      tertiaryFixedDim: Color(0xff97d59d),
      onTertiaryFixedVariant: Color(0xff145127),
      surfaceDim: Color(0xff171309),
      surfaceBright: Color(0xff3e392d),
      surfaceContainerLowest: Color(0xff110e05),
      surfaceContainerLow: Color(0xff1f1b11),
      surfaceContainer: Color(0xff241f15),
      surfaceContainerHigh: Color(0xff2e2a1e),
      surfaceContainerHighest: Color(0xff393429),
    );
  }

  static ThemeData dark() {
    return TichuMateTheme.theme(darkScheme());
  }

  static ThemeData theme(ColorScheme colorScheme) => ThemeData(
        useMaterial3: true,
        fontFamily: 'RobotoCondensed',
        brightness: colorScheme.brightness,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: colorScheme.surfaceContainerLow,
        canvasColor: colorScheme.surface,
      );
}
