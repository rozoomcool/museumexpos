import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Дополнительные цвета, которых нет в [ColorScheme]: фон «сцены» 3D-просмотра,
/// приглушённые границы и цвет подложки карточек.
@immutable
class AppTones extends ThemeExtension<AppTones> {
  const AppTones({
    required this.canvas,
    required this.card,
    required this.cardHover,
    required this.hairline,
    required this.stageTop,
    required this.stageBottom,
    required this.muted,
    required this.accentSoft,
  });

  final Color canvas;
  final Color card;
  final Color cardHover;
  final Color hairline;
  final Color stageTop;
  final Color stageBottom;
  final Color muted;
  final Color accentSoft;

  @override
  AppTones copyWith({
    Color? canvas,
    Color? card,
    Color? cardHover,
    Color? hairline,
    Color? stageTop,
    Color? stageBottom,
    Color? muted,
    Color? accentSoft,
  }) => AppTones(
    canvas: canvas ?? this.canvas,
    card: card ?? this.card,
    cardHover: cardHover ?? this.cardHover,
    hairline: hairline ?? this.hairline,
    stageTop: stageTop ?? this.stageTop,
    stageBottom: stageBottom ?? this.stageBottom,
    muted: muted ?? this.muted,
    accentSoft: accentSoft ?? this.accentSoft,
  );

  @override
  AppTones lerp(AppTones? other, double t) {
    if (other == null) return this;
    return AppTones(
      canvas: Color.lerp(canvas, other.canvas, t)!,
      card: Color.lerp(card, other.card, t)!,
      cardHover: Color.lerp(cardHover, other.cardHover, t)!,
      hairline: Color.lerp(hairline, other.hairline, t)!,
      stageTop: Color.lerp(stageTop, other.stageTop, t)!,
      stageBottom: Color.lerp(stageBottom, other.stageBottom, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
    );
  }
}

extension AppThemeX on BuildContext {
  AppTones get tones => Theme.of(this).extension<AppTones>()!;
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
}

/// Тёмная тема — основная: витринные фотографии и 3D читаются на ней лучше.
/// Светлая нужна для яркого зала, где экран бликует.
abstract final class AppTheme {
  static const _bronze = Color(0xFFD8A94A);
  static const _bronzeDeep = Color(0xFF9C6F14);

  static ThemeData dark() => _build(
    brightness: Brightness.dark,
    scheme: const ColorScheme.dark(
      primary: _bronze,
      onPrimary: Color(0xFF241A00),
      secondary: Color(0xFF8FA6B8),
      onSecondary: Color(0xFF0E1116),
      surface: Color(0xFF14161B),
      onSurface: Color(0xFFF1EFEA),
      onSurfaceVariant: Color(0xFF9BA0AB),
      outline: Color(0xFF2B303A),
      outlineVariant: Color(0xFF20242C),
      error: Color(0xFFE0796B),
    ),
    tones: const AppTones(
      canvas: Color(0xFF0D0F13),
      card: Color(0xFF171A20),
      cardHover: Color(0xFF1E222A),
      hairline: Color(0xFF262B34),
      stageTop: Color(0xFF1B1F26),
      stageBottom: Color(0xFF0B0D11),
      muted: Color(0xFF767C88),
      accentSoft: Color(0x1FD8A94A),
    ),
  );

  static ThemeData light() => _build(
    brightness: Brightness.light,
    scheme: const ColorScheme.light(
      primary: _bronzeDeep,
      onPrimary: Color(0xFFFFFFFF),
      secondary: Color(0xFF4A5A68),
      onSecondary: Color(0xFFFFFFFF),
      surface: Color(0xFFFFFFFF),
      onSurface: Color(0xFF15181D),
      onSurfaceVariant: Color(0xFF5C626C),
      outline: Color(0xFFDCD8CF),
      outlineVariant: Color(0xFFEBE7DF),
      error: Color(0xFFB3261E),
    ),
    tones: const AppTones(
      canvas: Color(0xFFF6F4F0),
      card: Color(0xFFFFFFFF),
      cardHover: Color(0xFFFBF9F5),
      hairline: Color(0xFFE6E2D9),
      stageTop: Color(0xFFFFFFFF),
      stageBottom: Color(0xFFECE8E0),
      muted: Color(0xFF8A8F98),
      accentSoft: Color(0x1A9C6F14),
    ),
  );

  static ThemeData _build({
    required Brightness brightness,
    required ColorScheme scheme,
    required AppTones tones,
  }) {
    final base = ThemeData(brightness: brightness, colorScheme: scheme);
    final onSurface = scheme.onSurface;
    final onVariant = scheme.onSurfaceVariant;

    TextStyle display(double size, {FontWeight weight = FontWeight.w600, double height = 1.12}) =>
        TextStyle(
          fontFamily: 'Playfair',
          fontSize: size,
          fontWeight: weight,
          height: height,
          color: onSurface,
          letterSpacing: -0.2,
        );

    TextStyle body(
      double size, {
      FontWeight weight = FontWeight.w400,
      double height = 1.5,
      Color? color,
      double spacing = 0,
    }) => TextStyle(
      fontFamily: 'Inter',
      fontSize: size,
      fontWeight: weight,
      height: height,
      color: color ?? onSurface,
      letterSpacing: spacing,
    );

    return base.copyWith(
      scaffoldBackgroundColor: tones.canvas,
      canvasColor: tones.canvas,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      extensions: [tones],
      textTheme: TextTheme(
        displayLarge: display(46),
        displayMedium: display(36),
        displaySmall: display(28),
        headlineMedium: display(24),
        headlineSmall: display(20),
        titleLarge: body(17, weight: FontWeight.w600, height: 1.3),
        titleMedium: body(15, weight: FontWeight.w600, height: 1.35),
        titleSmall: body(13, weight: FontWeight.w600, height: 1.35),
        bodyLarge: body(16, height: 1.62, color: onVariant),
        bodyMedium: body(14.5, height: 1.6, color: onVariant),
        bodySmall: body(13, height: 1.5, color: tones.muted),
        labelLarge: body(14, weight: FontWeight.w600, height: 1.2),
        labelMedium: body(12.5, weight: FontWeight.w500, height: 1.2),
        labelSmall: body(11, weight: FontWeight.w600, height: 1.2, spacing: 0.9),
      ),
      dividerTheme: DividerThemeData(color: tones.hairline, thickness: 1, space: 1),
      iconTheme: IconThemeData(color: onVariant, size: 20),
      tooltipTheme: TooltipThemeData(
        waitDuration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(
          color: brightness == Brightness.dark
              ? const Color(0xFF272C35)
              : const Color(0xFF23262B),
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: body(12.5, color: Colors.white, weight: FontWeight.w500),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thickness: WidgetStatePropertyAll(6),
        radius: const Radius.circular(3),
        thumbColor: WidgetStatePropertyAll(onVariant.withValues(alpha: 0.28)),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }

  static SystemUiOverlayStyle overlayFor(Brightness brightness) =>
      brightness == Brightness.dark
      ? SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: const Color(0xFF0D0F13),
        )
      : SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: const Color(0xFFF6F4F0),
        );
}
