import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../state/gallery_state.dart';
import 'sections/categories_section.dart';
import 'sections/models_section.dart';
import 'sections/top_bar.dart';
import 'sections/viewer_section.dart';
import 'widgets/common.dart';

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
    final brightness = Theme.of(context).brightness;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.overlayFor(brightness),
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
        final pad = compact ? 16.0 : 24.0;
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
        SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: context.colors.primary,
          ),
        ),
        const SizedBox(height: 18),
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
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 34, color: context.colors.error),
          const SizedBox(height: 16),
          Text('Не удалось прочитать каталог', style: context.text.headlineSmall),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Text(
              '${state.error}',
              textAlign: TextAlign.center,
              style: context.text.bodySmall,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: state.load,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Повторить'),
          ),
        ],
      ),
    );
  }
}

/// Общая «карточка» секции: подложка, скруглённые углы, тонкая рамка.
class SectionSurface extends StatelessWidget {
  const SectionSurface({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.tones.card,
        borderRadius: BorderRadius.circular(kRadius),
        border: Border.all(color: context.tones.hairline),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
