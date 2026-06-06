<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\API\AuthController;
use App\Http\Controllers\API\SocialAuthController;
use App\Http\Controllers\API\DashboardController;
use App\Http\Controllers\API\ContractController;
use App\Http\Controllers\API\FeeController;
use App\Http\Controllers\API\InvoiceController;
use App\Http\Controllers\API\PaymentController;
use App\Http\Controllers\API\TicketController;
use App\Http\Controllers\API\WebhookController;
use App\Http\Controllers\API\PostController;
use App\Http\Controllers\API\PublicServiceController;
use App\Http\Controllers\API\NotificationController;

Route::prefix('v1')->group(function () {

    // Paymob server-to-server webhook — no auth
    Route::post('webhooks/paymob', [WebhookController::class, 'paymob']);

    // Paymob redirect callback — no auth (browser is redirected here after payment)
    Route::get('payments/callback', [PaymentController::class, 'callback']);

    // Public routes — no auth required
    Route::get('posts', [PostController::class, 'index']);
    Route::get('posts/{post}', [PostController::class, 'show']);
    Route::get('services/public', [PublicServiceController::class, 'index']);
    Route::post('services/{service}/request', [PublicServiceController::class, 'request']);

    // Client auth
    Route::prefix('auth')->group(function () {
        Route::post('login', [AuthController::class, 'login']);
        Route::post('otp-login', [AuthController::class, 'otpLogin']);
        Route::post('social', [SocialAuthController::class, 'login']);
    });

    // Authenticated client routes
    Route::middleware('auth:sanctum')->group(function () {
        Route::prefix('auth')->group(function () {
            Route::post('logout', [AuthController::class, 'logout']);
            Route::get('profile', [AuthController::class, 'profile']);
            Route::put('fcm-token', [AuthController::class, 'updateFcmToken']);
            Route::put('locale', [AuthController::class, 'updateLocale']);
            Route::put('password', [AuthController::class, 'changePassword']);
            Route::put('profile', [AuthController::class, 'updateProfile']);
        });

        Route::get('dashboard', [DashboardController::class, 'index']);
        Route::get('contracts', [ContractController::class, 'index']);

        Route::get('fees', [FeeController::class, 'index']);
        Route::get('fees/{id}', [FeeController::class, 'show']);

        Route::get('invoices', [InvoiceController::class, 'index']);
        Route::get('invoices/{id}', [InvoiceController::class, 'show']);
        Route::post('invoices/{id}/send-email', [InvoiceController::class, 'sendEmail']);
        Route::get('invoices/{id}/pdf', [InvoiceController::class, 'download']);

        Route::get('payments', [PaymentController::class, 'index']);
        Route::get('payments/{id}', [PaymentController::class, 'show']);
        Route::post('payments/initiate', [PaymentController::class, 'initiate']);
        Route::post('payments/verify', [PaymentController::class, 'verify']);

        Route::get('tickets', [TicketController::class, 'index']);
        Route::post('tickets', [TicketController::class, 'store']);
        Route::get('tickets/{id}', [TicketController::class, 'show']);
        Route::post('tickets/{id}/reply', [TicketController::class, 'reply']);

        Route::get('notifications', [NotificationController::class, 'index']);
    });
});
