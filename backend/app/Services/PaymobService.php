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

    public function createPaymentIntent(Invoice $invoice): array
    {
        $client    = $invoice->client;
        $amountCents = (int) ($invoice->amount * 100);
        $reference = $client->email . '-INV' . $invoice->id . '-' . strtoupper(uniqid());

        $body = [
            'amount'          => $amountCents,
            'currency'        => 'EGP',
            'payment_methods' => $this->paymentMethods,
            'items'           => [[
                'name'        => 'Invoice #' . $invoice->invoice_number,
                'amount'      => $amountCents,
                'description' => 'Quadro Cloud Service Fee',
                'quantity'    => 1,
                'id'          => (string) $invoice->id,
            ]],
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

        $response = Http::withHeaders([
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
            'invoice_id'         => $invoice->id,
            'client_id'          => $client->id,
            'amount'             => $invoice->amount,
            'method'             => 'paymob',
            'special_reference'  => $reference,
            'status'             => 'pending',
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
