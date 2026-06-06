<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Invoice extends Model
{
    protected $fillable = [
        'client_id', 'contract_id', 'additional_fee_id', 'description', 'invoice_number',
        'amount', 'status', 'due_date', 'paid_at', 'payment_method', 'pdf_path',
    ];

    protected function casts(): array
    {
        return [
            'amount' => 'decimal:2',
            'due_date' => 'date',
            'paid_at' => 'datetime',
        ];
    }

    protected static function boot(): void
    {
        parent::boot();
        static::creating(function ($invoice) {
            if (!$invoice->invoice_number) {
                $invoice->invoice_number = 'INV-' . strtoupper(date('Ym')) . '-' . str_pad(
                    static::whereYear('created_at', date('Y'))->whereMonth('created_at', date('m'))->count() + 1,
                    4, '0', STR_PAD_LEFT
                );
            }
        });
    }

    public function client()
    {
        return $this->belongsTo(Client::class);
    }

    public function contract()
    {
        return $this->belongsTo(Contract::class);
    }

    public function additionalFee()
    {
        return $this->belongsTo(AdditionalFee::class, 'additional_fee_id');
    }

    public function payment()
    {
        return $this->hasOne(Payment::class);
    }
}
