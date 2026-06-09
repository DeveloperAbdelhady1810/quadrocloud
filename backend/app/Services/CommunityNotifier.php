<?php

namespace App\Services;

use App\Models\Client;

class CommunityNotifier
{
    public function __construct(private FcmService $fcm) {}

    /**
     * Send a push notification to every follower of $actor.
     * $data must include 'action' and 'action_id' (all string values).
     */
    public function notifyFollowers(
        Client $actor,
        string $type,
        string $title,
        string $body,
        array  $data = []
    ): void {
        foreach ($actor->followers as $follower) {
            $this->fcm->notifyAndLog(
                $follower,
                $type,
                $title,
                $body,
                'push',
                null,
                $data
            );
        }
    }
}
