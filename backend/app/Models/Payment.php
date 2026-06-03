<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Payment extends Model
{
    protected $fillable = [
        'invoice_id', 'client_id', 'amount', 'method',
        'paymob_transaction_id', 'paymob_order_id', 'special_reference',
        'status', 'marked_cash_by', 'raw_response', 'paid_at',
    ];

    protected function casts(): array
    {
        return [
            'amount' => 'decimal:2',
            'raw_response' => 'array',
            'paid_at' => 'datetime',
        ];
    }

    public function invoice()
    {
        return $this->belongsTo(Invoice::class);
    }

    public function client()
    {
        return $this->belongsTo(Client::class);
    }

    public function markedBy()
    {
        return $this->belongsTo(User::class, 'marked_cash_by');
    }
}
