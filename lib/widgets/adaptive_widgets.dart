import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../models/ipn.dart';
import '../models/platform.dart';
import '../utils/utils.dart';
import 'tv_widgets.dart';

class AdaptiveSearchBar extends StatelessWidget {
  final String placeholder;
  final String value;
  final FocusNode? focusNode;
  final TextEditingController? controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onCancel;

  const AdaptiveSearchBar({
    Key? key,
    required this.placeholder,
    required this.value,
    this.focusNode,
    required this.controller,
    required this.onChanged,
    required this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return isApple()
        ? CupertinoSearchTextField(
            focusNode: focusNode,
            controller: controller,
            placeholder: placeholder,
            placeholderStyle: TextStyle(
              color: CupertinoColors.systemGrey.resolveFrom(context),
            ),
            //value: value,
            onChanged: onChanged,
            onSubmitted: onChanged,
            onSuffixTap: () {
              onCancel();
              FocusScope.of(context).unfocus();
            },
          )
        : SearchBar(
            focusNode: focusNode,
            controller: controller,
            hintText: placeholder,
            onChanged: onChanged,
            onSubmitted: onChanged,
            onTapOutside: (_) => focusNode?.unfocus(),
            elevation: const WidgetStateProperty.fromMap(
              {
                WidgetState.hovered: 1,
                WidgetState.focused: 2,
                WidgetState.any: 0,
              },
            ),
            trailing: [
              if (controller?.text.isNotEmpty ?? false)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: onCancel,
                ),
            ],
          );
  }
}

class AdaptiveErrorIcon extends Icon {
  AdaptiveErrorIcon({super.key, super.color = Colors.red, super.size})
      : super(
          isApple() ? CupertinoIcons.exclamationmark_circle : Icons.error,
        );
}

class AdaptiveWarningIcon extends Icon {
  AdaptiveWarningIcon({super.key, super.color = Colors.amber, super.size})
      : super(
          isApple() ? CupertinoIcons.exclamationmark_triangle : Icons.warning,
        );
}

class AdaptiveSettingsIcon extends Icon {
  AdaptiveSettingsIcon({super.key, super.color, super.size})
      : super(
          isApple() ? CupertinoIcons.settings : Icons.settings,
        );
}

class AdaptiveHealthyIcon extends CircledCheckIcon {
  AdaptiveHealthyIcon({super.key, super.size})
      : super(
          color: isApple() ? CupertinoColors.activeGreen : Colors.green,
        );
}

class AdaptiveSuccessIcon extends AdaptiveHealthyIcon {
  AdaptiveSuccessIcon({super.key, super.size});
}

class AppleBackButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const AppleBackButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      sizeStyle: CupertinoButtonSize.small,
      alignment: Alignment.centerLeft,
      padding: EdgeInsets.only(
        left: Platform.isMacOS && !useNavigationRail(context) ? 64 : 0,
      ),
      onPressed: onPressed,
      child: const Icon(
        CupertinoIcons.chevron_left,
        size: 24,
      ),
    );
  }
}

class CircledCheckIcon extends Icon {
  CircledCheckIcon({super.size, super.color, super.key})
      : super(
          isApple() ? CupertinoIcons.check_mark_circled : Icons.check_circle,
        );
}

class AdaptiveAccountIcon extends Icon {
  AdaptiveAccountIcon({super.key, super.size, super.color})
      : super(
          isApple() ? CupertinoIcons.person : Icons.account_circle,
        );
}

class AdaptiveOnlineIcon extends Icon {
  AdaptiveOnlineIcon(
      {super.key, super.size = 12, bool? online, Color? disabledColor})
      : super(
          isApple() ? CupertinoIcons.circle_fill : Icons.circle,
          color: online ?? false
              ? isApple()
                  ? CupertinoColors.systemGreen
                  : Colors.green
              : isApple()
                  ? CupertinoColors.systemGrey
                  : disabledColor ?? Colors.grey,
        );
}

