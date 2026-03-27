import 'dart:io';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../services/gift_service.dart';
import '../../../services/models/gift_model.dart';
import '../../../services/auth_service.dart';
import 'gift_card_track_screen.dart';

class PurchaseCardScreen extends StatefulWidget {
  final dynamic currentShop;
  const PurchaseCardScreen({super.key, this.currentShop});

  static Future<void> show(BuildContext context, {dynamic currentShop}) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PurchaseCardScreen(currentShop: currentShop),
      ),
    );
  }

  @override
  State<PurchaseCardScreen> createState() => _PurchaseCardScreenState();
}

class _PurchaseCardScreenState extends State<PurchaseCardScreen> {
  static const Color _kPurple = Color(0xFF7C3AED);
  static const Color _kPurpleLight = Color(0xFFA78BFA);

  int _step = 0;
  final PageController _pageCtrl = PageController();

  // Step 1
  final List<int> _presets = [5000, 10000, 15000, 25000, 50000];
  int? _selectedAmount;
  bool _isCustom = false;
  final _customCtrl = TextEditingController();

  // Step 2
  final _senderNameCtrl  = TextEditingController();
  final _senderPhoneCtrl = TextEditingController();

  // Step 3
  final _recipientNameCtrl  = TextEditingController();
  final _recipientPhoneCtrl = TextEditingController();
  final _messageCtrl        = TextEditingController();
  String? _waveScreenshotPath;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final client = AuthService.currentClient;
    if (client != null) {
      _senderNameCtrl.text  = client.name;
      _senderPhoneCtrl.text = client.phone;
    }
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _customCtrl.dispose();
    _senderNameCtrl.dispose();
    _senderPhoneCtrl.dispose();
    _recipientNameCtrl.dispose();
    _recipientPhoneCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  int get _amount => _isCustom
      ? (int.tryParse(_customCtrl.text.replaceAll(' ', '')) ?? 0)
      : (_selectedAmount ?? 0);

  String _fmt(int price) {
    final s = price.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return '${buf.toString()} F';
  }

  void _goTo(int step) {
    setState(() => _step = step);
    _pageCtrl.animateToPage(step,
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  void _err(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Container(
            width: 36, height: 36, alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.error_outline_rounded,
                color: Colors.red.shade400, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text('Attention',
              style: GoogleFonts.inriaSerif(
                  fontWeight: FontWeight.w800, fontSize: 16))),
        ]),
        content: Text(msg,
          style: GoogleFonts.inriaSerif(
              fontSize: 13, color: Colors.grey.shade700, height: 1.5),
        ),
        actions: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [_kPurple, _kPurpleLight]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('OK', textAlign: TextAlign.center,
                  style: GoogleFonts.inriaSerif(
                      color: Colors.white, fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }

  bool _validateStep1() {
    if (_isCustom) {
      if (_amount < 500) { _err('Montant minimum : 500 F'); return false; }
      if (_amount > 500000) { _err('Montant maximum : 500 000 F'); return false; }
    } else if (_selectedAmount == null) {
      _err('Veuillez sélectionner un montant'); return false;
    }
    return true;
  }

  bool _validateStep2() {
    if (_senderNameCtrl.text.trim().isEmpty) { _err('Veuillez saisir votre nom'); return false; }
    if (_senderPhoneCtrl.text.trim().length < 8) { _err('Numéro invalide'); return false; }
    return true;
  }

  bool _validateStep3() {
    if (_recipientNameCtrl.text.trim().isEmpty) { _err('Saisissez le nom du bénéficiaire'); return false; }
    if (_recipientPhoneCtrl.text.trim().length < 8) { _err('Numéro du bénéficiaire invalide'); return false; }
    if (_waveScreenshotPath == null) { _err('Veuillez uploader la capture Wave'); return false; }
    return true;
  }

  bool get _hasWaveLink {
    final shop = widget.currentShop;
    return (shop?.wavePaymentLink != null && shop!.wavePaymentLink!.isNotEmpty) ||
           (shop?.wavePhone != null && shop!.wavePhone!.isNotEmpty);
  }

  Future<void> _openWave() async {
    // Priorité: lien Wave de la boutique → numéro Wave → numéro boutique
    final shop = widget.currentShop;
    String? waveUrl;

    if (shop?.wavePaymentLink != null && shop!.wavePaymentLink!.isNotEmpty) {
      waveUrl = shop.wavePaymentLink;
    } else if (shop?.wavePhone != null && shop!.wavePhone!.isNotEmpty) {
      waveUrl = 'https://pay.wave.com/m/${shop.wavePhone}';
    }

    if (waveUrl == null) {
      _err('Aucun lien Wave disponible pour cette boutique.');
      return;
    }

    final uri = Uri.parse(waveUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _err('Impossible d\'ouvrir Wave. Vérifiez que l\'application est installée.');
    }
  }

  Future<void> _pickScreenshot() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 90);
    if (picked == null) return;

    final fileSize = await File(picked.path).length();
    const maxBytes = 5 * 1024 * 1024; // 5 Mo
    if (fileSize > maxBytes) {
      _err('La capture est trop lourde (${(fileSize / 1024 / 1024).toStringAsFixed(1)} Mo). Maximum : 5 Mo.');
      return;
    }

    setState(() => _waveScreenshotPath = picked.path);
  }

