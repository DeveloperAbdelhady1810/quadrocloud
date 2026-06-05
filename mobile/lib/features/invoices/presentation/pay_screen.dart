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
          if (mounted) _checkPaymobCallback(url);
        },
        onWebResourceError: (_) {},
      ))
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  void _checkPaymobCallback(String url) {
    if (_paymentDone) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;

    final success = uri.queryParameters['success'];
    final isPaymobCallback = uri.path.contains('post_pay') ||
        uri.path.contains('transaction_processed') ||
        uri.queryParameters.containsKey('txn_response_callback');

    if (success == 'true' || (isPaymobCallback && success != 'false')) {
      _handleResult(success: true);
    } else if (success == 'false') {
      _handleResult(success: false);
    }
  }

  void _handleResult({required bool success}) {
    if (_paymentDone || !mounted) return;
    _paymentDone = true;

    // Capture container + router BEFORE any async — both outlive the widget
    final container = ProviderScope.containerOf(context);
    final goRouter = GoRouter.of(context);

    if (success) {
      // Refresh immediately, then at 3 s and 6 s to catch the Paymob webhook.
      // Uses ProviderContainer directly — safe after PayScreen is disposed.
      void refresh() {
        container.invalidate(invoicesProvider);
        container.invalidate(contractsProvider);
      }

      refresh();
      Future.delayed(const Duration(seconds: 3), refresh);
      Future.delayed(const Duration(seconds: 6), refresh);
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ResultDialog(
        success: success,
        onConfirm: () {
          context.pop();  // close the dialog
          goRouter.go('/invoices');
        } 
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
          onPressed: () => GoRouter.of(context).go('/invoices'),
        ),
      ),
      body: Stack(children: [
        WebViewWidget(controller: _controller),
        if (_isLoading) const Center(child: CircularProgressIndicator()),
      ]),
    );
  }
}

// ── Stateless dialog — no BuildContext captured from PayScreen ─────────────────

class _ResultDialog extends StatelessWidget {
  final bool success;
  final VoidCallback onConfirm;
  const _ResultDialog({required this.success, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 8),
        success ? const _SuccessIcon() : const Icon(Icons.cancel_rounded, color: AppTheme.danger, size: 64),
        const SizedBox(height: 20),
        Text(
          success ? 'تمت عملية الدفع بنجاح!' : 'فشلت عملية الدفع',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          success
              ? 'سيتم تحديث حالة الفاتورة خلال لحظات'
              : 'يرجى التحقق من بياناتك والمحاولة مرة أخرى',
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
      ]),
      actions: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onConfirm,   // uses the captured GoRouter — no context needed
            style: ElevatedButton.styleFrom(
              backgroundColor: success ? AppTheme.success : AppTheme.primary,
              minimumSize: const Size(0, 46),
            ),
            child: Text(success ? 'حسناً' : 'رجوع للفواتير'),
          ),
        ),
      ],
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
