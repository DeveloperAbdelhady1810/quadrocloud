<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Dashboard\AuthController;
use App\Http\Controllers\Dashboard\ClientController;
use App\Http\Controllers\Dashboard\ContractController;
use App\Http\Controllers\Dashboard\FeeController;
use App\Http\Controllers\Dashboard\PaymentController;
use App\Http\Controllers\Dashboard\ReportController;
use App\Http\Controllers\Dashboard\TicketController;
use App\Http\Controllers\Dashboard\TeamController;
use App\Http\Controllers\Dashboard\PostController;
use App\Http\Controllers\Dashboard\ServiceController;
use App\Http\Controllers\Dashboard\NotificationController;

Route::get('/', fn() => redirect()->route('dashboard.login'));

Route::prefix('dashboard')->name('dashboard.')->group(function () {

    // Auth routes (guest only)
    Route::middleware('guest')->group(function () {
        Route::get('login', [AuthController::class, 'showLogin'])->name('login');
        Route::post('login', [AuthController::class, 'login'])->name('login.post');
    });

    Route::post('logout', [AuthController::class, 'logout'])->name('logout');

    // Protected dashboard routes
    Route::middleware('auth')->group(function () {

        Route::get('/', function () {
            return view('dashboard.home');
        })->name('home');

        // Clients
        Route::get('clients', [ClientController::class, 'index'])->name('clients.index');
        Route::get('clients/create', [ClientController::class, 'create'])->name('clients.create');
        Route::post('clients', [ClientController::class, 'store'])->name('clients.store');
        Route::get('clients/{client}', [ClientController::class, 'show'])->name('clients.show');
        Route::get('clients/{client}/edit', [ClientController::class, 'edit'])->name('clients.edit');
        Route::put('clients/{client}', [ClientController::class, 'update'])->name('clients.update');
        Route::post('clients/{client}/toggle', [ClientController::class, 'toggleActive'])->name('clients.toggle');

        // Contracts
        Route::get('clients/{client}/contracts/create', [ContractController::class, 'create'])->name('contracts.create');
        Route::post('clients/{client}/contracts', [ContractController::class, 'store'])->name('contracts.store');
        Route::get('contracts/{contract}/edit', [ContractController::class, 'edit'])->name('contracts.edit');
        Route::put('contracts/{contract}', [ContractController::class, 'update'])->name('contracts.update');

        // Additional fees
        Route::get('clients/{client}/fees/create', [FeeController::class, 'create'])->name('fees.create');
        Route::post('clients/{client}/fees', [FeeController::class, 'store'])->name('fees.store');
        Route::post('fees/{fee}/cancel', [FeeController::class, 'cancel'])->name('fees.cancel');

        // Payments
        Route::get('payments', [PaymentController::class, 'index'])->name('payments.index');
        Route::post('invoices/{invoice}/mark-cash', [PaymentController::class, 'markCash'])->name('invoices.mark-cash');

        // Reports
        Route::get('reports', [ReportController::class, 'index'])->name('reports.index');
        Route::get('reports/export-overdue', [ReportController::class, 'exportOverdue'])->name('reports.export-overdue');
        Route::get('reports/clients/{client}', [ReportController::class, 'perClient'])->name('reports.per-client');

        // Support tickets
        Route::get('tickets', [TicketController::class, 'index'])->name('tickets.index');
        Route::get('tickets/{ticket}', [TicketController::class, 'show'])->name('tickets.show');
        Route::post('tickets/{ticket}/reply', [TicketController::class, 'reply'])->name('tickets.reply');
        Route::post('tickets/{ticket}/status', [TicketController::class, 'updateStatus'])->name('tickets.status');

        // Bulk notifications
        Route::get('notifications/send', [NotificationController::class, 'create'])->name('notifications.create');
        Route::post('notifications/send', [NotificationController::class, 'send'])->name('notifications.send');

        // Team management
        Route::get('team', [TeamController::class, 'index'])->name('team.index');
        Route::post('team', [TeamController::class, 'store'])->name('team.store');
        Route::post('team/{user}/toggle', [TeamController::class, 'toggleActive'])->name('team.toggle');

        // Posts
        Route::get('posts', [PostController::class, 'index'])->name('posts.index');
        Route::get('posts/create', [PostController::class, 'create'])->name('posts.create');
        Route::post('posts', [PostController::class, 'store'])->name('posts.store');
        Route::get('posts/{post}/edit', [PostController::class, 'edit'])->name('posts.edit');
        Route::put('posts/{post}', [PostController::class, 'update'])->name('posts.update');
        Route::delete('posts/{post}', [PostController::class, 'destroy'])->name('posts.destroy');

        // Services catalog
        Route::get('services', [ServiceController::class, 'index'])->name('services.index');
        Route::get('services/create', [ServiceController::class, 'create'])->name('services.create');
        Route::post('services', [ServiceController::class, 'store'])->name('services.store');
        Route::get('services/{service}/edit', [ServiceController::class, 'edit'])->name('services.edit');
        Route::put('services/{service}', [ServiceController::class, 'update'])->name('services.update');
        Route::delete('services/{service}', [ServiceController::class, 'destroy'])->name('services.destroy');
    });
});