Color focusedButtonColor(BuildContext context, Color color) {
  return HSLColor.fromColor(color)
      .withLightness(
        (HSLColor.fromColor(color).lightness * 1.2).clamp(0.0, 1.0),
      )
      .toColor();
}

class AdaptiveButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;
  final bool filled;
  final bool textButton;
  final bool small;
  final bool large;
  final bool autofocus;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  const AdaptiveButton({
    super.key,
    this.filled = false,
    this.textButton = false,
    this.small = false,
    this.large = false,
    this.autofocus = false,
    this.width,
    this.height,
    this.padding,
    required this.onPressed,
    required this.child,
  })  : assert(
          !filled || !textButton,
          "Cannot use both filled and textButton at the same time",
        ),
        assert(
          !small || !large,
          "Cannot use both small and large at the same time",
        );
  @override
  Widget build(BuildContext context) {
    if (isApple()) {
      if (textButton) {
        return CupertinoButton(
          padding: padding ?? const EdgeInsets.only(left: 16, right: 16),
          onPressed: onPressed,
          child: child,
        );
      }
      final style = large
          ? CupertinoButtonSize.large
          : small
              ? CupertinoButtonSize.small
              : CupertinoButtonSize.medium;
      if (filled) {
        return SizedBox(
          width: width,
          height: height,
          child: CupertinoButton.filled(
            padding: padding ?? const EdgeInsets.only(left: 16, right: 16),
            onPressed: onPressed,
            child: child,
            borderRadius: BorderRadius.circular(8),
            sizeStyle: style,
          ),
        );
      }
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          border: Border.all(
            color: CupertinoColors.systemGrey3.resolveFrom(context),
            width: 0.5,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: CupertinoButton(
          padding: padding ?? const EdgeInsets.only(left: 16, right: 16),
          sizeStyle: style,
          onPressed: onPressed,
          child: child,
        ),
      );
    }
    if (textButton) {
      return TextButton(
        onPressed: onPressed,
        child: child,
      );
    }
    if (isAndroidTV) {
      return TVButton(
        autofocus: autofocus,
        onPressed: onPressed,
        child: child,
        width: width,
        height: height,
        filled: filled,
        padding: padding,
      );
    }
    return SizedBox(
      width: width,
      height: height,
      child: filled
          ? FilledButton(
              onPressed: onPressed,
              child: child,
            )
          : OutlinedButton(
              onPressed: onPressed,
              child: child,
            ),
    );
  }
}

/// Cannot use Switch.adaptive because it requires a Material parent
class AdaptiveSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color? activeColor;
  final Color? inactiveThumbColor;
  final Color? inactiveTrackColor;

  const AdaptiveSwitch({
    super.key,
    required this.value,
    this.onChanged,
    this.activeColor,
    this.inactiveThumbColor,
    this.inactiveTrackColor,
  });

  @override
  Widget build(BuildContext context) {
    return isApple()
        ? CupertinoSwitch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: activeColor ?? CupertinoColors.activeGreen,
          )
        : Switch(
            value: value,
            onChanged: onChanged,
            activeColor: activeColor,
            inactiveThumbColor: inactiveThumbColor,
            inactiveTrackColor: inactiveTrackColor,
          );
  }
}

class AdaptiveLoadingWidget extends StatelessWidget {
  final double? size;
  final Color? color;
  final double? maxWidth;

  const AdaptiveLoadingWidget(
      {super.key, this.size, this.color, this.maxWidth});

  @override
  Widget build(BuildContext context) {
    return isApple()
        ? const CupertinoActivityIndicator()
        : CircularProgressIndicator(
            strokeWidth: size ?? 2.0,
            constraints: maxWidth != null
                ? BoxConstraints.tight(
                    Size(maxWidth!, maxWidth!),
                  )
                : null,
            valueColor: AlwaysStoppedAnimation<Color>(
              color ?? Theme.of(context).primaryColor,
            ),
          );
  }
}

