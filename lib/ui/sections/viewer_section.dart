import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../data/catalog.dart';
import '../../state/gallery_state.dart';
import '../home_screen.dart';
import '../widgets/common.dart';
import '../widgets/exhibit_card.dart';
import '../widgets/exhibit_details.dart';
import '../widgets/model_stage.dart';

/// Секция «Просмотр».
///
/// Пока экспонат не выбран, показывает сетку предметов раздела — она же играет
/// роль секции «Модели». Как только предмет выбран, превращается в раскладку
/// «3D-модель слева (40 %) — описание и фотографии справа (60 %)».
class ViewerSection extends StatelessWidget {
  const ViewerSection({super.key, required this.padding, required this.compact});

  final double padding;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GalleryState>();
    final exhibit = state.exhibit;
    final items = state.visibleExhibits;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(padding, 16, padding, 10),
          child: SectionLabel(
            'Просмотр',
            trailing: Align(
              alignment: Alignment.centerRight,
              child: Text(
                state.isSearching
                    ? 'Найдено: ${plural(items.length, 'экспонат', 'экспоната', 'экспонатов')}'
                    : exhibit != null
                    ? 'Экспонат № ${exhibit.number}'
                    : '${state.category?.title ?? ''} · ${plural(items.length, 'экспонат', 'экспоната', 'экспонатов')}',
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
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: padding),
            child: FadeSwitch(
              child: exhibit == null
                  ? _CatalogGrid(
                      key: ValueKey('grid-${state.category?.id}-${state.query}'),
                      items: items,
                      compact: compact,
                      emptyQuery: state.isSearching ? state.query : null,
                    )
                  : _ExhibitLayout(
                      key: ValueKey('exhibit-${exhibit.id}'),
                      exhibit: exhibit,
                      compact: compact,
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ExhibitLayout extends StatelessWidget {
  const _ExhibitLayout({super.key, required this.exhibit, required this.compact});

  final Exhibit exhibit;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<GalleryState>();
    final category = state.catalog!.categoryOf(exhibit);

    return LayoutBuilder(
      builder: (context, constraints) {
        final details = ExhibitDetails(
          exhibit: exhibit,
          category: category,
          compact: compact,
        );

        // Узкий экран: сцена сверху, описание под ней — единым скроллом.
        if (constraints.maxWidth < kSplitBreakpoint) {
          return SectionSurface(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(kRadius),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: 280, child: ModelStage(exhibit: exhibit)),
                    details,
                  ],
                ),
              ),
            ),
          );
        }

        final available = constraints.maxWidth - _Divider.width;
        final stageWidth = available * state.splitRatio;

        return Row(
          children: [
            SizedBox(width: stageWidth, child: ModelStage(exhibit: exhibit)),
            _Divider(
              onDrag: (dx) => context.read<GalleryState>().setSplitRatio(
                (stageWidth + dx) / available,
              ),
              onReset: context.read<GalleryState>().resetSplitRatio,
            ),
            Expanded(child: SectionSurface(child: details)),
          ],
        );
      },
    );
  }
}

/// Перетаскиваемая граница между сценой и описанием.
class _Divider extends StatefulWidget {
  const _Divider({required this.onDrag, required this.onReset});

  static const width = 18.0;

  final ValueChanged<double> onDrag;
  final VoidCallback onReset;

  @override
  State<_Divider> createState() => _DividerState();
}

class _DividerState extends State<_Divider> {
  bool _active = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeLeftRight,
      onEnter: (_) => setState(() => _active = true),
      onExit: (_) => setState(() => _active = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragUpdate: (d) => widget.onDrag(d.delta.dx),
        onDoubleTap: widget.onReset,
        child: Tooltip(
          message: 'Потяните, чтобы изменить пропорции · двойной клик — сброс',
          child: SizedBox(
            width: _Divider.width,
            child: Center(
              child: AnimatedContainer(
                duration: kFast,
                width: _active ? 4 : 2,
                height: _active ? 64 : 36,
                decoration: BoxDecoration(
                  color: _active
                      ? context.colors.primary.withValues(alpha: 0.8)
                      : context.tones.hairline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CatalogGrid extends StatelessWidget {
  const _CatalogGrid({
    super.key,
    required this.items,
    required this.compact,
    required this.emptyQuery,
  });

  final List<Exhibit> items;
  final bool compact;
  final String? emptyQuery;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return _EmptyState(query: emptyQuery);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Целевая ширина карточки ~270 px: на планшете три колонки,
        // на большом мониторе — пять.
        final columns = (constraints.maxWidth / (compact ? 210 : 272))
            .floor()
            .clamp(1, 6);
        return GridView.builder(
          padding: const EdgeInsets.only(bottom: 6),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: compact ? 0.78 : 0.84,
          ),
          itemCount: items.length,
          itemBuilder: (context, i) => ExhibitCard(
            exhibit: items[i],
            onTap: () => context.read<GalleryState>().selectExhibit(items[i]),
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.query});

  final String? query;

  @override
  Widget build(BuildContext context) {
    return SectionSurface(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 30, color: context.tones.muted),
            const SizedBox(height: 14),
            Text(
              query == null ? 'В разделе пока пусто' : 'Ничего не найдено',
              style: context.text.titleMedium,
            ),
            if (query != null) ...[
              const SizedBox(height: 6),
              Text('По запросу «$query» совпадений нет', style: context.text.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}
