<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('client_follows', function (Blueprint $table) {
            $table->id();
            $table->foreignId('follower_id')->constrained('clients')->cascadeOnDelete();
            $table->foreignId('followed_id')->constrained('clients')->cascadeOnDelete();
            $table->timestamps();
            $table->unique(['follower_id', 'followed_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('client_follows');
    }
};
