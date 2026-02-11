import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../../services/auth_service.dart';
import '../../core/messages/message_modal.dart';

/// Écran de vérification du code OTP
///
/// Paramètres requis:
/// - phone: Numéro de téléphone
/// - type: Type d'OTP ('register', 'login', 'reset_password')
/// - onVerified: Callback appelé après vérification réussie
class OtpVerificationScreen extends StatefulWidget {
  final String phone;
  final String type;
  final Function(String otp)? onVerified;
  final String? nextRoute;

  const OtpVerificationScreen({
    super.key,
    required this.phone,
    this.type = 'register',
    this.onVerified,
    this.nextRoute,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  bool _canResend = false;
  int _resendSeconds = 60;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    // Focus sur le premier champ
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startResendTimer() {
    _canResend = false;
    _resendSeconds = 60;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _resendSeconds--;
          if (_resendSeconds <= 0) {
            _canResend = true;
            timer.cancel();
          }
        });
      }
    });
  }

  String get _otpCode {
    return _controllers.map((c) => c.text).join();
  }

  void _onOtpDigitChanged(int index, String value) {
    if (value.isNotEmpty && index < 5) {
      // Passer au champ suivant
      _focusNodes[index + 1].requestFocus();
    }

    // Vérifier si tous les champs sont remplis
    if (_otpCode.length == 6) {
      _verifyOtp();
    }
  }

  void _onKeyPressed(int index, RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.backspace) {
        if (_controllers[index].text.isEmpty && index > 0) {
          // Revenir au champ précédent
          _controllers[index - 1].clear();
          _focusNodes[index - 1].requestFocus();
        }
      }
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpCode.length != 6) {
      showErrorModal(context, 'Veuillez entrer le code complet à 6 chiffres');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await AuthService.verifyOtp(
        phone: widget.phone,
        otp: _otpCode,
        type: widget.type,
      );

      if (!mounted) return;

      if (response.success) {
        // Appeler le callback si fourni
        if (widget.onVerified != null) {
          widget.onVerified!(_otpCode);
        }

        showSuccessModal(context, 'Code vérifié avec succès');

        // Navigation après un court délai
        await Future.delayed(const Duration(milliseconds: 800));

        if (!mounted) return;

        // Fermer le modal de succès d'abord
        Navigator.of(context).pop();

        if (!mounted) return;

        if (widget.nextRoute != null) {
          Navigator.pushReplacementNamed(context, widget.nextRoute!);
        } else {
          // Retourner avec succès
          Navigator.pop(context, true);
        }
      } else {
        showErrorModal(context, response.errorMessage);
        // Effacer les champs
        for (var controller in _controllers) {
          controller.clear();
        }
        _focusNodes[0].requestFocus();
      }
    } catch (e) {
      if (mounted) {
        showErrorModal(context, 'Erreur lors de la vérification');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resendOtp() async {
    if (!_canResend) return;

    setState(() => _isLoading = true);

    try {
      final response = await AuthService.sendOtp(
        phone: widget.phone,
        type: widget.type,
      );

      if (!mounted) return;

      if (response.success) {
        showSuccessModal(context, response.message ?? 'Code renvoyé');
        _startResendTimer();
      } else {
        showErrorModal(context, response.message ?? 'Erreur lors du renvoi');
      }
    } catch (e) {
      if (mounted) {
        showErrorModal(context, 'Erreur lors du renvoi du code');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back, color: Colors.black87, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // Icône
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFD48EFC), Color(0xFF8936A8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8936A8).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.sms_outlined,
                  size: 48,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 32),

              // Titre
              Text(
                'Vérification',
                style: GoogleFonts.openSans(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 12),

              // Sous-titre
              Text(
                'Entrez le code à 6 chiffres envoyé au',
                style: GoogleFonts.openSans(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                '+225 ${widget.phone}',
                style: GoogleFonts.openSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF8936A8),
                ),
              ),

              const SizedBox(height: 40),

              // Champs OTP
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 48,
                    height: 56,
                    child: RawKeyboardListener(
                      focusNode: FocusNode(),
                      onKey: (event) => _onKeyPressed(index, event),
                      child: TextFormField(
                        controller: _controllers[index],
                        focusNode: _focusNodes[index],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 1,
                        enabled: !_isLoading,
                        onChanged: (value) => _onOtpDigitChanged(index, value),
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: InputDecoration(
                          counterText: '',
                          filled: true,
                          fillColor: _controllers[index].text.isNotEmpty
                              ? const Color(0xFF8936A8).withOpacity(0.1)
                              : Colors.grey.shade100,
                          contentPadding: const EdgeInsets.symmetric(vertical: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF8936A8),
                              width: 2,
                            ),
                          ),
                        ),
                        style: GoogleFonts.openSans(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF8936A8),
                        ),
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 32),

              // Timer de renvoi
              if (!_canResend)
                Text(
                  'Renvoyer le code dans $_resendSeconds s',
                  style: GoogleFonts.openSans(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),

              // Bouton renvoyer
              if (_canResend)
                TextButton(
                  onPressed: _isLoading ? null : _resendOtp,
                  child: Text(
                    'Renvoyer le code',
                    style: GoogleFonts.openSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF8936A8),
                    ),
                  ),
                ),

              const SizedBox(height: 40),

              // Bouton vérifier
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8936A8),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Vérifier',
                          style: GoogleFonts.openSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 24),

              // Note
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Si vous ne recevez pas le code, vérifiez vos SMS ou attendez quelques instants.',
                        style: GoogleFonts.openSans(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
