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
        Schema::table('service_catalog', function (Blueprint $table) {
            $table->boolean('show_price')->default(false)->after('default_price');
            $table->boolean('is_public')->default(false)->after('show_price');
            $table->string('image_path')->nullable()->after('is_public');
            $table->string('icon')->nullable()->after('image_path'); // emoji or icon name
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('service_catalog', function (Blueprint $table) {
            $table->dropColumn(['show_price', 'is_public', 'image_path', 'icon']);
        });
    }
};
