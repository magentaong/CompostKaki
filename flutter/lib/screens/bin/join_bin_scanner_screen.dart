import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../theme/app_theme.dart';

class JoinBinScannerScreen extends StatefulWidget {
  const JoinBinScannerScreen({super.key});

  @override
  State<JoinBinScannerScreen> createState() => _JoinBinScannerScreenState();
}

class _JoinBinScannerScreenState extends State<JoinBinScannerScreen> {
  final MobileScannerController _controller =
      MobileScannerController(returnImage: false);
  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;

    for (final barcode in capture.barcodes) {
      final rawValue = barcode.rawValue;
      if (rawValue == null) continue;
      final binId = _extractBinId(rawValue);
      if (binId != null) {
        setState(() => _isProcessing = true);
        Navigator.pop(context, binId);
        return;
      }
    }
  }

  String? _extractBinId(String input) {
    final regex = RegExp(
        r'([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})');
    final match = regex.firstMatch(input);
    return match?.group(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Bin QR'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.black54,
              child: const Text(
                'Align the QR code within the frame to join a bin.',
                style: TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          if (_isProcessing)
            const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryGreen),
            ),
        ],
      ),
    );
  }
}
