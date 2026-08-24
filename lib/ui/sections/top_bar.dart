import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../state/gallery_state.dart';
import '../../state/theme_controller.dart';
import '../widgets/common.dart';

class TopBar extends StatelessWidget {
  const TopBar({super.key, required this.padding, required this.compact});

  final double padding;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GalleryState>();
    final catalog = state.catalog;
    final total = catalog?.allExhibits.length ?? 0;

    return Padding(
      padding: EdgeInsets.fromLTRB(padding, compact ? 12 : 18, padding, 10),
      child: Row(
        children: [
          const _Emblem(),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  catalog?.title ?? 'Экспонаты ЧР',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.headlineSmall?.copyWith(
                    fontSize: compact ? 18 : 21,
                    letterSpacing: 0.1,
                  ),
                ),
                if (!compact)
                  Text(
                    '${catalog?.subtitle ?? ''} · ${plural(total, 'предмет', 'предмета', 'предметов')}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodySmall,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          _SearchField(compact: compact),
          const SizedBox(width: 8),
          const _ThemeToggle(),
        ],
      ),
    );
  }
}

class _Emblem extends StatelessWidget {
  const _Emblem();

  @override
  Widget build(BuildContext context) {
    final primary = context.colors.primary;
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(11),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primary.withValues(alpha: 0.9), primary.withValues(alpha: 0.55)],
        ),
      ),
      child: Icon(
        Icons.museum_outlined,
        size: 20,
        color: context.colors.onPrimary,
      ),
    );
  }
}

class _SearchField extends StatefulWidget {
  const _SearchField({required this.compact});

  final bool compact;

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  late final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GalleryState>();
    // Состояние может обнулить запрос само (например, при выборе категории).
    if (state.query != _controller.text) {
      _controller.value = TextEditingValue(
        text: state.query,
        selection: TextSelection.collapsed(offset: state.query.length),
      );
    }

    return SizedBox(
      width: widget.compact ? 150 : 260,
      height: 40,
      child: TextField(
        controller: _controller,
        onChanged: context.read<GalleryState>().search,
        textInputAction: TextInputAction.search,
        style: context.text.bodyMedium?.copyWith(color: context.colors.onSurface),
        decoration: InputDecoration(
          isDense: true,
          hintText: widget.compact ? 'Поиск' : 'Поиск по коллекции',
          hintStyle: context.text.bodyMedium?.copyWith(color: context.tones.muted),
          filled: true,
          fillColor: context.tones.card,
          prefixIcon: Icon(Icons.search, size: 18, color: context.tones.muted),
          prefixIconConstraints: const BoxConstraints(minWidth: 38, minHeight: 38),
          suffixIcon: state.isSearching
              ? IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  splashRadius: 16,
                  tooltip: 'Очистить',
                  onPressed: () => context.read<GalleryState>().search(''),
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: _border(context, context.tones.hairline),
          enabledBorder: _border(context, context.tones.hairline),
          focusedBorder: _border(context, context.colors.primary.withValues(alpha: 0.7)),
        ),
      ),
    );
  }

  OutlineInputBorder _border(BuildContext context, Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(kRadiusSmall),
    borderSide: BorderSide(color: color),
  );
}

class _ThemeToggle extends StatelessWidget {
  const _ThemeToggle();

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeController>();
    return Tooltip(
      message: theme.isDark ? 'Светлая тема' : 'Тёмная тема',
      child: Material(
        color: context.tones.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kRadiusSmall),
          side: BorderSide(color: context.tones.hairline),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: context.read<ThemeController>().toggle,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(
              theme.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }
}
