import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:quadro_cloud/gen_l10n/app_localizations.dart';
import '../data/invoice_repository.dart';
import '../../contracts/data/contract_repository.dart';
import '../../../core/theme/app_theme.dart';

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
        onPageStarted: (_) {
          if (mounted) setState(() => _isLoading = true);
        },
        onPageFinished: (url) {
          if (mounted) setState(() => _isLoading = false);
          _checkPaymobCallback(url);
        },
        onWebResourceError: (error) {
          // Ignore resource errors (ads, trackers, etc.)
        },
      ))
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  void _checkPaymobCallback(String url) {
    if (_paymentDone) return;

    // Parse query parameters — Paymob appends ?success=true or ?success=false
    final uri = Uri.tryParse(url);
    if (uri == null) return;

    final success = uri.queryParameters['success'];
    final hasTxnResponse = uri.queryParameters.containsKey('txn_response_callback') ||
        uri.path.contains('post_pay') ||
        uri.path.contains('transaction_processed');

    if (success == 'true' || (hasTxnResponse && success != 'false')) {
      _onPaymentSuccess();
    } else if (success == 'false') {
      _onPaymentFailed();
    }
  }

  void _onPaymentSuccess() {
    if (_paymentDone) return;
    _paymentDone = true;

    // Invalidate providers immediately then again after webhook delay
    ref.invalidate(invoicesProvider);
    ref.invalidate(contractsProvider);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        ref.invalidate(invoicesProvider);
        ref.invalidate(contractsProvider);
      }
    });

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: const Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(height: 8),
          _SuccessIcon(),
          SizedBox(height: 20),
          Text(
            'تمت عملية الدفع بنجاح!',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            'سيتم تحديث حالة الفاتورة خلال لحظات',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4),
        ]),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Use context.go — handles dialog dismissal + navigation in one step
                if (context.mounted) context.go('/invoices');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.success,
                minimumSize: const Size(0, 46),
              ),
              child: const Text('حسناً'),
            ),
          ),
        ],
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }

  void _onPaymentFailed() {
    if (_paymentDone) return;
    _paymentDone = true;

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: const Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(height: 8),
          Icon(Icons.cancel_rounded, color: AppTheme.danger, size: 64),
          SizedBox(height: 20),
          Text(
            'فشلت عملية الدفع',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            'يرجى التحقق من بياناتك والمحاولة مرة أخرى',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
            textAlign: TextAlign.center,
          ),
        ]),
        actions: [
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                if (context.mounted) context.go('/invoices');
              },
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 46)),
              child: const Text('رجوع للفواتير'),
            ),
          ),
        ],
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
          icon: const Icon(Icons.close_rounded),
          onPressed: () {
            if (context.mounted) context.go('/invoices');
          },
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

class _SuccessIcon extends StatefulWidget {
  const _SuccessIcon();

  @override
  State<_SuccessIcon> createState() => _SuccessIconState();
}

class _SuccessIconState extends State<_SuccessIcon> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        width: 80, height: 80,
        decoration: BoxDecoration(
          color: AppTheme.success.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 52),
      ),
    );
  }
}
