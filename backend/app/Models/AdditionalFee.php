<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class AdditionalFee extends Model
{
    protected $fillable = [
        'client_id', 'created_by', 'title', 'description',
        'amount', 'due_date', 'acceptance_deadline', 'status',
    ];

    protected function casts(): array
    {
        return [
            'amount' => 'decimal:2',
            'due_date' => 'date',
            'acceptance_deadline' => 'date',
        ];
    }

    public function client()
    {
        return $this->belongsTo(Client::class);
    }

    public function creator()
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function invoice()
    {
        return $this->hasOne(Invoice::class, 'additional_fee_id');
    }
}
