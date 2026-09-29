import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

const kFast = Duration(milliseconds: 160);
const kMedium = Duration(milliseconds: 260);

const categoryIcons = <String, IconData>{
  'shield': Icons.shield_outlined,
  'costume': Icons.checkroom_outlined,
  'amphora': Icons.museum_outlined,
  'home': Icons.cottage_outlined,
  'medal': Icons.military_tech_outlined,
  'palette': Icons.palette_outlined,
};

IconData iconFor(String key) => categoryIcons[key] ?? Icons.museum_outlined;

/// Подпись секции: «КАТЕГОРИИ», «ПРОСМОТР», «МОДЕЛИ» и пояснение справа.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.detail});

  final String text;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          text.toUpperCase(),
          style: context.text.labelSmall?.copyWith(letterSpacing: 1.2),
        ),
        if (detail != null) ...[
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              detail!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: context.text.labelSmall,
            ),
          ),
        ],
      ],
    );
  }
}

/// Небольшая плоская метка поверх фотографии или сцены: номер экспоната,
/// признак 3D. Непрозрачная подложка — текст читается на любом снимке.
class Tag extends StatelessWidget {
  const Tag({super.key, required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(AppRadii.button),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: AppSpacing.xxs),
          ],
          Text(
            label,
            style: context.text.labelSmall?.copyWith(color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}

/// Панель: плоская подложка, радиус 16, разделитель 1 px.
class SectionSurface extends StatelessWidget {
  const SectionSurface({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(AppRadii.panel),
        border: Border.all(color: AppColors.divider),
      ),
      clipBehavior: Clip.antiAlias,
      padding: padding,
      child: child,
    );
  }
}

/// Отслеживает наведение курсора — на десктопе карточки подсвечиваются,
/// на сенсорном экране просто ничего не происходит.
class Hoverable extends StatefulWidget {
  const Hoverable({super.key, required this.builder, this.onTap});

  final Widget Function(BuildContext context, bool hovered) builder;
  final VoidCallback? onTap;

  @override
  State<Hoverable> createState() => _HoverableState();
}

class _HoverableState extends State<Hoverable> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.onTap == null ? MouseCursor.defer : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: widget.builder(context, _hovered),
      ),
    );
  }
}

/// Квадратная кнопка-иконка на непрозрачной подложке — поверх фотографий,
/// 3D-сцены и в шапках панелей. При наведении и фокусе контур и иконка
/// становятся латунными.
class PanelIconButton extends StatelessWidget {
  const PanelIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.size = kTouchTarget,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(icon, size: 20),
      style: ButtonStyle(
        fixedSize: WidgetStatePropertyAll(Size.square(size)),
        minimumSize: WidgetStatePropertyAll(Size.square(size)),
        padding: const WidgetStatePropertyAll(EdgeInsets.zero),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        backgroundColor: const WidgetStatePropertyAll(AppColors.panel),
        shape: WidgetStateProperty.resolveWith((states) {
          final Color color;
          if (states.contains(WidgetState.disabled)) {
            color = AppColors.divider;
          } else if (states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.focused) ||
              states.contains(WidgetState.pressed)) {
            color = AppColors.brassHover;
          } else {
            color = AppColors.outline;
          }
          return RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.button),
            side: BorderSide(color: color),
          );
        }),
      ),
    );
  }
}

/// Плавная подмена содержимого секции «Просмотр».
class FadeSwitch extends StatelessWidget {
  const FadeSwitch({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: kMedium,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: child,
    );
  }
}

String plural(int n, String one, String few, String many) {
  final mod100 = n % 100;
  final mod10 = n % 10;
  if (mod100 >= 11 && mod100 <= 14) return '$n $many';
  if (mod10 == 1) return '$n $one';
  if (mod10 >= 2 && mod10 <= 4) return '$n $few';
  return '$n $many';
}
