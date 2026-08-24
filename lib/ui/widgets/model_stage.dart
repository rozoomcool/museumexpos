import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';

import '../../core/theme/app_theme.dart';
import '../../data/catalog.dart';
import 'common.dart';
import 'exhibit_card.dart';
import 'photo_lightbox.dart';

/// «Сцена» — левая часть просмотра: интерактивная 3D-модель экспоната.
///
/// Модели собраны с квантованием и WebP-текстурами, поэтому model-viewer
/// открывает их без обращения к сети — приложение работает офлайн.
class ModelStage extends StatefulWidget {
  const ModelStage({
    super.key,
    required this.exhibit,
    this.fullscreen = false,
  });

  final Exhibit exhibit;
  final bool fullscreen;

  /// Подмена самого просмотрщика. Нужна снимкам раскладки: плагин вебвью в
  /// тестовой среде не регистрируется и падает на assert при построении.
  @visibleForTesting
  static Widget Function(String src)? viewerOverride;

  @override
  State<ModelStage> createState() => _ModelStageState();
}

/// Адрес модели для просмотрщика.
///
/// В вебе `<model-viewer>` живёт в обычном DOM и разрешает относительный путь
/// от адреса страницы, а Flutter отдаёт ассеты с приставкой `assets/`:
/// ключ `assets/models/x.glb` доступен по `assets/assets/models/x.glb`.
/// На остальных платформах модель читается из пакета ассетов как есть.
String modelSrc(String assetKey) => kIsWeb ? 'assets/$assetKey' : assetKey;

class _ModelStageState extends State<ModelStage> {
  final _controller = Flutter3DController();
  double _progress = 0;
  bool _loaded = false;
  bool _spinning = false;
  String? _error;

  @override
  void didUpdateWidget(covariant ModelStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.exhibit.id != widget.exhibit.id) {
      setState(() {
        _progress = 0;
        _loaded = false;
        _spinning = false;
        _error = null;
      });
    }
  }

  void _toggleSpin() {
    setState(() => _spinning = !_spinning);
    if (_spinning) {
      _controller.startRotation(rotationSpeed: 14);
    } else {
      _controller.pauseRotation();
    }
  }

  void _resetView() {
    _controller.resetCameraOrbit();
    _controller.resetCameraTarget();
  }

  void _openFullscreen() {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: true,
        transitionDuration: kMedium,
        pageBuilder: (_, _, _) => _FullscreenStage(exhibit: widget.exhibit),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tones = context.tones;
    final model = widget.exhibit.model;

    final stage = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [tones.stageTop, tones.stageBottom],
        ),
      ),
      child: model == null
          ? _NoModel(exhibit: widget.exhibit)
          : Stack(
              fit: StackFit.expand,
              children: [
                if (ModelStage.viewerOverride case final override?)
                  override(model)
                else
                  Flutter3DViewer(
                    key: ValueKey(model),
                    src: modelSrc(model),
                  controller: _controller,
                  progressBarColor: Colors.transparent,
                  onProgress: (value) {
                    if (!mounted) return;
                    setState(() => _progress = value);
                  },
                  onLoad: (_) {
                    if (!mounted) return;
                    setState(() {
                      _loaded = true;
                      _progress = 1;
                    });
                  },
                  onError: (error) {
                    if (!mounted) return;
                    setState(() => _error = error);
                  },
                ),
                if (_error != null)
                  _StageMessage(
                    icon: Icons.error_outline,
                    title: 'Модель не открылась',
                    subtitle: _error!,
                  )
                else
                  IgnorePointer(
                    child: AnimatedOpacity(
                      duration: kMedium,
                      opacity: _loaded ? 0 : 1,
                      child: _LoadingVeil(progress: _progress),
                    ),
                  ),
                Positioned(
                  left: 14,
                  top: 14,
                  child: IgnorePointer(
                    child: Tag(
                      label: '3D-модель',
                      icon: Icons.view_in_ar_outlined,
                      accent: true,
                    ),
                  ),
                ),
                Positioned(
                  right: 14,
                  top: 14,
                  child: Row(
                    children: [
                      GlassButton(
                        icon: _spinning
                            ? Icons.pause_rounded
                            : Icons.threesixty_rounded,
                        tooltip: _spinning ? 'Остановить вращение' : 'Вращать',
                        onPressed: _loaded ? _toggleSpin : null,
                      ),
                      const SizedBox(width: 8),
                      GlassButton(
                        icon: Icons.center_focus_strong_outlined,
                        tooltip: 'Исходный ракурс',
                        onPressed: _loaded ? _resetView : null,
                      ),
                      if (!widget.fullscreen) ...[
                        const SizedBox(width: 8),
                        GlassButton(
                          icon: Icons.open_in_full_rounded,
                          tooltip: 'Во весь экран',
                          onPressed: _loaded ? _openFullscreen : null,
                        ),
                      ],
                    ],
                  ),
                ),
                if (_loaded && !widget.fullscreen)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 12,
                    child: IgnorePointer(
                      child: Center(
                        child: _Hint(
                          text: 'Перетаскивайте — поворот · колесо или щипок — масштаб',
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );

    if (widget.fullscreen) return stage;

    return ClipRRect(
      borderRadius: BorderRadius.circular(kRadius),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kRadius),
          border: Border.all(color: tones.hairline),
        ),
        child: stage,
      ),
    );
  }
}

