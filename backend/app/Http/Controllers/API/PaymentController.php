<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class PaymentController extends Controller
{
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
                'amount'         => $p->amount,
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
            'amount'                  => $payment->amount,
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
            'success'     => true,
            'payment_url' => $result['payment_url'],
        ], 201);
    }
}
