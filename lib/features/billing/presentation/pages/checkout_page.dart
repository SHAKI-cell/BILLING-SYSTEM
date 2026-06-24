import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/entities/cart_item.dart';
import '../../../shop/presentation/bloc/shop_bloc.dart';
import '../bloc/billing_bloc.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  late final String _invoiceNumber;

  @override
  void initState() {
    super.initState();
    // Generate a consistent random invoice number for this session
    final random = math.Random();
    final invoiceId = random.nextInt(90000) + 10000; // 5-digit random
    _invoiceNumber = '#SK-$invoiceId';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        context.read<BillingBloc>().add(ClearCartEvent());
        context.go('/');
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.chevron_left_rounded,
                size: 28, color: AppTheme.primaryColor),
            onPressed: () {
              context.read<BillingBloc>().add(ClearCartEvent());
              context.go('/');
            },
          ),
        ),
        body: BlocConsumer<BillingBloc, BillingState>(
          listener: (context, state) {
            if (state.printSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Printed successfully'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          builder: (context, billingState) {
            return BlocBuilder<ShopBloc, ShopState>(
              builder: (context, shopState) {
                String upiId = '7307612221@axl';
                String shopName = 'Sakib Shop';
                String address1 = 'Chaurahat, Padao';
                String address2 = '221001';
                String phone = '73307612221';
                String cashierName = 'Sakib Khan';

                if (shopState is ShopLoaded) {
                  upiId = shopState.shop.upiId;
                  shopName = shopState.shop.name;
                  address1 = shopState.shop.addressLine1;
                  address2 = shopState.shop.addressLine2;
                  phone = shopState.shop.phoneNumber;
                }

                // Calculations
                final total = billingState.totalAmount;
                final subtotal = total / 1.18;
                final gst = total - subtotal;

                return Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Section
                            _buildHeader(shopName),
                            const SizedBox(height: 24),

                            // Main Receipt Card
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Top Colored Bar
                                  Container(
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      color: AppTheme.primaryColor,
                                      borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(24)),
                                    ),
                                  ),

                                  Padding(
                                    padding: const EdgeInsets.all(20.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Invoice ID & Date Info Row
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'INVOICE',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.grey[400],
                                                    letterSpacing: 1.0,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  _invoiceNumber,
                                                  style: const TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF0F172A),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  'DATE',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.grey[400],
                                                    letterSpacing: 1.0,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  DateFormat('dd-MM-yyyy hh:mm a')
                                                      .format(DateTime.now()),
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF64748B),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),

                                        const SizedBox(height: 16),
                                        const DashedDivider(),
                                        const SizedBox(height: 16),

                                        // Cashier & Customer Info Rows
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _buildDetailsMiniCard(
                                                'CASHIER',
                                                cashierName,
                                                badgeText: 'Official',
                                                badgeColor: Colors.blue,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: _buildDetailsMiniCard(
                                                'CUSTOMER',
                                                'Walk-in Retail',
                                                subtext: 'GSTIN: 09AAACH1108R1ZA',
                                              ),
                                            ),
                                          ],
                                        ),

                                        const SizedBox(height: 20),
                                        const DashedDivider(),
                                        const SizedBox(height: 20),

                                        // Products Header
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                const Text(
                                                  'Products',
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF0F172A),
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                      horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.primaryColor
                                                        .withValues(alpha: 0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    '${billingState.cartItems.length}',
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.bold,
                                                      color: AppTheme.primaryColor,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.green
                                                    .withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.check_circle_rounded,
                                                    color: Colors.green,
                                                    size: 12,
                                                  ),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    'Live Cart',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.green,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),

                                        // Scanned Products List Inside Card
                                        if (billingState.cartItems.isEmpty)
                                          const Padding(
                                            padding: EdgeInsets.symmetric(
                                                vertical: 24),
                                            child: Center(
                                              child: Text(
                                                'No products in cart',
                                                style: TextStyle(
                                                    color: Color(0xFF94A3B8)),
                                              ),
                                            ),
                                          )
                                        else
                                          ListView.separated(
                                            shrinkWrap: true,
                                            physics:
                                                const NeverScrollableScrollPhysics(),
                                            itemCount: billingState.cartItems.length,
                                            separatorBuilder: (context, index) =>
                                                const Padding(
                                              padding: EdgeInsets.symmetric(
                                                  vertical: 8),
                                              child: Divider(
                                                  height: 1,
                                                  color: Color(0xFFF1F5F9)),
                                            ),
                                            itemBuilder: (context, index) {
                                              final item =
                                                  billingState.cartItems[index];
                                              return _buildCheckoutItemRow(
                                                  context, item);
                                            },
                                          ),

                                        const SizedBox(height: 20),
                                        const DashedDivider(),
                                        const SizedBox(height: 20),

                                        // Order Summary
                                        _buildSummaryRow(
                                          'Subtotal (Excl. Tax)',
                                          '₹${subtotal.toStringAsFixed(2)}',
                                        ),
                                        _buildSummaryRow(
                                          'GST (18% Integrated)',
                                          '₹${gst.toStringAsFixed(2)}',
                                        ),
                                        _buildSummaryRow(
                                          'Discount',
                                          '₹0.00',
                                          valueColor: Colors.green,
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              'Grand Total',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF0F172A),
                                              ),
                                            ),
                                            Text(
                                              '₹${total.toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.primaryColor,
                                              ),
                                            ),
                                          ],
                                        ),

                                        const SizedBox(height: 20),
                                        const DashedDivider(),
                                        const SizedBox(height: 20),

                                        // QR Payment Section
                                        if (upiId.isNotEmpty && total > 0) ...[
                                          Center(
                                            child: Column(
                                              children: [
                                                const Text(
                                                  'SCAN QR TO PAY',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF0F172A),
                                                    letterSpacing: 1.2,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  'UPI ID: $upiId',
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    color: Color(0xFF64748B),
                                                  ),
                                                ),
                                                const SizedBox(height: 16),
                                                Container(
                                                  padding: const EdgeInsets.all(12),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(20),
                                                    border: Border.all(
                                                        color: const Color(
                                                            0xFFE2E8F0)),
                                                  ),
                                                  width: 160,
                                                  height: 160,
                                                  child: PrettyQrView.data(
                                                    data:
                                                        'upi://pay?pa=$upiId&pn=${Uri.encodeComponent(shopName)}&am=${total.toStringAsFixed(2)}&cu=INR',
                                                    decoration: const PrettyQrDecoration(
                                                      shape: PrettyQrSmoothSymbol(),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 12),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                      horizontal: 10, vertical: 6),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFF0FDF4),
                                                    borderRadius:
                                                        BorderRadius.circular(10),
                                                    border: Border.all(
                                                        color: const Color(
                                                            0xFFDCFCE7)),
                                                  ),
                                                  child: const Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        Icons.shield_outlined,
                                                        color: Colors.green,
                                                        size: 14,
                                                      ),
                                                      SizedBox(width: 6),
                                                      Text(
                                                        'BHIM UPI Verified Secure Payment',
                                                        style: TextStyle(
                                                          fontSize: 9,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.green,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Fixed Print Receipt Button Container at Bottom
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, -4),
                          ),
                        ],
                        border: const Border(
                          top: BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      child: SafeArea(
                        top: false,
                        child: PrimaryButton(
                          onPressed: () {
                            if (shopState is ShopLoaded) {
                              context.read<BillingBloc>().add(PrintReceiptEvent(
                                  shopName: shopState.shop.name,
                                  address1: shopState.shop.addressLine1,
                                  address2: shopState.shop.addressLine2,
                                  phone: shopState.shop.phoneNumber,
                                  footer: shopState.shop.footerText));
                            } else {
                              context.read<BillingBloc>().add(PrintReceiptEvent(
                                  shopName: shopName,
                                  address1: address1,
                                  address2: address2,
                                  phone: phone,
                                  footer: 'Thank you for shopping with us!'));
                            }
                          },
                          label: 'Print Receipt',
                          icon: Icons.print_rounded,
                          isLoading: billingState.isPrinting,
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(String shopName) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 54,
            height: 54,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE2E8F0)),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Image.asset(
              'assets/images/shop_logo.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            shopName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Invoice ready for review and payment',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsMiniCard(String label, String value,
      {String? subtext, String? badgeText, Color? badgeColor}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 0.8),
              ),
              if (badgeText != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: (badgeColor ?? Colors.green).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: badgeColor ?? Colors.green,
                        size: 9,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        badgeText.toUpperCase(),
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: badgeColor ?? Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A)),
          ),
          if (subtext != null) ...[
            const SizedBox(height: 2),
            Text(
              subtext,
              style: const TextStyle(fontSize: 9, color: Color(0xFF64748B)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCheckoutItemRow(BuildContext context, CartItem item) {
    return Row(
      children: [
        // Mini image placeholder or icon
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.shopping_bag_outlined,
            color: Color(0xFF94A3B8),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),

        // Name & SKU
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.product.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 2),
              Text(
                'SKU: ${item.product.barcode}',
                style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 6),

              // QTY Adjuster
              Container(
                height: 24,
                width: 76,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _miniQtyButton(Icons.remove, () {
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
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    _miniQtyButton(Icons.add, () {
                      context.read<BillingBloc>().add(UpdateQuantityEvent(
                          item.product.id, item.quantity + 1));
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),

        // Price and Delete icon
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '₹${item.total.toStringAsFixed(2)}',
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                context
                    .read<BillingBloc>()
                    .add(RemoveProductFromCartEvent(item.product.id));
              },
              child: const Icon(
                Icons.delete_outline_rounded,
                color: Color(0xFFEF4444),
                size: 18,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _miniQtyButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        alignment: Alignment.center,
        child: Icon(icon, size: 12, color: const Color(0xFF64748B)),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: valueColor ?? const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}

class DashedDivider extends StatelessWidget {
  final double height;
  final Color color;

  const DashedDivider({
    super.key,
    this.height = 1,
    this.color = const Color(0xFFE2E8F0),
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 5.0;
        final dashHeight = height;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(color: color),
              ),
            );
          }),
        );
      },
    );
  }
}
