import 'dart:io';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../panier/cart_manager.dart';
import '../../../services/models/shop_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/gift_service.dart';
class OfferProductScreen extends StatefulWidget {
  final Shop? currentShop;
  const OfferProductScreen({super.key, this.currentShop});

  static Future<void> show(BuildContext context, {Shop? currentShop}) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OfferProductScreen(currentShop: currentShop),
      ),
    );
  }

  @override
  State<OfferProductScreen> createState() => _OfferProductScreenState();
}

class _OfferProductScreenState extends State<OfferProductScreen> {
  static const Color _kPink = Color(0xFFE91E8C);
  static const Color _kPinkLight = Color(0xFFFF6BB5);

  final _formKey = GlobalKey<FormState>();
  final CartManager _cart = CartManager();

  final _senderNameCtrl    = TextEditingController();
  final _senderPhoneCtrl   = TextEditingController();
  final _recipientNameCtrl = TextEditingController();
  final _recipientPhoneCtrl= TextEditingController();
  final _messageCtrl       = TextEditingController();
  final _addressCtrl       = TextEditingController();

  bool _isLoading = false;
  String _paymentMode = 'especes';

  // Zone de livraison sélectionnée (si le shop a des zones configurées)
  DeliveryZone? _selectedZone;

  // Wave flow state
  bool _showWaveUpload = false;
  String? _pendingId;
  int? _waveTotalAmount;
  String? _waveScreenshotPath;

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
    _senderNameCtrl.dispose();
    _senderPhoneCtrl.dispose();
    _recipientNameCtrl.dispose();
    _recipientPhoneCtrl.dispose();
    _messageCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  String _fmt(int price) {
    final s = price.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return '${buf.toString()} F';
  }

  List<Map<String, dynamic>> _buildGiftItems() {
    return _cart.items.map((item) {
      return {
        'type': item['type'] ?? 'product',
        'id': item['id'],
        'quantity': item['quantity'],
        if (item['portion_id'] != null) 'portion_id': item['portion_id'],
        if (item['supplement_ids'] != null) 'supplement_ids': item['supplement_ids'],
        if (item['boisson_id'] != null) 'boisson_id': item['boisson_id'],
      };
    }).toList();
  }

