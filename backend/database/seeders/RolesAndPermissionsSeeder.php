<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class RolesAndPermissionsSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        app()[\Spatie\Permission\PermissionRegistrar::class]->forgetCachedPermissions();

        $permissions = [
            'manage_team',
            'create_clients', 'edit_clients', 'view_clients',
            'add_fees', 'cancel_fees',
            'mark_cash_payments', 'view_payments',
            'view_reports',
            'reply_tickets', 'close_tickets',
            'view_activity_log',
            'manage_contracts',
        ];

        foreach ($permissions as $perm) {
            \Spatie\Permission\Models\Permission::firstOrCreate(['name' => $perm]);
        }

        $superAdmin = \Spatie\Permission\Models\Role::firstOrCreate(['name' => 'super-admin']);
        $admin      = \Spatie\Permission\Models\Role::firstOrCreate(['name' => 'admin']);
        $staff      = \Spatie\Permission\Models\Role::firstOrCreate(['name' => 'staff']);

        $superAdmin->syncPermissions($permissions);

        $admin->syncPermissions([
            'create_clients', 'edit_clients', 'view_clients',
            'add_fees', 'cancel_fees',
            'mark_cash_payments', 'view_payments',
            'view_reports',
            'reply_tickets', 'close_tickets',
            'manage_contracts',
        ]);

        $staff->syncPermissions([
            'view_clients',
            'mark_cash_payments', 'view_payments',
            'view_reports',
            'reply_tickets',
        ]);
    }
}
