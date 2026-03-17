import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/gift_service.dart';
import '../../../services/models/gift_model.dart';

const Color _kPurple = Color(0xFF6B21A8);
const Color _kPurpleLight = Color(0xFF9333EA);

class GiftCardTrackScreen extends StatefulWidget {
  final String? initialToken;
  const GiftCardTrackScreen({super.key, this.initialToken});

  static Future<void> show(BuildContext context, {String? token}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (_) => GiftCardTrackScreen(initialToken: token),
    );
  }

  @override
  State<GiftCardTrackScreen> createState() => _GiftCardTrackScreenState();
}

class _GiftCardTrackScreenState extends State<GiftCardTrackScreen> {
  final _tokenCtrl = TextEditingController();
  GiftCardTrackData? _data;
  bool _isLoading = false;
  String? _error;

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
    super.dispose();
  }

  Future<void> _track() async {
    final token = _tokenCtrl.text.trim().toUpperCase();
    if (token.isEmpty) return;
    setState(() { _isLoading = true; _error = null; _data = null; });
    try {
      final data = await GiftService.trackGiftCard(token);
      setState(() { _data = data; _isLoading = false; });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'active': return const Color(0xFF16A34A);
      case 'partially_used': return Colors.blue;
      case 'exhausted': return Colors.grey;
      case 'expired': return Colors.red;
      case 'cancelled': return Colors.red;
      case 'pending_payment': return Colors.orange;
      default: return Colors.grey;
    }
  }

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
              colors: [_kPurple, _kPurpleLight],
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
            const FaIcon(FontAwesomeIcons.creditCard, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('Suivi carte cadeau', style: GoogleFonts.inriaSerif(
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
                  hintText: 'GCA-XXXXXX',
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
                  gradient: const LinearGradient(colors: [_kPurple, _kPurpleLight]),
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
      return const Center(child: CircularProgressIndicator(color: _kPurple));
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
        const FaIcon(FontAwesomeIcons.creditCard, color: _kPurple, size: 48),
        const SizedBox(height: 16),
        Text('Entrez votre numéro de suivi', style: GoogleFonts.inriaSerif(
          fontSize: 15, color: Colors.grey.shade600)),
        const SizedBox(height: 4),
        Text('Format: GCA-XXXXXX', style: GoogleFonts.inriaSerif(
          fontSize: 13, color: Colors.grey.shade500)),
      ]));
    }

    final d = _data!;
    final statusColor = _statusColor(d.status);
    final balancePct = d.amount > 0 ? (d.balance / d.amount) : 0.0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Card visual
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_kPurple, _kPurpleLight],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(
              color: _kPurple.withOpacity(0.3),
              blurRadius: 20, offset: const Offset(0, 8))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Carte d\'achat', style: GoogleFonts.inriaSerif(
                fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w600)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white30),
                ),
                child: Text(d.statusLabel, style: GoogleFonts.inriaSerif(
                  fontSize: 12, color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ]),
            const SizedBox(height: 16),
            Text('${d.balance} FCFA', style: GoogleFonts.inriaSerif(
              fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white)),
            Text('solde disponible', style: GoogleFonts.inriaSerif(
              fontSize: 12, color: Colors.white60)),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: balancePct.clamp(0.0, 1.0),
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation(Colors.white),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 6),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('0 FCFA', style: GoogleFonts.inriaSerif(fontSize: 11, color: Colors.white60)),
              Text('${d.amount} FCFA', style: GoogleFonts.inriaSerif(fontSize: 11, color: Colors.white60)),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('CODE', style: GoogleFonts.inriaSerif(fontSize: 10, color: Colors.white60,
                  letterSpacing: 1.5)),
                Text(d.code, style: GoogleFonts.inriaSerif(
                  fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
              ])),
              GestureDetector(
                onTap: () => Clipboard.setData(ClipboardData(text: d.code)),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.copy_rounded, color: Colors.white, size: 16),
                ),
              ),
            ]),
          ]),
        ),
        const SizedBox(height: 16),

        // Details
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: [
            _row('Boutique', d.shopName),
            _divider(),
            _row('De', d.senderName),
            _divider(),
            _row('Pour', d.recipientName),
            if (d.giftMessage != null && d.giftMessage!.isNotEmpty) ...[
              _divider(),
              _row('Message', d.giftMessage!),
            ],
            _divider(),
            _row('Montant initial', '${d.amount} FCFA'),
            _divider(),
            _row('Solde restant', '${d.balance} FCFA', valueColor: _kPurple),
            if (d.expiresAt != null) ...[
              _divider(),
              _row('Expire le', d.expiresAt!),
            ],
            if (d.createdAt != null) ...[
              _divider(),
              _row('Créée le', d.createdAt!),
            ],
          ]),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _row(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        SizedBox(
          width: 110,
          child: Text(label, style: GoogleFonts.inriaSerif(
            fontSize: 13, color: Colors.grey.shade600)),
        ),
        Expanded(child: Text(value, style: GoogleFonts.inriaSerif(
          fontSize: 13, fontWeight: FontWeight.w700,
          color: valueColor ?? const Color(0xFF1C1C1E)))),
      ]),
    );
  }

  Widget _divider() => Divider(height: 1, color: Colors.grey.shade100, indent: 16, endIndent: 16);
}
