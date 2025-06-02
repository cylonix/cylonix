import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../models/ipn.dart';
import '../utils/utils.dart';

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
            controller: controller,
            hintText: placeholder,
            onChanged: onChanged,
            onSubmitted: onChanged,
            trailing: [
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

class AppleBackButton extends CupertinoButton {
  const AppleBackButton({super.onPressed, super.key})
      : super(
          sizeStyle: CupertinoButtonSize.small,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.all(0),
          child: const Icon(
            CupertinoIcons.chevron_left,
            size: 24,
          ),
        );
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

class AdaptiveButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;
  final bool filled;
  final bool textButton;
  final double? width;
  const AdaptiveButton({
    super.key,
    this.filled = false,
    this.textButton = false,
    this.width,
    required this.onPressed,
    required this.child,
  }) : assert(
          !filled || !textButton,
          "Cannot use both filled and textButton at the same time",
        );
  @override
  Widget build(BuildContext context) {
    if (isApple()) {
      if (textButton) {
        return CupertinoButton(
          padding: const EdgeInsets.only(left: 16, right: 16),
          onPressed: onPressed,
          child: child,
        );
      }
      return Container(
        width: width,
        decoration: filled
            ? null
            : BoxDecoration(
                border: Border.all(
                  color: CupertinoColors.systemGrey3.resolveFrom(context),
                  width: 0.5,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
        child: filled
            ? CupertinoButton.filled(
                padding: const EdgeInsets.only(left: 16, right: 16),
                //sizeStyle: CupertinoButtonSize.medium,
                onPressed: onPressed,
                child: child,
              )
            : CupertinoButton(
                padding: const EdgeInsets.only(left: 16, right: 16),
                sizeStyle: CupertinoButtonSize.medium,
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
    return SizedBox(
      width: width,
      child: filled
          ? ElevatedButton(
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

/// Cannot use Switch.adaptive because it requires a Material paraent
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
            activeColor: activeColor ?? Theme.of(context).primaryColor,
            inactiveThumbColor: inactiveThumbColor,
            inactiveTrackColor: inactiveTrackColor,
          );
  }
}

class AdaptiveLoadingWidget extends StatelessWidget {
  final double? size;
  final Color? color;

  const AdaptiveLoadingWidget({super.key, this.size, this.color});

  @override
  Widget build(BuildContext context) {
    return isApple()
        ? const CupertinoActivityIndicator()
        : CircularProgressIndicator(
            strokeWidth: size ?? 4.0,
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
                          fontSize: radius * 0.6,
                        )
                      : Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontSize: radius * 0.6,
                          ),
                )
              : AdaptiveAccountIcon(size: radius * 0.6)
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
  final VoidCallback? onTap;

  const AdaptiveListTile({
    super.key,
    required this.title,
    this.leading,
    this.trailing,
    this.subtitle,
    this.backgroundColor,
    this.onTap,
    this.notched = false,
  });

  const AdaptiveListTile.notched({
    super.key,
    required this.title,
    this.leading,
    this.trailing,
    this.subtitle,
    this.backgroundColor,
    this.onTap,
  }) : notched = true;

  @override
  Widget build(BuildContext context) {
    return isApple()
        ? notched
            ? CupertinoListTile.notched(
                leading: leading,
                title: title,
                subtitle: subtitle,
                trailing: trailing,
                backgroundColor: backgroundColor ??
                    CupertinoColors.systemGrey6.resolveFrom(context),
                onTap: onTap,
              )
            : CupertinoListTile(
                leading: leading,
                trailing: trailing,
                subtitle: subtitle,
                title: title,
                backgroundColor: backgroundColor ??
                    CupertinoColors.systemGrey6.resolveFrom(context),
                onTap: onTap,
              )
        : ListTile(
            tileColor: backgroundColor,
            title: title,
            leading: leading,
            trailing: trailing,
            subtitle: subtitle,
            onTap: onTap,
          );
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
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: header,
              ),
              ...children,
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: footer,
              ),
            ],
          );
  }
}

class AdaptiveModalPopup extends StatelessWidget {
  final Widget child;
  final double? height;
  final VoidCallback? onDismiss;

  const AdaptiveModalPopup({
    super.key,
    required this.child,
    this.height,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return isApple()
        ? Container(
            decoration: BoxDecoration(
              color: CupertinoColors.systemBackground.resolveFrom(context),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            height: height ?? MediaQuery.of(context).size.height * 0.7,
            padding: const EdgeInsets.all(8),
            margin: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SafeArea(
              top: false,
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
                    child: child,
                  ),
                ],
              ),
            ),
          )
        : AlertDialog(
            content: child,
            actions: [
              TextButton(
                onPressed: () {
                  if (onDismiss != null) {
                    onDismiss!();
                  }
                  Navigator.of(context).pop();
                },
                child: const Text('Close'),
              ),
            ],
          );
  }
}
