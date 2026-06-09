<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('clients', function (Blueprint $table) {
            $table->boolean('hide_name')->default(false)->after('is_active');
            $table->boolean('hide_company')->default(false)->after('hide_name');
            $table->boolean('hide_all')->default(false)->after('hide_company');
            $table->string('visibility_request', 20)->nullable()->after('hide_all');
            $table->timestamp('visibility_requested_at')->nullable()->after('visibility_request');
            $table->unsignedSmallInteger('last_rank')->nullable()->after('visibility_requested_at');
        });
    }

    public function down(): void
    {
        Schema::table('clients', function (Blueprint $table) {
            $table->dropColumn(['hide_name', 'hide_company', 'hide_all', 'visibility_request', 'visibility_requested_at', 'last_rank']);
        });
    }
};
