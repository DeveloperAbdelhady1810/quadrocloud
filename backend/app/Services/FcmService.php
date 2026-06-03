<?php

namespace App\Services;

use App\Models\Client;
use App\Models\NotificationLog;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class FcmService
{
    private string $projectId;
    private string $clientEmail;
    private string $privateKey;

    public function __construct()
    {
        $this->projectId   = config('firebase.project_id', '');
        $this->clientEmail = config('firebase.client_email', '');
        $this->privateKey  = str_replace('\\n', "\n", config('firebase.private_key', ''));
    }

    // ─── Public API ───────────────────────────────────────────────────────────

    public function sendToClient(Client $client, string $title, string $body, array $data = []): bool
    {
        if (! $client->fcm_token || ! $this->projectId) {
            return false;
        }

        $token = $this->getAccessToken();
        if (! $token) {
            return false;
        }

        $response = Http::withToken($token)
            ->post("https://fcm.googleapis.com/v1/projects/{$this->projectId}/messages:send", [
                'message' => [
                    'token'        => $client->fcm_token,
                    'notification' => [
                        'title' => $title,
                        'body'  => $body,
                    ],
                    'android' => [
                        'notification' => [
                            'channel_id' => 'quadro_cloud_high',
                            'sound'      => 'default',
                        ],
                    ],
                    'apns' => [
                        'payload' => [
                            'aps' => [
                                'sound' => 'default',
                                'badge' => 1,
                            ],
                        ],
                    ],
                    'data' => array_map('strval', $data),
                ],
            ]);

        if (! $response->successful()) {
            Log::error('FCM V1 send failed', [
                'client'   => $client->id,
                'response' => $response->body(),
            ]);
            return false;
        }

        return true;
    }

    public function notifyAndLog(
        Client $client,
        string $type,
        string $title,
        string $body,
        string $channel = 'push',
        $reference = null,
        array $data = []
    ): void {
        $sent = false;

        if (in_array($channel, ['push', 'both'])) {
            $sent = $this->sendToClient($client, $title, $body, $data);
        }

        NotificationLog::create([
            'client_id'      => $client->id,
            'type'           => $type,
            'channel'        => $channel,
            'title'          => $title,
            'body'           => $body,
            'reference_type' => $reference ? get_class($reference) : null,
            'reference_id'   => $reference?->id,
            'sent'           => $sent,
            'sent_at'        => now(),
        ]);
    }

    // ─── OAuth2 access token (cached for 55 min) ──────────────────────────────

    private function getAccessToken(): ?string
    {
        return Cache::remember('fcm_access_token', 3300, function () {
            return $this->fetchNewAccessToken();
        });
    }

    private function fetchNewAccessToken(): ?string
    {
        if (! $this->clientEmail || ! $this->privateKey) {
            Log::warning('FCM: missing service account credentials in .env');
            return null;
        }

        $now = time();
        $jwt = $this->buildJwt([
            'iss'   => $this->clientEmail,
            'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
            'aud'   => 'https://oauth2.googleapis.com/token',
            'iat'   => $now,
            'exp'   => $now + 3600,
        ]);

        $response = Http::asForm()->post('https://oauth2.googleapis.com/token', [
            'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
            'assertion'  => $jwt,
        ]);

        if (! $response->successful() || ! isset($response['access_token'])) {
            Log::error('FCM: failed to fetch OAuth2 token', ['body' => $response->body()]);
            return null;
        }

        return $response['access_token'];
    }

    // ─── Minimal JWT RS256 builder (no extra packages needed) ────────────────

    private function buildJwt(array $claims): string
    {
        $header  = $this->base64url(json_encode(['alg' => 'RS256', 'typ' => 'JWT']));
        $payload = $this->base64url(json_encode($claims));
        $input   = "{$header}.{$payload}";

        openssl_sign($input, $signature, $this->privateKey, OPENSSL_ALGO_SHA256);

        return "{$input}." . $this->base64url($signature);
    }

    private function base64url(string $data): string
    {
        return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
    }
}
