import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../services/shop_service.dart';
import '../../services/models/shop_model.dart';
import '../boutique/home/home_online_screen.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onBarcodeDetect(BarcodeCapture barcodeCapture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = barcodeCapture.barcodes;
    if (barcodes.isEmpty) return;

    final String? code = barcodes.first.rawValue;
    if (code == null) return;

    setState(() {
      _isProcessing = true;
    });

    await _openShopFromSlug(code);
  }

  Future<void> _openShopFromSlug(String input) async {
    try {
      // Utiliser getShopByLink qui accepte un ID ou une URL
      final Shop shop = await ShopService.getShopByLink(input);

      if (!mounted) return;

      // Naviguer vers l'écran d'accueil de la boutique avec les données
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(shop: shop),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Text(
              'Scanner le QR code',
              style: GoogleFonts.openSans(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Positionnez le QR code dans le cadre',
              style: GoogleFonts.openSans(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 40),
            Expanded(
              child: Center(
                child: Container(
                  width: 280,
                  height: 280,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: MobileScanner(
                      controller: _controller,
                      onDetect: _onBarcodeDetect,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: ValueListenableBuilder(
                      valueListenable: _controller,
                      builder: (context, value, child) {
                        final torchState = value.torchState;
                        switch (torchState) {
                          case TorchState.off:
                          case TorchState.unavailable:
                          case TorchState.auto:
                            return const Icon(
                              Icons.flash_off,
                              color: Colors.white,
                              size: 24,
                            );
                          case TorchState.on:
                            return const Icon(
                              Icons.flash_on,
                              color: Colors.amber,
                              size: 24,
                            );
                        }
                      },
                    ),
                    onPressed: () => _controller.toggleTorch(),
                  ),
                ),
                const SizedBox(width: 24),
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.cameraswitch,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: () => _controller.switchCamera(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8936A8),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      'Retour',
                      style: GoogleFonts.openSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
