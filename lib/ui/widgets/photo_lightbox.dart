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
        barrierColor: Colors.black.withValues(alpha: 0.86),
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
                    padding: const EdgeInsets.fromLTRB(56, 56, 56, 92),
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
              top: 20,
              right: 20,
              child: GlassButton(
                icon: Icons.close_rounded,
                tooltip: 'Закрыть',
                size: 42,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
            Positioned(
              top: 24,
              left: 24,
              right: 80,
              child: Text(
                widget.exhibit.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.titleMedium?.copyWith(color: Colors.white),
              ),
            ),
            if (photos.length > 1) ...[
              Positioned(
                left: 16,
                top: 0,
                bottom: 0,
                child: Center(
                  child: GlassButton(
                    icon: Icons.chevron_left_rounded,
                    tooltip: 'Предыдущее фото',
                    size: 44,
                    onPressed: _current > 0 ? () => _step(-1) : null,
                  ),
                ),
              ),
              Positioned(
                right: 16,
                top: 0,
                bottom: 0,
                child: Center(
                  child: GlassButton(
                    icon: Icons.chevron_right_rounded,
                    tooltip: 'Следующее фото',
                    size: 44,
                    onPressed: _current < photos.length - 1 ? () => _step(1) : null,
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 28,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${_current + 1} / ${photos.length}',
                      style: context.text.labelMedium?.copyWith(color: Colors.white),
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
