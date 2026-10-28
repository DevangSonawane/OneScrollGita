import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'glass_nav_bar.dart';
import 'tokens.dart';

/// A short message that clears the floating nav pill.
void showToast(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        margin: EdgeInsets.fromLTRB(
          Space.s16,
          0,
          Space.s16,
          navBarInset(context) - Space.s8,
        ),
      ),
    );
}

/// Tapping the child copies [text] to the clipboard.
class CopyOnTap extends StatelessWidget {
  const CopyOnTap({
    super.key,
    required this.text,
    required this.what,
    required this.child,
  });

  final String text;

  /// What was copied, for the message ("Sanskrit", "Translation").
  final String what;
  final Widget child;

  @override
  Widget build(BuildContext context) => Semantics(
    onTapHint: 'Copy $what',
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: text));
        await HapticFeedback.selectionClick();
        if (context.mounted) showToast(context, '$what copied');
      },
      child: child,
    ),
  );
}
