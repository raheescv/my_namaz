import 'package:flutter/material.dart';

/// A clean settings row matching the reference design — icon in a tinted
/// rounded square, title left, trailing value/widget, optional subtitle.
class SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool enabled;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 19),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 1),
                      Text(subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Group of settings tiles in a single rounded card with hairline dividers.
class SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  const SettingsGroup({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final divider = Divider(
        height: 1,
        thickness: 0.5,
        indent: 60,
        endIndent: 12,
        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4));
    final rows = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      rows.add(children[i]);
      if (i < children.length - 1) rows.add(divider);
    }
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(children: rows),
    );
  }
}

/// Tappable header that animates a body in/out — mimics iOS disclosure groups.
/// Renders the same SettingsTile style as a normal row, with a chevron that
/// rotates from > to v when expanded.
class ExpandableSettingsTile extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final List<Widget> children;
  final bool initiallyExpanded;

  const ExpandableSettingsTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    required this.children,
    this.initiallyExpanded = false,
  });

  @override
  State<ExpandableSettingsTile> createState() =>
      _ExpandableSettingsTileState();
}

class _ExpandableSettingsTileState extends State<ExpandableSettingsTile>
    with SingleTickerProviderStateMixin {
  late bool _open = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final divider = Divider(
        height: 1,
        thickness: 0.5,
        indent: 60,
        endIndent: 12,
        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4));
    final body = <Widget>[];
    for (int i = 0; i < widget.children.length; i++) {
      body.add(widget.children[i]);
      if (i < widget.children.length - 1) body.add(divider);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsTile(
          icon: widget.icon,
          iconColor: widget.iconColor,
          title: widget.title,
          subtitle: widget.subtitle,
          trailing: AnimatedRotation(
            turns: _open ? 0.25 : 0,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            child: const Icon(Icons.chevron_right, size: 20),
          ),
          onTap: () => setState(() => _open = !_open),
        ),
        ClipRect(
          child: AnimatedAlign(
            alignment: Alignment.topCenter,
            heightFactor: _open ? 1 : 0,
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            child: Container(
              color: theme.colorScheme.surface.withValues(alpha: 0.3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Divider(
                      height: 1,
                      thickness: 0.5,
                      color: theme.colorScheme.outlineVariant
                          .withValues(alpha: 0.4)),
                  ...body,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A sub-row that goes inside an ExpandableSettingsTile body — no icon,
/// indented to align under the parent's icon column.
class SubSettingsRow extends StatelessWidget {
  final String title;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;

  const SubSettingsRow({
    super.key,
    required this.title,
    this.value,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(60, 12, 14, 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500),
              ),
            ),
            if (value != null)
              Text(
                value!,
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500),
              ),
            if (trailing != null) ...[
              const SizedBox(width: 6),
              trailing!,
            ] else if (onTap != null && value != null) ...[
              const SizedBox(width: 4),
              Icon(Icons.chevron_right,
                  size: 18, color: theme.colorScheme.onSurfaceVariant),
            ],
          ],
        ),
      ),
    );
  }
}
