import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../data/catalog.dart';
import '../../state/gallery_state.dart';
import '../widgets/common.dart';
import '../widgets/exhibit_card.dart';

/// Секция «Модели» — лента экспонатов текущего раздела.
///
/// Появляется только когда экспонат выбран: пока выбора нет, ту же роль
/// выполняет сетка в секции «Просмотр».
class ModelsSection extends StatefulWidget {
  const ModelsSection({super.key, required this.padding, required this.compact});

  final double padding;
  final bool compact;

  @override
  State<ModelsSection> createState() => _ModelsSectionState();
}

class _ModelsSectionState extends State<ModelsSection> {
  final _scroll = ScrollController();
  String? _lastId;

  static const _itemWidth = 210.0;
  static const _gap = 10.0;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Держит выбранную карточку в поле зрения при переключении стрелками.
  void _revealSelected(int index) {
    if (index < 0 || !_scroll.hasClients) return;
    final viewport = _scroll.position.viewportDimension;
    final start = index * (_itemWidth + _gap);
    final end = start + _itemWidth;
    final offset = _scroll.offset;
    double? target;
    if (start < offset) {
      target = start - _gap;
    } else if (end > offset + viewport) {
      target = end - viewport + _gap;
    }
    if (target == null) return;
    _scroll.animateTo(
      target.clamp(0, _scroll.position.maxScrollExtent),
      duration: kMedium,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GalleryState>();
    final selected = state.exhibit;
    final items = state.visibleExhibits;
    final index = state.selectedIndex;

    if (selected != null && selected.id != _lastId) {
      _lastId = selected.id;
      WidgetsBinding.instance.addPostFrameCallback((_) => _revealSelected(index));
    } else if (selected == null) {
      _lastId = null;
    }

    final height = widget.compact ? 104.0 : 118.0;

    return AnimatedSize(
      duration: kMedium,
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: selected == null
          ? const SizedBox(width: double.infinity, height: 0)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(widget.padding, 14, widget.padding, 9),
                  child: SectionLabel(
                    'Модели',
                    trailing: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${state.category?.title ?? ''} · ${plural(items.length, 'экспонат', 'экспоната', 'экспонатов')}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: context.text.labelSmall?.copyWith(
                          color: context.tones.muted,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: height,
                  child: ListView.separated(
                    controller: _scroll,
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.fromLTRB(
                      widget.padding,
                      0,
                      widget.padding,
                      widget.compact ? 12 : 16,
                    ),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(width: _gap),
                    itemBuilder: (context, i) => _ModelTile(
                      exhibit: items[i],
                      selected: items[i].id == selected.id,
                      width: _itemWidth,
                      onTap: () => context.read<GalleryState>().selectExhibit(items[i]),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _ModelTile extends StatelessWidget {
  const _ModelTile({
    required this.exhibit,
    required this.selected,
    required this.width,
    required this.onTap,
  });

  final Exhibit exhibit;
  final bool selected;
  final double width;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tones = context.tones;
    final primary = context.colors.primary;

    return Hoverable(
      onTap: onTap,
      builder: (context, hovered) => AnimatedContainer(
        duration: kFast,
        width: width,
        decoration: BoxDecoration(
          color: selected
              ? tones.accentSoft
              : hovered
              ? tones.cardHover
              : tones.card,
          borderRadius: BorderRadius.circular(kRadiusSmall + 2),
          border: Border.all(
            color: selected
                ? primary.withValues(alpha: 0.65)
                : hovered
                ? tones.muted.withValues(alpha: 0.45)
                : tones.hairline,
            width: selected ? 1.5 : 1,
          ),
        ),
        padding: const EdgeInsets.all(7),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 56,
                height: double.infinity,
                child: ExhibitThumb(exhibit: exhibit, zoom: hovered),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exhibit.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.labelMedium?.copyWith(
                      color: selected ? context.colors.onSurface : context.colors.onSurfaceVariant,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Text(
                        '№ ${exhibit.number}',
                        style: context.text.labelSmall?.copyWith(
                          color: tones.muted,
                          fontSize: 10,
                        ),
                      ),
                      if (exhibit.hasModel) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.view_in_ar_outlined, size: 11, color: primary),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}
