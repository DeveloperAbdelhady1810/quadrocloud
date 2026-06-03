<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class ContractController extends Controller
{
    // Paymob processing fee added on top of invoice amount (EGP)
    public const PAYMOB_FEE = 5;

    public function index(Request $request)
    {
        $contracts = $request->user()
            ->contracts()
            ->with([
                'service',
                'invoices' => fn($q) => $q->whereIn('status', ['unpaid', 'overdue'])
                                          ->orderByDesc('created_at'),
            ])
            ->where('status', 'active')
            ->get()
            ->map(function ($c) {
                $daysUntilDue  = $c->next_due_date
                    ? (int) now()->startOfDay()->diffInDays($c->next_due_date, false)
                    : 0;

                $unpaidInvoice = $c->invoices->first();

                // Show Pay when the invoice's own due_date is within 5 days OR already overdue.
                // Use invoice.due_date (not contract.next_due_date which was already advanced).
                $showPay = false;
                if ($unpaidInvoice) {
                    $invoiceDays = $unpaidInvoice->due_date
                        ? (int) now()->startOfDay()->diffInDays($unpaidInvoice->due_date, false)
                        : 0;
                    $showPay = $invoiceDays <= 5;
                }

                return [
                    'id'                => $c->id,
                    'name'              => $c->display_name,
                    'price'             => (float) $c->price,
                    'billing_cycle'     => $c->billing_cycle,
                    'next_due_date'     => $c->next_due_date?->format('Y-m-d'),
                    'days_until_due'    => $daysUntilDue,
                    'grace_period_days' => $c->grace_period_days,
                    'start_date'        => $c->start_date?->format('Y-m-d'),
                    'end_date'          => $c->end_date?->format('Y-m-d'),
                    'status'            => $c->status,
                    'unpaid_invoice_id' => $showPay ? $unpaidInvoice->id : null,
                    'payable_amount'    => $showPay
                        ? ((float) $unpaidInvoice->amount + self::PAYMOB_FEE)
                        : null,
                ];
            });

        return response()->json($contracts);
    }
}
