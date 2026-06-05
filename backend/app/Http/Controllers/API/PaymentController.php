<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Payment;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class PaymentController extends Controller
{
    // ── Public: Paymob redirects the WebView here after payment ───────────────
    public function callback(Request $request)
    {
        $params  = $request->all();
        $paymob  = app(\App\Services\PaymobService::class);
        $success = filter_var($params['success'] ?? false, FILTER_VALIDATE_BOOLEAN);
        $txnId   = $params['id']    ?? null;
        $orderId = $params['order'] ?? null;

        // Verify HMAC — log but don't block so the app always gets a response
        if (!$paymob->verifyCallbackHmac($params)) {
            Log::warning('Paymob callback: invalid HMAC', ['ip' => $request->ip(), 'params' => $params]);
        }

        $payment = $orderId
            ? Payment::where('paymob_order_id', (string) $orderId)->first()
            : null;

        if (!$payment && $txnId) {
            $payment = Payment::where('paymob_transaction_id', (string) $txnId)->first();
        }

        if (!$payment) {
            Log::warning('Paymob callback: payment not found', ['order' => $orderId, 'txn' => $txnId]);
            return response()->json(['success' => $success, 'updated' => false]);
        }

        if ($payment->status !== 'success') {
            $payment->paymob_transaction_id = $txnId;

            if ($success) {
                $payment->status  = 'success';
                $payment->paid_at = now();
                $payment->save();

                $payment->invoice->update([
                    'status'         => 'paid',
                    'paid_at'        => now(),
                    'payment_method' => 'paymob',
                ]);
            } else {
                $payment->status = 'failed';
                $payment->save();
            }
        }

        return response()->json(['success' => $success, 'updated' => true]);
    }

    // ── Authenticated: app calls this right after success to ensure DB is updated
    public function verify(Request $request)
    {
        $request->validate([
            'paymob_order_id' => 'required|string',
            'transaction_id'  => 'nullable|string',
        ]);

        $payment = Payment::where('paymob_order_id', $request->paymob_order_id)
            ->where('client_id', $request->user()->id)
            ->first();

        if (!$payment) {
            return response()->json(['error' => 'Payment not found'], 404);
        }

        // Already confirmed (webhook or callback already ran)
        if ($payment->status === 'success') {
            return response()->json(['paid' => true, 'source' => 'db']);
        }

        // Query Paymob directly
        $txnId = $request->transaction_id ?? $payment->paymob_transaction_id;
        if ($txnId) {
            $paymob = app(\App\Services\PaymobService::class);
            $txn    = $paymob->getTransaction((int) $txnId);

            if ($txn && ($txn['success'] ?? false)) {
                $payment->paymob_transaction_id = $txnId;
                $payment->status                = 'success';
                $payment->paid_at               = now();
                $payment->save();

                $payment->invoice->update([
                    'status'         => 'paid',
                    'paid_at'        => now(),
                    'payment_method' => 'paymob',
                ]);

                return response()->json(['paid' => true, 'source' => 'paymob_api']);
            }
        }

        return response()->json(['paid' => false]);
    }


    public function index(Request $request)
    {
        $payments = $request->user()
            ->payments()
            ->with('invoice')
            ->latest()
            ->get()
            ->map(fn($p) => [
                'id'             => $p->id,
                'invoice_number' => $p->invoice?->invoice_number,
                'amount'         => (float) $p->amount,
                'method'         => $p->method,
                'status'         => $p->status,
                'paid_at'        => $p->paid_at?->format('Y-m-d H:i'),
            ]);

        return response()->json($payments);
    }

    public function show(Request $request, int $id)
    {
        $payment = $request->user()->payments()->with('invoice')->findOrFail($id);
        return response()->json([
            'id'                      => $payment->id,
            'invoice_number'          => $payment->invoice?->invoice_number,
            'amount'                  => (float) $payment->amount,
            'method'                  => $payment->method,
            'status'                  => $payment->status,
            'paymob_transaction_id'   => $payment->paymob_transaction_id,
            'paid_at'                 => $payment->paid_at?->format('Y-m-d H:i'),
        ]);
    }

    public function initiate(Request $request)
    {
        $request->validate(['invoice_id' => 'required|integer']);

        $invoice = $request->user()->invoices()
            ->whereIn('status', ['unpaid', 'overdue'])
            ->findOrFail($request->invoice_id);

        $paymob = app(\App\Services\PaymobService::class);
        $result = $paymob->createPaymentIntent($invoice);

        return response()->json([
            'success'         => true,
            'payment_url'     => $result['payment_url'],
            'paymob_order_id' => $result['paymob_order_id'] ?? '',
        ], 201);
    }
}
