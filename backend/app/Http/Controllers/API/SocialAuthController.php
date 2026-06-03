<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Client;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Str;

class SocialAuthController extends Controller
{
    /**
     * POST /api/v1/auth/social
     * Body: { provider: 'google'|'apple', token: '...', name?: '...', email?: '...', user_id?: '...' }
     */
    public function login(Request $request)
    {
        $request->validate([
            'provider' => 'required|in:google,apple',
            'token'    => 'required|string',
        ]);

        $provider = $request->provider;

        [$providerId, $email, $name, $avatar] = match ($provider) {
            'google' => $this->verifyGoogle($request->token),
            'apple'  => $this->verifyApple($request->token, $request->user_id, $request->name, $request->email),
        };

        if (! $providerId) {
            return response()->json(['message' => 'Invalid social token'], 401);
        }

        // Find or create client
        $idColumn = $provider === 'google' ? 'google_id' : 'apple_id';

        $client = Client::where($idColumn, $providerId)->first();

        if (! $client && $email) {
            $client = Client::where('email', $email)->first();
            if ($client) {
                // Link social ID to existing account
                $client->update([$idColumn => $providerId]);
            }
        }

        if (! $client) {
            if (! $email) {
                return response()->json(['message' => 'Email is required for first-time sign-in'], 422);
            }
            $client = Client::create([
                $idColumn    => $providerId,
                'email'      => $email,
                'name'       => $name ?? explode('@', $email)[0],
                'avatar'     => $avatar,
                'password'   => null,
                'locale'     => 'ar',
                'is_active'  => true,
            ]);
        }

        if (! $client->is_active) {
            return response()->json(['message' => 'Account is deactivated'], 403);
        }

        $token = $client->createToken('mobile')->plainTextToken;

        return response()->json([
            'token'  => $token,
            'client' => $this->clientData($client),
        ]);
    }

    // ─── Google verification ───────────────────────────────────────────────

    private function verifyGoogle(string $idToken): array
    {
        $res = Http::withOptions(['verify' => app()->isProduction()])->timeout(10)->get('https://oauth2.googleapis.com/tokeninfo', [
            'id_token' => $idToken,
        ]);

        if ($res->failed() || ! isset($res['sub'])) {
            return [null, null, null, null];
        }

        return [
            $res['sub'],
            $res['email'] ?? null,
            $res['name'] ?? null,
            $res['picture'] ?? null,
        ];
    }

    // ─── Apple verification ────────────────────────────────────────────────
    // We decode the JWT payload (base64) to extract claims.
    // Full RS256 signature verification requires fetching Apple's public keys.
    // For production, add `lcobucci/jwt` and verify against https://appleid.apple.com/auth/keys

    private function verifyApple(string $identityToken, ?string $userId, ?string $name, ?string $email): array
    {
        try {
            $parts = explode('.', $identityToken);
            if (count($parts) !== 3) {
                return [null, null, null, null];
            }
            $payload = json_decode(base64_decode(str_pad(
                strtr($parts[1], '-_', '+/'),
                strlen($parts[1]) + (4 - strlen($parts[1]) % 4) % 4,
                '='
            )), true);

            if (! isset($payload['sub'])) {
                return [null, null, null, null];
            }

            // Verify issuer
            if (($payload['iss'] ?? '') !== 'https://appleid.apple.com') {
                return [null, null, null, null];
            }

            // Check expiry
            if (isset($payload['exp']) && $payload['exp'] < time()) {
                return [null, null, null, null];
            }

            $resolvedEmail = $payload['email'] ?? $email;

            return [$payload['sub'], $resolvedEmail, $name, null];
        } catch (\Throwable) {
            return [null, null, null, null];
        }
    }

    private function clientData(Client $client): array
    {
        return [
            'id'           => $client->id,
            'name'         => $client->name,
            'email'        => $client->email,
            'phone'        => $client->phone,
            'company_name' => $client->company_name,
            'avatar'       => $client->avatar,
            'locale'       => $client->locale ?? 'ar',
            'is_active'    => $client->is_active,
        ];
    }
}
