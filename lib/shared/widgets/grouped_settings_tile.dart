import 'package:flutter/material.dart';
import 'package:fluent_icons_kit/fluent_icons_kit.dart';

/// Where a tile sits inside a grouped settings block.
///
/// The four cases are deliberately exhaustive: a group always has exactly one
/// `first` and one `last`, every element in between is `middle`, and a group
/// with a single element is `single`.
enum GroupedTilePosition { single, first, middle, last }

/// Shared corner radius for grouped settings tiles.
const double groupedTileRadius = 18;

/// The single source of truth for grouped tile corners.
///
/// Background and ink are both clipped with this value, so the ripple can
/// never have a different shape from the visible surface.
BorderRadius groupedTileBorderRadius(
  GroupedTilePosition position, {
  double radius = groupedTileRadius,
}) {
  final corner = Radius.circular(radius);
  return switch (position) {
    GroupedTilePosition.single => BorderRadius.all(corner),
    GroupedTilePosition.first => BorderRadius.only(
      topLeft: corner,
      topRight: corner,
    ),
    GroupedTilePosition.middle => BorderRadius.zero,
    GroupedTilePosition.last => BorderRadius.only(
      bottomLeft: corner,
      bottomRight: corner,
    ),
  };
}

/// Calculates the position of the child at [index] in a group of [length].
GroupedTilePosition groupedTilePositionAt(int index, int length) {
  if (length <= 1) {
    return GroupedTilePosition.single;
  }
  if (index == 0) {
    return GroupedTilePosition.first;
  }
  if (index == length - 1) {
    return GroupedTilePosition.last;
  }
  return GroupedTilePosition.middle;
}

/// A ListTile whose background, splash and shape are guaranteed to match.
///
/// The tile is wrapped in a transparent [Material] with the same
/// [BorderRadius] that is passed to the [InkWell]. Because the Material sizes
/// itself to the ListTile, `ListTile.contentPadding` stays an internal padding
/// and can never create a transparent strip between the ripple and the row.
class GroupedSettingsTile extends StatelessWidget {
  const GroupedSettingsTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.position,
    this.enabled = true,
    this.destructive = false,
    this.titleStyle,
    this.subtitleStyle,
    this.showChevron = true,
    this.contentPadding = const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 4,
    ),
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;

  /// Overrides the position supplied by [GroupedSettingsGroup]. Standalone
  /// tiles default to [GroupedTilePosition.single].
  final GroupedTilePosition? position;

  final bool enabled;
  final bool destructive;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;

  /// Shows a chevron when the row is tappable and no custom trailing widget was
  /// supplied.
  final bool showChevron;

  final EdgeInsetsGeometry contentPadding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final effectivePosition =
        position ??
        GroupedTilePositionScope.maybeOf(context) ??
        GroupedTilePosition.single;
    final radius = groupedTileBorderRadius(effectivePosition);
    final foreground = destructive ? scheme.error : scheme.onSurface;
    final isInteractive = enabled && onTap != null;

    final resolvedTrailing =
        trailing ??
        (isInteractive && showChevron
            ? Icon(
                FluentIcons.line.chevron_right,
                size: 16,
                color: scheme.onSurfaceVariant,
              )
            : null);

    return Material(
      type: MaterialType.transparency,
      color: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: radius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isInteractive ? onTap : null,
        customBorder: RoundedRectangleBorder(borderRadius: radius),
        child: ListTile(
          enabled: enabled,
          // The outer InkWell owns the gesture and the splash. Giving the
          // ListTile its own onTap would create a second, differently clipped
          // ripple.
          onTap: null,
          contentPadding: contentPadding,
          leading: leading,
          title: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: (titleStyle ?? theme.textTheme.bodyLarge)?.copyWith(
              color: enabled
                  ? foreground
                  : scheme.onSurface.withValues(alpha: 0.38),
            ),
          ),
          subtitle: subtitle == null
              ? null
              : Text(
                  subtitle!,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: (subtitleStyle ?? theme.textTheme.bodySmall)?.copyWith(
                    color: enabled
                        ? (destructive
                              ? scheme.error.withValues(alpha: 0.85)
                              : scheme.onSurfaceVariant)
                        : scheme.onSurface.withValues(alpha: 0.38),
                  ),
                ),
          trailing: resolvedTrailing,
        ),
      ),
    );
  }
}

/// Vertically stacks grouped tiles and assigns first/middle/last positions.
///
/// Divider height is exactly one logical pixel and contributes no padding, so
/// there is never an empty strip between two rows of the same group.
class GroupedSettingsGroup extends StatelessWidget {
  const GroupedSettingsGroup({
    super.key,
    required this.children,
    this.showDividers = true,
  });

  final List<Widget> children;
  final bool showDividers;

  @override
  Widget build(BuildContext context) {
    final dividerColor = Theme.of(context).colorScheme.outlineVariant
        .withValues(alpha: 0.55);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (var index = 0; index < children.length; index++) ...<Widget>[
          GroupedTilePositionScope(
            position: groupedTilePositionAt(index, children.length),
            child: children[index],
          ),
          if (showDividers && index < children.length - 1)
            Divider(height: 1, thickness: 1, color: dividerColor),
        ],
      ],
    );
  }
}

/// Supplies a group position to descendant tiles without repeating the
/// position argument at every call site.
class GroupedTilePositionScope extends InheritedWidget {
  const GroupedTilePositionScope({
    super.key,
    required this.position,
    required super.child,
  });

  final GroupedTilePosition position;

  static GroupedTilePosition? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<GroupedTilePositionScope>()
        ?.position;
  }

  @override
  bool updateShouldNotify(GroupedTilePositionScope oldWidget) {
    return oldWidget.position != position;
  }
}
