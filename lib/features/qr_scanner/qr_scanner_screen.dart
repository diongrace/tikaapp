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

    setState(() => _isProcessing = true);
    await _openShopFromSlug(code);
  }

  Future<void> _openShopFromSlug(String input) async {
    try {
      final Shop shop = await ShopService.getShopByLink(input);

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen(shop: shop)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size   = MediaQuery.of(context).size;
    final frame  = size.width * 0.80; // taille du cadre de scan
    final corner = 28.0;              // longueur des coins
    const stroke = 4.0;              // épaisseur des coins

    return Scaffold(
      backgroundColor: Colors.black,
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Caméra plein écran ────────────────────────────────
          MobileScanner(
            controller: _controller,
            onDetect: _onBarcodeDetect,
            fit: BoxFit.cover,
          ),

          // ── Overlay sombre autour du cadre ───────────────────
          Positioned.fill(
            child: _ScanOverlay(frameSize: frame, verticalOffset: -40),
          ),

          // ── Coins du cadre ───────────────────────────────────
          Positioned.fill(
            child: Transform.translate(
              offset: const Offset(0, -40),
              child: Center(child: SizedBox(
              width: frame,
              height: frame,
              child: Stack(
                children: [
                  // Coin haut-gauche
                  Positioned(top: 0, left: 0,
                    child: _Corner(corner: corner, stroke: stroke,
                        top: true, left: true)),
                  // Coin haut-droite
                  Positioned(top: 0, right: 0,
                    child: _Corner(corner: corner, stroke: stroke,
                        top: true, left: false)),
                  // Coin bas-gauche
                  Positioned(bottom: 0, left: 0,
                    child: _Corner(corner: corner, stroke: stroke,
                        top: false, left: true)),
                  // Coin bas-droite
                  Positioned(bottom: 0, right: 0,
                    child: _Corner(corner: corner, stroke: stroke,
                        top: false, left: false)),
                ],
              ),
            )))),

          // ── Zone haut : titre + sous-titre ───────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 32),
                  Text(
                    'Scanner le QR code',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inriaSerif(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Positionnez le QR code dans le cadre',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inriaSerif(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Zone bas : boutons + retour ───────────────────────
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Flash + retournement caméra
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _CamBtn(
                          icon: ValueListenableBuilder(
                            valueListenable: _controller,
                            builder: (_, value, __) {
                              final on = value.torchState == TorchState.on;
                              return Icon(
                                on ? Icons.flash_on : Icons.flash_off,
                                color: on ? Colors.amber : Colors.white,
                                size: 24,
                              );
                            },
                          ),
                          onTap: () => _controller.toggleTorch(),
                        ),
                        const SizedBox(width: 24),
                        _CamBtn(
                          icon: const Icon(Icons.cameraswitch,
                              color: Colors.white, size: 24),
                          onTap: () => _controller.switchCamera(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Bouton Retour
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: double.infinity,
                        height: 58,
                        decoration: BoxDecoration(
                          color: const Color(0xFF8936A8),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF8936A8).withOpacity(0.45),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'Retour',
                            style: GoogleFonts.inriaSerif(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Loader quand traitement en cours ─────────────────
          if (_isProcessing)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: const Center(
                  child: CircularProgressIndicator(color: Color(0xFF8936A8)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Overlay sombre avec découpe centrale ──────────────────────────────────
class _ScanOverlay extends StatelessWidget {
  final double frameSize;
  final double verticalOffset;
  const _ScanOverlay({required this.frameSize, this.verticalOffset = 0});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _OverlayPainter(
          frameSize: frameSize, verticalOffset: verticalOffset));
  }
}

class _OverlayPainter extends CustomPainter {
  final double frameSize;
  final double verticalOffset;
  const _OverlayPainter({required this.frameSize, this.verticalOffset = 0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.55);

    final cx = size.width  / 2;
    final cy = size.height / 2 + verticalOffset;
    final half = frameSize / 2;
    final r = 16.0;

    final full = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final hole = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTRB(cx - half, cy - half, cx + half, cy + half),
        Radius.circular(r),
      ));

    canvas.drawPath(
      Path.combine(PathOperation.difference, full, hole),
      paint,
    );
  }

  @override
  bool shouldRepaint(_OverlayPainter old) =>
      old.frameSize != frameSize || old.verticalOffset != verticalOffset;
}

// ── Coin du cadre de scan ─────────────────────────────────────────────────
class _Corner extends StatelessWidget {
  final double corner;
  final double stroke;
  final bool top;
  final bool left;

  const _Corner({
    required this.corner,
    required this.stroke,
    required this.top,
    required this.left,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: corner,
      height: corner,
      child: CustomPaint(
        painter: _CornerPainter(
          stroke: stroke, top: top, left: left,
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final double stroke;
  final bool top;
  final bool left;

  const _CornerPainter({
    required this.stroke,
    required this.top,
    required this.left,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final w = size.width;
    final h = size.height;

    // Branche horizontale
    canvas.drawLine(
      Offset(left ? 0 : w, top ? 0 : h),
      Offset(left ? w : 0, top ? 0 : h),
      paint,
    );
    // Branche verticale
    canvas.drawLine(
      Offset(left ? 0 : w, top ? 0 : h),
      Offset(left ? 0 : w, top ? h : 0),
      paint,
    );
  }

  @override
  bool shouldRepaint(_CornerPainter old) => false;
}

// ── Bouton caméra circulaire ──────────────────────────────────────────────
class _CamBtn extends StatelessWidget {
  final Widget icon;
  final VoidCallback onTap;
  const _CamBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24, width: 1),
        ),
        child: Center(child: icon),
      ),
    );
  }
}
