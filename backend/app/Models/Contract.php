<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Contract extends Model
{
    protected $fillable = [
        'client_id', 'service_id', 'custom_name', 'price', 'billing_cycle',
        'start_date', 'next_due_date', 'end_date', 'status', 'grace_period_days',
        'notes', 'created_by',
    ];

    protected function casts(): array
    {
        return [
            'price' => 'decimal:2',
            'start_date' => 'date',
            'next_due_date' => 'date',
            'end_date' => 'date',
        ];
    }

    public function client()
    {
        return $this->belongsTo(Client::class);
    }

    public function service()
    {
        return $this->belongsTo(ServiceCatalog::class, 'service_id');
    }

    public function creator()
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function invoices()
    {
        return $this->hasMany(Invoice::class);
    }

    public function getDisplayNameAttribute(): string
    {
        return $this->custom_name ?? $this->service?->name ?? 'Service';
    }

    public function advanceNextDueDate(): void
    {
        $this->next_due_date = match ($this->billing_cycle) {
            'monthly'   => $this->next_due_date->addMonth(),
            'quarterly' => $this->next_due_date->addMonths(3),
            'annually'  => $this->next_due_date->addYear(),
        };
        $this->save();
    }
}
