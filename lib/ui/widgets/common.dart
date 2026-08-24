import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

const kRadius = 18.0;
const kRadiusSmall = 12.0;
const kFast = Duration(milliseconds: 160);
const kMedium = Duration(milliseconds: 260);
const kSlow = Duration(milliseconds: 420);

const categoryIcons = <String, IconData>{
  'shield': Icons.shield_outlined,
  'costume': Icons.checkroom_outlined,
  'amphora': Icons.museum_outlined,
  'home': Icons.cottage_outlined,
  'medal': Icons.military_tech_outlined,
  'palette': Icons.palette_outlined,
};

IconData iconFor(String key) => categoryIcons[key] ?? Icons.museum_outlined;

/// Подпись секции: «КАТЕГОРИИ», «ПРОСМОТР», «МОДЕЛИ».
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 5,
          height: 5,
          margin: const EdgeInsets.only(right: 9, bottom: 1),
          decoration: BoxDecoration(
            color: context.colors.primary,
            borderRadius: BorderRadius.circular(1.5),
          ),
        ),
        Text(
          text.toUpperCase(),
          style: context.text.labelSmall?.copyWith(
            color: context.tones.muted,
            letterSpacing: 1.3,
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 12), Expanded(child: trailing!)],
      ],
    );
  }
}

/// Небольшая метка-«таблетка»: номер экспоната, признак 3D, счётчик фото.
class Tag extends StatelessWidget {
  const Tag({
    super.key,
    required this.label,
    this.icon,
    this.accent = false,
    this.compact = false,
  });

  final String label;
  final IconData? icon;
  final bool accent;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final tones = context.tones;
    final color = accent ? context.colors.primary : tones.muted;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 9,
        vertical: compact ? 3 : 4.5,
      ),
      decoration: BoxDecoration(
        color: accent ? tones.accentSoft : tones.hairline.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: accent ? color.withValues(alpha: 0.35) : Colors.transparent,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: compact ? 11 : 12.5, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: context.text.labelSmall?.copyWith(
              color: color,
              letterSpacing: 0.4,
              fontSize: compact ? 10 : 11,
            ),
          ),
        ],
      ),
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

/// Иконка-кнопка на полупрозрачной подложке — поверх фотографий и 3D-сцены.
class GlassButton extends StatelessWidget {
  const GlassButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.size = 36,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final double size;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.black.withValues(alpha: 0.38),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kRadiusSmall),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(
              icon,
              size: size * 0.5,
              color: Colors.white.withValues(alpha: enabled ? 0.92 : 0.35),
            ),
          ),
        ),
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
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.012),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
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
