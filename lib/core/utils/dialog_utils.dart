import 'package:app/core/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DialogUtils {
  DialogUtils._();

  static Future<void> showNotification(
    BuildContext context, {
    required String title,
    required String message,
    String closeText = 'Đóng',
    VoidCallback? onClose,
  }) {
    return showDialog(
      context: context,
      builder: (context) => _DialogShell(
        title: title,
        message: message,
        actions: [
          _FilledPinkButton(
            text: closeText,
            onPressed: () {
              Navigator.of(context).pop();
              onClose?.call();
            },
          ),
        ],
      ),
    );
  }

  static Future<void> showConfirmation(
    BuildContext context, {
    required String title,
    required String message,
    String cancelText = 'Hủy',
    String confirmText = 'Xác nhận',
    VoidCallback? onCancel,
    VoidCallback? onConfirm,
  }) {
    return showDialog(
      context: context,
      builder: (context) => _DialogShell(
        title: title,
        message: message,
        actions: [
          Expanded(
            child: _OutlinedPinkButton(
              text: cancelText,
              onPressed: () {
                Navigator.of(context).pop();
                onCancel?.call();
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _FilledPinkButton(
              text: confirmText,
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm?.call();
              },
            ),
          ),
        ],
      ),
    );
  }

  static Future<bool?> showConfirmationAsync(
    BuildContext context, {
    required String title,
    required String message,
    String cancelText = 'Hủy',
    String confirmText = 'Xác nhận',
    required Future<bool> Function() onConfirm,
    String? errorMessage,
  }) {
    bool isLoading = false;
    return showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return _DialogShell(
            title: title,
            message: message,
            actions: [
              Expanded(
                child: _OutlinedPinkButton(
                  text: cancelText,
                  onPressed: isLoading
                      ? () {}
                      : () => Navigator.of(context).pop(false),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _FilledPinkButton(
                  text: confirmText,
                  isLoading: isLoading,
                  onPressed: isLoading
                      ? () {}
                      : () async {
                          setDialogState(() => isLoading = true);
                          final success = await onConfirm();
                          if (!context.mounted) return;

                          if (success) {
                            Navigator.of(context).pop(true);
                          } else {
                            setDialogState(() => isLoading = false);
                            if (errorMessage != null) {
                              SnackbarUtils.failure(context, errorMessage);
                            }
                          }
                        },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DialogShell extends StatelessWidget {
  final String title;
  final String message;
  final List<Widget> actions;

  const _DialogShell({
    required this.title,
    required this.message,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(
                color: Colors.black,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(
                color: Colors.black.withValues(alpha: 0.7),
                fontSize: 15,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisSize: actions.length == 1
                  ? MainAxisSize.max
                  : MainAxisSize.max,
              children: actions.length == 1
                  ? [Expanded(child: actions.first)]
                  : actions,
            ),
          ],
        ),
      ),
    );
  }
}

class _FilledPinkButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;

  const _FilledPinkButton({
    required this.text,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isLoading
              ? Colors.black.withValues(alpha: 0.1)
              : Colors.pink,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                text,
                style: GoogleFonts.roboto(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
      ),
    );
  }
}

class _OutlinedPinkButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const _OutlinedPinkButton({required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.pink,
          side: const BorderSide(color: Colors.pink, width: 1.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          text,
          style: GoogleFonts.roboto(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
    );
  }
}
