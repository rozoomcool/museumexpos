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

  @override
  void didUpdateWidget(covariant ExhibitDetails oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.exhibit.id != widget.exhibit.id) _photo = 0;
  }

  @override
  Widget build(BuildContext context) {
    final exhibit = widget.exhibit;
    final state = context.watch<GalleryState>();
    final pad = widget.compact ? 18.0 : 26.0;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(pad, pad - 4, pad, pad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Tag(label: widget.category.title, icon: iconFor(widget.category.icon)),
                    Tag(label: '№ ${exhibit.number} из 60'),
                    if (exhibit.hasModel)
                      Tag(label: '3D', icon: Icons.view_in_ar_outlined, accent: true),
                    if (exhibit.photos.length > 1)
                      Tag(
                        label: plural(exhibit.photos.length, 'фото', 'фото', 'фото'),
                        icon: Icons.photo_library_outlined,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: context.read<GalleryState>().clearSelection,
                icon: const Icon(Icons.close_rounded, size: 18),
                tooltip: 'Ко всем экспонатам (Esc)',
                style: IconButton.styleFrom(
                  backgroundColor: context.tones.hairline.withValues(alpha: 0.6),
                  minimumSize: const Size(34, 34),
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            exhibit.title,
            style: (widget.compact
                    ? context.text.headlineMedium
                    : context.text.displaySmall)
                ?.copyWith(height: 1.16),
          ),
          if (exhibit.reason.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(exhibit.reason, style: context.text.bodyLarge),
          ],
          if (exhibit.hasPhotos) ...[
            const SizedBox(height: 22),
            _Gallery(
              exhibit: exhibit,
              index: _photo,
              onSelect: (i) => setState(() => _photo = i),
            ),
          ],
          const SizedBox(height: 22),
          _Navigation(state: state),
        ],
      ),
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
    final tones = context.tones;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel('Фотографии'),
        const SizedBox(height: 10),
        Hoverable(
          onTap: () => PhotoLightbox.open(context, exhibit: exhibit, index: index),
          builder: (context, hovered) => AnimatedContainer(
            duration: kFast,
            decoration: BoxDecoration(
              color: tones.stageBottom,
              borderRadius: BorderRadius.circular(kRadius),
              border: Border.all(
                color: hovered ? tones.muted.withValues(alpha: 0.5) : tones.hairline,
              ),
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
                    right: 12,
                    bottom: 12,
                    child: AnimatedOpacity(
                      duration: kFast,
                      opacity: hovered ? 1 : 0.55,
                      child: GlassButton(
                        icon: Icons.zoom_out_map_rounded,
                        tooltip: 'Открыть во весь экран',
                        onPressed: () => PhotoLightbox.open(
                          context,
                          exhibit: exhibit,
                          index: index,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (exhibit.photos.length > 1) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 62,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: exhibit.thumbs.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final selected = i == index;
                return Hoverable(
                  onTap: () => onSelect(i),
                  builder: (context, hovered) => AnimatedContainer(
                    duration: kFast,
                    width: 82,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(kRadiusSmall),
                      border: Border.all(
                        color: selected
                            ? context.colors.primary
                            : hovered
                            ? tones.muted.withValues(alpha: 0.6)
                            : tones.hairline,
                        width: selected ? 1.8 : 1,
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
    return Row(
      children: [
        _NavButton(
          icon: Icons.arrow_back_rounded,
          label: 'Предыдущий',
          onPressed: state.hasPrevious ? () => state.step(-1) : null,
        ),
        const SizedBox(width: 10),
        _NavButton(
          icon: Icons.arrow_forward_rounded,
          label: 'Следующий',
          trailingIcon: true,
          onPressed: state.hasNext ? () => state.step(1) : null,
        ),
        const Spacer(),
        if (index >= 0)
          Text(
            '${index + 1} / ${items.length}',
            style: context.text.labelMedium?.copyWith(color: context.tones.muted),
          ),
      ],
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.trailingIcon = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool trailingIcon;

  @override
  Widget build(BuildContext context) {
    final children = [
      Icon(icon, size: 16),
      const SizedBox(width: 8),
      Text(label),
    ];
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: context.colors.onSurface,
        disabledForegroundColor: context.tones.muted.withValues(alpha: 0.5),
        side: BorderSide(color: context.tones.hairline),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusSmall)),
        textStyle: context.text.labelLarge,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: trailingIcon ? children.reversed.toList() : children,
      ),
    );
  }
}
