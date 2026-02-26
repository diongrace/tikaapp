import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'order_tracking_api_page.dart';
import 'receipt_view_page.dart';
import '../loyalty/create_loyalty_card_page.dart';
import '../../../core/services/boutique_theme_provider.dart';
import '../../../services/auth_service.dart';
import '../../../services/loyalty_service.dart';

/// Page de succès simple apres commande
class LoadingSuccessPage extends StatefulWidget {
  final Map<String, dynamic>? orderData;

  const LoadingSuccessPage({super.key, this.orderData});

  @override
  State<LoadingSuccessPage> createState() => _LoadingSuccessPageState();
}

class _LoadingSuccessPageState extends State<LoadingSuccessPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _checkController;
  late Animation<double> _checkAnimation;
  bool _hasLoyaltyCard = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _checkController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _checkAnimation = CurvedAnimation(
      parent: _checkController,
      curve: Curves.elasticOut,
    );

    _checkController.forward();
    _checkLoyaltyCard();
  }

  Future<void> _checkLoyaltyCard() async {
    if (widget.orderData != null && widget.orderData!['shopId'] != null) {
      try {
        _hasLoyaltyCard = await LoyaltyService.hasCard(
          widget.orderData!['shopId'] as int,
        );
      } catch (e) {
        _hasLoyaltyCard = false;
      }
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _checkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orderNumber = widget.orderData?['orderNumber'] as String? ?? 'N/A';
    final primaryColor = BoutiqueThemeProvider.of(context).primary;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            children: [
              const SizedBox(height: 40),

              // Icone de succes
              ScaleTransition(
                scale: _checkAnimation,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Titre
              Text(
                'Commande confirmee !',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Merci pour votre commande',
                style: GoogleFonts.openSans(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 28),

              // Numero de commande
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFF3B82F6).withOpacity(0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Numero de commande',
                      style: GoogleFonts.openSans(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        orderNumber,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF3B82F6),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Message preparation
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Votre commande est en cours de preparation.',
                  style: GoogleFonts.openSans(
                    fontSize: 13,
                    color: const Color(0xFF059669),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),

              // Banneau points de fidélité
              if (widget.orderData?['loyaltyCardId'] != null) ...[
                Builder(builder: (context) {
                  final pointValue = widget.orderData?['loyaltyPointValue'] as int? ?? 10;
                  final rawTotal = widget.orderData?['total'];
                  final totalInt = rawTotal is int
                      ? rawTotal
                      : rawTotal is double
                          ? rawTotal.toInt()
                          : int.tryParse(rawTotal?.toString() ?? '') ?? 0;
                  final pointsEarned = pointValue > 0 ? (totalInt / pointValue).floor() : 0;

                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E8FF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.star_rounded, color: Color(0xFF7C3AED), size: 28),
                        const SizedBox(height: 6),
                        Text(
                          'Carte de fidélité détectée !',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF5B21B6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.card_giftcard_rounded, color: Color(0xFF7C3AED), size: 16),
                            const SizedBox(width: 6),
                            RichText(
                              text: TextSpan(
                                style: GoogleFonts.openSans(fontSize: 13, color: const Color(0xFF5B21B6)),
                                children: [
                                  const TextSpan(text: 'Vous gagnerez '),
                                  TextSpan(
                                    text: '$pointsEarned points',
                                    style: const TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Points ajoutés après livraison',
                          style: GoogleFonts.openSans(
                            fontSize: 11,
                            color: const Color(0xFF7C3AED).withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 16),
              ],

              const SizedBox(height: 16),

              // Boutons d'action
              if (!_isLoading) ...[
                // Carte de fidelite
                if (!_hasLoyaltyCard)
                  _buildActionButton(
                    label: 'Creer carte de fidelite',
                    icon: Icons.card_giftcard,
                    color: const Color(0xFFD946EF),
                    onPressed: () {
                      final shop = BoutiqueThemeProvider.shopOf(context);
                      final shopId = widget.orderData?['shopId'] ?? 1;
                      final boutiqueName = widget.orderData?['boutiqueName'] ?? 'Tika Shop';

                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => BoutiqueThemeProvider(
                            shop: shop,
                            child: CreateLoyaltyCardPage(
                              shopId: shopId,
                              boutiqueName: boutiqueName,
                              shop: shop,
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                if (!_hasLoyaltyCard) const SizedBox(height: 12),

                // Voir le recu
                _buildActionButton(
                  label: 'Voir le recu',
                  icon: Icons.receipt_long,
                  color: const Color(0xFF3B82F6),
                  onPressed: () => _openReceipt(),
                ),
                const SizedBox(height: 12),

                // Telecharger le recu
                _buildActionButton(
                  label: 'Telecharger le recu',
                  icon: Icons.download,
                  color: const Color(0xFF10B981),
                  onPressed: () => _downloadReceipt(),
                ),
                const SizedBox(height: 12),

                // Suivre ma commande
                _buildActionButton(
                  label: 'Suivre ma commande',
                  icon: Icons.local_shipping_outlined,
                  color: const Color(0xFFF97316),
                  onPressed: () => _trackOrder(),
                ),
                const SizedBox(height: 20),

                // Bouton Fermer
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                      side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Retour a la boutique',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Actions ---

  /// Recupere les donnees du recu depuis l'API (retourne du JSON, pas un PDF)
  Future<Map<String, dynamic>> _fetchReceiptData(String url) async {
    await AuthService.ensureToken();
    final token = widget.orderData?['authToken'] as String? ?? AuthService.authToken;
    print('📄 [Recu] URL: $url');
    print('📄 [Recu] Token: ${token != null ? "present" : "ABSENT"}');

    final dio = Dio();
    final response = await dio.get(
      url,
      options: Options(
        followRedirects: true,
        validateStatus: (status) => true,
        headers: {
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ),
    );

    print('📄 [Recu] Status: ${response.statusCode}');
    print('📄 [Recu] Content-Type: ${response.headers.value('content-type')}');

    if (response.statusCode != 200) {
      throw Exception('Erreur ${response.statusCode}');
    }

    // L'API retourne du JSON avec les donnees du recu
    final data = response.data is String ? jsonDecode(response.data) : response.data;

    if (data is! Map<String, dynamic> || data['success'] != true) {
      throw Exception(data?['message'] ?? 'Reponse invalide');
    }

    print('📄 [Recu] Donnees recues OK');
    return data;
  }

  Future<void> _openReceipt() async {
    final url = widget.orderData?['receiptUrl'];

    print('📄 [Recu] _openReceipt()');
    print('📄 [Recu] orderId: ${widget.orderData?['orderId']}');

    if (widget.orderData == null) {
      _showCenteredMessage('Recu non disponible', Colors.orange);
      return;
    }

    // Verifier le token disponible (stocke dans orderData ou en memoire)
    await AuthService.ensureToken();
    final token = widget.orderData?['authToken'] as String? ?? AuthService.authToken;

    // Si pas de token ou pas d'URL, afficher le recu local
    if (token == null || url == null) {
      _openLocalReceipt();
      return;
    }

    _showLoadingDialog('Chargement du recu...');

    try {
      final receiptData = await _fetchReceiptData(url as String);

      if (!mounted) return;
      _dismissDialog();

      final shop = BoutiqueThemeProvider.shopOf(context);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => BoutiqueThemeProvider(
            shop: shop,
            child: ReceiptViewPage(receiptData: receiptData),
          ),
        ),
      );
    } catch (e) {
      print('📄 [Recu] ERREUR open: $e');
      if (mounted) {
        _dismissDialog();
        // Fallback sur le recu local en cas d'erreur API
        _openLocalReceipt();
      }
    }
  }

  void _openLocalReceipt() {
    if (!mounted) return;
    final localData = _buildLocalReceiptData();
    final shop = BoutiqueThemeProvider.shopOf(context);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BoutiqueThemeProvider(
          shop: shop,
          child: ReceiptViewPage(receiptData: localData),
        ),
      ),
    );
  }

  Map<String, dynamic> _buildLocalReceiptData() {
    final od = widget.orderData ?? {};
    final rawItems = od['items'] as List? ?? [];
    final items = rawItems.map((item) {
      final m = item as Map<String, dynamic>;
      final qty = (m['quantity'] ?? 1) as num;
      final price = (m['price'] ?? 0) as num;
      return {
        'name': m['name'] ?? '-',
        'quantity': qty,
        'unit_price': price.toString(),
        'total': (qty * price).toString(),
      };
    }).toList();

    final paymentMode = od['paymentMode']?.toString() ?? '';
    String paymentMethod = 'especes';
    if (paymentMode.toLowerCase().contains('wave')) {
      paymentMethod = 'wave';
    } else if (paymentMode.toLowerCase().contains('mobile') || paymentMode.toLowerCase().contains('momo')) {
      paymentMethod = 'mobile_money';
    }

    return {
      'success': true,
      'data': {
        'receipt': {
          'shop': {'name': od['boutiqueName'] ?? 'Boutique'},
          'customer': {
            'name': od['customerName'] ?? (od['deliveryInfo'] as Map?)?['name'] ?? '-',
            'phone': od['customerPhone'] ?? (od['deliveryInfo'] as Map?)?['phone'] ?? '-',
            'address': (od['deliveryInfo'] as Map?)?['address'] ?? '',
          },
          'items': items,
          'order_number': od['orderNumber'] ?? '-',
          'date': od['orderDate']?.toString() ?? DateTime.now().toLocal().toString(),
          'status': 'Confirmee',
          'total': od['total']?.toString() ?? '0',
          'payment_method': paymentMethod,
          'payment_status': 'pending',
          'service_type': od['deliveryMode'] ?? '',
        },
      },
    };
  }

  Future<void> _downloadReceipt() async {
    final receiptUrl = widget.orderData?['receiptUrl'];

    print('📄 [Recu] _downloadReceipt()');
    print('📄 [Recu] orderId: ${widget.orderData?['orderId']}');

    if (widget.orderData == null) {
      _showCenteredMessage('Recu non disponible', Colors.orange);
      return;
    }

    _showLoadingDialog('Generation du PDF...');

    try {
      // Verifier le token disponible
      await AuthService.ensureToken();
      final token = widget.orderData?['authToken'] as String? ?? AuthService.authToken;

      Map<String, dynamic> receiptData;
      if (token != null && receiptUrl != null) {
        receiptData = await _fetchReceiptData(receiptUrl as String);
      } else {
        // Fallback: construire le recu depuis les donnees locales
        receiptData = _buildLocalReceiptData();
      }
      final receipt = receiptData['data']?['receipt'] ?? receiptData['receipt'] ?? receiptData;

      // Generer le PDF localement
      final pdfBytes = await _generateReceiptPdf(receipt);

      // Dossier de telechargement sans permission requise
      Directory? downloadDir;
      if (Platform.isAndroid) {
        // Dossier prive de l'app (aucune permission requise)
        downloadDir = await getExternalStorageDirectory();
        downloadDir ??= await getApplicationDocumentsDirectory();
      } else {
        downloadDir = await getApplicationDocumentsDirectory();
      }

      if (downloadDir == null) throw Exception('Dossier non accessible');

      final orderNum = receipt['order_number']?.toString() ?? 'recu';
      final filePath = '${downloadDir.path}/recu_$orderNum.pdf';
      final file = File(filePath);
      await file.writeAsBytes(pdfBytes);

      print('📄 [Recu] PDF genere: $filePath (${pdfBytes.length} octets)');

      if (!mounted) return;
      _dismissDialog();
      _showCenteredMessage(
        'PDF telecharge !',
        const Color(0xFF10B981),
        actionLabel: 'Ouvrir le PDF',
        onAction: () => OpenFilex.open(filePath),
      );
    } catch (e) {
      print('📄 [Recu] ERREUR download: $e');
      if (mounted) {
        _dismissDialog();
        _showCenteredMessage('Impossible de generer le PDF', Colors.red);
      }
    }
  }

  /// Genere un PDF a partir des donnees du recu
  Future<List<int>> _generateReceiptPdf(Map<String, dynamic> receipt) async {
    final pdf = pw.Document();
    final shop = receipt['shop'] as Map<String, dynamic>? ?? {};
    final customer = receipt['customer'] as Map<String, dynamic>? ?? {};
    final items = receipt['items'] as List? ?? [];

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      shop['name']?.toString() ?? 'Boutique',
                      style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
                    ),
                    if (shop['address'] != null)
                      pw.Text(shop['address'].toString(), style: const pw.TextStyle(fontSize: 11)),
                    if (shop['phone'] != null)
                      pw.Text(shop['phone'].toString(), style: const pw.TextStyle(fontSize: 11)),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'RECU DE COMMANDE',
                      style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.SizedBox(height: 12),
              _pdfInfoRow('N commande', receipt['order_number']?.toString() ?? '-'),
              _pdfInfoRow('Date', receipt['date']?.toString() ?? '-'),
              _pdfInfoRow('Statut', receipt['status']?.toString() ?? '-'),
              pw.SizedBox(height: 12),
              pw.Text('CLIENT', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              _pdfInfoRow('Nom', customer['name']?.toString() ?? '-'),
              _pdfInfoRow('Telephone', customer['phone']?.toString() ?? '-'),
              if (customer['address'] != null && customer['address'].toString().isNotEmpty)
                _pdfInfoRow('Adresse', customer['address'].toString()),
              pw.SizedBox(height: 12),
              pw.Divider(),
              pw.SizedBox(height: 12),
              pw.Table(
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(1),
                  2: const pw.FlexColumnWidth(1),
                  3: const pw.FlexColumnWidth(1),
                },
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      _pdfCell('Article', bold: true),
                      _pdfCell('Qte', bold: true, center: true),
                      _pdfCell('P.U.', bold: true, center: true),
                      _pdfCell('Total', bold: true, center: true),
                    ],
                  ),
                  ...items.map((item) {
                    final m = item as Map<String, dynamic>;
                    return pw.TableRow(
                      children: [
                        _pdfCell(m['name']?.toString() ?? '-'),
                        _pdfCell('${m['quantity'] ?? 1}', center: true),
                        _pdfCell('${m['unit_price'] ?? '-'}', center: true),
                        _pdfCell('${m['total'] ?? '-'}', center: true),
                      ],
                    );
                  }),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.green50,
                  border: pw.Border.all(color: PdfColors.green),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('TOTAL', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    pw.Text(
                      '${receipt['total'] ?? '0'} FCFA',
                      style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Divider(),
              pw.SizedBox(height: 8),
              _pdfInfoRow('Paiement', _formatPaymentMethod(receipt['payment_method']?.toString())),
              _pdfInfoRow('Statut paiement', _formatPaymentStatus(receipt['payment_status']?.toString())),
              pw.SizedBox(height: 24),
              pw.Center(
                child: pw.Text(
                  'Merci pour votre commande !',
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _pdfInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          ),
          pw.Expanded(
            child: pw.Text(value, style: const pw.TextStyle(fontSize: 10), textAlign: pw.TextAlign.right),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfCell(String text, {bool bold = false, bool center = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: center ? pw.TextAlign.center : pw.TextAlign.left,
      ),
    );
  }

  String _formatPaymentMethod(String? method) {
    switch (method) {
      case 'especes': return 'Especes';
      case 'mobile_money': return 'Mobile Money';
      case 'wave': return 'Wave';
      case 'carte': return 'Carte bancaire';
      default: return method ?? '-';
    }
  }

  String _formatPaymentStatus(String? status) {
    switch (status) {
      case 'pending': return 'En attente';
      case 'paid': return 'Paye';
      case 'failed': return 'Echoue';
      default: return status ?? '-';
    }
  }

  void _trackOrder() {
    if (widget.orderData == null ||
        widget.orderData!['orderNumber'] == null ||
        widget.orderData!['customerPhone'] == null) return;

    final shop = BoutiqueThemeProvider.shopOf(context);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BoutiqueThemeProvider(
          shop: shop,
          child: OrderTrackingApiPage(
            orderNumber: widget.orderData!['orderNumber'],
            customerPhone: widget.orderData!['customerPhone'],
          ),
        ),
      ),
    );
  }

  /// Affiche un message centre sur l'ecran (pas en bas)
  void _showCenteredMessage(String message, Color color, {String? actionLabel, VoidCallback? onAction}) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black26,
      builder: (ctx) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  color == Colors.red || color == Colors.orange
                      ? Icons.warning_rounded
                      : Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 36,
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (actionLabel != null) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        onAction?.call();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: color,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        actionLabel,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
                if (actionLabel == null) ...[
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => Navigator.of(ctx).pop(),
                    child: Text(
                      'OK',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Affiche un indicateur de chargement centre
  void _showLoadingDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black26,
      builder: (ctx) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _dismissDialog() {
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
  }
}

/// Page de succes pour commande En boutique (A emporter)
class LoadingSuccessInStorePage extends StatefulWidget {
  final Map<String, dynamic>? orderData;

  const LoadingSuccessInStorePage({super.key, this.orderData});

  @override
  State<LoadingSuccessInStorePage> createState() => _LoadingSuccessInStorePageState();
}

class _LoadingSuccessInStorePageState extends State<LoadingSuccessInStorePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _checkController;
  late Animation<double> _checkAnimation;
  bool _hasLoyaltyCard = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _checkController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _checkAnimation = CurvedAnimation(
      parent: _checkController,
      curve: Curves.elasticOut,
    );

    _checkController.forward();
    _checkLoyaltyCard();
  }

  Future<void> _checkLoyaltyCard() async {
    if (widget.orderData != null && widget.orderData!['shopId'] != null) {
      try {
        _hasLoyaltyCard = await LoyaltyService.hasCard(
          widget.orderData!['shopId'] as int,
        );
      } catch (e) {
        _hasLoyaltyCard = false;
      }
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _checkController.dispose();
    super.dispose();
  }

  String _formatPickupDateTime(DateTime? date, TimeOfDay? time) {
    if (date == null || time == null) return '';
    final months = ['jan', 'fev', 'mar', 'avr', 'mai', 'juin', 'juil', 'aout', 'sep', 'oct', 'nov', 'dec'];
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '${date.day} ${months[date.month - 1]} ${date.year} a $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = BoutiqueThemeProvider.of(context).primary;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            children: [
              const SizedBox(height: 40),

              // Icone de succes
              ScaleTransition(
                scale: _checkAnimation,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Titre
              Text(
                'Commande enregistree !',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Votre commande a ete enregistree avec succes',
                style: GoogleFonts.openSans(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),

              // Info recuperation
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFF10B981).withOpacity(0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.store, color: const Color(0xFF059669), size: 22),
                        const SizedBox(width: 10),
                        Text(
                          'Recuperation en boutique',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF059669),
                          ),
                        ),
                      ],
                    ),
                    if (widget.orderData?['pickupDate'] != null &&
                        widget.orderData?['pickupTime'] != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, size: 18, color: Colors.grey.shade700),
                            const SizedBox(width: 10),
                            Text(
                              _formatPickupDateTime(
                                widget.orderData!['pickupDate'],
                                widget.orderData!['pickupTime'],
                              ),
                              style: GoogleFonts.openSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Boutons
              if (!_isLoading) ...[
                if (!_hasLoyaltyCard) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final shop = BoutiqueThemeProvider.shopOf(context);
                        final shopId = widget.orderData?['shopId'] ?? 1;
                        final boutiqueName = widget.orderData?['boutiqueName'] ?? 'Tika Shop';

                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => BoutiqueThemeProvider(
                              shop: shop,
                              child: CreateLoyaltyCardPage(
                                shopId: shopId,
                                boutiqueName: boutiqueName,
                                shop: shop,
                              ),
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.card_giftcard, size: 20),
                      label: Text(
                        'Creer une carte de fidelite',
                        style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFD946EF),
                        side: const BorderSide(color: Color(0xFFD946EF), width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Fermer
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Retour a la boutique',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
