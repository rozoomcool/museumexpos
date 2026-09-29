import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../../data/catalog.dart';
import 'common.dart';

/// Полноэкранный просмотр фотографий с масштабированием.
class PhotoLightbox extends StatefulWidget {
  const PhotoLightbox({super.key, required this.exhibit, required this.index});

  final Exhibit exhibit;
  final int index;

  static Future<void> open(
    BuildContext context, {
    required Exhibit exhibit,
    required int index,
  }) {
    if (exhibit.photos.isEmpty) return Future.value();
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        // Непрозрачный основной фон: без размытия и «стекла».
        barrierColor: AppColors.background,
        transitionDuration: kMedium,
        pageBuilder: (_, _, _) => PhotoLightbox(exhibit: exhibit, index: index),
        transitionsBuilder: (_, animation, _, child) => FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween(begin: 0.97, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  @override
  State<PhotoLightbox> createState() => _PhotoLightboxState();
}

class _PhotoLightboxState extends State<PhotoLightbox> {
  late final PageController _pages = PageController(initialPage: widget.index);
  late int _current = widget.index;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _step(int delta) {
    final next = _current + delta;
    if (next < 0 || next >= widget.exhibit.photos.length) return;
    _pages.animateToPage(next, duration: kMedium, curve: Curves.easeOutCubic);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.escape:
        Navigator.of(context).maybePop();
      case LogicalKeyboardKey.arrowRight:
        _step(1);
      case LogicalKeyboardKey.arrowLeft:
        _step(-1);
      default:
        return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final photos = widget.exhibit.photos;
    return Focus(
      autofocus: true,
      onKeyEvent: _onKey,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                behavior: HitTestBehavior.opaque,
              ),
            ),
            Positioned.fill(
              child: PageView.builder(
                controller: _pages,
                itemCount: photos.length,
                onPageChanged: (i) => setState(() => _current = i),
                itemBuilder: (context, i) => InteractiveViewer(
                  maxScale: 5,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xxxl + AppSpacing.md,
                      AppSpacing.xxl + AppSpacing.xl,
                      AppSpacing.xxxl + AppSpacing.md,
                      AppSpacing.xxl + AppSpacing.xl,
                    ),
                    child: Image.asset(
                      photos[i],
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.medium,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: AppSpacing.lg,
              right: AppSpacing.lg,
              child: PanelIconButton(
                icon: Icons.close_rounded,
                tooltip: 'Закрыть (Esc)',
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
            Positioned(
              top: AppSpacing.lg,
              left: AppSpacing.lg,
              right: AppSpacing.lg + kTouchTarget + AppSpacing.md,
              child: Text(
                widget.exhibit.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.headlineSmall,
              ),
            ),
            if (photos.length > 1) ...[
              Positioned(
                left: AppSpacing.lg,
                top: 0,
                bottom: 0,
                child: Center(
                  child: PanelIconButton(
                    icon: Icons.chevron_left_rounded,
                    tooltip: 'Предыдущее фото',
                    onPressed: _current > 0 ? () => _step(-1) : null,
                  ),
                ),
              ),
              Positioned(
                right: AppSpacing.lg,
                top: 0,
                bottom: 0,
                child: Center(
                  child: PanelIconButton(
                    icon: Icons.chevron_right_rounded,
                    tooltip: 'Следующее фото',
                    onPressed: _current < photos.length - 1 ? () => _step(1) : null,
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: AppSpacing.lg,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.panel,
                      borderRadius: BorderRadius.circular(AppRadii.button),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Text(
                      '${_current + 1} / ${photos.length}',
                      style: context.text.labelMedium?.copyWith(color: AppColors.textPrimary),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
