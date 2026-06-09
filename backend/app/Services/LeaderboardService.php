<?php

namespace App\Services;

use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use App\Models\Client;

class LeaderboardService
{
    /**
     * Returns clients ranked by their total loyalty score.
     * Score per paid invoice:
     *   +20  paid ≥3 days before due_date
     *   +10  paid on or before due_date
     *   +3   paid within grace_period_days after due_date
     *   -10  paid after grace period (or no contract grace)
     *
     * Clients with hide_all=true and inactive clients are excluded.
     */
    public function ranked(?int $limit = null): Collection
    {
        $sql = "
            SELECT
                c.id,
                c.name,
                c.company_name,
                c.avatar,
                c.hide_name,
                c.hide_company,
                c.hide_all,
                c.last_rank,
                COALESCE(SUM(
                    CASE
                        WHEN DATEDIFF(i.paid_at, i.due_date) <= -3                                           THEN 20
                        WHEN DATEDIFF(i.paid_at, i.due_date) <= 0                                            THEN 10
                        WHEN con.grace_period_days IS NOT NULL
                             AND DATEDIFF(i.paid_at, i.due_date) <= con.grace_period_days                    THEN 3
                        ELSE -10
                    END
                ), 0) AS score
            FROM clients c
            LEFT JOIN invoices i
                ON i.client_id = c.id
                AND i.status = 'paid'
                AND i.paid_at IS NOT NULL
                AND i.due_date IS NOT NULL
            LEFT JOIN contracts con ON con.id = i.contract_id
            WHERE c.hide_all = 0
              AND c.is_active = 1
            GROUP BY c.id, c.name, c.company_name, c.avatar, c.hide_name, c.hide_company, c.hide_all, c.last_rank
            ORDER BY score DESC
        ";

        if ($limit) {
            $sql .= " LIMIT {$limit}";
        }

        $rows = DB::select($sql);

        return collect($rows)->values()->map(function ($row, $index) {
            $row->rank = $index + 1;
            return $row;
        });
    }

    public function goldClient(): ?object
    {
        return $this->ranked(1)->first();
    }

    /**
     * If the given client is currently rank #1 (gold), apply 5% discount.
     * Returns [finalAmount, wasDiscounted].
     */
    public function applyGoldDiscount(Client $client, float $amount): array
    {
        $gold = $this->goldClient();

        if ($gold && $gold->id === $client->id && $gold->score > 0) {
            return [round($amount * 0.95, 2), true];
        }

        return [$amount, false];
    }

    /**
     * Return a client's current rank and score, or null if not on the board.
     */
    public function clientStats(int $clientId): ?object
    {
        return $this->ranked()->firstWhere('id', $clientId);
    }
}
