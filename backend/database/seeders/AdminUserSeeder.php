<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class AdminUserSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $admin = \App\Models\User::firstOrCreate(
            ['email' => 'admin@quadrocloud.com'],
            [
                'name'      => 'Ahmed - Quadro Cloud',
                'password'  => \Illuminate\Support\Facades\Hash::make('Admin@123'),
                'is_active' => true,
            ]
        );

        $admin->assignRole('super-admin');
    }
}
