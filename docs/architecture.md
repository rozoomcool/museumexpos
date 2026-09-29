# Архитектура «Экспонаты ЧР»

Канонический технический документ проекта. Цель — чтобы в новой сессии не
приходилось заново разбирать код. При значимых изменениях обновляйте его
вместе с кодом.

Правила визуального языка описаны отдельно, в [design-system.md](design-system.md).

---

## 1. Что это

Экспонат музея ЧГУ им. А. А. Кадырова: интерактивный офлайн-каталог
коллекции. В нём **58 экспонатов в 6 разделах, у 43 есть 3D-модель**. Нумерация
кураторская, от 1 до 60, с пропусками. Для каждого экспоната есть описание
(«почему выбран»), фотографии и, если снята, GLB-модель.

- Flutter (Dart SDK ^3.11.5, проверено на Flutter 3.47.2).
- Целевые платформы: **macOS** и **Android** (киоск). Есть и веб-сборка
  (`web/`, `build/web/`).
- Приложение полностью офлайновое, сеть не используется. Единственное
  «сетевое» разрешение нужно для localhost-сервера плагина 3D (см. §6).
- Одна тёмная тема по дизайн-системе музея. Светлой темы и переключателя
  больше нет.
- Ориентация: альбомная и портретная (`main.dart`), режим edge-to-edge.

## 2. Карта файлов

```
lib/
  main.dart                     ExpoApp: Provider<GalleryState>, MaterialApp, скролл мышью
  core/theme/
    tokens.dart                 AppColors, AppFonts, AppSpacing, AppRadii, AppAssets, kTouchTarget
    app_theme.dart              AppTheme.dark(), AppTheme.overlay, extension context.colors/text
  data/catalog.dart             Exhibit, ExhibitCategory, Catalog, CatalogRepository
  state/gallery_state.dart      GalleryState (ChangeNotifier): всё состояние экрана
  ui/
    home_screen.dart            HomeScreen: клавиши, загрузка/ошибка, колонка секций; брейкпоинты
    sections/
      top_bar.dart              логотип, название, поиск
      categories_section.dart   лента разделов
      viewer_section.dart       «Просмотр»: сетка ИЛИ раскладка экспоната; перетаскиваемый делитель
      models_section.dart       лента «Модели» (только когда экспонат выбран)
    widgets/
      common.dart               SectionLabel, Tag, SectionSurface, Hoverable, PanelIconButton,
                                FadeSwitch, plural(), categoryIcons, длительности kFast/kMedium
      exhibit_card.dart         ExhibitCard (сетка), ExhibitThumb (превью)
      exhibit_details.dart      описание, галерея фото, навигация «предыдущий/следующий»
      model_stage.dart          3D-сцена, полноэкранный режим, экспонат без модели
      photo_lightbox.dart       полноэкранные фото с масштабированием
assets/
  data/catalog.json             генерируется tools/build_assets.py
  photos/ thumbs/ models/       генерируются скриптами (в git)
  fonts/                        Literata, Manrope + лицензии OFL
  images/brand/logo_white.png   прозрачный белый логотип музея
  expos/                        исходный архив, 5 ГБ, в .gitignore, в сборку НЕ входит
tools/                          пайплайн ассетов (Python + gltf-transform)
test/                           логика состояния + golden-снимки раскладки
web/                            index.html, model-viewer.min.js (локальная копия)
docs/                           эта документация
museum-design-prompt.md         первоисточник правил дизайна (не редактировать)
```

## 3. Данные

### catalog.json

```jsonc
{
  "title": "Экспонаты ЧР",
  "subtitle": "Кураторская подборка 60 экспонатов",
  "categories": [
    {
      "id": "armour-and-weapons",        // slug, задаётся вручную в build_assets.py
      "title": "Доспехи и оружие",
      "icon": "shield",                  // ключ из categoryIcons (common.dart)
      "exhibits": [
        {
          "id": "001-rekonstrukciya-vooruzheniya-chechenskogo", // NNN-транслит
          "number": 1,                   // номер в кураторской подборке
          "title": "…",
          "categoryId": "armour-and-weapons",
          "reason": "…",                 // «Почему выбран»: основной текст описания
          "note": "…",                   // примечание куратора (в UI пока не выводится)
          "sources": "…",                // технические папки-источники (в UI не выводится)
          "photos": ["assets/photos/<id>_01.jpg", …],  // до 1800 px
          "thumbs": ["assets/thumbs/<id>_01.jpg", …],  // до 640 px, тот же порядок
          "model": "assets/models/<id>.glb"            // или null
        }
      ]
    }
  ]
}
```

