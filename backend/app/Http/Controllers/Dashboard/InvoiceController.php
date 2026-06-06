<?php

namespace App\Http\Controllers\Dashboard;

use App\Http\Controllers\Controller;
use App\Models\Client;
use App\Models\Invoice;
use Illuminate\Http\Request;

class InvoiceController extends Controller
{
    public function create(Request $request)
    {
        $clients  = Client::where('is_active', true)->orderBy('name')->get();
        $selected = $request->client_id ? Client::find($request->client_id) : null;
        return view('dashboard.invoices.create', compact('clients', 'selected'));
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'client_id'   => 'required|exists:clients,id',
            'description' => 'required|string|max:255',
            'amount'      => 'required|numeric|min:1',
            'due_date'    => 'required|date|after_or_equal:today',
        ]);

        $invoice = Invoice::create([
            'client_id'   => $data['client_id'],
            'description' => $data['description'],
            'amount'      => $data['amount'],
            'due_date'    => $data['due_date'],
            'status'      => 'unpaid',
        ]);

        \App\Models\ActivityLog::record('invoice_created', $invoice, [], $invoice->toArray());

        return redirect()
            ->route('dashboard.clients.show', $invoice->client_id)
            ->with('success', 'تم إنشاء الفاتورة #' . $invoice->invoice_number . ' وإرسالها للعميل بالبريد الإلكتروني');
    }
}
