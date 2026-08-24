@Tags(['golden'])
library;

import 'dart:io';

import 'package:chrexpo/core/theme/app_theme.dart';
import 'package:chrexpo/data/catalog.dart';
import 'package:chrexpo/state/gallery_state.dart';
import 'package:chrexpo/state/theme_controller.dart';
import 'package:chrexpo/ui/home_screen.dart';
import 'package:chrexpo/ui/widgets/model_stage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// Снимки раскладки. Плагин 3D-просмотра в тестовой среде недоступен, поэтому
/// сцена выходит пустой — проверяется всё остальное: сетка, описание,
/// категории и лента моделей.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Плагин вебвью в тестовой среде не регистрируется, поэтому на снимках
  // вместо сцены — нейтральная заглушка. Проверяется раскладка, а не рендер 3D.
  setUp(() {
    ModelStage.viewerOverride = (src) => const ColoredBox(color: Color(0x11000000));
    addTearDown(() => ModelStage.viewerOverride = null);
  });

  setUpAll(() async {
    for (final family in {'Inter', 'Playfair'}) {
      final loader = FontLoader(family);
      for (final path in _fontFiles(family)) {
        loader.addFont(rootBundle.load(path));
      }
      await loader.load();
    }
    // Без явной загрузки иконочного шрифта тестовый рендерер рисует квадраты.
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
  });

  Future<GalleryState> pumpApp(
    WidgetTester tester, {
    required Size size,
    ThemeMode mode = ThemeMode.dark,
  }) async {
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    late final GalleryState state;
    await tester.runAsync(() async {
      state = GalleryState(const CatalogRepository());
      while (state.status == LoadStatus.loading) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
    });

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ThemeController>(create: (_) => ThemeController()),
          ChangeNotifierProvider<GalleryState>.value(value: state),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          themeMode: mode,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          home: const HomeScreen(),
        ),
      ),
    );
    await settle(tester);
    return state;
  }

  testWidgets('сетка экспонатов', (tester) async {
    await pumpApp(tester, size: const Size(1440, 900));
    await expectLater(
      find.byType(HomeScreen),
      matchesGoldenFile('goldens/grid_dark.png'),
    );
  });

  testWidgets('выбранный экспонат: модель, описание, лента', (tester) async {
    final state = await pumpApp(tester, size: const Size(1440, 900));
    state.selectExhibit(state.categories.first.exhibits[1]);
    await settle(tester);
    await expectLater(
      find.byType(HomeScreen),
      matchesGoldenFile('goldens/exhibit_dark.png'),
    );
  });

  testWidgets('светлая тема', (tester) async {
    final state = await pumpApp(
      tester,
      size: const Size(1440, 900),
      mode: ThemeMode.light,
    );
    state.selectExhibit(state.categories.first.exhibits[3]);
    await settle(tester);
    await expectLater(
      find.byType(HomeScreen),
      matchesGoldenFile('goldens/exhibit_light.png'),
    );
  });

  testWidgets('узкий экран: вертикальная раскладка', (tester) async {
    final state = await pumpApp(tester, size: const Size(820, 1180));
    state.selectExhibit(state.categories.last.exhibits.first);
    await settle(tester);
    await expectLater(
      find.byType(HomeScreen),
      matchesGoldenFile('goldens/exhibit_narrow.png'),
    );
  });
}

List<String> _fontFiles(String family) {
  final dir = Directory('assets/fonts');
  final prefix = family == 'Inter' ? 'Inter-' : 'PlayfairDisplay-';
  return dir
      .listSync()
      .whereType<File>()
      .map((f) => f.path)
      .where((p) => p.split('/').last.startsWith(prefix))
      .toList()
    ..sort();
}

/// Прогоняет анимации и догружает изображения: в тестовой среде декодирование
/// возможно только внутри runAsync, иначе на снимке будут пустые рамки.
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.runAsync(() async {
    for (final element in find.byType(Image).evaluate()) {
      final image = element.widget as Image;
      await precacheImage(image.image, element);
    }
  });
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pump(const Duration(milliseconds: 600));
}
