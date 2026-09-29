import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../data/catalog.dart';
import '../../state/gallery_state.dart';
import 'common.dart';
import 'photo_lightbox.dart';

/// Правая часть просмотра: описание экспоната и его фотографии.
class ExhibitDetails extends StatefulWidget {
  const ExhibitDetails({
    super.key,
    required this.exhibit,
    required this.category,
    required this.compact,
  });

  final Exhibit exhibit;
  final ExhibitCategory category;
  final bool compact;

  @override
  State<ExhibitDetails> createState() => _ExhibitDetailsState();
}

class _ExhibitDetailsState extends State<ExhibitDetails> {
  int _photo = 0;

  /// Удобная для чтения длина строки описания.
  static const _readingWidth = 720.0;

  @override
  void didUpdateWidget(covariant ExhibitDetails oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.exhibit.id != widget.exhibit.id) _photo = 0;
  }

  @override
  Widget build(BuildContext context) {
    final exhibit = widget.exhibit;
    final state = context.watch<GalleryState>();
    final pad = widget.compact ? AppSpacing.md : AppSpacing.lg;

    return SingleChildScrollView(
      padding: EdgeInsets.all(pad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  // Выравнивает строку метаданных по центру кнопки закрытия.
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.xs,
                    children: [
                      _Meta(icon: iconFor(widget.category.icon), label: widget.category.title),
                      _Meta(label: '№ ${exhibit.number} из 60'),
                      if (exhibit.hasModel)
                        const _Meta(icon: Icons.view_in_ar_outlined, label: '3D-модель'),
                      if (exhibit.photos.length > 1)
                        _Meta(
                          icon: Icons.photo_library_outlined,
                          label: plural(exhibit.photos.length, 'фото', 'фото', 'фото'),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              PanelIconButton(
                icon: Icons.close_rounded,
                tooltip: 'Ко всем экспонатам (Esc)',
                onPressed: context.read<GalleryState>().clearSelection,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _readingWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exhibit.title,
                  style: widget.compact
                      ? context.text.headlineSmall
                      : context.text.headlineLarge,
                ),
                if (exhibit.reason.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(exhibit.reason, style: context.text.bodyLarge),
                ],
              ],
            ),
          ),
          if (exhibit.hasPhotos) ...[
            const SizedBox(height: AppSpacing.lg),
            _Gallery(
              exhibit: exhibit,
              index: _photo,
              onSelect: (i) => setState(() => _photo = i),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          const Divider(),
          const SizedBox(height: AppSpacing.md),
          _Navigation(state: state),
        ],
      ),
    );
  }
}

/// Элемент строки метаданных: раздел, номер, наличие 3D, число фото.
class _Meta extends StatelessWidget {
  const _Meta({required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.xs),
        ],
        Text(label, style: context.text.labelMedium),
      ],
    );
  }
}

class _Gallery extends StatelessWidget {
  const _Gallery({
    required this.exhibit,
    required this.index,
    required this.onSelect,
  });

  final Exhibit exhibit;
  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final count = exhibit.photos.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel('Фотографии', detail: count > 1 ? '${index + 1} из $count' : null),
        const SizedBox(height: AppSpacing.xs),
        Hoverable(
          onTap: () => PhotoLightbox.open(context, exhibit: exhibit, index: index),
          builder: (context, hovered) => AnimatedContainer(
            duration: kFast,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppRadii.card),
              border: Border.all(color: hovered ? AppColors.outline : AppColors.divider),
            ),
            clipBehavior: Clip.antiAlias,
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // BoxFit.contain: кадрировать музейную фотографию нельзя —
                  // предмет может уйти за край.
                  AnimatedSwitcher(
                    duration: kMedium,
                    child: SizedBox.expand(
                      key: ValueKey(exhibit.photos[index]),
                      child: Image.asset(
                        exhibit.photos[index],
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.medium,
                      ),
                    ),
                  ),
                  Positioned(
                    right: AppSpacing.sm,
                    bottom: AppSpacing.sm,
                    child: PanelIconButton(
                      icon: Icons.zoom_out_map_rounded,
                      tooltip: 'Открыть во весь экран',
                      onPressed: () => PhotoLightbox.open(
                        context,
                        exhibit: exhibit,
                        index: index,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (count > 1) ...[
          const SizedBox(height: AppSpacing.xs),
          SizedBox(
            height: 64,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: exhibit.thumbs.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
              itemBuilder: (context, i) {
                final selected = i == index;
                return Hoverable(
                  onTap: () => onSelect(i),
                  builder: (context, hovered) => AnimatedContainer(
                    duration: kFast,
                    width: 88,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadii.button),
                      border: Border.all(
                        color: selected
                            ? AppColors.brass
                            : hovered
                            ? AppColors.outline
                            : AppColors.divider,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      exhibit.thumbs[i],
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.low,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _Navigation extends StatelessWidget {
  const _Navigation({required this.state});

  final GalleryState state;

  @override
  Widget build(BuildContext context) {
    final items = state.visibleExhibits;
    final index = state.selectedIndex;
    final previous = state.hasPrevious ? () => state.step(-1) : null;
    final next = state.hasNext ? () => state.step(1) : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        // На узком экране подписи кнопок не помещаются — остаются иконки.
        final iconsOnly = constraints.maxWidth < 440;
        return Row(
          children: [
            if (iconsOnly) ...[
              PanelIconButton(
                icon: Icons.arrow_back_rounded,
                tooltip: 'Предыдущий',
                onPressed: previous,
              ),
              const SizedBox(width: AppSpacing.xs),
              PanelIconButton(
                icon: Icons.arrow_forward_rounded,
                tooltip: 'Следующий',
                onPressed: next,
              ),
            ] else ...[
              OutlinedButton.icon(
                onPressed: previous,
                icon: const Icon(Icons.arrow_back_rounded, size: 20),
                label: const Text('Предыдущий'),
              ),
              const SizedBox(width: AppSpacing.xs),
              OutlinedButton.icon(
                onPressed: next,
                icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                iconAlignment: IconAlignment.end,
                label: const Text('Следующий'),
              ),
            ],
            const Spacer(),
            if (index >= 0)
              Text('${index + 1} / ${items.length}', style: context.text.labelMedium),
          ],
        );
      },
    );
  }
}
