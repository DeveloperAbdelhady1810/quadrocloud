<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;

class SendPaymentReminders extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'fees:send-reminders';
    protected $description = 'Send daily payment reminders and overdue warnings to clients';

    public function handle(): void
    {
        $fcm = app(\App\Services\FcmService::class);

        // Mark overdue invoices
        \App\Models\Invoice::where('status', 'unpaid')
            ->where('due_date', '<', now()->startOfDay())
            ->update(['status' => 'overdue']);

        // Reminders for upcoming invoices (1-5 days)
        for ($days = 1; $days <= 5; $days++) {
            $targetDate = now()->addDays($days)->toDateString();
            $invoices = \App\Models\Invoice::with('client')
                ->where('status', 'unpaid')
                ->whereDate('due_date', $targetDate)
                ->get();

            foreach ($invoices as $invoice) {
                $client = $invoice->client;
                if (!$client->is_active) continue;

                $alreadySent = \App\Models\NotificationLog::where('client_id', $client->id)
                    ->where('reference_type', \App\Models\Invoice::class)
                    ->where('reference_id', $invoice->id)
                    ->whereDate('sent_at', today())
                    ->exists();

                if ($alreadySent) continue;

                $title = $days === 1 ? 'موعد الدفع غداً!' : "موعد الدفع بعد {$days} أيام";
                $body  = "الفاتورة {$invoice->invoice_number} بمبلغ {$invoice->amount} ج.م";

                $fcm->notifyAndLog($client, 'reminder_' . $days . 'day', $title, $body, 'push', $invoice);
                $this->info("Reminder sent to client #{$client->id} for invoice #{$invoice->id} ({$days} days)");
            }
        }

        // Daily overdue warnings
        $overdueInvoices = \App\Models\Invoice::with('client')
            ->where('status', 'overdue')
            ->get();

        foreach ($overdueInvoices as $invoice) {
            $client = $invoice->client;
            if (!$client->is_active) continue;

            $daysOverdue = (int) now()->startOfDay()->diffInDays($invoice->due_date);
            $title = '⚠️ تحذير: فاتورة متأخرة!';
            $body  = "الفاتورة {$invoice->invoice_number} متأخرة منذ {$daysOverdue} يوم. المبلغ: {$invoice->amount} ج.م";

            $fcm->notifyAndLog($client, 'overdue', $title, $body, 'push', $invoice);
        }

        $this->info('Payment reminders sent successfully.');
    }
}
