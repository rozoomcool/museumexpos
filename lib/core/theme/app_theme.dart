import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'tokens.dart';

export 'tokens.dart';

extension AppThemeX on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
}

/// Тема по дизайн-системе музея ЧГУ (см. `docs/design-system.md`).
///
/// Одна тёмная тема: палитра музея и белый логотип рассчитаны на тёмный фон.
/// Поверхности плоские — без теней, размытия, градиентов и surface tint.
/// Literata назначена только стилям `display*` и `headline*`, всё остальное —
/// Manrope.
abstract final class AppTheme {
  static const _scheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.brass,
    onPrimary: AppColors.background,
    primaryContainer: AppColors.raised,
    onPrimaryContainer: AppColors.textPrimary,
    secondary: AppColors.textSecondary,
    onSecondary: AppColors.background,
    error: AppColors.error,
    onError: AppColors.background,
    errorContainer: AppColors.errorBg,
    onErrorContainer: AppColors.error,
    surface: AppColors.panel,
    onSurface: AppColors.textPrimary,
    onSurfaceVariant: AppColors.textSecondary,
    surfaceContainerLowest: AppColors.background,
    surfaceContainerLow: AppColors.panel,
    surfaceContainer: AppColors.panel,
    surfaceContainerHigh: AppColors.raised,
    surfaceContainerHighest: AppColors.raised,
    outline: AppColors.outline,
    outlineVariant: AppColors.divider,
    surfaceTint: Colors.transparent,
    shadow: Colors.transparent,
  );

  static const _heading = TextStyle(
    fontFamily: AppFonts.heading,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  static const _body = TextStyle(
    fontFamily: AppFonts.body,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const _label = TextStyle(
    fontFamily: AppFonts.body,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.35,
  );

  static final _textTheme = TextTheme(
    // Заголовки: Literata Regular, 28–88 px, межстрочный 1.15–1.25.
    displayLarge: _heading.copyWith(fontSize: 64, height: 1.15),
    displayMedium: _heading.copyWith(fontSize: 48, height: 1.15),
    displaySmall: _heading.copyWith(fontSize: 40),
    headlineLarge: _heading.copyWith(fontSize: 36),
    headlineMedium: _heading.copyWith(fontSize: 32),
    headlineSmall: _heading.copyWith(fontSize: 28),
    // Заголовки интерфейса — Manrope SemiBold.
    titleLarge: _label.copyWith(fontSize: 22, height: 1.3),
    titleMedium: _label.copyWith(fontSize: 18),
    titleSmall: _label.copyWith(fontSize: 16),
    // Основной текст: 16–22 px, межстрочный 1.45–1.6.
    bodyLarge: _body.copyWith(fontSize: 18, height: 1.55),
    bodyMedium: _body.copyWith(fontSize: 16),
    bodySmall: _body.copyWith(
      fontSize: 14,
      height: 1.45,
      color: AppColors.textSecondary,
    ),
    // Кнопки и служебные подписи: 12–16 px.
    labelLarge: _label.copyWith(fontSize: 16, height: 1.25),
    labelMedium: _label.copyWith(fontSize: 14, color: AppColors.textSecondary),
    labelSmall: _label.copyWith(
      fontSize: 12,
      color: AppColors.textSecondary,
      letterSpacing: 0.4,
    ),
  );

  static bool _isActive(Set<WidgetState> states) =>
      states.contains(WidgetState.hovered) ||
      states.contains(WidgetState.focused) ||
      states.contains(WidgetState.pressed);

  static const _buttonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(AppRadii.button)),
  );
  static const _buttonMinSize = Size(kTouchTarget, kTouchTarget);
  static const _buttonPadding = EdgeInsets.symmetric(
    horizontal: AppSpacing.lg,
    vertical: AppSpacing.sm,
  );

  /// Текст второстепенных кнопок: основной цвет, при наведении и фокусе —
  /// светлая латунь.
  static final _quietForeground = WidgetStateProperty.resolveWith<Color>((states) {
    if (states.contains(WidgetState.disabled)) {
      return AppColors.textSecondary.withValues(alpha: 0.5);
    }
    return _isActive(states) ? AppColors.brassHover : AppColors.textPrimary;
  });

  static final _quietOverlay = WidgetStateProperty.resolveWith<Color?>(
    (states) => _isActive(states) ? AppColors.brassHover.withValues(alpha: 0.08) : null,
  );

  static OutlineInputBorder _fieldBorder(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppRadii.field),
    borderSide: BorderSide(color: color),
  );

  static ThemeData dark() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: _scheme,
      fontFamily: AppFonts.body,
    );
    return base.copyWith(
      textTheme: _textTheme,
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.background,
      dividerColor: AppColors.divider,
      focusColor: AppColors.brassHover.withValues(alpha: 0.12),
      hoverColor: AppColors.brassHover.withValues(alpha: 0.08),
      splashFactory: InkRipple.splashFactory,
      visualDensity: VisualDensity.standard,
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
      iconTheme: const IconThemeData(color: AppColors.textPrimary, size: 20),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.brass,
        circularTrackColor: AppColors.divider,
        linearTrackColor: AppColors.divider,
      ),

      // Одно главное действие на экране.
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(_buttonMinSize),
          padding: const WidgetStatePropertyAll(_buttonPadding),
          shape: const WidgetStatePropertyAll(_buttonShape),
          elevation: const WidgetStatePropertyAll(0),
          textStyle: WidgetStatePropertyAll(_textTheme.labelLarge),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) return AppColors.raised;
            return _isActive(states) ? AppColors.brassHover : AppColors.brass;
          }),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? AppColors.textSecondary
                : AppColors.background,
          ),
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        ),
      ),

      // Второстепенные действия: контур, при наведении — латунный контур.
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(_buttonMinSize),
          padding: const WidgetStatePropertyAll(_buttonPadding),
          shape: const WidgetStatePropertyAll(_buttonShape),
          textStyle: WidgetStatePropertyAll(_textTheme.labelLarge),
          foregroundColor: _quietForeground,
          overlayColor: _quietOverlay,
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return const BorderSide(color: AppColors.divider);
            }
            return BorderSide(
              color: _isActive(states) ? AppColors.brassHover : AppColors.outline,
            );
          }),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(_buttonMinSize),
          padding: const WidgetStatePropertyAll(_buttonPadding),
          shape: const WidgetStatePropertyAll(_buttonShape),
          textStyle: WidgetStatePropertyAll(_textTheme.labelLarge),
          foregroundColor: _quietForeground,
          overlayColor: _quietOverlay,
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          shape: const WidgetStatePropertyAll(_buttonShape),
          foregroundColor: _quietForeground,
          overlayColor: _quietOverlay,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.panel,
        hintStyle: _textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        border: _fieldBorder(AppColors.outline),
        enabledBorder: _fieldBorder(AppColors.outline),
        focusedBorder: _fieldBorder(AppColors.brassHover),
        prefixIconColor: AppColors.textSecondary,
        suffixIconColor: AppColors.textSecondary,
      ),

      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.brass,
        selectionColor: AppColors.brass.withValues(alpha: 0.3),
        selectionHandleColor: AppColors.brass,
      ),

      tooltipTheme: TooltipThemeData(
        waitDuration: const Duration(milliseconds: 500),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: AppColors.raised,
          borderRadius: BorderRadius.circular(AppRadii.button),
          border: Border.all(color: AppColors.divider),
        ),
        textStyle: _textTheme.labelMedium?.copyWith(color: AppColors.textPrimary),
      ),

      scrollbarTheme: ScrollbarThemeData(
        thickness: const WidgetStatePropertyAll(4),
        radius: const Radius.circular(2),
        thumbColor: WidgetStatePropertyAll(AppColors.outline.withValues(alpha: 0.6)),
      ),

      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }

  static final SystemUiOverlayStyle overlay = SystemUiOverlayStyle.light.copyWith(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: AppColors.background,
  );
}
