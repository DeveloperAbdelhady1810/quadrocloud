<?php

namespace App\Models;

use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class Client extends Authenticatable
{
    use Notifiable, HasApiTokens;

    protected $fillable = [
        'name',
        'email',
        'password',
        'phone',
        'company_name',
        'address',
        'notes',
        'google_id',
        'apple_id',
        'avatar',
        'fcm_token',
        'locale',
        'login_otp',
        'otp_expires_at',
        'is_active',
        'created_by',
    ];

    protected $hidden = [
        'password',
        'remember_token',
        'notes',
    ];

    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
            'is_active' => 'boolean',
        ];
    }

    public function contracts()
    {
        return $this->hasMany(Contract::class);
    }

    public function additionalFees()
    {
        return $this->hasMany(AdditionalFee::class);
    }

    public function invoices()
    {
        return $this->hasMany(Invoice::class);
    }

    public function payments()
    {
        return $this->hasMany(Payment::class);
    }

    public function supportTickets()
    {
        return $this->hasMany(SupportTicket::class);
    }

    public function notificationLogs()
    {
        return $this->hasMany(NotificationLog::class);
    }

    public function creator()
    {
        return $this->belongsTo(User::class, 'created_by');
    }
}
