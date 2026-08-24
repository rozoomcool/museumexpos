import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/catalog.dart';
import 'common.dart';

/// Карточка экспоната в сетке секции «Просмотр».
class ExhibitCard extends StatelessWidget {
  const ExhibitCard({super.key, required this.exhibit, required this.onTap});

  final Exhibit exhibit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tones = context.tones;

    return Hoverable(
      onTap: onTap,
      builder: (context, hovered) => AnimatedContainer(
        duration: kFast,
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, hovered ? -3 : 0, 0),
        decoration: BoxDecoration(
          color: hovered ? tones.cardHover : tones.card,
          borderRadius: BorderRadius.circular(kRadius),
          border: Border.all(
            color: hovered ? tones.muted.withValues(alpha: 0.45) : tones.hairline,
          ),
          boxShadow: hovered
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.22),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ]
              : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ExhibitThumb(exhibit: exhibit, zoom: hovered),
                  Positioned(
                    left: 10,
                    top: 10,
                    child: Tag(label: '№ ${exhibit.number}', compact: true),
                  ),
                  if (exhibit.hasModel)
                    Positioned(
                      right: 10,
                      top: 10,
                      child: Tag(
                        label: '3D',
                        icon: Icons.view_in_ar_outlined,
                        accent: true,
                        compact: true,
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    exhibit.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.titleMedium?.copyWith(height: 1.3),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    exhibit.reason,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodySmall?.copyWith(fontSize: 12.2, height: 1.45),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Превью экспоната с мягким зумом при наведении.
class ExhibitThumb extends StatelessWidget {
  const ExhibitThumb({
    super.key,
    required this.exhibit,
    this.zoom = false,
    this.fit = BoxFit.cover,
  });

  final Exhibit exhibit;
  final bool zoom;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final cover = exhibit.cover;
    if (cover == null) {
      return ColoredBox(
        color: context.tones.stageTop,
        child: Icon(Icons.image_not_supported_outlined, color: context.tones.muted),
      );
    }
    return AnimatedScale(
      duration: kSlow,
      curve: Curves.easeOutCubic,
      scale: zoom ? 1.045 : 1,
      child: Image.asset(
        cover,
        fit: fit,
        filterQuality: FilterQuality.medium,
        errorBuilder: (context, _, _) => ColoredBox(
          color: context.tones.stageTop,
          child: Icon(Icons.broken_image_outlined, color: context.tones.muted),
        ),
      ),
    );
  }
}
