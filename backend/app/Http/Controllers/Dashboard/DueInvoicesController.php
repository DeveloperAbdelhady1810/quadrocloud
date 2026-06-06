<?php

namespace App\Http\Controllers\Dashboard;

use App\Http\Controllers\Controller;
use App\Models\Contract;
use App\Models\Invoice;
use Illuminate\Http\Request;

class DueInvoicesController extends Controller
{
    public function index()
    {
        // Active contracts whose next_due_date has arrived and have no invoice for this period yet
        $due = Contract::with(['client', 'service'])
            ->where('status', 'active')
            ->whereNotNull('next_due_date')
            ->whereDate('next_due_date', '<=', now())
            ->whereDoesntHave('invoices', fn($q) => $q->whereColumn('invoices.created_at', '>=', 'contracts.next_due_date'))
            ->orderBy('next_due_date')
            ->get();

        // Already has an unpaid invoice (pending payment)
        $pending = Contract::with(['client', 'service', 'invoices' => fn($q) => $q->whereIn('status', ['unpaid', 'overdue'])->latest()])
            ->where('status', 'active')
            ->whereHas('invoices', fn($q) => $q->whereIn('status', ['unpaid', 'overdue']))
            ->orderBy('next_due_date')
            ->get();

        return view('dashboard.due-invoices.index', compact('due', 'pending'));
    }

    public function generate(Request $request)
    {
        $ids = $request->input('contract_ids', []);

        if (empty($ids)) {
            return back()->with('error', 'لم تختر أي عقد.');
        }

        $contracts = Contract::with('client')
            ->whereIn('id', $ids)
            ->where('status', 'active')
            ->whereDoesntHave('invoices', fn($q) => $q->whereIn('status', ['unpaid', 'overdue']))
            ->get();

        $count = 0;
        foreach ($contracts as $contract) {
            Invoice::create([
                'client_id'   => $contract->client_id,
                'contract_id' => $contract->id,
                'amount'      => $contract->price,
                'status'      => 'unpaid',
                'due_date'    => now()->toDateString(),
                'description' => $contract->display_name,
            ]);
            $count++;
        }

        return back()->with('success', "تم إنشاء {$count} فاتورة بنجاح وإرسالها للعملاء.");
    }

    public function generateAll()
    {
        $contracts = Contract::with('client')
            ->where('status', 'active')
            ->whereNotNull('next_due_date')
            ->whereDate('next_due_date', '<=', now())
            ->whereDoesntHave('invoices', fn($q) => $q->whereIn('status', ['unpaid', 'overdue']))
            ->get();

        $count = 0;
        foreach ($contracts as $contract) {
            Invoice::create([
                'client_id'   => $contract->client_id,
                'contract_id' => $contract->id,
                'amount'      => $contract->price,
                'status'      => 'unpaid',
                'due_date'    => now()->toDateString(),
                'description' => $contract->display_name,
            ]);
            $count++;
        }

        return back()->with('success', $count > 0
            ? "تم إنشاء {$count} فاتورة لجميع المستحقات."
            : 'لا توجد مستحقات جديدة لإنشاء فواتير لها.');
    }
}
