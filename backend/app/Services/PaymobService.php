<?php

namespace App\Services;

use App\Models\Client;
use App\Models\Invoice;
use App\Models\Payment;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class PaymobService
{
    private string $secretKey;
    private string $publicKey;
    private string $hmacSecret;
    private array $paymentMethods;
    private string $baseUrl;
    private int $expiration;

    public function __construct()
    {
        $this->secretKey      = config('paymob.secret_key');
        $this->publicKey      = config('paymob.public_key');
        $this->hmacSecret     = config('paymob.hmac_secret');
        $this->paymentMethods = config('paymob.payment_methods');
        $this->baseUrl        = config('paymob.base_url');
        $this->expiration     = config('paymob.expiration');
    }

    // Fixed Paymob processing fee in EGP (500 piastres)
    private const TRANSACTION_FEE_CENTS = 500;

    public function createPaymentIntent(Invoice $invoice): array
    {
        $client       = $invoice->client;
        $invoiceCents = (int) ($invoice->amount * 100);
        $totalCents   = $invoiceCents + self::TRANSACTION_FEE_CENTS;
        $reference    = $client->email . '-INV' . $invoice->id . '-' . strtoupper(uniqid());

        $body = [
            'amount'          => $totalCents,
            'currency'        => 'EGP',
            'payment_methods' => $this->paymentMethods,
            'items'           => [
                [
                    'name'        => 'Invoice #' . $invoice->invoice_number,
                    'amount'      => $invoiceCents,
                    'description' => 'Quadro Cloud Service Fee',
                    'quantity'    => 1,
                    'id'          => (string) $invoice->id,
                ],
                [
                    'name'        => 'Paymob Transaction Fee',
                    'amount'      => self::TRANSACTION_FEE_CENTS,
                    'description' => 'Online payment processing fee',
                    'quantity'    => 1,
                    'id'          => 'fee-' . $invoice->id,
                ],
            ],
            'billing_data' => [
                'apartment'    => $client->address ?? 'NA',
                'first_name'   => explode(' ', $client->name)[0],
                'last_name'    => explode(' ', $client->name, 2)[1] ?? 'Client',
                'street'       => $client->address ?? 'NA',
                'building'     => 'NA',
                'phone_number' => $client->phone ?? '01000000000',
                'country'      => 'EG',
                'email'        => $client->email,
                'floor'        => 'NA',
                'state'        => 'NA',
            ],
            'customer' => [
                'first_name' => explode(' ', $client->name)[0],
                'last_name'  => explode(' ', $client->name, 2)[1] ?? 'Client',
                'email'      => $client->email,
            ],
            'special_reference' => $reference,
            'expiration'        => $this->expiration,
        ];

        $response = Http::withOptions([
                // Disable SSL verification on local dev (Windows lacks a CA bundle).
                // On production this must be true — set APP_ENV=production to enable.
                'verify' => app()->isProduction(),
            ])
            ->timeout(30)
            ->withHeaders([
                'Authorization' => 'Token ' . $this->secretKey,
                'Content-Type'  => 'application/json',
            ])->post($this->baseUrl . '/v1/intention/', $body);

        if (!$response->successful()) {
            Log::error('Paymob intention failed', ['response' => $response->body(), 'invoice' => $invoice->id]);
            throw new \RuntimeException('Failed to create Paymob payment intent: ' . $response->body());
        }

        $clientSecret = $response->json('client_secret');
        $paymentUrl   = $this->baseUrl . '/unifiedcheckout/?publicKey=' . $this->publicKey . '&clientSecret=' . $clientSecret;

        Payment::create([
            'invoice_id'        => $invoice->id,
            'client_id'         => $client->id,
            'amount'            => $invoice->amount + (self::TRANSACTION_FEE_CENTS / 100),
            'method'            => 'paymob',
            'special_reference' => $reference,
            'paymob_order_id'   => (string) ($response->json('id') ?? ''),
            'status'            => 'pending',
        ]);

        return [
            'payment_url'       => $paymentUrl,
            'special_reference' => $reference,
        ];
    }

    public function verifyWebhookHmac(array $data): bool
    {
        $requestHmac = $data['hmac'] ?? '';
        $obj = $data['obj'] ?? [];

        $string =
            ($obj['amount_cents'] ?? '') .
            ($obj['created_at'] ?? '') .
            ($obj['currency'] ?? '') .
            ($this->boolToString($obj['error_occured'] ?? false)) .
            ($this->boolToString($obj['has_parent_transaction'] ?? false)) .
            ($obj['id'] ?? '') .
            ($obj['integration_id'] ?? '') .
            ($this->boolToString($obj['is_3d_secure'] ?? false)) .
            ($this->boolToString($obj['is_auth'] ?? false)) .
            ($this->boolToString($obj['is_capture'] ?? false)) .
            ($this->boolToString($obj['is_refunded'] ?? false)) .
            ($this->boolToString($obj['is_standalone_payment'] ?? false)) .
            ($this->boolToString($obj['is_voided'] ?? false)) .
            ($obj['order']['id'] ?? '') .
            ($obj['owner'] ?? '') .
            ($this->boolToString($obj['pending'] ?? false)) .
            ($obj['source_data']['pan'] ?? 'NA') .
            ($obj['source_data']['sub_type'] ?? 'NA') .
            ($obj['source_data']['type'] ?? 'NA') .
            ($this->boolToString($obj['success'] ?? false));

        $calculated = hash_hmac('sha512', $string, $this->hmacSecret);
        return hash_equals($calculated, $requestHmac);
    }

    private function boolToString(mixed $value): string
    {
        if (is_bool($value)) {
            return $value ? 'true' : 'false';
        }
        return (string) $value;
    }
}
