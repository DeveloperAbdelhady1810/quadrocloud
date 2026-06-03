<?php

namespace App\Console\Commands;

use App\Models\Contract;
use App\Models\Invoice;
use Illuminate\Console\Command;

class GenerateContractInvoices extends Command
{
    protected $signature = 'contracts:generate-invoices';
    protected $description = 'Generate invoices for contracts due today OR overdue with no unpaid invoice';

    public function handle(): void
    {
        $today = now()->toDateString();

        // Include contracts due today AND overdue ones that never got an invoice
        $contracts = Contract::with('client')
            ->where('status', 'active')
            ->whereDate('next_due_date', '<=', $today)
            ->get();

        $generated = 0;

        foreach ($contracts as $contract) {
            // Skip if there's already an unpaid/overdue invoice for this contract period
            $hasOpenInvoice = Invoice::where('contract_id', $contract->id)
                ->whereIn('status', ['unpaid', 'overdue'])
                ->exists();

            if ($hasOpenInvoice) continue;

            $dueDate = $contract->next_due_date->toDateString();

            Invoice::create([
                'client_id'   => $contract->client_id,
                'contract_id' => $contract->id,
                'amount'      => $contract->price,
                'status'      => 'unpaid',
                'due_date'    => $dueDate,
            ]);

            $contract->advanceNextDueDate();
            $generated++;

            $this->info("Invoice generated for contract #{$contract->id} (client #{$contract->client_id}) — due: {$dueDate}");
        }

        $this->info("Done. {$generated} invoice(s) generated.");
    }
}
