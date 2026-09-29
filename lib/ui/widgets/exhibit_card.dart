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
    return Hoverable(
      onTap: onTap,
      builder: (context, hovered) => AnimatedContainer(
        duration: kFast,
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: hovered ? AppColors.raised : AppColors.panel,
          borderRadius: BorderRadius.circular(AppRadii.card),
          border: Border.all(color: hovered ? AppColors.outline : AppColors.divider),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ExhibitThumb(exhibit: exhibit),
                  Positioned(
                    left: AppSpacing.xs,
                    top: AppSpacing.xs,
                    child: Tag(label: '№ ${exhibit.number}'),
                  ),
                  if (exhibit.hasModel)
                    const Positioned(
                      right: AppSpacing.xs,
                      top: AppSpacing.xs,
                      child: Tag(label: '3D', icon: Icons.view_in_ar_outlined),
                    ),
                ],
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    exhibit.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    exhibit.reason,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodySmall,
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

/// Превью экспоната. Снимок показывается в естественных цветах.
class ExhibitThumb extends StatelessWidget {
  const ExhibitThumb({super.key, required this.exhibit, this.fit = BoxFit.cover});

  final Exhibit exhibit;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final cover = exhibit.cover;
    if (cover == null) return const _ThumbPlaceholder(Icons.image_not_supported_outlined);
    return Image.asset(
      cover,
      fit: fit,
      filterQuality: FilterQuality.medium,
      errorBuilder: (context, _, _) => const _ThumbPlaceholder(Icons.broken_image_outlined),
    );
  }
}

class _ThumbPlaceholder extends StatelessWidget {
  const _ThumbPlaceholder(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.raised,
      child: Icon(icon, color: AppColors.textSecondary),
    );
  }
}
