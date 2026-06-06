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

        // Primary: match by special_reference echoed back by Paymob
        $specialRef = $obj['special_reference']
            ?? $obj['order']['merchant_order_id']
            ?? null;

        $payment = \App\Models\Payment::when($specialRef, fn($q) => $q->where('special_reference', $specialRef))
            ->when(!$specialRef, fn($q) => $q->whereRaw('0=1'))
            ->first();

        // Fallback: match by paymob_order_id stored at intent creation
        if (!$payment) {
            $paymobOrderId = $obj['order']['id'] ?? null;
            if ($paymobOrderId) {
                $payment = \App\Models\Payment::where('paymob_order_id', (string) $paymobOrderId)->first();
            }
        }

        if (!$payment) {
            \Illuminate\Support\Facades\Log::warning('Paymob webhook: payment not found', [
                'special_reference' => $specialRef,
                'order_id'          => $obj['order']['id'] ?? null,
            ]);
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
                ['action' => 'invoice_detail', 'action_id' => (string) $invoice->id],
            );
        } else {
            $payment->status = 'failed';
            $payment->save();
        }

        return response()->json(['message' => 'ok']);
    }
}
