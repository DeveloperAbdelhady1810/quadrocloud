<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class DashboardController extends Controller
{
    public function index(Request $request)
    {
        $client = $request->user();

        $overdueInvoices = $client->invoices()
            ->where('status', 'overdue')
            ->orWhere(function ($q) {
                $q->where('status', 'unpaid')->where('due_date', '<', now());
            })
            ->count();

        $nextInvoice = $client->invoices()
            ->where('status', 'unpaid')
            ->where('due_date', '>=', now())
            ->orderBy('due_date')
            ->first();

        $pendingFees = $client->additionalFees()
            ->where('status', 'pending')
            ->get()
            ->map(fn($f) => [
                'id'                  => $f->id,
                'title'               => $f->title,
                'amount'              => $f->amount,
                'due_date'            => $f->due_date?->format('Y-m-d'),
                'acceptance_deadline' => $f->acceptance_deadline?->format('Y-m-d'),
                'days_until_due'      => now()->diffInDays($f->due_date, false),
            ]);

        $daysUntilNext = $nextInvoice
            ? (int) now()->startOfDay()->diffInDays($nextInvoice->due_date, false)
            : null;

        return response()->json([
            'overdue_count'    => $overdueInvoices,
            'pending_fees'     => $pendingFees,
            'next_invoice'     => $nextInvoice ? [
                'id'             => $nextInvoice->id,
                'invoice_number' => $nextInvoice->invoice_number,
                'amount'         => $nextInvoice->amount,
                'due_date'       => $nextInvoice->due_date?->format('Y-m-d'),
                'days_until_due' => $daysUntilNext,
            ] : null,
        ]);
    }
}