Разделы и их иконки: `armour-and-weapons`/`shield`,
`costume-and-jewellery`/`costume`, `archaeology`/`amphora`,
`ethnography`/`home`, `modern-history`/`medal`, `painting`/`palette`.

Имена файлов ассетов только латинские: кириллица в путях ломает сборку на
части платформ. Русские названия хранятся только в JSON.

### Модели Dart (`lib/data/catalog.dart`)

- `Exhibit`: поля из JSON; `hasModel`, `hasPhotos`, `cover` (первое превью).
- `ExhibitCategory`: `modelCount`.
- `Catalog`: `allExhibits` (плоский список по всем разделам),
  `categoryOf(exhibit)`.
- `CatalogRepository.load()` читает `assets/data/catalog.json` через
  `rootBundle`.

## 4. Состояние: `GalleryState`

Один `ChangeNotifier` на весь экран. Создаётся в `main.dart` и сразу вызывает
`load()`.

| Поле / метод | Смысл |
|---|---|
| `status` | `loading` / `ready` / `failed` (+ `error`) |
| `category` | текущий раздел; после загрузки — первый |
| `exhibit` | выбранный экспонат или `null` (тогда показывается сетка) |
| `query`, `isSearching` | поиск по `title` и `reason` во **всей** коллекции |
| `visibleExhibits` | результаты поиска или экспонаты текущего раздела |
| `selectedIndex`, `hasPrevious`, `hasNext`, `step(±1)` | навигация внутри `visibleExhibits` |
| `splitRatio` | доля ширины под 3D-сцену: 0.4 по умолчанию, пределы 0.25–0.65 |

Поведенческие инварианты (их проверяют тесты в `test/widget_test.dart`):

- `selectCategory` сбрасывает выбранный экспонат и поиск.
- `selectExhibit` переключает раздел на раздел экспоната и сбрасывает поиск.
  Так лента «Модели» показывает окружение предмета, а не результаты поиска.
- Непустой `search()` снимает выбор экспоната: показывается сетка результатов.
- `step()` не выходит за границы списка.

## 5. Экран

`HomeScreen` — `Focus` с клавишами: `←`/`→` листают `step(±1)`, `Esc` вызывает
`clearSelection()`. Внутри колонка:

```
TopBar              логотип | название + подзаголовок | поиск; под ним Divider
CategoriesSection   подпись «Категории» + горизонтальная лента плашек-разделов
ViewerSection       (Expanded) подпись «Просмотр» + FadeSwitch:
                      exhibit == null → _CatalogGrid (ExhibitCard) / _EmptyState
                      exhibit != null → _ExhibitLayout
ModelsSection       лента «Модели»; AnimatedSize, высота 0, пока ничего не выбрано
```

Брейкпоинты:

- `kCompactBreakpoint = 700` (`home_screen.dart`): боковые поля 16 вместо 24,
  компактные размеры, у `ExhibitDetails` заголовок 28 вместо 36.
- `kSplitBreakpoint = 900`: при ширине ≥ 900 `_ExhibitLayout` раскладывается
  так: сцена (`splitRatio`), перетаскиваемый `_Divider` (двойной клик
  сбрасывает пропорцию), описание. При ширине < 900 — одна панель со скроллом:
  сцена сверху (320 px, компактно 240), под ней `ExhibitDetails`.
- `TopBar._titleBreakpoint = 560`: ниже этой ширины название скрывается,
  остаются логотип и поиск.
- `ExhibitDetails._Navigation`: при ширине < 440 кнопки показываются только
  иконками.
- Колонки сетки: `ширина / 272` (компактно `/ 210`), от 1 до 6.

Мелочи, которые легко сломать:

- `CategoriesSection` строит все плашки сразу (`SingleChildScrollView`, а не
  ленивый список), чтобы `Scrollable.ensureVisible` мог докрутить до активного
  раздела, если его сменили не касанием (например, через поиск).
- `ModelsSection._revealSelected` считает смещение по фиксированной ширине
  карточки `_itemWidth + _gap`. При изменении размеров плитки обновляйте
  константы.
- Поле поиска синхронизируется с `state.query` в `build`: состояние может
  само обнулить запрос.
- `ExhibitDetails` сбрасывает номер фото в `didUpdateWidget` при смене
  экспоната.

## 6. 3D-просмотр (`model_stage.dart`)

- Пакет `flutter_3d_controller` 2.3.0 — обёртка над Google `<model-viewer>` в
  WebView (на вебе — прямо в DOM). Фон просмотрщика прозрачный: модель лежит
  на панели `AppColors.panel` (в полноэкранном режиме — на `background`).
- **Офлайн:** модели собраны без Draco, потому что model-viewer грузит
  draco-декодер с CDN. Используются квантование (`KHR_mesh_quantization`) и
  WebP-текстуры: они декодируются штатно.
