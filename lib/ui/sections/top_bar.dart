import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../state/gallery_state.dart';
import '../widgets/common.dart';

/// Шапка: логотип музея, название экспозиции и поиск по коллекции.
class TopBar extends StatelessWidget {
  const TopBar({super.key, required this.padding, required this.compact});

  final double padding;
  final bool compact;

  /// Ниже этой ширины название не помещается рядом с логотипом и поиском.
  static const _titleBreakpoint = 560.0;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GalleryState>();
    final catalog = state.catalog;
    final total = catalog?.allExhibits.length ?? 0;
    final logoHeight = compact ? 48.0 : 56.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: padding, vertical: AppSpacing.md),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final showTitle = constraints.maxWidth >= _titleBreakpoint;
              return Row(
                children: [
                  _BrandLogo(height: logoHeight),
                  if (showTitle) ...[
                    // Охранное поле логотипа — не меньше четверти его высоты.
                    const SizedBox(width: AppSpacing.md),
                    Container(width: 1, height: logoHeight, color: AppColors.divider),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            catalog?.title ?? 'Экспонаты ЧР',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.text.headlineSmall?.copyWith(height: 1.15),
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
                  ] else
                    const Spacer(),
                  const SizedBox(width: AppSpacing.md),
                  _SearchField(compact: compact),
                ],
              );
            },
          ),
        ),
        const Divider(),
      ],
    );
  }
}

/// Белая версия прозрачного логотипа — без перерисовки и искажения.
class _BrandLogo extends StatelessWidget {
  const _BrandLogo({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Музей ЧГУ имени А. А. Кадырова',
      image: true,
      child: Image.asset(
        AppAssets.logoWhite,
        height: height,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        excludeFromSemantics: true,
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
      width: widget.compact ? 200 : 320,
      height: kTouchTarget,
      child: TextField(
        controller: _controller,
        onChanged: context.read<GalleryState>().search,
        textInputAction: TextInputAction.search,
        style: context.text.bodyMedium,
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          isDense: true,
          hintText: widget.compact ? 'Поиск' : 'Поиск по коллекции',
          prefixIcon: const Icon(Icons.search, size: 20),
          prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          suffixIcon: state.isSearching
              ? IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  tooltip: 'Очистить',
                  onPressed: () => context.read<GalleryState>().search(''),
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        ),
      ),
    );
  }
}
