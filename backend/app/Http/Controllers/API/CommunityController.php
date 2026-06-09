<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Client;
use App\Services\LeaderboardService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CommunityController extends Controller
{
    public function __construct(private LeaderboardService $leaderboard) {}

    // GET /community/clients — all visible clients with score + follow state
    public function clients(Request $request): JsonResponse
    {
        $me = $request->user();
        $ranked = $this->leaderboard->ranked();

        $myFollowingIds = $me->following()->pluck('clients.id')->toArray();

        $clients = Client::where('is_active', true)
            ->where('hide_all', false)
            ->withCount('contracts')
            ->get()
            ->map(function (Client $c) use ($ranked, $myFollowingIds, $me) {
                $stats = $ranked->firstWhere('id', $c->id);
                return [
                    'id'              => $c->id,
                    'public_name'     => $c->public_name,
                    'public_company'  => $c->public_company,
                    'avatar'          => $c->avatar,
                    'contracts_count' => $c->contracts_count,
                    'score'           => $stats ? (int) $stats->score : 0,
                    'rank'            => $stats ? $stats->rank : null,
                    'is_following'    => in_array($c->id, $myFollowingIds),
                    'is_me'           => $c->id === $me->id,
                ];
            })
            ->sortByDesc('score')
            ->values();

        return response()->json($clients);
    }

    // GET /community/leaderboard — ranked entries + caller's own rank
    public function leaderboard(Request $request): JsonResponse
    {
        $me = $request->user();
        $ranked = $this->leaderboard->ranked();
        $myFollowingIds = $me->following()->pluck('clients.id')->toArray();

        $entries = $ranked->map(function ($row) use ($myFollowingIds, $me) {
            $medal = match ($row->rank) {
                1 => 'gold',
                2 => 'silver',
                3 => 'bronze',
                default => null,
            };
            return [
                'client_id'      => $row->id,
                'display_name'   => ($row->hide_name || $row->hide_all) ? 'عميل Quadro' : $row->name,
                'company'        => ($row->hide_company || $row->hide_all) ? null : $row->company_name,
                'avatar'         => $row->avatar,
                'score'          => (int) $row->score,
                'rank'           => $row->rank,
                'medal'          => $medal,
                'is_gold'        => $row->rank === 1 && $row->score > 0,
                'is_me'          => $row->id === $me->id,
                'is_following'   => in_array($row->id, $myFollowingIds),
            ];
        });

        $myStats = $ranked->firstWhere('id', $me->id);

        return response()->json([
            'entries'   => $entries->values(),
            'my_rank'   => $myStats ? $myStats->rank : null,
            'my_score'  => $myStats ? (int) $myStats->score : 0,
        ]);
    }

    // GET /community/clients/{id} — public profile
    public function profile(Request $request, int $id): JsonResponse
    {
        $me = $request->user();
        $client = Client::withCount(['contracts', 'followers', 'following'])->findOrFail($id);

        if ($client->hide_all) {
            return response()->json(['message' => 'هذا الملف الشخصي مخفي'], 403);
        }

        $stats = $this->leaderboard->clientStats($id);

        return response()->json([
            'id'               => $client->id,
            'public_name'      => $client->public_name,
            'public_company'   => $client->public_company,
            'avatar'           => $client->avatar,
            'contracts_count'  => $client->contracts_count,
            'followers_count'  => $client->followers_count,
            'following_count'  => $client->following_count,
            'score'            => $stats ? (int) $stats->score : 0,
            'rank'             => $stats ? $stats->rank : null,
            'is_following'     => $client->isFollowedBy($me),
            'is_me'            => $client->id === $me->id,
            'member_since'     => $client->created_at->format('Y-m-d'),
        ]);
    }

    // POST /community/clients/{id}/follow
    public function follow(Request $request, int $id): JsonResponse
    {
        $me = $request->user();

        if ($me->id === $id) {
            return response()->json(['message' => 'لا يمكنك متابعة نفسك'], 422);
        }

        $target = Client::findOrFail($id);
        $me->following()->syncWithoutDetaching([$id]);

        return response()->json(['following' => true, 'followers_count' => $target->fresh()->followers()->count()]);
    }

    // POST /community/clients/{id}/unfollow
    public function unfollow(Request $request, int $id): JsonResponse
    {
        $me = $request->user();
        $target = Client::findOrFail($id);
        $me->following()->detach($id);

        return response()->json(['following' => false, 'followers_count' => $target->fresh()->followers()->count()]);
    }

    // GET /community/following
    public function following(Request $request): JsonResponse
    {
        $list = $request->user()->following()->where('is_active', true)->get()->map(fn(Client $c) => [
            'id'             => $c->id,
            'public_name'    => $c->public_name,
            'public_company' => $c->public_company,
            'avatar'         => $c->avatar,
        ]);

        return response()->json($list);
    }

    // GET /community/followers
    public function followers(Request $request): JsonResponse
    {
        $list = $request->user()->followers()->where('is_active', true)->get()->map(fn(Client $c) => [
            'id'             => $c->id,
            'public_name'    => $c->public_name,
            'public_company' => $c->public_company,
            'avatar'         => $c->avatar,
        ]);

        return response()->json($list);
    }

    // POST /community/visibility-request
    public function visibilityRequest(Request $request): JsonResponse
    {
        $request->validate(['scope' => 'required|in:hide_name,hide_company,hide_all']);

        $request->user()->update([
            'visibility_request'      => $request->scope,
            'visibility_requested_at' => now(),
        ]);

        return response()->json(['message' => 'تم إرسال طلبك للمراجعة']);
    }
}
