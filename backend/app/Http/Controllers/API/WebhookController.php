<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class WebhookController extends Controller
{
    public function paymob(Request $request)
    {
        $paymob = app(\App\Services\PaymobService::class);

        if (!$paymob->verifyWebhookHmac($request->all())) {
            \Illuminate\Support\Facades\Log::warning('Paymob webhook: invalid HMAC', ['ip' => $request->ip()]);
            return response()->json(['message' => 'Invalid HMAC'], 403);
        }

        $obj     = $request->input('obj', []);
        $success = $obj['success'] ?? false;
        $txnId   = $obj['id'] ?? null;
        $ref     = $obj['order']['merchant_order_id'] ?? null;

        $payment = \App\Models\Payment::where('special_reference', 'LIKE', '%-INV%')
            ->whereHas('invoice', function ($q) use ($obj) {
                $q->where('id', $obj['order']['items'][0]['id'] ?? 0);
            })
            ->orWhere('paymob_order_id', $obj['order']['id'] ?? null)
            ->first();

        if (!$payment) {
            $invoiceId = null;
            if (preg_match('/-INV(\d+)-/', $payment?->special_reference ?? '', $m)) {
                $invoiceId = $m[1];
            }
            \Illuminate\Support\Facades\Log::warning('Paymob webhook: payment not found', ['obj' => $obj]);
            return response()->json(['message' => 'ok']);
        }

        $payment->paymob_transaction_id = $txnId;
        $payment->raw_response          = $obj;

        if ($success) {
            $payment->status  = 'success';
            $payment->paid_at = now();
            $payment->save();

            $invoice = $payment->invoice;
            $invoice->update([
                'status'         => 'paid',
                'paid_at'        => now(),
                'payment_method' => 'paymob',
            ]);

            if ($invoice->additional_fee_id) {
                $invoice->additionalFee?->update(['status' => 'paid']);
            }

            $fcm = app(\App\Services\FcmService::class);
            $fcm->notifyAndLog(
                $payment->client,
                'payment_confirmed',
                'تم استلام الدفعة',
                'تم استلام دفعتك بنجاح للفاتورة ' . $invoice->invoice_number,
                'push',
                $invoice,
            );
        } else {
            $payment->status = 'failed';
            $payment->save();
        }

        return response()->json(['message' => 'ok']);
    }
}
