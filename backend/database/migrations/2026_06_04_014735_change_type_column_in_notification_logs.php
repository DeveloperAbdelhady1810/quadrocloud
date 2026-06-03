<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // Change ENUM to VARCHAR so any notification type string is accepted
        \Illuminate\Support\Facades\DB::statement(
            "ALTER TABLE notification_logs MODIFY COLUMN `type` VARCHAR(50) NOT NULL"
        );
    }

    public function down(): void
    {
        \Illuminate\Support\Facades\DB::statement(
            "ALTER TABLE notification_logs MODIFY COLUMN `type` ENUM('reminder_5day','reminder_daily','overdue','fee_added','payment_confirmed','manual') NOT NULL"
        );
    }
};
