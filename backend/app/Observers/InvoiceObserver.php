<?php

namespace App\Observers;

use App\Mail\InvoiceMail;
use App\Models\Invoice;
use App\Services\CommunityNotifier;
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
        if (! $invoice->wasChanged('status') || $invoice->status !== 'paid') {
            return;
        }

        // Advance next_due_date on the linked contract
        if ($invoice->contract_id) {
            try {
                $invoice->contract()->first()?->advanceNextDueDate();
            } catch (\Throwable) {}
        }

        // Check for perfect-payer streak milestones (5, 10 consecutive on-time)
        try {
            $this->checkPayerStreak($invoice);
        } catch (\Throwable) {}
    }

    private function checkPayerStreak(Invoice $invoice): void
    {
        $client = $invoice->client;

        // Fetch last N paid invoices with a due_date (most recent first)
        $recentPaid = $client->invoices()
            ->whereNotNull('due_date')
            ->whereNotNull('paid_at')
            ->where('status', 'paid')
            ->orderByDesc('paid_at')
            ->limit(10)
            ->get();

        if ($recentPaid->isEmpty()) return;

        $streak = 0;
        foreach ($recentPaid as $inv) {
            if ($inv->paid_at->lte($inv->due_date)) {
                $streak++;
            } else {
                break; // Streak broken
            }
        }

        if (! in_array($streak, [5, 10])) return;

        $notifier = app(CommunityNotifier::class);
        $notifier->notifyFollowers(
            $client,
            'milestone',
            'إنجاز رائع! 🎉',
            "{$client->public_name} حقق سلسلة {$streak} دفعات في الموعد!",
            ['action' => 'community_profile', 'action_id' => (string) $client->id]
        );
    }
}