  Future<void> _submit() async {
    if (_cart.items.isEmpty) {
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
              child: FaIcon(FontAwesomeIcons.cartShopping,
                  color: Colors.red.shade400, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text('Panier vide',
                style: GoogleFonts.inriaSerif(
                    fontWeight: FontWeight.w800, fontSize: 16))),
          ]),
          content: Text(
            'Veuillez d\'abord sélectionner un produit dans la boutique avant d\'offrir un cadeau.',
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
                      colors: [_kPink, _kPinkLight]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('Compris', textAlign: TextAlign.center,
                    style: GoogleFonts.inriaSerif(
                        color: Colors.white, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    // Validate zone selection when shop has delivery zones
    final zones = widget.currentShop?.deliveryZones?.where((z) => z.isActive).toList();
    if (zones != null && zones.isNotEmpty && _selectedZone == null) {
      _showDialog('Zone requise', 'Veuillez sélectionner une zone de livraison.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await GiftService.createGiftOrder(
        shopId: widget.currentShop?.id ?? 0,
        senderName: _senderNameCtrl.text.trim(),
        senderPhone: _senderPhoneCtrl.text.trim(),
        recipientName: _recipientNameCtrl.text.trim(),
        recipientPhone: _recipientPhoneCtrl.text.trim(),
        items: _buildGiftItems(),
        paymentMethod: _paymentMode,
        deliveryAddress: _selectedZone != null
            ? '${_selectedZone!.name} — ${_addressCtrl.text.trim()}'
            : _addressCtrl.text.trim(),
        giftMessage: _messageCtrl.text.trim().isEmpty
            ? null
            : _messageCtrl.text.trim(),
        customerUserId: AuthService.currentClient?.id,
      );

      if (!mounted) return;

      if (result.waveRedirect && result.waveUrl != null) {
        // Wave : stocker pending_id, afficher vue upload, ouvrir Wave
        setState(() {
          _isLoading = false;
          _pendingId = result.pendingId;
          _waveTotalAmount = result.totalAmount;
          _showWaveUpload = true;
        });
        _openWaveUrl(result.waveUrl!);
      } else {
        // Espèces : commande créée immédiatement
        setState(() => _isLoading = false);
        _showSuccessDialog(
          trackingToken: result.trackingToken ?? '',
          totalAmount: result.totalAmount ?? _cart.totalPrice,
          deliveryType: result.deliveryType,
          requiresYango: result.requiresYangoOrder,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showDialog('Erreur', e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: GoogleFonts.inriaSerif(
            fontWeight: FontWeight.w800, fontSize: 16)),
        content: Text(message, style: GoogleFonts.inriaSerif(
            fontSize: 13, color: Colors.grey.shade700, height: 1.5)),
        actions: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [_kPink, _kPinkLight]),
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

  // ── Wave flow methods ──────────────────────────────────────────────────────

  Future<void> _openWaveUrl(String url) async {
    // Injecter le montant dans l'URL pour que Wave pré-remplisse le champ
    String urlToOpen = url;
    if (_waveTotalAmount != null) {
      final uri = Uri.tryParse(url);
      if (uri != null && !uri.queryParameters.containsKey('amount')) {
        urlToOpen = uri.replace(queryParameters: {
          ...uri.queryParameters,
          'amount': _waveTotalAmount.toString(),
        }).toString();
      }
    }

    final uri = Uri.parse(urlToOpen);
    try {
      await launchUrl(uri, mode: LaunchMode.externalNonBrowserApplication);
    } catch (_) {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showDialog('Wave introuvable', 'Impossible d\'ouvrir Wave. Vérifiez que l\'application est installée.');
      }
    }
  }

  Future<void> _pickScreenshot() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (picked == null) return;
    // Vérification taille max 5 Mo
    final fileSize = await File(picked.path).length();
    if (fileSize > 5 * 1024 * 1024) {
      _showDialog('Fichier trop lourd', 'La capture ne doit pas dépasser 5 Mo. Veuillez en choisir une autre.');
      return;
    }
    setState(() => _waveScreenshotPath = picked.path);
  }

  Future<void> _submitWaveProof() async {
    if (_waveScreenshotPath == null) {
      _showDialog('Capture manquante', 'Veuillez uploader la capture d\'écran Wave avant de continuer.');
      return;
    }
    if (_pendingId == null) {
      _showDialog('Erreur', 'Identifiant de commande manquant. Veuillez recommencer.');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final result = await GiftService.validateWavePending(
        pendingId: _pendingId!,
        screenshotPath: _waveScreenshotPath!,
      );
      if (!mounted) return;
      setState(() { _isLoading = false; _showWaveUpload = false; });
      _showSuccessDialog(
        trackingToken: result.trackingToken ?? '',
        totalAmount: result.totalAmount ?? _waveTotalAmount ?? _cart.totalPrice,
        deliveryType: result.deliveryType,
        requiresYango: result.requiresYangoOrder,
      );
    } on GiftValidationException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showValidationError(e.message, e.details);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showDialog('Erreur', e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _showValidationError(String message, List<String> details) {
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
            const SizedBox(height: 12),
            Text('Veuillez uploader une nouvelle capture.',
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
                color: _kPink, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog({
    required String trackingToken,
    required int totalAmount,
    String? deliveryType,
    bool requiresYango = false,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Container(
            width: 40, height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [_kPink, _kPinkLight]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const FaIcon(FontAwesomeIcons.gift, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text('Cadeau envoyé !',
              style: GoogleFonts.inriaSerif(fontWeight: FontWeight.w800, fontSize: 16))),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Votre commande cadeau a été créée avec succès.',
                style: GoogleFonts.inriaSerif(fontSize: 13, color: Colors.grey.shade700)),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0F5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kPink.withOpacity(0.3)),
              ),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Total', style: GoogleFonts.inriaSerif(
                      fontSize: 13, color: Colors.grey.shade600)),
                  Text(_fmt(totalAmount), style: GoogleFonts.inriaSerif(
                      fontSize: 15, fontWeight: FontWeight.w800, color: _kPink)),
                ]),
                if (trackingToken.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Numéro de suivi',
                          style: GoogleFonts.inriaSerif(fontSize: 12, color: Colors.grey.shade600)),
                      Text(trackingToken, style: GoogleFonts.inriaSerif(
                          fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF1C1C1E))),
                    ])),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: trackingToken));
                        Navigator.pop(context);
                        _showDialog('Copié !', 'Numéro de suivi copié dans le presse-papiers.');
                      },
                      child: Icon(Icons.copy_rounded, size: 18, color: _kPink),
                    ),
                  ]),
                ],
              ]),
            ),
            if (requiresYango) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.local_taxi_rounded, color: Colors.orange, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(
                    'La boutique n\'a pas de livreur. Vous devrez commander Yango pour la livraison une fois la commande prête.',
                    style: GoogleFonts.inriaSerif(fontSize: 12, color: Colors.orange.shade800),
                  )),
                ]),
              ),
            ],
          ],
        ),
        actions: [
          GestureDetector(
            onTap: () {
              Navigator.pop(context); // dialog
              Navigator.pop(context); // page
              _cart.clear();
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [_kPink, _kPinkLight]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('Fermer', textAlign: TextAlign.center,
                style: GoogleFonts.inriaSerif(
                    color: Colors.white, fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }

  // ── helpers ──────────────────────────────────────────────────────────────

  Widget _field({
    required TextEditingController ctrl,
    required String label,
    String? hint,
    bool optional = false,
    int maxLines = 1,
    TextInputType kb = TextInputType.text,
    List<TextInputFormatter>? fmt,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label + (optional ? ' (optionnel)' : ''),
            style: GoogleFonts.inriaSerif(
              fontSize: 14, fontWeight: FontWeight.w700,
              color: const Color(0xFF1C1C1E),
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: ctrl,
            maxLines: maxLines,
            keyboardType: kb,
            inputFormatters: fmt,
            style: GoogleFonts.inriaSerif(
              fontSize: 15, fontWeight: FontWeight.w600,
              color: const Color(0xFF0D0D0D),
            ),
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
                borderSide: BorderSide(color: _kPink, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.red.shade400),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.red.shade600, width: 2),
              ),
            ),
            validator: validator ??
                (optional ? null : (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required int number,
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9FB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                Container(
                  width: 26, height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [_kPink, _kPinkLight]),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text('$number',
                    style: GoogleFonts.inriaSerif(
                      color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                ),
                const SizedBox(width: 8),
                Icon(icon, color: _kPink, size: 18),
                const SizedBox(width: 6),
                Text(title,
                  style: GoogleFonts.inriaSerif(
                    fontSize: 14, fontWeight: FontWeight.w800,
                    color: const Color(0xFF1C1C1E),
                  )),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          Padding(padding: const EdgeInsets.all(14), child: child),
        ],
      ),
    );
  }

  Widget _buildCartSection() {
    final items = _cart.items;
    return _sectionCard(
      number: 1, title: 'Produits à offrir', icon: FontAwesomeIcons.bagShopping,
      child: items.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(children: [
                  FaIcon(FontAwesomeIcons.cartShopping, color: Colors.grey.shade400, size: 36),
                  const SizedBox(height: 6),
                  Text('Panier vide — ajoutez des produits',
                    style: GoogleFonts.inriaSerif(fontSize: 13, color: Colors.grey.shade500)),
                ]),
              ),
            )
          : Column(children: [
              ...items.map((item) {
                final name = item['name']?.toString() ?? 'Produit';
                final p = item['price']; final q = item['quantity'];
                final pi = p is int ? p : (p is num ? p.toInt() : int.tryParse(p?.toString() ?? '0') ?? 0);
                final qi = q is int ? q : (q is num ? q.toInt() : int.tryParse(q?.toString() ?? '0') ?? 0);
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(children: [
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: GoogleFonts.inriaSerif(
                          fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF1C1C1E))),
                        Text('Qté: $qi', style: GoogleFonts.inriaSerif(
                          fontSize: 12, color: Colors.grey.shade600)),
                      ],
                    )),
                    Text(_fmt(pi * qi), style: GoogleFonts.inriaSerif(
                      fontSize: 13, fontWeight: FontWeight.w800, color: _kPink)),
                  ]),
                );
              }),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_kPink.withOpacity(0.08), _kPinkLight.withOpacity(0.05)]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Sous-total', style: GoogleFonts.inriaSerif(
                      fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF1C1C1E))),
                    Text(_fmt(_cart.totalPrice), style: GoogleFonts.inriaSerif(
                      fontSize: 15, fontWeight: FontWeight.w800, color: _kPink)),
                  ],
                ),
              ),
            ]),
    );
  }

  Widget _buildSenderSection() => _sectionCard(
    number: 2, title: 'Vos informations', icon: FontAwesomeIcons.user,
    child: Column(children: [
      _field(ctrl: _senderNameCtrl, label: 'Votre nom', hint: 'Ex: Jean Kouassi'),
      _field(ctrl: _senderPhoneCtrl, label: 'Votre téléphone', hint: '07 XX XX XX XX',
        kb: TextInputType.phone,
        fmt: [FilteringTextInputFormatter.digitsOnly],
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Champ requis';
          if (v.trim().length < 8) return 'Numéro invalide';
          return null;
        }),
    ]),
  );

  Widget _buildRecipientSection() => _sectionCard(
    number: 3, title: 'Le destinataire', icon: FontAwesomeIcons.gift,
    child: Column(children: [
      _field(ctrl: _recipientNameCtrl, label: 'Nom du destinataire', hint: 'Ex: Marie Koné'),
      _field(ctrl: _recipientPhoneCtrl, label: 'Téléphone du destinataire', hint: '07 XX XX XX XX',
        kb: TextInputType.phone,
        fmt: [FilteringTextInputFormatter.digitsOnly],
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Champ requis';
          if (v.trim().length < 8) return 'Numéro invalide';
          return null;
        }),
      _field(ctrl: _messageCtrl, label: 'Petit mot', hint: 'Joyeux anniversaire ! 🎂',
        optional: true, maxLines: 3),
    ]),
  );

  Widget _buildDeliverySection() {
    final zones = widget.currentShop?.deliveryZones
        ?.where((z) => z.isActive)
        .toList();
    final hasZones = zones != null && zones.isNotEmpty;

    return _sectionCard(
      number: 4, title: 'Livraison & paiement', icon: FontAwesomeIcons.truck,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (hasZones) ...[
          Row(children: [
            const Icon(Icons.map_outlined, size: 16, color: Color(0xFF1C1C1E)),
            const SizedBox(width: 6),
            Text('Sélectionnez une zone de livraison', style: GoogleFonts.inriaSerif(
              fontSize: 14, fontWeight: FontWeight.w700,
              color: const Color(0xFF1C1C1E),
            )),
          ]),
          const SizedBox(height: 8),
          ...zones.map((zone) {
            final sel = _selectedZone?.id == zone.id;
            return GestureDetector(
              onTap: () => setState(() => _selectedZone = zone),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: sel ? _kPink.withOpacity(0.07) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: sel ? _kPink : Colors.grey.shade300,
                    width: sel ? 2 : 1.2,
                  ),
                ),
                child: Row(children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 20, height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: sel ? _kPink : Colors.transparent,
                      border: Border.all(
                        color: sel ? _kPink : Colors.grey.shade400,
                        width: 2,
                      ),
                    ),
                    child: sel
                        ? const Icon(Icons.check, color: Colors.white, size: 13)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(zone.name, style: GoogleFonts.inriaSerif(
                        fontSize: 14, fontWeight: FontWeight.w700,
                        color: sel ? _kPink : const Color(0xFF1C1C1E),
                      )),
                      if (zone.estimatedTime != null && zone.estimatedTime!.isNotEmpty)
                        Text(zone.estimatedTime!, style: GoogleFonts.inriaSerif(
                          fontSize: 12, color: Colors.grey.shade500,
                        )),
                    ],
                  )),
                  if (zone.deliveryFee > 0)
                    Text(_fmt(zone.deliveryFee), style: GoogleFonts.inriaSerif(
                      fontSize: 13, fontWeight: FontWeight.w800,
                      color: sel ? _kPink : Colors.grey.shade700,
                    ))
                  else
                    Text('Gratuit', style: GoogleFonts.inriaSerif(
                      fontSize: 13, fontWeight: FontWeight.w700,
                      color: Colors.green.shade600,
                    )),
                ]),
              ),
            );
          }),
          const SizedBox(height: 8),
          _field(ctrl: _addressCtrl, label: 'Adresse complète',
            hint: 'Adresse de livraison pour le bénéficiaire',
            maxLines: 2),
          const SizedBox(height: 4),
        ] else ...[
          _field(ctrl: _addressCtrl, label: 'Adresse de livraison',
            hint: 'Ex: Cocody, Rue des Jardins, Abidjan'),
          const SizedBox(height: 4),
        ],
      Text('Mode de paiement', style: GoogleFonts.inriaSerif(
        fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1C1C1E))),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: _payCard('especes', 'Espèces', const Color(0xFF22C55E),
            iconBuilder: (sel) => FaIcon(FontAwesomeIcons.moneyBill, size: 24,
                color: sel ? const Color(0xFF22C55E) : Colors.grey.shade400))),
        const SizedBox(width: 10),
        Expanded(child: _payCard('mobile_money', 'Wave', const Color(0xFF1A73E8),
            iconBuilder: (sel) => Opacity(
              opacity: sel ? 1.0 : 0.4,
              child: Image.asset('lib/core/assets/WAVE.png', width: 38, height: 28,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(Icons.waves_rounded, size: 24,
                      color: sel ? const Color(0xFF1A73E8) : Colors.grey.shade400)),
            ))),
      ]),
      const SizedBox(height: 14),
      _buildSummary(),
    ]),
    );
  }

  Widget _payCard(String mode, String label, Color color,
      {required Widget Function(bool selected) iconBuilder}) {
    final sel = _paymentMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _paymentMode = mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: sel ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: sel ? color : Colors.grey.shade300, width: sel ? 2 : 1.2),
        ),
        child: Column(children: [
          iconBuilder(sel),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.inriaSerif(
            fontSize: 13, fontWeight: FontWeight.w700,
            color: sel ? color : Colors.grey.shade600)),
        ]),
      ),
    );
  }

  Widget _buildSummary() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          FaIcon(FontAwesomeIcons.receipt, size: 15, color: _kPink),
          const SizedBox(width: 6),
          Text('Récapitulatif', style: GoogleFonts.inriaSerif(
            fontSize: 13, fontWeight: FontWeight.w800, color: const Color(0xFF1C1C1E))),
        ]),
        const SizedBox(height: 10),
        ..._cart.items.map((item) {
          final name = item['name']?.toString() ?? '';
          final p = item['price']; final q = item['quantity'];
          final pi = p is int ? p : (p is num ? p.toInt() : int.tryParse(p?.toString() ?? '0') ?? 0);
          final qi = q is int ? q : (q is num ? q.toInt() : int.tryParse(q?.toString() ?? '0') ?? 0);
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Expanded(child: Text('$name × $qi',
                style: GoogleFonts.inriaSerif(fontSize: 12, color: Colors.grey.shade700),
                overflow: TextOverflow.ellipsis)),
              Text(_fmt(pi * qi), style: GoogleFonts.inriaSerif(
                fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF1C1C1E))),
            ]),
          );
        }),
        const Divider(height: 14),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Total', style: GoogleFonts.inriaSerif(
            fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF1C1C1E))),
          Text(_fmt(_cart.totalPrice), style: GoogleFonts.inriaSerif(
            fontSize: 16, fontWeight: FontWeight.w800, color: _kPink)),
        ]),
      ]),
    );
  }

  // ── Wave upload view ──────────────────────────────────────────────────────

  Widget _step(String num, String text) {
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
            fontSize: 13, color: Colors.grey.shade700))),
      ]),
    );
  }

  Widget _buildWaveUploadView() {
    return Column(children: [
      // Header
      Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A73E8), Color(0xFF0D47A1)],
            begin: Alignment.centerLeft, end: Alignment.centerRight),
        ),
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 18),
        child: Row(children: [
          GestureDetector(
            onTap: () => setState(() {
              _showWaveUpload = false;
              _pendingId = null;
              _waveScreenshotPath = null;
            }),
            child: Container(
              width: 36, height: 36, alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10)),
              child: const FaIcon(FontAwesomeIcons.arrowLeft, color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.waves_rounded, color: Colors.white, size: 22),
          const SizedBox(width: 8),
          Text('Paiement Wave', style: GoogleFonts.inriaSerif(
              fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
        ]),
      ),

      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Instructions
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1A73E8).withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF1A73E8).withOpacity(0.2)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.info_outline_rounded, color: Color(0xFF1A73E8), size: 20),
                  const SizedBox(width: 8),
                  Text('Étapes à suivre', style: GoogleFonts.inriaSerif(
                      fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF1A73E8))),
                ]),
                const SizedBox(height: 10),
                _step('1', 'Vous avez été redirigé vers Wave pour payer'),
                _step('2', 'Revenez ici après le paiement'),
                _step('3', 'Uploadez la capture d\'écran de confirmation'),
              ]),
            ),

            // Rouvrir Wave si nécessaire
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _pendingId != null ? null : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A73E8).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF1A73E8).withOpacity(0.3)),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.waves_rounded, color: Color(0xFF1A73E8), size: 18),
                  const SizedBox(width: 8),
                  Text('Montant : ${_waveTotalAmount != null ? "$_waveTotalAmount F" : "—"}',
                      style: GoogleFonts.inriaSerif(
                          fontSize: 14, fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A73E8))),
                ]),
              ),
            ),

            const SizedBox(height: 16),
            Text('Capture d\'écran Wave', style: GoogleFonts.inriaSerif(
                fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1C1C1E))),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickScreenshot,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
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
                    size: 32),
                  const SizedBox(height: 8),
                  Text(
                    _waveScreenshotPath != null ? 'Capture ajoutée ✓' : 'Appuyer pour importer',
                    style: GoogleFonts.inriaSerif(
                        fontSize: 14, fontWeight: FontWeight.w700,
                        color: _waveScreenshotPath != null
                            ? Colors.green.shade600 : const Color(0xFF1A73E8))),
                  if (_waveScreenshotPath != null)
                    Text('Appuyer pour changer',
                        style: GoogleFonts.inriaSerif(fontSize: 11, color: Colors.grey.shade500)),
                ]),
              ),
            ),
          ]),
        ),
      ),

      // Bouton confirmer
      Container(
        padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08),
              blurRadius: 16, offset: const Offset(0, -4))],
        ),
        child: GestureDetector(
          onTap: _isLoading ? null : _submitWaveProof,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: _isLoading ? Colors.grey.shade300 : const Color(0xFF1A73E8),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [if (!_isLoading) BoxShadow(
                  color: const Color(0xFF1A73E8).withOpacity(0.35),
                  blurRadius: 14, offset: const Offset(0, 4))],
            ),
            child: _isLoading
                ? const Center(child: SizedBox(width: 22, height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
                : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.waves_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Text('Confirmer le paiement Wave', style: GoogleFonts.inriaSerif(
                        fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
                  ]),
          ),
        ),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: _showWaveUpload ? _buildWaveUploadView() : Column(children: [
              // ── Header gradient ─────────────────────────────────
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_kPink, _kPinkLight],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
                padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 10, 16, 18),
                child: Row(children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36, height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const FaIcon(FontAwesomeIcons.arrowLeft, color: Colors.white, size: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('🎁', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Offrir un cadeau',
                    style: GoogleFonts.inriaSerif(
                      fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white))),
                  if (_cart.itemCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const FaIcon(FontAwesomeIcons.bagShopping, color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text('${_cart.itemCount}', style: GoogleFonts.inriaSerif(
                          color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                      ]),
                    ),
                ]),
              ),

              // ── Scrollable form ─────────────────────────────────
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
                    children: [
                      _buildCartSection(),
                      _buildSenderSection(),
                      _buildRecipientSection(),
                      _buildDeliverySection(),
                    ],
                  ),
                ),
              ),

              // ── Submit button ───────────────────────────────────
              Container(
                padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08),
                    blurRadius: 16, offset: const Offset(0, -4))],
                ),
                child: GestureDetector(
                  onTap: _isLoading ? null : _submit,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: _isLoading
                          ? null
                          : LinearGradient(colors: [_kPink, _kPinkLight],
                              begin: Alignment.centerLeft, end: Alignment.centerRight),
                      color: _isLoading ? Colors.grey.shade300 : null,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [if (!_isLoading) BoxShadow(color: _kPink.withOpacity(0.35),
                        blurRadius: 14, offset: const Offset(0, 4))],
                    ),
                    child: _isLoading
                        ? const Center(child: SizedBox(width: 22, height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
                        : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            const FaIcon(FontAwesomeIcons.gift, color: Colors.white, size: 20),
                            const SizedBox(width: 10),
                            Text('Offrir ce cadeau', style: GoogleFonts.inriaSerif(
                              fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                          ]),
                  ),
                ),
              ),
            ]),
    );
  }
}
