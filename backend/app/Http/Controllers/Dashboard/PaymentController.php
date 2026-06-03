<?php

namespace App\Http\Controllers\Dashboard;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class PaymentController extends Controller
{
    public function index(Request $request)
    {
        $payments = \App\Models\Payment::with(['client', 'invoice'])
            ->when($request->method, fn($q) => $q->where('method', $request->method))
            ->when($request->status, fn($q) => $q->where('status', $request->status))
            ->when($request->search, fn($q) => $q->whereHas('client', fn($c) =>
                $c->where('name', 'like', '%'.$request->search.'%')
            ))
            ->latest()
            ->paginate(25);

        return view('dashboard.payments.index', compact('payments'));
    }

    public function markCash(Request $request, \App\Models\Invoice $invoice)
    {
        if ($invoice->status === 'paid') {
            return back()->with('error', 'الفاتورة مدفوعة مسبقاً');
        }

        $payment = \App\Models\Payment::create([
            'invoice_id'      => $invoice->id,
            'client_id'       => $invoice->client_id,
            'amount'          => $invoice->amount,
            'method'          => 'cash',
            'status'          => 'success',
            'marked_cash_by'  => auth()->id(),
            'paid_at'         => now(),
        ]);

        $invoice->update([
            'status'         => 'paid',
            'paid_at'        => now(),
            'payment_method' => 'cash',
        ]);

        if ($invoice->additional_fee_id) {
            $invoice->additionalFee?->update(['status' => 'paid']);
        }

        $fcm = app(\App\Services\FcmService::class);
        $fcm->notifyAndLog(
            $invoice->client, 'payment_confirmed',
            'تم استلام الدفعة',
            "تم تسجيل دفعتك النقدية للفاتورة {$invoice->invoice_number}",
            'push', $invoice
        );

        \App\Models\ActivityLog::record('cash_payment_marked', $payment);
        return back()->with('success', 'تم تسجيل الدفع النقدي بنجاح');
    }
}
