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
        'hide_name',
        'hide_company',
        'hide_all',
        'visibility_request',
        'visibility_requested_at',
        'last_rank',
    ];

    protected $hidden = [
        'password',
        'remember_token',
        'notes',
    ];

    protected function casts(): array
    {
        return [
            'email_verified_at'       => 'datetime',
            'password'                => 'hashed',
            'is_active'               => 'boolean',
            'hide_name'               => 'boolean',
            'hide_company'            => 'boolean',
            'hide_all'                => 'boolean',
            'visibility_requested_at' => 'datetime',
        ];
    }

    // ─── Community visibility accessors ──────────────────────────────────────

    public function getPublicNameAttribute(): string
    {
        return ($this->hide_name || $this->hide_all) ? 'عميل Quadro' : $this->name;
    }

    public function getPublicCompanyAttribute(): ?string
    {
        return ($this->hide_company || $this->hide_all) ? null : $this->company_name;
    }

    // ─── Follow relationships ─────────────────────────────────────────────────

    public function following()
    {
        return $this->belongsToMany(Client::class, 'client_follows', 'follower_id', 'followed_id')->withTimestamps();
    }

    public function followers()
    {
        return $this->belongsToMany(Client::class, 'client_follows', 'followed_id', 'follower_id')->withTimestamps();
    }

    public function isFollowedBy(Client $client): bool
    {
        return $this->followers()->where('follower_id', $client->id)->exists();
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
