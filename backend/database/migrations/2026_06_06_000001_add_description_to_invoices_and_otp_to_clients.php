<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('invoices', function (Blueprint $table) {
            $table->string('description')->nullable()->after('additional_fee_id');
        });

        Schema::table('clients', function (Blueprint $table) {
            $table->string('login_otp', 6)->nullable()->after('locale');
            $table->timestamp('otp_expires_at')->nullable()->after('login_otp');
        });
    }

    public function down(): void
    {
        Schema::table('invoices', function (Blueprint $table) {
            $table->dropColumn('description');
        });
        Schema::table('clients', function (Blueprint $table) {
            $table->dropColumn(['login_otp', 'otp_expires_at']);
        });
    }
};
