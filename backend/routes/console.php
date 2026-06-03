<?php

use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Schedule;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

// Generate invoices for contracts due today (runs at midnight)
Schedule::command('contracts:generate-invoices')->dailyAt('00:05');

// Send payment reminders (runs at 9am every day)
Schedule::command('fees:send-reminders')->dailyAt('09:00');
