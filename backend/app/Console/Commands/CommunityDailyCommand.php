<?php

namespace App\Console\Commands;

use App\Models\Client;
use App\Services\CommunityNotifier;
use App\Services\LeaderboardService;
use Illuminate\Console\Command;

class CommunityDailyCommand extends Command
{
    protected $signature   = 'community:daily';
    protected $description = 'Send community notifications: rank changes, anniversaries';

    public function handle(LeaderboardService $lb, CommunityNotifier $notifier): void
    {
        $ranked = $lb->ranked();

        foreach ($ranked as $row) {
            $client = Client::find($row->id);
            if (! $client) continue;

            $newRank = $row->rank;
            $oldRank = $client->last_rank;

            // Notify followers if client newly enters top 3 or becomes gold
            if ($newRank <= 3 && ($oldRank === null || $oldRank > 3)) {
                $medal = match ($newRank) { 1 => '🥇', 2 => '🥈', 3 => '🥉', default => '' };
                $notifier->notifyFollowers(
                    $client,
                    'rank_up',
                    "صعود في الترتيب {$medal}",
                    "{$client->public_name} دخل قائمة أفضل 3 عملاء!",
                    ['action' => 'leaderboard', 'action_id' => (string) $client->id]
                );
            }

            // Persist updated rank
            $client->update(['last_rank' => $newRank]);
        }

        // Contract anniversaries (1 yr, 2 yr, …)
        $today = now()->toDateString();
        $clients = Client::where('is_active', true)->with(['contracts' => fn($q) => $q->orderBy('start_date')])->get();

        foreach ($clients as $client) {
            $firstContract = $client->contracts->first();
            if (! $firstContract?->start_date) continue;

            $start    = $firstContract->start_date;
            $years    = now()->diffInYears($start);
            $anniversary = $start->copy()->addYears($years)->toDateString();

            if ($anniversary === $today && $years >= 1) {
                $notifier->notifyFollowers(
                    $client,
                    'milestone',
                    "ذكرى سنوية 🎂",
                    "{$client->public_name} مع Quadro Cloud منذ {$years} " . ($years === 1 ? 'سنة' : 'سنوات') . '!',
                    ['action' => 'community_profile', 'action_id' => (string) $client->id]
                );
            }
        }

        $this->info('Community daily notifications sent.');
    }
}
