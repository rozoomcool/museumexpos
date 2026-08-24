import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'data/catalog.dart';
import 'state/gallery_state.dart';
import 'state/theme_controller.dart';
import 'ui/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
    DeviceOrientation.portraitUp,
  ]);
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
  );
  runApp(const ExpoApp());
}

class ExpoApp extends StatelessWidget {
  const ExpoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeController()),
        ChangeNotifierProvider(
          create: (_) => GalleryState(const CatalogRepository()),
        ),
      ],
      child: Consumer<ThemeController>(
        builder: (context, theme, _) => MaterialApp(
          title: 'Экспонаты ЧР',
          debugShowCheckedModeBanner: false,
          themeMode: theme.mode,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          scrollBehavior: const _AppScrollBehavior(),
          home: const HomeScreen(),
        ),
      ),
    );
  }
}

/// Горизонтальные ленты должны тянуться и мышью — приложение живёт и на
/// десктопе, и на сенсорном экране.
class _AppScrollBehavior extends MaterialScrollBehavior {
  const _AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
  };
}
