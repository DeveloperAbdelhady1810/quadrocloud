<?php

namespace App\Mail;

use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;
use Illuminate\Mail\Mailables\Address;
use Illuminate\Queue\SerializesModels;

class ServiceRequestMail extends Mailable
{
    use Queueable, SerializesModels;

    public function __construct(
        public string $serviceName,
        public string $senderName,
        public string $senderEmail,
        public string $senderPhone,
        public string $message,
    ) {}

    public function envelope(): Envelope
    {
        return new Envelope(
            from: new Address('contact@quadrocloud.net', 'Quadro Cloud'),
            subject: 'طلب خدمة جديد: ' . $this->serviceName,
        );
    }

    public function content(): Content
    {
        return new Content(view: 'emails.service-request');
    }
}
