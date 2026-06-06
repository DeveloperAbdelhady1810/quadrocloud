<?php

namespace App\Observers;

use App\Mail\InvoiceMail;
use App\Models\Invoice;
use Illuminate\Support\Facades\Mail;

class InvoiceObserver
{
    public function created(Invoice $invoice): void
    {
        try {
            $invoice->load(['client', 'contract', 'additionalFee']);
            Mail::to($invoice->client->email)->send(new InvoiceMail($invoice));
        } catch (\Throwable) {
            // Never block invoice creation due to mail failure
        }
    }

    public function updated(Invoice $invoice): void
    {
        // When an invoice transitions to paid, advance the contract's next_due_date
        if ($invoice->wasChanged('status') && $invoice->status === 'paid' && $invoice->contract_id) {
            try {
                $invoice->contract()->first()?->advanceNextDueDate();
            } catch (\Throwable) {}
        }
    }
}
