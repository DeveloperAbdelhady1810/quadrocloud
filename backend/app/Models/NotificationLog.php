<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class NotificationLog extends Model
{
    protected $fillable = [
        'client_id', 'type', 'channel', 'title', 'body',
        'reference_type', 'reference_id', 'sent', 'sent_at',
    ];

    protected function casts(): array
    {
        return [
            'sent' => 'boolean',
            'sent_at' => 'datetime',
        ];
    }

    public function client()
    {
        return $this->belongsTo(Client::class);
    }

    public function reference()
    {
        return $this->morphTo();
    }
}