  Future<void> _submit() async {
    if (!_validateStep3()) return;

    setState(() => _isLoading = true);

    try {
      final shopId = widget.currentShop?.id as int? ?? 0;
      final result = await GiftService.createGiftCard(
        shopId: shopId,
        amount: _amount,
        senderName: _senderNameCtrl.text.trim(),
        senderPhone: _senderPhoneCtrl.text.trim(),
        recipientName: _recipientNameCtrl.text.trim(),
        recipientPhone: _recipientPhoneCtrl.text.trim(),
        screenshotPath: _waveScreenshotPath!,
        giftMessage: _messageCtrl.text.trim().isEmpty
            ? null
            : _messageCtrl.text.trim(),
        customerUserId: AuthService.currentClient?.id,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (result.validationFailed) {
        _showOcrError(result.message, result.details, result.confidence);
      } else if (result.success) {
        _showSuccess(result);
      } else {
        _err(result.message);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _err(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _showOcrError(String message, List<String> details, int? confidence) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
          const SizedBox(width: 8),
          Expanded(child: Text('Capture refusée',
              style: GoogleFonts.inriaSerif(fontWeight: FontWeight.w800))),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message, style: GoogleFonts.inriaSerif(fontSize: 14)),
            if (details.isNotEmpty) ...[
              const SizedBox(height: 10),
              ...details.map((d) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('• ', style: TextStyle(color: Colors.red)),
                  Expanded(child: Text(d, style: GoogleFonts.inriaSerif(
                      fontSize: 12, color: Colors.grey.shade700))),
                ]),
              )),
            ],
            if (confidence != null) ...[
              const SizedBox(height: 8),
              Text('Confiance OCR: $confidence%',
                  style: GoogleFonts.inriaSerif(fontSize: 12, color: Colors.grey.shade500)),
            ],
            const SizedBox(height: 12),
            Text('Veuillez uploader une capture Wave valide.',
                style: GoogleFonts.inriaSerif(fontSize: 13, color: Colors.grey.shade600)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _waveScreenshotPath = null);
            },
            child: Text('Réessayer', style: GoogleFonts.inriaSerif(
                color: _kPurple, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showSuccess(GiftCardResult result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Container(
            width: 40, height: 40, alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [_kPurple, _kPurpleLight]),
              borderRadius: BorderRadius.circular(12)),
            child: const FaIcon(FontAwesomeIcons.creditCard, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text('Carte créée !',
              style: GoogleFonts.inriaSerif(fontWeight: FontWeight.w800, fontSize: 16))),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              result.autoActivated
                  ? 'La carte a été activée ! Le code a été envoyé au bénéficiaire par WhatsApp.'
                  : 'Carte créée. Le vendeur va confirmer le paiement manuellement.',
              style: GoogleFonts.inriaSerif(fontSize: 13, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _kPurple.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kPurple.withOpacity(0.2)),
              ),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Montant', style: GoogleFonts.inriaSerif(
                      fontSize: 13, color: Colors.grey.shade600)),
                  Text(_fmt(result.amount ?? _amount), style: GoogleFonts.inriaSerif(
                      fontSize: 15, fontWeight: FontWeight.w800, color: _kPurple)),
                ]),
                if (result.trackingToken != null) ...[
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Numéro de suivi', style: GoogleFonts.inriaSerif(
                          fontSize: 12, color: Colors.grey.shade600)),
                      Text(result.trackingToken!, style: GoogleFonts.inriaSerif(
                          fontSize: 14, fontWeight: FontWeight.w800,
                          color: const Color(0xFF1C1C1E))),
                    ])),
                    GestureDetector(
                      onTap: () => Clipboard.setData(
                          ClipboardData(text: result.trackingToken!)),
                      child: Icon(Icons.copy_rounded, size: 18, color: _kPurple),
                    ),
                  ]),
                ],
                if (!result.autoActivated) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Icon(Icons.hourglass_top_rounded,
                          color: Colors.orange, size: 16),
                      const SizedBox(width: 6),
                      Expanded(child: Text(
                        'En attente de confirmation du vendeur.',
                        style: GoogleFonts.inriaSerif(
                            fontSize: 12, color: Colors.orange.shade800))),
                    ]),
                  ),
                ],
              ]),
            ),
          ],
        ),
        actions: [
          Column(mainAxisSize: MainAxisSize.min, children: [
            if (result.trackingToken != null) ...[
              GestureDetector(
                onTap: () {
                  final token = result.trackingToken!;
                  Navigator.pop(context); // dialog
                  Navigator.pop(context); // bottom sheet
                  GiftCardTrackScreen.show(context, token: token);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [_kPurple, _kPurpleLight]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const FaIcon(FontAwesomeIcons.magnifyingGlass, color: Colors.white, size: 14),
                    const SizedBox(width: 8),
                    Text('Suivre la carte', textAlign: TextAlign.center,
                      style: GoogleFonts.inriaSerif(
                          color: Colors.white, fontWeight: FontWeight.w800)),
                  ]),
                ),
              ),
              const SizedBox(height: 8),
            ],
            GestureDetector(
              onTap: () {
                Navigator.pop(context); // dialog
                Navigator.pop(context); // bottom sheet
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('Fermer', textAlign: TextAlign.center,
                  style: GoogleFonts.inriaSerif(
                      color: Colors.grey.shade700, fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  // ── Field helper ─────────────────────────────────────────────────────────

  Widget _field({
    required TextEditingController ctrl,
    required String label,
    String? hint,
    bool optional = false,
    int maxLines = 1,
    TextInputType kb = TextInputType.text,
    List<TextInputFormatter>? fmt,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label + (optional ? ' (optionnel)' : ''),
          style: GoogleFonts.inriaSerif(
            fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1C1C1E))),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          keyboardType: kb,
          inputFormatters: fmt,
          style: GoogleFonts.inriaSerif(
            fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF0D0D0D)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inriaSerif(fontSize: 14, color: Colors.grey.shade500),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade400, width: 1.2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: _kPurple, width: 2),
            ),
          ),
        ),
      ]),
    );
  }

  // ── Progress dots ─────────────────────────────────────────────────────────

  Widget _dots() => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: List.generate(3, (i) {
      final active = i == _step;
      final done   = i < _step;
      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: active ? 28 : 10, height: 10,
        decoration: BoxDecoration(
          color: done
              ? _kPurple.withOpacity(0.4)
              : active ? _kPurple : Colors.white.withOpacity(0.4),
          borderRadius: BorderRadius.circular(5),
        ),
      );
    }),
  );

  // ── Nav buttons ───────────────────────────────────────────────────────────

  Widget _primaryBtn(String label, IconData icon, VoidCallback onTap) =>
    GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_kPurple, _kPurpleLight],
            begin: Alignment.centerLeft, end: Alignment.centerRight),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: _kPurple.withOpacity(0.35),
            blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(label, style: GoogleFonts.inriaSerif(
            fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(width: 8),
          Icon(icon, color: Colors.white, size: 18),
        ]),
      ),
    );

  Widget _outlineBtn(String label, IconData icon, VoidCallback onTap) =>
    GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kPurple.withOpacity(0.5), width: 1.5),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: _kPurple, size: 18),
          const SizedBox(width: 8),
          Text(label, style: GoogleFonts.inriaSerif(
            fontSize: 15, fontWeight: FontWeight.w700, color: _kPurple)),
        ]),
      ),
    );

  Widget _waveStep(String num, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 20, height: 20, alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFF1A73E8),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(num, style: GoogleFonts.inriaSerif(
            color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11)),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: GoogleFonts.inriaSerif(
          fontSize: 12, color: Colors.grey.shade700, height: 1.4))),
      ]),
    );
  }

  // ── Steps ─────────────────────────────────────────────────────────────────

  Widget _buildStep1() => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Choisissez le montant', style: GoogleFonts.inriaSerif(
        fontSize: 17, fontWeight: FontWeight.w800, color: const Color(0xFF1C1C1E))),
      const SizedBox(height: 4),
      Text('Montant que la personne pourra dépenser en boutique',
        style: GoogleFonts.inriaSerif(fontSize: 13, color: Colors.grey.shade600)),
      const SizedBox(height: 20),

      GridView.count(
        crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10,
        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.9,
        children: [
          ..._presets.map((a) {
            final sel = !_isCustom && _selectedAmount == a;
            return GestureDetector(
              onTap: () => setState(() { _selectedAmount = a; _isCustom = false; _customCtrl.clear(); }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: sel ? _kPurple : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: sel ? _kPurple : Colors.grey.shade300,
                    width: sel ? 2 : 1.2),
                  boxShadow: [BoxShadow(
                    color: sel ? _kPurple.withOpacity(0.25) : Colors.black.withOpacity(0.04),
                    blurRadius: sel ? 10 : 4)],
                ),
                child: Center(child: Text(_fmt(a), style: GoogleFonts.inriaSerif(
                  fontSize: 13, fontWeight: FontWeight.w800,
                  color: sel ? Colors.white : const Color(0xFF1C1C1E)))),
              ),
            );
          }),
          GestureDetector(
            onTap: () => setState(() { _isCustom = true; _selectedAmount = null; }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: _isCustom ? _kPurpleLight : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isCustom ? _kPurpleLight : Colors.grey.shade300,
                  width: _isCustom ? 2 : 1.2),
              ),
              child: Center(child: Text('Autre', style: GoogleFonts.inriaSerif(
                fontSize: 13, fontWeight: FontWeight.w800,
                color: _isCustom ? Colors.white : Colors.grey.shade600))),
            ),
          ),
        ],
      ),

      AnimatedSize(
        duration: const Duration(milliseconds: 200),
        child: _isCustom ? Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Montant personnalisé (F)', style: GoogleFonts.inriaSerif(
              fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1C1C1E))),
            const SizedBox(height: 6),
            TextField(
              controller: _customCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() {}),
              style: GoogleFonts.inriaSerif(
                fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF0D0D0D)),
              decoration: InputDecoration(
                hintText: 'Ex: 20 000',
                hintStyle: GoogleFonts.inriaSerif(fontSize: 14, color: Colors.grey.shade500),
                filled: true, fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade400, width: 1.2)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: _kPurple, width: 2)),
              ),
            ),
          ]),
        ) : const SizedBox.shrink(),
      ),

      if (_amount > 0) ...[
        const SizedBox(height: 24),
        Center(child: Column(children: [
          Text('Montant sélectionné',
            style: GoogleFonts.inriaSerif(fontSize: 13, color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          Text(_fmt(_amount), style: GoogleFonts.inriaSerif(
            fontSize: 34, fontWeight: FontWeight.w900, color: _kPurple)),
        ])),
      ],

      const SizedBox(height: 28),
      _primaryBtn('Suivant', FontAwesomeIcons.arrowRight,
        () { if (_validateStep1()) _goTo(1); }),
    ]),
  );

  Widget _buildStep2() => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Vos informations', style: GoogleFonts.inriaSerif(
        fontSize: 17, fontWeight: FontWeight.w800, color: const Color(0xFF1C1C1E))),
      const SizedBox(height: 4),
      Text('Le bénéficiaire saura que c\'est vous qui offrez',
        style: GoogleFonts.inriaSerif(fontSize: 13, color: Colors.grey.shade600)),
      const SizedBox(height: 20),
      _field(ctrl: _senderNameCtrl, label: 'Votre nom', hint: 'Ex: Jean Kouassi'),
      _field(ctrl: _senderPhoneCtrl, label: 'Votre téléphone', hint: '07 XX XX XX XX',
        kb: TextInputType.phone, fmt: [FilteringTextInputFormatter.digitsOnly]),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: _outlineBtn('Retour', FontAwesomeIcons.arrowLeft, () => _goTo(0))),
        const SizedBox(width: 12),
        Expanded(child: _primaryBtn('Suivant', FontAwesomeIcons.arrowRight,
          () { if (_validateStep2()) _goTo(2); })),
      ]),
    ]),
  );

  Widget _buildStep3() => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Le bénéficiaire', style: GoogleFonts.inriaSerif(
        fontSize: 17, fontWeight: FontWeight.w800, color: const Color(0xFF1C1C1E))),
      const SizedBox(height: 4),
      Text('La personne qui recevra la carte cadeau',
        style: GoogleFonts.inriaSerif(fontSize: 13, color: Colors.grey.shade600)),
      const SizedBox(height: 20),
      _field(ctrl: _recipientNameCtrl, label: 'Nom du bénéficiaire', hint: 'Ex: Marie Koné'),
      _field(ctrl: _recipientPhoneCtrl, label: 'Téléphone du bénéficiaire',
        hint: '07 XX XX XX XX', kb: TextInputType.phone,
        fmt: [FilteringTextInputFormatter.digitsOnly]),
      _field(ctrl: _messageCtrl, label: 'Message', optional: true,
        hint: 'Ex: Joyeux anniversaire ! 🎉', maxLines: 3),

      // Récapitulatif montant
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _kPurple.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kPurple.withOpacity(0.2)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: _kPurple, borderRadius: BorderRadius.circular(10)),
              child: const FaIcon(FontAwesomeIcons.creditCard, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("Carte d'achat", style: GoogleFonts.inriaSerif(
                fontSize: 13, fontWeight: FontWeight.w800, color: _kPurple)),
              Text(_fmt(_amount), style: GoogleFonts.inriaSerif(
                fontSize: 20, fontWeight: FontWeight.w900, color: _kPurple)),
            ]),
          ]),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(8)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              FaIcon(FontAwesomeIcons.circleInfo, color: _kPurple.withOpacity(0.7), size: 15),
              const SizedBox(width: 8),
              Expanded(child: Text(
                'Le bénéficiaire recevra un code par WhatsApp pour dépenser ce montant en boutique.',
                style: GoogleFonts.inriaSerif(fontSize: 12, color: Colors.grey.shade700, height: 1.5))),
            ]),
          ),
        ]),
      ),

      const SizedBox(height: 16),

      // ── Bannière si Wave non configuré ──────────────────────────────────
      if (!_hasWaveLink) ...[
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red.shade500, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(
              'Cette boutique n\'a pas de lien Wave configuré. Le paiement par carte cadeau n\'est pas disponible.',
              style: GoogleFonts.inriaSerif(fontSize: 13, color: Colors.red.shade700, height: 1.4),
            )),
          ]),
        ),
        const SizedBox(height: 16),
      ],

      // ── Étape Wave ──────────────────────────────────────────────────────
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A73E8).withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF1A73E8).withOpacity(0.25)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Titre
          Row(children: [
            Image.asset(
              'lib/core/assets/WAVE.png',
              width: 22, height: 22, fit: BoxFit.contain,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.waves_rounded, color: Color(0xFF1A73E8), size: 20),
            ),
            const SizedBox(width: 8),
            Text('Paiement Wave', style: GoogleFonts.inriaSerif(
              fontSize: 14, fontWeight: FontWeight.w800,
              color: const Color(0xFF1A73E8))),
          ]),
          const SizedBox(height: 12),

          // Instructions étapes
          _waveStep('1', 'Appuyez sur le bouton ci-dessous pour ouvrir Wave'),
          _waveStep('2', 'Effectuez le paiement de ${_fmt(_amount)}'),
          _waveStep('3', 'Prenez une capture d\'écran de la confirmation'),
          _waveStep('4', 'Revenez ici et uploadez la capture'),

          const SizedBox(height: 14),

          // Bouton ouvrir Wave
          GestureDetector(
            onTap: _hasWaveLink ? _openWave : null,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF1A73E8),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(
                  color: const Color(0xFF1A73E8).withOpacity(0.35),
                  blurRadius: 10, offset: const Offset(0, 3))],
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Image.asset(
                  'lib/core/assets/WAVE.png',
                  width: 28, height: 28,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.waves_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 10),
                Text('Payer ${_fmt(_amount)} avec Wave',
                  style: GoogleFonts.inriaSerif(
                    fontSize: 14, fontWeight: FontWeight.w800,
                    color: Colors.white)),
              ]),
            ),
          ),
        ]),
      ),

      const SizedBox(height: 16),

      // Capture Wave
      Text('Capture de paiement Wave', style: GoogleFonts.inriaSerif(
        fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1C1C1E))),
      const SizedBox(height: 4),
      Text('Après paiement, uploadez la capture Wave ci-dessous',
        style: GoogleFonts.inriaSerif(fontSize: 12, color: Colors.grey.shade600)),
      const SizedBox(height: 10),
      GestureDetector(
        onTap: _pickScreenshot,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 22),
          decoration: BoxDecoration(
            color: _waveScreenshotPath != null
                ? Colors.green.shade50
                : const Color(0xFF1A73E8).withOpacity(0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _waveScreenshotPath != null
                  ? Colors.green.shade400
                  : const Color(0xFF1A73E8).withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(
              _waveScreenshotPath != null
                  ? FontAwesomeIcons.circleCheck
                  : FontAwesomeIcons.upload,
              color: _waveScreenshotPath != null
                  ? Colors.green.shade500
                  : const Color(0xFF1A73E8).withOpacity(0.6),
              size: 30),
            const SizedBox(height: 6),
            Text(
              _waveScreenshotPath != null ? 'Capture ajoutée ✓' : 'Ajouter la capture Wave',
              style: GoogleFonts.inriaSerif(
                fontSize: 13, fontWeight: FontWeight.w700,
                color: _waveScreenshotPath != null
                    ? Colors.green.shade600 : const Color(0xFF1A73E8))),
            Text(
              _waveScreenshotPath != null ? 'Appuyer pour changer' : 'Appuyez pour importer',
              style: GoogleFonts.inriaSerif(fontSize: 11, color: Colors.grey.shade500)),
          ]),
        ),
      ),

      const SizedBox(height: 24),
      Row(children: [
        Expanded(child: _outlineBtn('Retour', FontAwesomeIcons.arrowLeft, () => _goTo(1))),
        const SizedBox(width: 12),
        Expanded(child: _isLoading
            ? Container(
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(child: SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))),
              )
            : _primaryBtn('Envoyer', FontAwesomeIcons.paperPlane,
                _hasWaveLink ? _submit : () => _err('Paiement Wave non disponible pour cette boutique.'))),
      ]),
    ]),
  );

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: Column(children: [
        // Header purple
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_kPurple, _kPurpleLight],
              begin: Alignment.centerLeft, end: Alignment.centerRight),
          ),
          padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 10, 16, 16),
          child: Column(children: [
            Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 36, height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10)),
                  child: const FaIcon(FontAwesomeIcons.arrowLeft, color: Colors.white, size: 18),
                ),
              ),
              const SizedBox(width: 12),
              const FaIcon(FontAwesomeIcons.creditCard, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text("Carte d'achat", style: GoogleFonts.inriaSerif(
                fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
            ]),
            const SizedBox(height: 12),
            _dots(),
            const SizedBox(height: 6),
            Text(
              ['Choisir le montant', 'Vos informations', 'Le bénéficiaire'][_step],
              style: GoogleFonts.inriaSerif(
                fontSize: 13, color: Colors.white.withOpacity(0.85), fontWeight: FontWeight.w600)),
          ]),
        ),

        // Pages
        Expanded(
          child: PageView(
            controller: _pageCtrl,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (i) => setState(() => _step = i),
            children: [_buildStep1(), _buildStep2(), _buildStep3()],
          ),
        ),
      ]),
    );
  }

}
