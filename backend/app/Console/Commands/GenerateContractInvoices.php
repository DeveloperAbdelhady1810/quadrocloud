<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;

class GenerateContractInvoices extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'contracts:generate-invoices';
    protected $description = 'Generate invoices for contracts whose next_due_date is today';

    public function handle(): void
    {
        $today = now()->toDateString();

        $contracts = \App\Models\Contract::with('client')
            ->where('status', 'active')
            ->whereDate('next_due_date', $today)
            ->get();

        foreach ($contracts as $contract) {
            $exists = \App\Models\Invoice::where('contract_id', $contract->id)
                ->whereDate('due_date', $today)
                ->exists();

            if ($exists) continue;

            \App\Models\Invoice::create([
                'client_id'   => $contract->client_id,
                'contract_id' => $contract->id,
                'amount'      => $contract->price,
                'status'      => 'unpaid',
                'due_date'    => $today,
            ]);

            $contract->advanceNextDueDate();

            $this->info("Invoice generated for contract #{$contract->id} (client #{$contract->client_id})");
        }

        $this->info('Contract invoices generated.');
    }
}
