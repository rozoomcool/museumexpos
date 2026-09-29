import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../state/gallery_state.dart';
import 'sections/categories_section.dart';
import 'sections/models_section.dart';
import 'sections/top_bar.dart';
import 'sections/viewer_section.dart';

/// Ширина, ниже которой раскладка «модель слева, описание справа» перестаёт
/// быть читаемой и превращается в вертикальную.
const kSplitBreakpoint = 900.0;
const kCompactBreakpoint = 700.0;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final state = context.read<GalleryState>();
    switch (event.logicalKey) {
      case LogicalKeyboardKey.escape:
        state.clearSelection();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowRight:
        state.step(1);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowLeft:
        state.step(-1);
        return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.overlay,
      child: Scaffold(
        body: Focus(
          focusNode: _focusNode,
          autofocus: true,
          onKeyEvent: _onKey,
          child: SafeArea(
            child: Consumer<GalleryState>(
              builder: (context, state, _) => switch (state.status) {
                LoadStatus.loading => const _Centered(child: _Loader()),
                LoadStatus.failed => _Centered(child: _Failure(state: state)),
                LoadStatus.ready => const _Content(),
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < kCompactBreakpoint;
        final pad = compact ? AppSpacing.md : AppSpacing.lg;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TopBar(padding: pad, compact: compact),
            CategoriesSection(padding: pad, compact: compact),
            Expanded(child: ViewerSection(padding: pad, compact: compact)),
            ModelsSection(padding: pad, compact: compact),
          ],
        );
      },
    );
  }
}

class _Centered extends StatelessWidget {
  const _Centered({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Center(child: child);
}

class _Loader extends StatelessWidget {
  const _Loader();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Загружаем коллекцию', style: context.text.bodyMedium),
      ],
    );
  }
}

class _Failure extends StatelessWidget {
  const _Failure({required this.state});

  final GalleryState state;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Не удалось прочитать каталог', style: context.text.headlineSmall),
          const SizedBox(height: AppSpacing.md),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.errorBg,
                borderRadius: BorderRadius.circular(AppRadii.card),
              ),
              child: Text(
                '${state.error}',
                textAlign: TextAlign.center,
                style: context.text.bodySmall?.copyWith(color: AppColors.error),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: state.load,
            icon: const Icon(Icons.refresh, size: 20),
            label: const Text('Повторить'),
          ),
        ],
      ),
    );
  }
}