class _FullscreenStage extends StatelessWidget {
  const _FullscreenStage({required this.exhibit});

  final Exhibit exhibit;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.tones.stageBottom,
      body: Stack(
        fit: StackFit.expand,
        children: [
          ModelStage(exhibit: exhibit, fullscreen: true),
          Positioned(
            left: 0,
            right: 0,
            bottom: 26,
            child: Center(
              child: _Hint(text: exhibit.title),
            ),
          ),
          Positioned(
            right: 18,
            bottom: 22,
            child: GlassButton(
              icon: Icons.close_fullscreen_rounded,
              tooltip: 'Свернуть',
              size: 44,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Экспонат без 3D-модели: показываем крупное фото, а не пустоту.
class _NoModel extends StatelessWidget {
  const _NoModel({required this.exhibit});

  final Exhibit exhibit;

  @override
  Widget build(BuildContext context) {
    if (!exhibit.hasPhotos) {
      return const _StageMessage(
        icon: Icons.view_in_ar_outlined,
        title: '3D-модель недоступна',
        subtitle: 'Для этого экспоната есть только описание.',
      );
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        Hoverable(
          onTap: () => PhotoLightbox.open(context, exhibit: exhibit, index: 0),
          builder: (context, hovered) => ExhibitThumb(
            exhibit: exhibit,
            zoom: hovered,
            fit: BoxFit.contain,
          ),
        ),
        Positioned(
          left: 14,
          top: 14,
          child: IgnorePointer(
            child: Tag(label: 'Только фотографии', icon: Icons.photo_outlined),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 12,
          child: IgnorePointer(
            child: Center(child: _Hint(text: '3D-модель для этого предмета не снята')),
          ),
        ),
      ],
    );
  }
}

class _LoadingVeil extends StatelessWidget {
  const _LoadingVeil({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final tones = context.tones;
    return ColoredBox(
      color: tones.stageBottom,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 34,
              height: 34,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: progress > 0 && progress < 1 ? progress : null,
                color: context.colors.primary,
                backgroundColor: tones.hairline,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              progress > 0 ? 'Загрузка модели · ${(progress * 100).round()}%' : 'Подготовка сцены',
              style: context.text.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _StageMessage extends StatelessWidget {
  const _StageMessage({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: context.tones.muted),
            const SizedBox(height: 14),
            Text(title, style: context.text.titleMedium),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: context.text.bodySmall,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: context.text.labelSmall?.copyWith(
          color: Colors.white.withValues(alpha: 0.75),
          letterSpacing: 0.2,
          fontSize: 10.5,
        ),
      ),
    );
  }
}
