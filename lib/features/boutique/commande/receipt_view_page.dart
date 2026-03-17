import 'dart:io';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/utils/format_utils.dart';

/// Page affichant le recu de commande a partir des donnees JSON de l'API
class ReceiptViewPage extends StatelessWidget {
  final Map<String, dynamic> receiptData;

  const ReceiptViewPage({super.key, required this.receiptData});

  @override
  Widget build(BuildContext context) {
    final receipt = receiptData['data']?['receipt'] ?? receiptData['receipt'] ?? receiptData;
    final shop = receipt['shop'] as Map<String, dynamic>? ?? {};
    final customer = receipt['customer'] as Map<String, dynamic>? ?? {};
    final items = receipt['items'] as List? ?? [];

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(
          'Reçu de commande',
          style: GoogleFonts.inriaSerif(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.download),
            onPressed: () => _downloadPdf(context, receipt),
            tooltip: 'Télécharger PDF',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // En-tete boutique
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    children: [
                      const FaIcon(FontAwesomeIcons.receipt, color: Colors.white, size: 36),
                      const SizedBox(height: 12),
                      Text(
                        shop['name']?.toString() ?? 'Boutique',
                        style: GoogleFonts.inriaSerif(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (shop['address'] != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          shop['address'].toString(),
                          style: GoogleFonts.inriaSerif(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      if (shop['phone'] != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          shop['phone'].toString(),
                          style: GoogleFonts.inriaSerif(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Numero et date
                      _buildInfoRow(
                        'N° commande',
                        receipt['order_number']?.toString() ?? '-',
                        bold: true,
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        'Date',
                        receipt['date']?.toString() ?? '-',
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        'Statut',
                        receipt['status']?.toString() ?? '-',
                      ),

                      const SizedBox(height: 16),
                      _buildDivider(),
                      const SizedBox(height: 16),

                      // Info client
                      Text(
                        'CLIENT',
                        style: GoogleFonts.inriaSerif(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow('Nom', customer['name']?.toString() ?? '-'),
                      const SizedBox(height: 4),
                      _buildInfoRow('Tel', customer['phone']?.toString() ?? '-'),
                      if (customer['address'] != null && customer['address'].toString().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        _buildInfoRow('Adresse', customer['address'].toString()),
                      ],

                      const SizedBox(height: 16),
                      _buildDivider(),
                      const SizedBox(height: 16),

                      // Articles
                      Text(
                        'ARTICLES',
                        style: GoogleFonts.inriaSerif(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // En-tete tableau
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text('Article', style: _tableHeaderStyle()),
                          ),
                          SizedBox(
                            width: 40,
                            child: Text('Qte', style: _tableHeaderStyle(), textAlign: TextAlign.center),
                          ),
                          Expanded(
                            child: Text('P.U.', style: _tableHeaderStyle(), textAlign: TextAlign.right),
                          ),
                          Expanded(
                            child: Text('Total', style: _tableHeaderStyle(), textAlign: TextAlign.right),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Lignes articles
                      ...items.map((item) {
                        final itemMap = item as Map<String, dynamic>;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  itemMap['name']?.toString() ?? '-',
                                  style: GoogleFonts.inriaSerif(fontSize: 14),
                                ),
                              ),
                              SizedBox(
                                width: 40,
                                child: Text(
                                  '${itemMap['quantity'] ?? 1}',
                                  style: GoogleFonts.inriaSerif(fontSize: 14),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  itemMap['unit_price'] != null ? fmtAmount(itemMap['unit_price']) : '-',
                                  style: GoogleFonts.inriaSerif(fontSize: 14),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  itemMap['total'] != null ? fmtAmount(itemMap['total']) : '-',
                                  style: GoogleFonts.inriaSerif(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

                      const SizedBox(height: 12),
                      _buildDivider(),
                      const SizedBox(height: 12),

                      // Totaux
                      if (receipt['subtotal'] != null)
                        _buildTotalRow('Sous-total', '${fmtAmount(receipt['subtotal'])} FCFA'),
                      if (receipt['delivery_fee'] != null &&
                          receipt['delivery_fee'].toString() != '0' &&
                          receipt['delivery_fee'].toString() != '0.00')
                        _buildTotalRow('Livraison', '${fmtAmount(receipt['delivery_fee'])} FCFA'),
                      if (receipt['discount'] != null &&
                          receipt['discount'].toString() != '0' &&
                          receipt['discount'].toString() != '0.00')
                        _buildTotalRow('Réduction', '-${fmtAmount(receipt['discount'])} FCFA'),

                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'TOTAL',
                              style: GoogleFonts.inriaSerif(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF059669),
                              ),
                            ),
                            Text(
                              '${fmtAmount(receipt['total'] ?? 0)} FCFA',
                              style: GoogleFonts.inriaSerif(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF059669),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),
                      _buildDivider(),
                      const SizedBox(height: 16),

                      // Paiement
                      _buildInfoRow(
                        'Paiement',
                        _formatPaymentMethod(receipt['payment_method']?.toString()),
                      ),
                      const SizedBox(height: 4),
                      _buildInfoRow(
                        'Statut paiement',
                        _formatPaymentStatus(receipt['payment_status']?.toString()),
                      ),
                      if (receipt['service_type'] != null &&
                          receipt['service_type'].toString().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        _buildInfoRow('Service', receipt['service_type'].toString()),
                      ],

                      const SizedBox(height: 24),

                      // Merci
                      Center(
                        child: Text(
                          'Merci pour votre commande !',
                          style: GoogleFonts.inriaSerif(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool bold = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: GoogleFonts.inriaSerif(
              fontSize: 14,
              color: Colors.grey.shade800,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inriaSerif(
              fontSize: 14,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: Colors.black87,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildTotalRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inriaSerif(fontSize: 14, color: Colors.grey.shade900),
          ),
          Text(
            value,
            style: GoogleFonts.inriaSerif(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: double.infinity,
      height: 1,
      color: Colors.grey.shade200,
    );
  }

  TextStyle _tableHeaderStyle() {
    return GoogleFonts.inriaSerif(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: Colors.grey.shade800,
    );
  }

  String _formatPaymentMethod(String? method) {
    switch (method) {
      case 'especes':
        return 'Espèces';
      case 'mobile_money':
        return 'Mobile Money';
      case 'wave':
        return 'Wave';
      case 'carte':
        return 'Carte bancaire';
      default:
        return method ?? '-';
    }
  }

  String _formatPaymentStatus(String? status) {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'paid':
        return 'Payé';
      case 'failed':
        return 'Échoué';
      case 'refunded':
        return 'Remboursé';
      default:
        return status ?? '-';
    }
  }

  // --- Generation PDF ---

  Future<void> _downloadPdf(BuildContext context, Map<String, dynamic> receipt) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Génération du PDF...'),
          backgroundColor: Color(0xFF3B82F6),
          duration: Duration(seconds: 2),
        ),
      );

      final pdfDoc = _buildPdfDocument(receipt);
      final bytes = await pdfDoc.save();

      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          await Permission.photos.request();
        }
      }

      Directory? downloadDir;
      if (Platform.isAndroid) {
        downloadDir = Directory('/storage/emulated/0/Download');
        if (!await downloadDir.exists()) {
          downloadDir = await getExternalStorageDirectory();
        }
      } else {
        downloadDir = await getApplicationDocumentsDirectory();
      }

      if (downloadDir == null) throw Exception('Dossier non accessible');

      final orderNum = receipt['order_number']?.toString() ?? 'recu';
      final filePath = '${downloadDir.path}/recu_$orderNum.pdf';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('PDF téléchargé !'),
          backgroundColor: const Color(0xFF10B981),
          action: SnackBarAction(
            label: 'Ouvrir',
            textColor: Colors.white,
            onPressed: () => OpenFilex.open(filePath),
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  pw.Document _buildPdfDocument(Map<String, dynamic> receipt) {
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
              // En-tete
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      shop['name']?.toString() ?? 'Boutique',
                      style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
                    ),
                    if (shop['address'] != null)
                      pw.Text(shop['address'].toString(), style: const pw.TextStyle(fontSize: 13)),
                    if (shop['phone'] != null)
                      pw.Text(shop['phone'].toString(), style: const pw.TextStyle(fontSize: 13)),
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

              // Info commande
              _pdfRow('N commande', receipt['order_number']?.toString() ?? '-'),
              _pdfRow('Date', receipt['date']?.toString() ?? '-'),
              _pdfRow('Statut', receipt['status']?.toString() ?? '-'),
              pw.SizedBox(height: 12),

              // Client
              pw.Text('CLIENT', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              _pdfRow('Nom', customer['name']?.toString() ?? '-'),
              _pdfRow('Telephone', customer['phone']?.toString() ?? '-'),
              if (customer['address'] != null && customer['address'].toString().isNotEmpty)
                _pdfRow('Adresse', customer['address'].toString()),
              pw.SizedBox(height: 12),
              pw.Divider(),
              pw.SizedBox(height: 12),

              // Tableau articles
              pw.Table(
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(1),
                  2: const pw.FlexColumnWidth(1),
                  3: const pw.FlexColumnWidth(1),
                },
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                children: [
                  // En-tete
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      _pdfCell('Article', bold: true),
                      _pdfCell('Qte', bold: true, center: true),
                      _pdfCell('P.U.', bold: true, center: true),
                      _pdfCell('Total', bold: true, center: true),
                    ],
                  ),
                  // Lignes
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

              // Totaux
              if (receipt['subtotal'] != null)
                _pdfTotalRow('Sous-total', '${receipt['subtotal']} FCFA'),
              if (receipt['delivery_fee'] != null &&
                  receipt['delivery_fee'].toString() != '0' &&
                  receipt['delivery_fee'].toString() != '0.00')
                _pdfTotalRow('Livraison', '${receipt['delivery_fee']} FCFA'),
              if (receipt['discount'] != null &&
                  receipt['discount'].toString() != '0' &&
                  receipt['discount'].toString() != '0.00')
                _pdfTotalRow('Reduction', '-${receipt['discount']} FCFA'),

              pw.SizedBox(height: 8),
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

              _pdfRow('Paiement', _formatPaymentMethod(receipt['payment_method']?.toString())),
              _pdfRow('Statut paiement', _formatPaymentStatus(receipt['payment_status']?.toString())),
              if (receipt['service_type'] != null && receipt['service_type'].toString().isNotEmpty)
                _pdfRow('Service', receipt['service_type'].toString()),

              pw.SizedBox(height: 24),
              pw.Center(
                child: pw.Text(
                  'Merci pour votre commande !',
                  style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  pw.Widget _pdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(label, style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
          ),
          pw.Expanded(
            child: pw.Text(value, style: const pw.TextStyle(fontSize: 12), textAlign: pw.TextAlign.right),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfTotalRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 12)),
          pw.Text(value, style: const pw.TextStyle(fontSize: 12)),
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
          fontSize: 12,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: center ? pw.TextAlign.center : pw.TextAlign.left,
      ),
    );
  }
}
