import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/gift_service.dart';
import '../../../services/models/gift_model.dart';
import '../../../services/auth_service.dart';
import 'gift_order_track_screen.dart';

const Color _kPink = Color(0xFFE91E8C);
const Color _kPinkLight = Color(0xFFFF5252);

class SentGiftsScreen extends StatefulWidget {
  const SentGiftsScreen({super.key});

  static Future<void> show(BuildContext context) {
    return Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SentGiftsScreen()),
    );
  }

  @override
  State<SentGiftsScreen> createState() => _SentGiftsScreenState();
}

class _SentGiftsScreenState extends State<SentGiftsScreen> {
  final _phoneCtrl = TextEditingController();
  List<SentGift>? _gifts;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final phone = AuthService.currentClient?.phone;
    if (phone != null && phone.isNotEmpty) {
      _phoneCtrl.text = phone;
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) return;
    setState(() { _isLoading = true; _error = null; });
    try {
      final gifts = await GiftService.getMySentGifts(phone);
      setState(() { _gifts = gifts; _isLoading = false; });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1C1C1E), size: 20),
        ),
        title: Text('Mes cadeaux envoyés', style: GoogleFonts.inriaSerif(
          fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF1C1C1E))),
        centerTitle: true,
      ),
      body: Column(children: [
        // Phone input
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                style: GoogleFonts.inriaSerif(fontSize: 15, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: '+225 07 XX XX XX XX',
                  hintStyle: GoogleFonts.inriaSerif(color: Colors.grey.shade500),
                  filled: true,
                  fillColor: const Color(0xFFF2F2F7),
                  prefixIcon: const Icon(Icons.phone_rounded, size: 18, color: _kPink),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _load(),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _isLoading ? null : _load,
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

        // Body
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

    if (_gifts == null) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const FaIcon(FontAwesomeIcons.paperPlane, color: _kPink, size: 48),
        const SizedBox(height: 16),
        Text('Entrez votre numéro de téléphone', style: GoogleFonts.inriaSerif(
          fontSize: 15, color: Colors.grey.shade600)),
        Text('pour voir vos cadeaux envoyés', style: GoogleFonts.inriaSerif(
          fontSize: 13, color: Colors.grey.shade500)),
      ]));
    }

    if (_gifts!.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const FaIcon(FontAwesomeIcons.gift, color: Color(0xFFE91E8C), size: 48),
        const SizedBox(height: 16),
        Text('Aucun cadeau envoyé', style: GoogleFonts.inriaSerif(
          fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF1C1C1E))),
        Text('Vous n\'avez pas encore envoyé de cadeau.', style: GoogleFonts.inriaSerif(
          fontSize: 13, color: Colors.grey.shade500)),
      ]));
    }

    return RefreshIndicator(
      color: _kPink,
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _gifts!.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) => _buildCard(_gifts![i]),
      ),
    );
  }

  Widget _buildCard(SentGift gift) {
    final statusColor = _statusColor(gift.status);
    return GestureDetector(
      onTap: () => GiftOrderTrackScreen.show(context, token: gift.trackingToken),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: statusColor.withOpacity(0.2)),
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44, alignment: Alignment.center,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const FaIcon(FontAwesomeIcons.gift, color: _kPink, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(gift.recipientName, style: GoogleFonts.inriaSerif(
                fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF1C1C1E)))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(gift.statusLabel, style: GoogleFonts.inriaSerif(
                  fontSize: 11, fontWeight: FontWeight.w700, color: statusColor)),
              ),
            ]),
            const SizedBox(height: 2),
            Text(gift.shopName, style: GoogleFonts.inriaSerif(
              fontSize: 12, color: Colors.grey.shade600)),
            const SizedBox(height: 4),
            Row(children: [
              Text(gift.trackingToken, style: GoogleFonts.inriaSerif(
                fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey.shade700)),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => Clipboard.setData(ClipboardData(text: gift.trackingToken)),
                child: const Icon(Icons.copy_rounded, size: 13, color: _kPink),
              ),
              const Spacer(),
              Text('${gift.totalAmount} FCFA', style: GoogleFonts.inriaSerif(
                fontSize: 13, fontWeight: FontWeight.w800, color: _kPink)),
            ]),
            if (gift.requiresYangoOrder && gift.status == 'delivery_pending') ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.local_taxi_rounded, color: Colors.orange, size: 14),
                  const SizedBox(width: 4),
                  Text('Commandez Yango', style: GoogleFonts.inriaSerif(
                    fontSize: 11, color: Colors.orange.shade800, fontWeight: FontWeight.w700)),
                ]),
              ),
            ],
          ])),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFFAAAAAA)),
        ]),
      ),
    );
  }
}