class AdaptiveAvatar extends StatelessWidget {
  final UserProfile? user;
  final double radius;
  final Color? color;
  const AdaptiveAvatar({super.key, this.user, this.radius = 32, this.color});

  @override
  Widget build(BuildContext context) {
    final initial = (user?.displayName ?? "").isNotEmpty
        ? user?.displayName.characters.first.toUpperCase()
        : null;

    return CircleAvatar(
      radius: radius,
      backgroundColor: isApple()
          ? isDarkMode(context)
              ? CupertinoColors.systemGrey
              : CupertinoColors.systemGrey4
          : Theme.of(context).colorScheme.secondaryContainer,
      backgroundImage: (user?.profilePicURL ?? "").isNotEmpty
          ? NetworkImage(user!.profilePicURL)
          : null,
      child: (user?.profilePicURL ?? "").isEmpty
          ? initial != null
              ? Text(
                  initial,
                  style: isApple()
                      ? TextStyle(
                          fontSize: radius,
                        )
                      : Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontSize: radius,
                          ),
                )
              : AdaptiveAccountIcon(
                  size: radius * 1.5,
                  color: color,
                )
          : null,
    );
  }
}

class AdaptiveLogo extends StatelessWidget {
  final double size;
  final Color? color;
  const AdaptiveLogo({super.key, this.size = 32, this.color});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      // Use different logo for iOS if needed
      'lib/assets/images/cylonix_128.png',
      width: size,
      height: size,
    );
  }
}

