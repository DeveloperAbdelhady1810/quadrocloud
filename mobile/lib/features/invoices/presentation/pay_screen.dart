import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:quadro_cloud/gen_l10n/app_localizations.dart';
import '../data/invoice_repository.dart';

class PayScreen extends ConsumerStatefulWidget {
  final int invoiceId;
  final String paymentUrl;
  const PayScreen({super.key, required this.invoiceId, required this.paymentUrl});

  @override
  ConsumerState<PayScreen> createState() => _PayScreenState();
}

class _PayScreenState extends ConsumerState<PayScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _paymentDone = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) => setState(() => _isLoading = true),
        onPageFinished: (url) {
          setState(() => _isLoading = false);
          // Paymob redirects to success/pending URL after payment
          if (url.contains('success') || url.contains('pending') || url.contains('txn_response')) {
            _onPaymentComplete();
          }
        },
      ))
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  void _onPaymentComplete() {
    if (_paymentDone) return;
    _paymentDone = true;
    ref.invalidate(invoicesProvider);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: const Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 64),
          SizedBox(height: 16),
          Text('تمت عملية الدفع', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          SizedBox(height: 8),
          Text('سيتم تحديث الفاتورة خلال لحظات', style: TextStyle(color: Colors.grey)),
        ]),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/invoices');
            },
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.onlinePay),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/invoices'),
        ),
      ),
      body: Stack(children: [
        WebViewWidget(controller: _controller),
        if (_isLoading)
          const Center(child: CircularProgressIndicator()),
      ]),
    );
  }
}
