import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pracpro/providers/auth_provider.dart';
import 'package:pracpro/widgets/error_message.dart';
import 'package:provider/provider.dart';

void showEmailVerificationDialog(BuildContext context, String email, {int timerSeconds = 5}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => _EmailVerificationDialog(
      email: email,
      timerSeconds: timerSeconds,
      onClose: () => Navigator.of(dialogContext).pop(),
    ),
  );
}

class _EmailVerificationDialog extends StatefulWidget {
  final String email;
  final int timerSeconds;
  final VoidCallback onClose;

  const _EmailVerificationDialog({
    required this.email,
    required this.timerSeconds,
    required this.onClose,
  });

  @override
  State<_EmailVerificationDialog> createState() => _EmailVerificationDialogState();
}

class _EmailVerificationDialogState extends State<_EmailVerificationDialog> {
  bool _isResending = false;
  String? _resendMessage;
  bool _isSuccess = false;
  Timer? _redirectTimer;
  int _remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.timerSeconds;
    _startTimer();
  }

  @override
  void dispose() {
    _redirectTimer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _redirectTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _remainingSeconds--;
        });

        if (_remainingSeconds <= 0) {
          timer.cancel();
          _redirectToWelcome();
        }
      }
    });
  }

  void _redirectToWelcome() {
    if (mounted) {
      widget.onClose();
      Navigator.of(context).pushReplacementNamed('/welcome');
    }
  }

  Future<void> _resendVerificationEmail() async {
    setState(() {
      _isResending = true;
      _resendMessage = null;
      _isSuccess = false;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.resendVerificationEmail(widget.email);

    if (mounted) {
      setState(() {
        _isResending = false;
        if (success) {
          _isSuccess = true;
          _resendMessage = 'Verification email sent! Please check your inbox.';
        } else {
          _isSuccess = false;
          _resendMessage = authProvider.error ?? 'Failed to send verification email.';
        }
      });

      if (_isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_resendMessage!),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _resendMessage = null;
              _isSuccess = false;
            });
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            Row(
              children: [
                Icon(
                  Icons.mail_outline,
                  size: 32,
                  color: Colors.blue[700],
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Verify Your Email',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            const Text(
              'We sent a verification link to:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),

            SelectableText(
              widget.email,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.blue[700],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Please check your email and click the',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'verification link to activate your account.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Once verified, you can sign in.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),

            if (_resendMessage != null && !_isSuccess)
              ErrorMessage(message: _resendMessage!),

            if (_remainingSeconds > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  'Redirecting in $_remainingSeconds second${_remainingSeconds != 1 ? 's' : ''}...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),

            Row(
              children: [

                Expanded(
                  child: TextButton(
                    onPressed: _isResending ? null : _resendVerificationEmail,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.purple[700],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isResending
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.purple,
                              ),
                            ),
                          )
                        : const Text(
                            'Resend Email',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _redirectTimer?.cancel();
                      _redirectToWelcome();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Go to Login',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
