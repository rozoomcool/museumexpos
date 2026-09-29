import 'package:flutter/painting.dart';

/// Палитра единой дизайн-системы музея ЧГУ им. А. А. Кадырова
/// (первоисточник — `museum-design-prompt.md`).
///
/// Фирменные цвета относятся к оболочке и управлению. Фотографии и 3D-модели
/// показываются в естественных цветах: поверх них ничего не тонируется.
abstract final class AppColors {
  // Поверхности.
  static const background = Color(0xFF111C19);
  static const panel = Color(0xFF192823);

  /// Приподнятые / активные поверхности: наведение, выбранная карточка,
  /// тултипы.
  static const raised = Color(0xFF21352D);

  // Текст.
  static const textPrimary = Color(0xFFF3EFE5);
  static const textSecondary = Color(0xFFB9C4BA);

  /// Приглушённая латунь — дозированно: главное действие и активное состояние.
  static const brass = Color(0xFFC9AD79);

  /// Наведение и фокус.
  static const brassHover = Color(0xFFDFC394);

  // Линии.
  static const divider = Color(0xFF35463C);

  /// Контуры интерактивных элементов: поля, кнопки, карточки при наведении.
  static const outline = Color(0xFF718276);

  // Статусы.
  static const success = Color(0xFF9BCCA9);
  static const successBg = Color(0xFF253F31);
  static const error = Color(0xFFE0A59C);
  static const errorBg = Color(0xFF42302A);
}

/// Локальные шрифты из `assets/fonts/` (лицензии OFL лежат рядом).
abstract final class AppFonts {
  /// Заголовки и крупные акцентные числа. Только Regular (w400).
  static const heading = 'Literata';

  /// Текст, интерфейс и данные. Regular (w400) и SemiBold (w600) — других
  /// начертаний нет, Flutter дорисовал бы их синтетически.
  static const body = 'Manrope';
}

/// Сетка 4/8; основные интервалы 16/24/32/48/64.
abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;
}

/// Радиусы: кнопки 8, поля 10, карточки 12, панели 16.
abstract final class AppRadii {
  static const double button = 8;
  static const double field = 10;
  static const double card = 12;
  static const double panel = 16;
}

/// Минимальный размер нажимаемого элемента: приложение работает в киоске
/// с сенсорным экраном.
const double kTouchTarget = 48;

abstract final class AppAssets {
  /// Белая версия прозрачного логотипа музея — только на тёмном фоне,
  /// без перерисовки и искажения пропорций.
  static const logoWhite = 'assets/images/brand/logo_white.png';
}
