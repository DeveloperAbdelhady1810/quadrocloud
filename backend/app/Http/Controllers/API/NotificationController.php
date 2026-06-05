<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class NotificationController extends Controller
{
    public function index(Request $request)
    {
        $notifications = $request->user()
            ->notificationLogs()
            ->latest()
            ->take(50)
            ->get()
            ->map(fn($n) => [
                'id'             => $n->id,
                'type'           => $n->type,
                'title'          => $n->title,
                'body'           => $n->body,
                'reference_type' => $n->reference_type,
                'reference_id'   => $n->reference_id,
                'sent'           => $n->sent,
                'sent_at'        => $n->sent_at?->format('Y-m-d H:i'),
                'created_at'     => $n->created_at->format('Y-m-d H:i'),
            ]);

        return response()->json($notifications);
    }
}