- **macOS:** плагин поднимает локальный HTTP-сервер, поэтому в entitlements
  нужны `network.client` и `network.server`. **Android:** разрешение
  `INTERNET` и `usesCleartextTraffic="true"` для того же localhost.
- **Веб:** пакет не подключает model-viewer сам. `web/index.html` грузит
  локальную копию `web/model-viewer.min.js`; после обновления пакета её
  нужно пересинхронизировать через `tools/sync_model_viewer.sh`. Путь к
  модели на вебе получает приставку `assets/` (`modelSrc()`).
- Управление: вращение (`startRotation`/`pauseRotation`), сброс ракурса,
  полноэкранный режим (`_FullscreenStage`, отдельный маршрут). Кнопки активны
  только после `onLoad`.
- Экспонат без модели (`_NoModel`): крупное фото, открывается в лайтбоксе.
- `ModelStage.viewerOverride` — подмена просмотрщика для тестов: плагин в
  тестовой среде не регистрируется.
- Параметр `framed`: рисовать ли собственную панель. В вертикальной раскладке
  он `false`, потому что сцена уже лежит внутри общей панели.

## 7. Пайплайн ассетов (`tools/`)

Исходники — `assets/expos/<NN_Раздел>/<NNN_Название>/`: `description.txt`,
фото (`.jpg/.png/.tif`), один `.glb`. Архив весит около 5 ГБ, лежит в
`.gitignore` и в сборку не попадает.

```bash
python3 tools/build_assets.py   # catalog.json, photos/, thumbs/, tools/model_jobs.json (нужен Pillow)
cd tools && npm install          # один раз: @gltf-transform/cli
tools/build_models.sh            # сжимает GLB по model_jobs.json
```

- `build_assets.py` **удаляет и пересоздаёт** `assets/{photos,thumbs,data,models}`.
  После него модели нужно пересобрать через `build_models.sh`, иначе
  `assets/models/` останется пустым.
- `description.txt` разбирается по ключам: `Экспонат:`, `Раздел:`,
  `Почему выбран:`, `Исходные технические папки:`, `Примечание:`,
  `Номер в кураторской подборке: N`.
- Slug и иконка раздела задаются вручную в словаре `CATEGORIES`. Новый раздел
  нужно добавить туда, а его иконку — в `categoryIcons` (`common.dart`).
- `build_models.sh`: `gltf-transform optimize --compress quantize
  --texture-compress webp --texture-size 2048 --simplify`. Сейчас модели
  занимают около 390 МБ; `--texture-size 1024` ужмёт их примерно втрое.

## 8. Проверки

```bash
flutter analyze                                              # должно быть: No issues found
flutter test                                                 # логика + golden
flutter test test/layout_golden_test.dart --update-goldens   # после изменений UI
```

Golden-снимки (`test/goldens/`): `grid_dark` (1440×900, сетка),
`exhibit_dark` (1440×900, выбранный экспонат), `exhibit_narrow`
(820×1180, вертикальная раскладка), `exhibit_phone` (390×844). Сцена 3D на
снимках — заглушка с индикатором «Подготовка сцены». Тест сам загружает
шрифты Literata и Manrope из `assets/fonts/` и MaterialIcons. **После
обновления снимков смотрите PNG глазами**: тест только сравнивает пиксели с
эталоном.

## 9. Сборка

```bash
flutter pub get
flutter run -d macos
flutter build apk --release      # около 430 МБ: для установки в киоск, не для Play
```

`applicationId` — `ru.chr.expo`.

## 10. Подводные камни

- `build/web/` **закоммичен** в git (коммит «add web»): сборка веба меняет
  отслеживаемые файлы. Не коммитьте их случайно вместе с кодом.
- `flutter analyze` может сам дописать в `analysis_options.yaml` секцию
  `analyzer.exclude`: это поведение инструмента, а не ошибка.
- В UI зашит текст «№ N из 60» (`exhibit_details.dart`): кураторская подборка
  рассчитана на 60 номеров, хотя в каталоге 58 экспонатов.
- Поля `note` и `sources` есть в данных, но на экран не выводятся.

## 11. Рецепты

- **Добавить или изменить экспонат:** поправить исходник в `assets/expos/`,
  затем запустить `build_assets.py` и `build_models.sh`. Руками
  `catalog.json` не правят: следующая сборка его перезапишет.
- **Новый элемент UI:** сначала [чек-лист дизайн-системы](design-system.md#чек-лист),
  потом снимки через `--update-goldens` и просмотр PNG.
- **Новая клавиша:** `HomeScreen._onKey`, а в лайтбоксе — `PhotoLightbox._onKey`
  (у лайтбокса свой `Focus`).
