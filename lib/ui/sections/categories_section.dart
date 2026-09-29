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
          padding: EdgeInsets.fromLTRB(padding, AppSpacing.md, padding, AppSpacing.xs),
          child: SectionLabel(
            'Категории',
            detail: plural(categories.length, 'раздел', 'раздела', 'разделов'),
          ),
        ),
        SizedBox(
          height: 64,
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
                  if (category != categories.last) const SizedBox(width: AppSpacing.xs),
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
    return Hoverable(
      onTap: onTap,
      builder: (context, hovered) {
        // Латунь — только у активного раздела.
        final border = selected
            ? AppColors.brass
            : hovered
            ? AppColors.outline
            : AppColors.divider;
        return AnimatedContainer(
          duration: kFast,
          curve: Curves.easeOut,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? AppSpacing.sm : AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: selected || hovered ? AppColors.raised : AppColors.panel,
            borderRadius: BorderRadius.circular(AppRadii.card),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                iconFor(category.icon),
                size: 20,
                color: selected ? AppColors.brass : AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.title,
                    style: (compact ? context.text.labelMedium : context.text.titleSmall)
                        ?.copyWith(
                          color: selected
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                          height: 1.3,
                        ),
                  ),
                  Text(
                    '${plural(category.exhibits.length, 'экспонат', 'экспоната', 'экспонатов')} · ${category.modelCount} в 3D',
                    style: context.text.labelSmall?.copyWith(
                      fontWeight: FontWeight.w400,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
