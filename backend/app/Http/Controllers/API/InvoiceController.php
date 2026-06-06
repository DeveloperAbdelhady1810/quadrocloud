<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Mail\InvoiceMail;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Mail;

class InvoiceController extends Controller
{
    public function index(Request $request)
    {
        $invoices = $request->user()
            ->invoices()
            ->latest()
            ->get()
            ->map(fn($i) => $this->formatInvoice($i));

        return response()->json($invoices);
    }

    public function show(Request $request, int $id)
    {
        $invoice = $request->user()->invoices()->with(['contract', 'additionalFee'])->findOrFail($id);

        return response()->json($this->formatInvoice($invoice));
    }

    public function sendEmail(Request $request, int $id)
    {
        $invoice = $request->user()->invoices()->with(['client', 'contract', 'additionalFee'])->findOrFail($id);

        try {
            Mail::to($invoice->client->email)->send(new InvoiceMail($invoice));
        } catch (\Throwable $e) {
            return response()->json(['message' => 'فشل إرسال البريد الإلكتروني'], 500);
        }

        return response()->json(['message' => 'تم إرسال الفاتورة بنجاح إلى ' . $invoice->client->email]);
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

    private function formatInvoice($i): array
    {
        return [
            'id'             => $i->id,
            'invoice_number' => $i->invoice_number,
            'amount'         => (float) $i->amount,
            'status'         => $i->status,
            'due_date'       => $i->due_date?->format('Y-m-d'),
            'paid_at'        => $i->paid_at?->format('Y-m-d H:i'),
            'payment_method' => $i->payment_method,
            'description'    => $i->description ?? $i->contract?->display_name ?? $i->additionalFee?->title ?? 'خدمة Quadro Cloud',
        ];
    }
}
