<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class TicketMessage extends Model
{
    protected $fillable = ['ticket_id', 'sender_type', 'sender_id', 'message', 'attachments'];

    protected function casts(): array
    {
        return ['attachments' => 'array'];
    }

    public function ticket()
    {
        return $this->belongsTo(SupportTicket::class, 'ticket_id');
    }

    public function sender()
    {
        return $this->morphTo();
    }
}