// CupertinoLargeNavigationBar is a custom widget that mimics the large title bar
// seen in iOS apps, with a bold title and an optional back button. It differs
// from CupertinoNavigationBar.large by working with a material scaffold
// by providing a bigger height that works for a material scaffold.
// We need to use material scaffold since the column layout in Cupertino
// in cupertino scaffold does not work correctly with expanded children.
class CupertinoLargeNavigationBar extends StatelessWidget
    implements PreferredSizeWidget {
  final Color? backgroundColor;
  final bool automaticBackgroundVisibility;
  final Widget? leading;
  final Widget? largeTitle;
  final Widget? trailing;
  final bool transitionBetweenRoutes;
  final Object? heroTag;

  const CupertinoLargeNavigationBar({
    super.key,
    this.backgroundColor,
    this.automaticBackgroundVisibility = true,
    this.leading,
    this.largeTitle,
    this.trailing,
    this.transitionBetweenRoutes = true,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    if (heroTag != null) {
      return CupertinoNavigationBar.large(
        backgroundColor: backgroundColor,
        automaticBackgroundVisibility: automaticBackgroundVisibility,
        leading: leading,
        largeTitle: largeTitle,
        trailing: trailing,
        transitionBetweenRoutes: transitionBetweenRoutes,
        heroTag: heroTag!,
      );
    }
    return CupertinoNavigationBar.large(
      backgroundColor: backgroundColor,
      automaticBackgroundVisibility: automaticBackgroundVisibility,
      leading: leading,
      largeTitle: largeTitle,
      trailing: trailing,
      transitionBetweenRoutes: transitionBetweenRoutes,
    );
  }

  @override
  Size get preferredSize {
    return const Size.fromHeight(80.0);
  }
}

void showAdaptiveToast(BuildContext context, String message) {
  if (isApple()) {
    showCupertinoSnackBar(
      context: context,
      message: message,
      duration: const Duration(seconds: 2),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// Helper method for showing Cupertino-style toast
void showCupertinoSnackBar({
  required BuildContext context,
  required String message,
  Duration duration = const Duration(seconds: 2),
}) {
  final overlay = Overlay.of(context);
  final overlayEntry = OverlayEntry(
    builder: (context) => Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 20,
      left: 16,
      right: 16,
      child: SafeArea(
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey.withOpacity(0.9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              message,
              style: const TextStyle(
                color: CupertinoColors.white,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ),
    ),
  );

  overlay.insert(overlayEntry);
  Future.delayed(duration, () {
    overlayEntry.remove();
  });
}

class AdaptiveListTile extends StatelessWidget {
  final Widget title;
  final Widget? leading;
  final Widget? trailing;
  final Widget? subtitle;
  final Color? backgroundColor;
  final bool notched;
  final bool dense;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const AdaptiveListTile({
    super.key,
    required this.title,
    this.leading,
    this.trailing,
    this.subtitle,
    this.backgroundColor,
    this.padding,
    this.onTap,
    this.notched = false,
    this.dense = false,
  });

  const AdaptiveListTile.notched({
    super.key,
    required this.title,
    this.leading,
    this.trailing,
    this.subtitle,
    this.backgroundColor,
    this.padding,
    this.dense = false,
    this.onTap,
  }) : notched = true;

  @override
  Widget build(BuildContext context) {
    final child = ListTile(
      visualDensity: VisualDensity.compact,
      dense: dense,
      contentPadding: padding,
      tileColor: backgroundColor,
      title: title,
      leading: leading,
      trailing: trailing,
      subtitle: subtitle,
      onTap: onTap,
    );
    return isApple()
        ? notched
            ? CupertinoListTile.notched(
                leading: leading,
                padding: padding,
                title: title,
                subtitle: subtitle,
                trailing: trailing,
                backgroundColor: backgroundColor ??
                    CupertinoColors.tertiarySystemGroupedBackground
                        .resolveFrom(context),
                onTap: onTap,
              )
            : CupertinoListTile(
                padding: padding,
                leading: leading,
                trailing: trailing,
                subtitle: subtitle,
                title: title,
                backgroundColor: backgroundColor ??
                    CupertinoColors.tertiarySystemGroupedBackground
                        .resolveFrom(context),
                onTap: onTap,
              )
        : child;
  }
}

class AdaptiveListSection extends StatelessWidget {
  final Widget? header;
  final Widget? footer;
  final Color? backgroundColor;
  final List<Widget> children;
  final bool insetGrouped;
  final EdgeInsetsGeometry? margin;

  const AdaptiveListSection({
    super.key,
    this.backgroundColor,
    this.header,
    this.footer,
    this.margin,
    this.insetGrouped = false,
    required this.children,
  });

  const AdaptiveListSection.insetGrouped({
    super.key,
    this.backgroundColor,
    this.header,
    this.footer,
    this.margin,
    required this.children,
  }) : insetGrouped = true;

  @override
  Widget build(BuildContext context) {
    final groupedChildren = <Widget>[];
    if (insetGrouped && !isApple()) {
      for (var i = 0; i < children.length; i++) {
        groupedChildren.add(children[i]);
        if (i < children.length - 1) {
          groupedChildren.add(const Divider(height: 1, thickness: 0.5));
        }
      }
    }

    return isApple()
        ? insetGrouped
            ? CupertinoListSection.insetGrouped(
                backgroundColor: backgroundColor ?? Colors.transparent,
                separatorColor: Colors.transparent,
                additionalDividerMargin: 0,
                header: header,
                footer: footer,
                margin: margin,
                children: children,
              )
            : CupertinoListSection(
                backgroundColor: backgroundColor ?? Colors.transparent,
                separatorColor: Colors.transparent,
                additionalDividerMargin: 0,
                header: header,
                footer: footer,
                margin: margin ?? const EdgeInsets.all(8),
                children: children,
              )
        : Container(
            margin: margin,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8,
                  ),
                  child: header,
                ),
                ...insetGrouped
                    ? [
                        Card(
                          clipBehavior: Clip.antiAlias,
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          elevation: 0,
                          child: Column(children: groupedChildren),
                        )
                      ]
                    : children,
                Padding(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 4,
                    bottom: 16,
                  ),
                  child: footer,
                ),
              ],
            ),
          );
  }
}

class AdaptiveModalPopup extends StatelessWidget {
  final Widget child;
  final double? height;
  final double? maxWidth;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onDismiss;

