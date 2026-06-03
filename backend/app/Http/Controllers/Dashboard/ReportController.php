<?php

namespace App\Http\Controllers\Dashboard;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class ReportController extends Controller
{
    public function index()
    {
        $currentMonth = now()->month;
        $currentYear  = now()->year;

        $monthlyRevenue = \App\Models\Payment::where('status', 'success')
            ->whereYear('paid_at', $currentYear)
            ->whereMonth('paid_at', $currentMonth)
            ->sum('amount');

        $totalClients    = \App\Models\Client::where('is_active', true)->count();
        $overdueCount    = \App\Models\Invoice::where('status', 'overdue')->count();
        $upcomingCount   = \App\Models\Invoice::where('status', 'unpaid')
            ->whereBetween('due_date', [now(), now()->addDays(30)])
            ->count();

        $monthlyData = \App\Models\Payment::where('status', 'success')
            ->whereYear('paid_at', $currentYear)
            ->selectRaw('MONTH(paid_at) as month, SUM(amount) as total')
            ->groupBy('month')
            ->orderBy('month')
            ->pluck('total', 'month')
            ->toArray();

        $overdueInvoices = \App\Models\Invoice::with('client')
            ->where('status', 'overdue')
            ->orderBy('due_date')
            ->get();

        $upcomingInvoices = \App\Models\Invoice::with('client')
            ->where('status', 'unpaid')
            ->whereBetween('due_date', [now(), now()->addDays(30)])
            ->orderBy('due_date')
            ->get();

        $totalRevenue = \App\Models\Payment::where('status', 'success')
            ->whereYear('paid_at', $currentYear)
            ->sum('amount');

        $collectionRate = \App\Models\Invoice::whereYear('created_at', $currentYear)->count() > 0
            ? round(\App\Models\Invoice::whereYear('created_at', $currentYear)->where('status', 'paid')->count()
                / \App\Models\Invoice::whereYear('created_at', $currentYear)->count() * 100, 1)
            : 0;

        return view('dashboard.reports.index', compact(
            'monthlyRevenue', 'totalClients', 'overdueCount', 'upcomingCount',
            'monthlyData', 'overdueInvoices', 'upcomingInvoices',
            'totalRevenue', 'collectionRate'
        ));
    }

    public function exportOverdue()
    {
        $invoices = \App\Models\Invoice::with('client')
            ->where('status', 'overdue')
            ->orderBy('due_date')
            ->get();

        $csv = "العميل,البريد الإلكتروني,رقم الفاتورة,المبلغ,تاريخ الاستحقاق,أيام التأخير\n";
        foreach ($invoices as $inv) {
            $days = (int) now()->startOfDay()->diffInDays($inv->due_date);
            $csv .= "{$inv->client->name},{$inv->client->email},{$inv->invoice_number},{$inv->amount},{$inv->due_date->format('Y-m-d')},{$days}\n";
        }

        return response($csv, 200, [
            'Content-Type'        => 'text/csv; charset=UTF-8',
            'Content-Disposition' => 'attachment; filename=overdue-' . now()->format('Y-m-d') . '.csv',
        ]);
    }

    public function perClient(Request $request, \App\Models\Client $client)
    {
        $payments = $client->payments()->with('invoice')->where('status', 'success')->latest()->get();
        $total    = $payments->sum('amount');
        return view('dashboard.reports.per-client', compact('client', 'payments', 'total'));
    }
}
