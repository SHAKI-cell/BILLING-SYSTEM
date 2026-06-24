import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vibration/vibration.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:intl/intl.dart';

import '../../../billing/presentation/bloc/billing_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/entities/cart_item.dart';
import '../../../shop/presentation/bloc/shop_bloc.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    returnImage: false,
  );

  bool _isCameraOn = true;
  bool _isFlashOn = false;
  String _lastScannedName = 'None';

  // Cooldown mapping to prevent rapid firing of the same barcode
  final Map<String, DateTime> _lastScanTimes = {};

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    final List<Barcode> barcodes = capture.barcodes;
    final now = DateTime.now();

    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        final rawValue = barcode.rawValue!;

        // Cooldown logic: 2 seconds per identical barcode
        if (_lastScanTimes.containsKey(rawValue)) {
          final lastScan = _lastScanTimes[rawValue]!;
          if (now.difference(lastScan).inSeconds < 2) {
            continue;
          }
        }

        _lastScanTimes[rawValue] = now;

        // Vibrate
        final hasVibrator = await Vibration.hasVibrator();
        if (hasVibrator == true) {
          Vibration.vibrate();
        }

        if (mounted) {
          context.read<BillingBloc>().add(ScanBarcodeEvent(rawValue));
        }
        break; // Process one barcode at a time per frame
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: BlocListener<BillingBloc, BillingState>(
        listenWhen: (previous, current) =>
            (previous.error != current.error && current.error != null) ||
            (previous.cartItems != current.cartItems),
        listener: (context, state) {
          // Track last scanned item
          if (state.cartItems.isNotEmpty) {
            setState(() {
              _lastScannedName = state.cartItems.last.product.name;
            });
          }

          if (state.error != null) {
            final errorText = state.error!;
            if (errorText.startsWith('Product not found: ')) {
              final barcode = errorText.replaceFirst('Product not found: ', '').trim();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(errorText),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                  action: SnackBarAction(
                    label: 'Add Product',
                    textColor: Colors.white,
                    onPressed: () async {
                      _scannerController.stop();
                      await context.push('/products/add', extra: barcode);
                      if (_isCameraOn && mounted) {
                        _scannerController.start();
                      }
                    },
                  ),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(errorText),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        },
        child: BlocBuilder<ShopBloc, ShopState>(
          builder: (context, shopState) {
            String shopName = 'Sakib Shop';
            if (shopState is ShopLoaded) {
              shopName = shopState.shop.name;
            }

            // Greet message based on time of day
            final hour = DateTime.now().hour;
            final String greeting;
            if (hour < 12) {
              greeting = 'Good Morning, Cashier 👋';
            } else if (hour < 17) {
              greeting = 'Good Afternoon, Cashier 👋';
            } else {
              greeting = 'Good Evening, Cashier 👋';
            }

            final String currentDate =
                DateFormat('EEEE, d MMMM yyyy').format(DateTime.now());

            return BlocBuilder<BillingBloc, BillingState>(
              builder: (context, billingState) {
                final totalItems = billingState.cartItems
                    .fold<int>(0, (sum, item) => sum + item.quantity);

                return SafeArea(
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header Row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        greeting,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        currentDate,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF94A3B8),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        shopName,
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Store Icon Button
                                  GestureDetector(
                                    onTap: () async {
                                      _scannerController.stop();
                                      await context.push('/shop');
                                      if (_isCameraOn && mounted) {
                                        _scannerController.start();
                                      }
                                    },
                                    child: Container(
                                      width: 48,
                                      height: 48,
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        border: Border.all(
                                            color: const Color(0xFFE2E8F0)),
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppTheme.primaryColor
                                                .withValues(alpha: 0.1),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          )
                                        ],
                                      ),
                                      child: Image.asset(
                                        'assets/images/shop_logo.png',
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Scanner Card
                              _buildScannerSection(),
                              const SizedBox(height: 24),

                              // Stats Card
                              _buildStatsCard(totalItems, billingState.totalAmount),
                              const SizedBox(height: 24),

                              // Scanned Products Header
                              Row(
                                children: [
                                  const Text(
                                    'Scanned Products',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '$totalItems',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Cart List View
                              if (billingState.cartItems.isEmpty)
                                _buildEmptyCart()
                              else
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: billingState.cartItems.length,
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    final item = billingState.cartItems[index];
                                    return _buildCartItemCard(context, item);
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),

                      // Fixed Review Order button at bottom (outside scrollable area)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: PrimaryButton(
                          onPressed: billingState.cartItems.isEmpty
                              ? null
                              : () async {
                                  _scannerController.stop();
                                  await context.push('/checkout');
                                  if (_isCameraOn && mounted) {
                                    _scannerController.start();
                                  }
                                },
                          icon: Icons.chevron_right_rounded,
                          label: 'Review Order',
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildScannerSection() {
    return Center(
      child: Column(
        children: [
          Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                )
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (_isCameraOn)
                    MobileScanner(
                      controller: _scannerController,
                      onDetect: _onDetect,
                    )
                  else
                    _buildCameraOffState(),

                  // Scanning Corners Overlay
                  if (_isCameraOn) ...[
                    _buildCorner(Alignment.topLeft),
                    _buildCorner(Alignment.topRight),
                    _buildCorner(Alignment.bottomLeft),
                    _buildCorner(Alignment.bottomRight),

                    // Scanning laser line animation
                    const AnimatedLaserLine(),
                  ],

                  // Controls Overlay (Top Right)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isCameraOn) ...[
                          _buildOverlayButton(
                            icon: _isFlashOn
                                ? Icons.flashlight_off_rounded
                                : Icons.flashlight_on_rounded,
                            onPressed: () {
                              setState(() => _isFlashOn = !_isFlashOn);
                              _scannerController.toggleTorch();
                            },
                          ),
                          const SizedBox(width: 8),
                        ],
                        _buildOverlayButton(
                          icon: _isCameraOn
                              ? Icons.videocam_rounded
                              : Icons.videocam_off_rounded,
                          onPressed: () {
                            setState(() {
                              _isCameraOn = !_isCameraOn;
                            });
                            if (_isCameraOn) {
                              _scannerController.start();
                            } else {
                              _scannerController.stop();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Align barcode within the frame',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverlayButton(
      {required IconData icon, required VoidCallback onPressed}) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 16),
        padding: EdgeInsets.zero,
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildCorner(Alignment alignment) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 24,
        height: 24,
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border(
            top: (alignment == Alignment.topLeft ||
                    alignment == Alignment.topRight)
                ? const BorderSide(color: Color(0xFF22C55E), width: 3)
                : BorderSide.none,
            bottom: (alignment == Alignment.bottomLeft ||
                    alignment == Alignment.bottomRight)
                ? const BorderSide(color: Color(0xFF22C55E), width: 3)
                : BorderSide.none,
            left: (alignment == Alignment.topLeft ||
                    alignment == Alignment.bottomLeft)
                ? const BorderSide(color: Color(0xFF22C55E), width: 3)
                : BorderSide.none,
            right: (alignment == Alignment.topRight ||
                    alignment == Alignment.bottomRight)
                ? const BorderSide(color: Color(0xFF22C55E), width: 3)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildCameraOffState() {
    return Container(
      color: const Color(0xFF1E293B), // slate-800
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFF334155), // slate-700
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.videocam_off_rounded,
                color: Colors.white, size: 24),
          ),
          const SizedBox(height: 12),
          const Text(
            'Camera is off',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Tap video icon to start scanning items.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(int totalItems, double totalAmount) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Row(
        children: [
          _buildStatColumn('Items', '$totalItems'),
          _buildStatDivider(),
          _buildStatColumn('Total', '₹${totalAmount.toStringAsFixed(2)}',
              isPrimaryColor: true),
          _buildStatDivider(),
          _buildStatColumn('Last Scanned', _lastScannedName, isLastScanned: true),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value,
      {bool isPrimaryColor = false, bool isLastScanned = false}) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFF94A3B8),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: isLastScanned ? 13 : 16,
              fontWeight: FontWeight.bold,
              color: isPrimaryColor
                  ? AppTheme.primaryColor
                  : const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      height: 24,
      width: 1,
      color: const Color(0xFFE2E8F0),
    );
  }

  Widget _buildEmptyCart() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.shopping_basket_outlined,
                size: 28, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 12),
          const Text(
            'Cart is Empty',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 4),
          const Text(
            'Scan barcodes to add items here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItemCard(BuildContext context, CartItem item) {
    return Container(
      height: 96,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            // Left indicator strip
            Container(
              width: 5,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(width: 12),

            // Product Image (or icon)
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.shopping_bag_outlined,
                color: Color(0xFF64748B),
                size: 28,
              ),
            ),
            const SizedBox(width: 12),

            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'SKU: ${item.product.barcode}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Qty Adjuster
                  Container(
                    height: 28,
                    width: 90,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _qtyButton(Icons.remove, () {
                          if (item.quantity > 1) {
                            context.read<BillingBloc>().add(UpdateQuantityEvent(
                                item.product.id, item.quantity - 1));
                          } else {
                            context.read<BillingBloc>().add(
                                RemoveProductFromCartEvent(item.product.id));
                          }
                        }),
                        Text(
                          '${item.quantity}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        _qtyButton(Icons.add, () {
                          context.read<BillingBloc>().add(UpdateQuantityEvent(
                              item.product.id, item.quantity + 1));
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Price & Delete Icon
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${item.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () {
                      context
                          .read<BillingBloc>()
                          .add(RemoveProductFromCartEvent(item.product.id));
                    },
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: Color(0xFFEF4444),
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        child: Icon(icon, size: 14, color: const Color(0xFF64748B)),
      ),
    );
  }
}

class AnimatedLaserLine extends StatefulWidget {
  const AnimatedLaserLine({super.key});

  @override
  State<AnimatedLaserLine> createState() => _AnimatedLaserLineState();
}

class _AnimatedLaserLineState extends State<AnimatedLaserLine>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.05, end: 0.95).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Positioned(
          top: 280 * _animation.value,
          left: 20,
          right: 20,
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF22C55E).withValues(alpha: 0.8),
                  blurRadius: 8,
                  spreadRadius: 2,
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