  const AdaptiveModalPopup({
    super.key,
    this.height,
    this.maxWidth,
    this.padding,
    this.onDismiss,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isApple()
            ? CupertinoColors.systemBackground.resolveFrom(context)
            : Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      width: double.infinity,
      height: height ?? MediaQuery.of(context).size.height * 0.7,
      padding: padding,
      margin: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Column(
          children: [
            Container(
              height: 6,
              width: 40,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: CupertinoColors.separator,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            Expanded(
              child: SizedBox(
                width: maxWidth ?? double.infinity,
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> show(BuildContext context) async {
    if (isApple()) {
      await showCupertinoModalPopup(
        context: context,
        builder: (context) => this,
      );
    } else {
      await showModalBottomSheet(
        constraints: const BoxConstraints(
          minWidth: double.infinity,
          maxWidth: double.infinity,
        ),
        isScrollControlled: true,
        useSafeArea: true,
        context: context,
        builder: (context) => this,
      );
    }
  }
}

class AdaptiveErrorWidget extends StatefulWidget {
  final String error;
  final Future<void> Function()? onRetry;

  const AdaptiveErrorWidget({
    super.key,
    required this.error,
    this.onRetry,
  });

  @override
  State<AdaptiveErrorWidget> createState() => _AdaptiveErrorWidgetState();
}

class _AdaptiveErrorWidgetState extends State<AdaptiveErrorWidget> {
  bool _retrying = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 16,
      children: [
        const SizedBox(height: 32),
        Icon(
          isApple() ? CupertinoIcons.exclamationmark_circle : Icons.error,
          color: isApple()
              ? CupertinoColors.systemRed.resolveFrom(context)
              : Theme.of(context).colorScheme.error,
          size: 48,
        ),
        const SizedBox(height: 16),
        Text(
          'Error',
          style: Theme.of(context).textTheme.titleMedium?.apply(
                fontWeightDelta: 2,
                color: isApple()
                    ? CupertinoColors.label.resolveFrom(context)
                    : Theme.of(context).colorScheme.primary,
              ),
        ),
        Text(
          widget.error,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isApple()
                ? CupertinoColors.systemOrange.resolveFrom(context)
                : Theme.of(context).colorScheme.error,
          ),
        ),
        const SizedBox(height: 16),
        if (widget.onRetry != null)
          _retrying
              ? const Center(child: AdaptiveLoadingWidget())
              : AdaptiveButton(
                  filled: true,
                  width: 200,
                  onPressed: () async {
                    setState(() {
                      _retrying = true;
                    });
                    await widget.onRetry?.call();
                    if (mounted) {
                      setState(() {
                        _retrying = false;
                      });
                    }
                  },
                  child: const Text('Retry'),
                ),
      ],
    );
  }
}

class AdaptiveListTileChevron extends StatelessWidget {
  const AdaptiveListTileChevron({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return isApple()
        ? const CupertinoListTileChevron()
        : const Icon(Icons.chevron_right, size: 20);
  }
}

TextStyle? adaptiveGroupedHeaderStyle(BuildContext context) {
  if (isApple()) {
    return null;
  }
  return Theme.of(context)
      .textTheme
      .titleMedium
      ?.copyWith(fontWeight: FontWeight.bold);
}

TextStyle? adaptiveGroupedFooterStyle(BuildContext context) {
  if (isApple()) {
    return TextStyle(
      fontSize: 12,
      color: CupertinoColors.secondaryLabel.resolveFrom(context),
    );
  }
  return Theme.of(context)
      .textTheme
      .bodySmall
      ?.copyWith(fontWeight: FontWeight.w300);
}

class AdaptiveGroupedHeader extends StatelessWidget {
  final String title;

  const AdaptiveGroupedHeader(
    this.title, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: adaptiveGroupedHeaderStyle(context),
    );
  }
}

class AdaptiveGroupedFooter extends StatelessWidget {
  final String title;

  const AdaptiveGroupedFooter(
    this.title, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: adaptiveGroupedFooterStyle(context),
    );
  }
}

Color? appleScaffoldBackgroundColor(BuildContext context) {
  return CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context);
}
