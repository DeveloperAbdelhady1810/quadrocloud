<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ServiceCatalog extends Model
{
    protected $table = 'service_catalog';

    protected $fillable = ['name', 'description', 'default_price', 'show_price', 'is_public', 'image_path', 'icon', 'is_active'];

    protected function casts(): array
    {
        return [
            'default_price' => 'decimal:2',
            'is_active' => 'boolean',
            'show_price' => 'boolean',
            'is_public' => 'boolean',
        ];
    }

    public function contracts()
    {
        return $this->hasMany(Contract::class, 'service_id');
    }
}
