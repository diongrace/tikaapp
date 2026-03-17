import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/gift_service.dart';
import '../../../services/models/gift_model.dart';

const Color _kPink = Color(0xFFE91E8C);
const Color _kPinkLight = Color(0xFFFF5252);

class GiftOrderTrackScreen extends StatefulWidget {
  final String? initialToken;
  const GiftOrderTrackScreen({super.key, this.initialToken});

  static Future<void> show(BuildContext context, {String? token}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (_) => GiftOrderTrackScreen(initialToken: token),
    );
  }

  @override
  State<GiftOrderTrackScreen> createState() => _GiftOrderTrackScreenState();
}

class _GiftOrderTrackScreenState extends State<GiftOrderTrackScreen> {
  final _tokenCtrl = TextEditingController();
  GiftTrackData? _data;
  bool _isLoading = false;
  String? _error;

  // Yango dialog
  final _yangoCtrl = TextEditingController();
  bool _isConfirmingYango = false;
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialToken != null) {
      _tokenCtrl.text = widget.initialToken!;
      WidgetsBinding.instance.addPostFrameCallback((_) => _track());
    }
  }

  @override
  void dispose() {
    _tokenCtrl.dispose();
    _yangoCtrl.dispose();
    super.dispose();
  }

  Future<void> _track() async {
    final token = _tokenCtrl.text.trim().toUpperCase();
    if (token.isEmpty) return;
    setState(() { _isLoading = true; _error = null; _data = null; });
    try {
      final data = await GiftService.trackGiftOrder(token);
      setState(() { _data = data; _isLoading = false; });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _confirmYango() async {
    final yangoId = _yangoCtrl.text.trim();
    if (yangoId.isEmpty) return;
    setState(() => _isConfirmingYango = true);
    try {
      await GiftService.confirmYangoOrder(
        trackingToken: _data!.trackingToken,
        yangoOrderId: yangoId,
      );
      if (!mounted) return;
      Navigator.pop(context); // close dialog
      _track(); // refresh
      _showMsg('Confirmé', 'La commande Yango a été confirmée. Le bénéficiaire sera notifié.');
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _showMsg('Erreur', e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isConfirmingYango = false);
    }
  }

  Future<void> _cancel() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Annuler la commande ?',
            style: GoogleFonts.inriaSerif(fontWeight: FontWeight.w800)),
        content: Text(
          'Cette action est irréversible. Confirmer l\'annulation ?',
          style: GoogleFonts.inriaSerif(fontSize: 13, color: Colors.grey.shade700),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Non', style: GoogleFonts.inriaSerif(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Oui, annuler',
                style: GoogleFonts.inriaSerif(color: Colors.red.shade600, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _isCancelling = true);
    try {
      await GiftService.cancelGiftOrder(_data!.id ?? 0);
      if (!mounted) return;
      _track();
    } catch (e) {
      if (!mounted) return;
      _showMsg('Erreur', e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isCancelling = false);
    }
  }

  void _showYangoDialog() {
    _yangoCtrl.clear();
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          const Icon(Icons.local_taxi_rounded, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(child: Text('Confirmer Yango',
              style: GoogleFonts.inriaSerif(fontWeight: FontWeight.w800))),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Entrez l\'ID de la commande Yango que vous avez passée.',
              style: GoogleFonts.inriaSerif(fontSize: 13, color: Colors.grey.shade700)),
          const SizedBox(height: 12),
          TextField(
            controller: _yangoCtrl,
            decoration: InputDecoration(
              labelText: 'ID Yango (ex: YANGO-123456)',
              labelStyle: GoogleFonts.inriaSerif(fontSize: 13),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.orange, width: 2),
              ),
            ),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler', style: GoogleFonts.inriaSerif(color: Colors.grey)),
          ),
          GestureDetector(
            onTap: _isConfirmingYango ? null : _confirmYango,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(10),
              ),
              child: _isConfirmingYango
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('Confirmer', style: GoogleFonts.inriaSerif(
                      color: Colors.white, fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      )),
    );
  }

  void _showMsg(String title, String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: GoogleFonts.inriaSerif(fontWeight: FontWeight.w800)),
        content: Text(msg, style: GoogleFonts.inriaSerif(fontSize: 13, color: Colors.grey.shade700)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: GoogleFonts.inriaSerif(color: _kPink)),
          ),
        ],
      ),
    );
  }

  // ── Status colors ──────────────────────────────────────────────────────────

  Color _statusColor(String status) {
    switch (status) {
      case 'pending_payment': return Colors.orange;
      case 'paid': return Colors.blue;
      case 'preparing': return Colors.purple;
      case 'ready': return Colors.teal;
      case 'delivery_pending': return Colors.deepOrange;
      case 'delivering': return Colors.indigo;
      case 'delivered': return const Color(0xFF16A34A);
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'pending_payment': return Icons.hourglass_top_rounded;
      case 'paid': return Icons.check_circle_outline_rounded;
      case 'preparing': return Icons.restaurant_rounded;
      case 'ready': return Icons.done_all_rounded;
      case 'delivery_pending': return Icons.local_taxi_rounded;
      case 'delivering': return Icons.delivery_dining_rounded;
      case 'delivered': return Icons.check_circle_rounded;
      case 'cancelled': return Icons.cancel_rounded;
      default: return Icons.info_outline_rounded;
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    return Container(
      height: screenH * 0.92,
      decoration: const BoxDecoration(
        color: Color(0xFFF2F2F7),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(children: [
        // Handle
        Container(
          width: 40, height: 4,
          margin: const EdgeInsets.only(top: 12, bottom: 0),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        // Header
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_kPink, _kPinkLight],
              begin: Alignment.centerLeft, end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
          child: Row(children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 36, height: 36, alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
              ),
            ),
            const SizedBox(width: 12),
            const FaIcon(FontAwesomeIcons.gift, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('Suivi cadeau', style: GoogleFonts.inriaSerif(
              fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
          ]),
        ),
        // Search bar
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _tokenCtrl,
                textCapitalization: TextCapitalization.characters,
                style: GoogleFonts.inriaSerif(fontSize: 15, fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  hintText: 'GFT-XXXXXX',
                  hintStyle: GoogleFonts.inriaSerif(color: Colors.grey.shade500),
                  filled: true,
                  fillColor: const Color(0xFFF2F2F7),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _track(),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _isLoading ? null : _track,
              child: Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_kPink, _kPinkLight]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _isLoading
                    ? const Center(child: SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
                    : const Icon(Icons.search_rounded, color: Colors.white),
              ),
            ),
          ]),
        ),
        Expanded(child: _buildBody()),
      ]),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _kPink));
    }

    if (_error != null) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const FaIcon(FontAwesomeIcons.triangleExclamation, color: Colors.orange, size: 40),
          const SizedBox(height: 16),
          Text(_error!, textAlign: TextAlign.center,
              style: GoogleFonts.inriaSerif(fontSize: 14, color: Colors.grey.shade700)),
        ]),
      ));
    }

    if (_data == null) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const FaIcon(FontAwesomeIcons.gift, color: Color(0xFFE91E8C), size: 48),
        const SizedBox(height: 16),
        Text('Entrez votre numéro de suivi', style: GoogleFonts.inriaSerif(
          fontSize: 15, color: Colors.grey.shade600)),
        const SizedBox(height: 4),
        Text('Format: GFT-XXXXXX', style: GoogleFonts.inriaSerif(
          fontSize: 13, color: Colors.grey.shade500)),
      ]));
    }

    final d = _data!;
    final statusColor = _statusColor(d.status);
    final canCancel = ['pending_payment', 'paid'].contains(d.status);
    final canConfirmYango = d.status == 'delivery_pending' && d.requiresYangoOrder;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Status card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: statusColor.withOpacity(0.3)),
          ),
          child: Row(children: [
            Container(
              width: 52, height: 52, alignment: Alignment.center,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(_statusIcon(d.status), color: statusColor, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(d.statusLabel, style: GoogleFonts.inriaSerif(
                fontSize: 18, fontWeight: FontWeight.w900, color: statusColor)),
              Text(d.trackingToken, style: GoogleFonts.inriaSerif(
                fontSize: 13, color: Colors.grey.shade600)),
            ])),
            GestureDetector(
              onTap: () => Clipboard.setData(ClipboardData(text: d.trackingToken)),
              child: const Icon(Icons.copy_rounded, size: 18, color: _kPink),
            ),
          ]),
        ),
        const SizedBox(height: 12),

        // Yango banner
        if (canConfirmYango) ...[
          GestureDetector(
            onTap: _showYangoDialog,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.orange.shade300),
              ),
              child: Row(children: [
                const Icon(Icons.local_taxi_rounded, color: Colors.orange, size: 22),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Action requise — Yango', style: GoogleFonts.inriaSerif(
                    fontSize: 14, fontWeight: FontWeight.w800, color: Colors.orange.shade800)),
                  Text('Commandez Yango pour la livraison, puis confirmez ici.',
                    style: GoogleFonts.inriaSerif(fontSize: 12, color: Colors.orange.shade700)),
                ])),
                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.orange, size: 16),
              ]),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Yango info
        if (d.requiresYangoOrder && d.yangoInfo != null) ...[
          _infoCard(
            icon: Icons.local_taxi_rounded,
            color: Colors.orange,
            title: 'Infos livraison Yango',
            children: [
              if (d.yangoInfo!['pickup_address'] != null)
                _infoRow('Départ', d.yangoInfo!['pickup_address']),
              if (d.yangoInfo!['pickup_street'] != null)
                _infoRow('Rue départ', d.yangoInfo!['pickup_street']),
              if (d.yangoInfo!['delivery_address'] != null)
                _infoRow('Destination', d.yangoInfo!['delivery_address']),
            ],
          ),
          const SizedBox(height: 12),
        ],

        // Sender / recipient
        _infoCard(
          icon: FontAwesomeIcons.gift,
          color: _kPink,
          title: 'Cadeau',
          children: [
            _infoRow('De', d.senderName),
            _infoRow('Pour', d.recipientName),
            if (d.giftMessage != null && d.giftMessage!.isNotEmpty)
              _infoRow('Message', d.giftMessage!),
            if (d.deliveryType != null)
              _infoRow('Livraison', d.deliveryType == 'personal' ? 'Livreur du restaurant' : 'Yango'),
          ],
        ),
        const SizedBox(height: 12),

        // Shop
        if (d.shopName != null) ...[
          _infoCard(
            icon: FontAwesomeIcons.store,
            color: Colors.teal,
            title: 'Boutique',
            children: [
              _infoRow('Nom', d.shopName!),
              if (d.shopAddress != null) _infoRow('Adresse', d.shopAddress!),
            ],
          ),
          const SizedBox(height: 12),
        ],

        // Items
        if (d.items.isNotEmpty) ...[
          _infoCard(
            icon: FontAwesomeIcons.bagShopping,
            color: Colors.indigo,
            title: 'Articles',
            children: d.items.map((item) {
              final name = item['name'] ?? '';
              final qty = item['quantity'] ?? 1;
              final price = item['price'] is num ? (item['price'] as num).toInt() : 0;
              return _infoRow('$name × $qty', '${price * qty} FCFA');
            }).toList()
              ..add(_infoRow('Total', '${d.totalAmount ?? 0} FCFA', bold: true)),
          ),
          const SizedBox(height: 12),
        ],

        // Cancel button
        if (canCancel) ...[
          const SizedBox(height: 4),
          GestureDetector(
            onTap: _isCancelling ? null : _cancel,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: _isCancelling
                  ? const Center(child: SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(color: Colors.red, strokeWidth: 2)))
                  : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.cancel_outlined, color: Colors.red.shade500, size: 18),
                      const SizedBox(width: 8),
                      Text('Annuler la commande', style: GoogleFonts.inriaSerif(
                        color: Colors.red.shade600, fontWeight: FontWeight.w700, fontSize: 14)),
                    ]),
            ),
          ),
        ],

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _infoCard({
    required IconData icon,
    required Color color,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          child: Row(children: [
            Container(
              width: 24, height: 24, alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(7),
              ),
              child: FaIcon(icon, color: color, size: 13),
            ),
            const SizedBox(width: 8),
            Text(title, style: GoogleFonts.inriaSerif(
              fontSize: 13, fontWeight: FontWeight.w800, color: const Color(0xFF1C1C1E))),
          ]),
        ),
        Divider(height: 1, color: Colors.grey.shade100),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(children: children),
        ),
      ]),
    );
  }

  Widget _infoRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          width: 100,
          child: Text(label, style: GoogleFonts.inriaSerif(
            fontSize: 13, color: Colors.grey.shade600)),
        ),
        Expanded(child: Text(value, style: GoogleFonts.inriaSerif(
          fontSize: 13,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
          color: const Color(0xFF1C1C1E)))),
      ]),
    );
  }
}
