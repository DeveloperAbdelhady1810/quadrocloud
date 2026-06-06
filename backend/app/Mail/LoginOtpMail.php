<?php

namespace App\Mail;

use App\Models\Client;
use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Mail\Mailables\Address;
use Illuminate\Mail\Mailables\Envelope;
use Illuminate\Queue\SerializesModels;

class LoginOtpMail extends Mailable
{
    use Queueable, SerializesModels;

    public function __construct(
        public Client $client,
        public string $otp
    ) {}

    public function envelope(): Envelope
    {
        return new Envelope(
            from: new Address('noreply@quadrocloud.net', 'Quadro Cloud'),
            subject: 'كود الدخول - Quadro Cloud',
        );
    }

    public function content(): \Illuminate\Mail\Mailables\Content
    {
        return new \Illuminate\Mail\Mailables\Content(
            view: 'emails.login-otp',
        );
    }
}
