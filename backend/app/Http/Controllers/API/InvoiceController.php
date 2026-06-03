<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class InvoiceController extends Controller
{
    public function index(Request $request)
    {
        $invoices = $request->user()
            ->invoices()
            ->latest()
            ->get()
            ->map(fn($i) => [
                'id'             => $i->id,
                'invoice_number' => $i->invoice_number,
                'amount'         => $i->amount,
                'status'         => $i->status,
                'due_date'       => $i->due_date?->format('Y-m-d'),
                'paid_at'        => $i->paid_at?->format('Y-m-d H:i'),
                'payment_method' => $i->payment_method,
            ]);

        return response()->json($invoices);
    }

    public function download(Request $request, int $id)
    {
        $invoice = $request->user()->invoices()->findOrFail($id);

        if ($invoice->pdf_path && \Illuminate\Support\Facades\Storage::exists($invoice->pdf_path)) {
            return \Illuminate\Support\Facades\Storage::download($invoice->pdf_path, 'invoice-' . $invoice->invoice_number . '.pdf');
        }

        $pdf = \Barryvdh\DomPDF\Facade\Pdf::loadView('pdf.invoice', ['invoice' => $invoice]);
        $path = 'invoices/' . $invoice->invoice_number . '.pdf';
        \Illuminate\Support\Facades\Storage::put($path, $pdf->output());
        $invoice->update(['pdf_path' => $path]);

        return $pdf->download('invoice-' . $invoice->invoice_number . '.pdf');
    }
}
