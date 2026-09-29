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
    this.framed = true,
  });

  final Exhibit exhibit;
  final bool fullscreen;

  /// Рисовать ли собственную панель вокруг сцены. В вертикальной раскладке
  /// сцена уже лежит внутри общей панели с описанием.
  final bool framed;

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
    final model = widget.exhibit.model;
    // Плоский фон: просмотрщик прозрачный, модель лежит прямо на панели.
    final background = widget.fullscreen ? AppColors.background : AppColors.panel;

    final stage = ColoredBox(
      color: background,
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
                      child: _LoadingVeil(progress: _progress, color: background),
                    ),
                  ),
                const Positioned(
                  left: AppSpacing.sm,
                  top: AppSpacing.sm,
                  child: IgnorePointer(
                    child: Tag(label: '3D-модель', icon: Icons.view_in_ar_outlined),
                  ),
                ),
                Positioned(
                  right: AppSpacing.sm,
                  top: AppSpacing.sm,
                  child: Row(
                    children: [
                      PanelIconButton(
                        icon: _spinning
                            ? Icons.pause_rounded
                            : Icons.threesixty_rounded,
                        tooltip: _spinning ? 'Остановить вращение' : 'Вращать',
                        onPressed: _loaded ? _toggleSpin : null,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      PanelIconButton(
                        icon: Icons.center_focus_strong_outlined,
                        tooltip: 'Исходный ракурс',
                        onPressed: _loaded ? _resetView : null,
                      ),
                      if (!widget.fullscreen) ...[
                        const SizedBox(width: AppSpacing.xs),
                        PanelIconButton(
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
                    bottom: AppSpacing.sm,
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

    if (widget.fullscreen || !widget.framed) return stage;
    return SectionSurface(child: stage);
  }
}

class _FullscreenStage extends StatelessWidget {
  const _FullscreenStage({required this.exhibit});

  final Exhibit exhibit;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          ModelStage(exhibit: exhibit, fullscreen: true),
          Positioned(
            left: AppSpacing.lg,
            right: AppSpacing.lg + kTouchTarget + AppSpacing.md,
            bottom: AppSpacing.lg,
            child: IgnorePointer(
              child: Text(
                exhibit.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.text.headlineSmall,
              ),
            ),
          ),
          Positioned(
            right: AppSpacing.lg,
            bottom: AppSpacing.lg,
            child: PanelIconButton(
              icon: Icons.close_fullscreen_rounded,
              tooltip: 'Свернуть',
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
          builder: (context, _) => ExhibitThumb(exhibit: exhibit, fit: BoxFit.contain),
        ),
        const Positioned(
          left: AppSpacing.sm,
          top: AppSpacing.sm,
          child: IgnorePointer(
            child: Tag(label: 'Только фотографии', icon: Icons.photo_outlined),
          ),
        ),
        const Positioned(
          left: 0,
          right: 0,
          bottom: AppSpacing.sm,
          child: IgnorePointer(
            child: Center(child: _Hint(text: '3D-модель для этого предмета не снята')),
          ),
        ),
      ],
    );
  }
}

class _LoadingVeil extends StatelessWidget {
  const _LoadingVeil({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: color,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: progress > 0 && progress < 1 ? progress : null,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
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
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: AppColors.textSecondary),
            const SizedBox(height: AppSpacing.md),
            Text(title, style: context.text.titleMedium),
            const SizedBox(height: AppSpacing.xs),
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(AppRadii.button),
        border: Border.all(color: AppColors.divider),
      ),
      child: Text(text, style: context.text.labelSmall),
    );
  }
}
