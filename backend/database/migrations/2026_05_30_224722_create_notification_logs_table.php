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
        Schema::create('notification_logs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('client_id')->constrained()->cascadeOnDelete();
            $table->enum('type', ['reminder_5day', 'reminder_daily', 'overdue', 'fee_added', 'payment_confirmed', 'manual']);
            $table->enum('channel', ['push', 'email', 'both']);
            $table->string('title');
            $table->text('body');
            $table->nullableMorphs('reference');
            $table->boolean('sent')->default(true);
            $table->timestamp('sent_at')->nullable();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('notification_logs');
    }
};
