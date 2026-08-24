import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../data/catalog.dart';
import '../../state/gallery_state.dart';
import '../widgets/common.dart';

/// Секция «Категории» — верхняя плашка выбора раздела коллекции.
class CategoriesSection extends StatefulWidget {
  const CategoriesSection({super.key, required this.padding, required this.compact});

  final double padding;
  final bool compact;

  @override
  State<CategoriesSection> createState() => _CategoriesSectionState();
}

class _CategoriesSectionState extends State<CategoriesSection> {
  final _keys = <String, GlobalKey>{};
  String? _revealed;

  /// Раздел может смениться не только нажатием на плашку — например, при
  /// переходе к найденному экспонату. Тогда активную плашку нужно показать.
  void _reveal(String id) {
    if (_revealed == id) return;
    _revealed = id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _keys[id]?.currentContext;
      if (context == null || !context.mounted) return;
      Scrollable.ensureVisible(
        context,
        duration: kMedium,
        curve: Curves.easeOutCubic,
        alignment: 0.5,
        alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final padding = widget.padding;
    final compact = widget.compact;
    final state = context.watch<GalleryState>();
    final categories = state.categories;
    final activeId = state.isSearching ? null : state.category?.id;
    if (activeId != null) _reveal(activeId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(padding, 6, padding, 10),
          child: SectionLabel(
            'Категории',
            trailing: Align(
              alignment: Alignment.centerRight,
              child: Text(
                plural(categories.length, 'раздел', 'раздела', 'разделов'),
                style: context.text.labelSmall?.copyWith(
                  color: context.tones.muted,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ),
        SizedBox(
          height: compact ? 62 : 70,
          // Разделов немного, поэтому строим их сразу все: ленивый список не
          // создаёт элементы для плашек за краем экрана, и до них нельзя
          // доскроллить программно.
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: padding),
            child: Row(
              children: [
                for (final category in categories) ...[
                  _CategoryChip(
                    key: _keys.putIfAbsent(category.id, GlobalKey.new),
                    category: category,
                    selected: category.id == activeId,
                    compact: compact,
                    onTap: () =>
                        context.read<GalleryState>().selectCategory(category.id),
                  ),
                  if (category != categories.last) const SizedBox(width: 10),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    super.key,
    required this.category,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  final ExhibitCategory category;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tones = context.tones;
    final primary = context.colors.primary;

    return Hoverable(
      onTap: onTap,
      builder: (context, hovered) {
        final border = selected
            ? primary.withValues(alpha: 0.55)
            : hovered
            ? tones.muted.withValues(alpha: 0.45)
            : tones.hairline;
        return AnimatedContainer(
          duration: kFast,
          curve: Curves.easeOut,
          padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 15, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? tones.accentSoft
                : hovered
                ? tones.cardHover
                : tones.card,
            borderRadius: BorderRadius.circular(kRadius - 2),
            border: Border.all(color: border, width: selected ? 1.4 : 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: kFast,
                width: compact ? 30 : 34,
                height: compact ? 30 : 34,
                decoration: BoxDecoration(
                  color: selected
                      ? primary.withValues(alpha: 0.18)
                      : tones.hairline.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  iconFor(category.icon),
                  size: compact ? 16 : 18,
                  color: selected ? primary : tones.muted,
                ),
              ),
              const SizedBox(width: 11),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.title,
                    style: context.text.titleSmall?.copyWith(
                      color: selected ? context.colors.onSurface : context.colors.onSurfaceVariant,
                      fontSize: compact ? 12.5 : 13.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${category.exhibits.length} · ${category.modelCount} 3D',
                    style: context.text.labelSmall?.copyWith(
                      color: tones.muted,
                      fontSize: 10.5,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
            ],
          ),
        );
      },
    );
  }
}
