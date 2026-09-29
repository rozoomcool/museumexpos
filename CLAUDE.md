# CLAUDE.md

Flutter-экспонат музея ЧГУ им. А. А. Кадырова «Экспонаты ЧР»: офлайн-каталог
коллекции, 58 экспонатов в 6 разделах, 43 3D-модели (GLB через
`flutter_3d_controller`). Платформы: macOS и Android (киоск), есть веб-сборка.

## Сначала прочитай
- **[docs/architecture.md](docs/architecture.md)** — канонический документ:
  карта файлов, `catalog.json`, `GalleryState`, раскладка и брейкпоинты,
  3D и офлайн, пайплайн ассетов, тесты, подводные камни. Весь код заново не
  разбирай: там всё есть.
- **[docs/design-system.md](docs/design-system.md)** — как правила дизайна
  музея реализованы в коде: токены, шрифты, компоненты, латунь, логотип,
  чек-лист.
- `museum-design-prompt.md` — первоисточник правил дизайна (не редактировать).

## Команды
```bash
flutter pub get
flutter analyze        # должно быть: No issues found
flutter test           # логика состояния + golden-снимки
flutter test test/layout_golden_test.dart --update-goldens   # после правок UI; PNG смотреть глазами
flutter run -d macos
```

## Нельзя ломать
- Офлайн: никаких сетевых запросов, CDN и Draco в моделях (model-viewer
  тянет draco-декодер из сети).
- `assets/expos/` (5 ГБ исходников) не подключать в `pubspec.yaml`.
- `catalog.json`, `photos/`, `thumbs/` и `models/` генерируются скриптами из
  `tools/`. `build_assets.py` стирает `assets/models/`, после него запускай
  `build_models.sh`.
- Имена файлов ассетов — только латиница.
- Инварианты `GalleryState` (выбор экспоната переключает раздел и сбрасывает
  поиск и т. д.) закреплены тестами в `test/widget_test.dart`.
- `build/web/` лежит в git: не коммить его случайно вместе с кодом.

## Стиль UI
- Цвета, шрифты, отступы и радиусы — только токены из
  `lib/core/theme/tokens.dart` (`AppColors`, `AppFonts`, `AppSpacing`,
  `AppRadii`, `kTouchTarget`) и `context.text.*`. Hex-литералов и
  `Colors.white/black` в виджетах нет.
- Тема одна, тёмная (`AppTheme.dark()`). Literata — только `headline*` и
  `display*`, остальное Manrope (веса 400/600).
- Латунь `AppColors.brass` — только главное действие и активное состояние.
- Никаких теней, градиентов, стекла и полупрозрачных подложек, свечения,
  подъёма при наведении. Поверх фото и 3D — `Tag` и `PanelIconButton`.
- Фото и модели не тонировать.

## Обновляй документацию
При значимых изменениях правь `docs/architecture.md`, а если меняется
визуальный язык — и `docs/design-system.md`. Код без документации не
обновляй.
