<?php

namespace App\Http\Controllers\Dashboard;

use App\Http\Controllers\Controller;
use App\Models\Client;
use App\Models\ServiceCatalog;
use App\Services\FcmService;
use Illuminate\Http\Request;

class NotificationController extends Controller
{
    public function create()
    {
        $clients  = Client::where('is_active', true)->orderBy('name')->get(['id', 'name', 'email']);
        $services = ServiceCatalog::where('is_active', true)->orderBy('name')->get(['id', 'name']);

        return view('dashboard.notifications.send', compact('clients', 'services'));
    }

    public function send(Request $request)
    {
        $data = $request->validate([
            'title'      => 'required|string|max:100',
            'body'       => 'required|string|max:300',
            'target'     => 'required|in:all,selected',
            'client_ids' => 'required_if:target,selected|array',
            'client_ids.*' => 'exists:clients,id',
            'action'     => 'nullable|in:none,services,service_detail,news,contracts,invoices',
            'action_id'  => 'nullable|integer',
        ]);

        $clients = $data['target'] === 'all'
            ? Client::where('is_active', true)->whereNotNull('fcm_token')->get()
            : Client::whereIn('id', $data['client_ids'] ?? [])->whereNotNull('fcm_token')->get();

        if ($clients->isEmpty()) {
            return back()->with('error', 'لا يوجد عملاء لديهم توكن للإشعارات');
        }

        $fcm = app(FcmService::class);
        $payload = [
            'action'    => $data['action'] ?? 'none',
            'action_id' => (string) ($data['action_id'] ?? ''),
        ];

        $sent = 0;
        foreach ($clients as $client) {
            $ok = $fcm->sendToClient($client, $data['title'], $data['body'], $payload);
            if ($ok) $sent++;
        }

        \App\Models\ActivityLog::record('bulk_notification_sent', null, [], [
            'title'   => $data['title'],
            'target'  => $data['target'],
            'sent_to' => $sent,
        ]);

        return back()->with('success', "تم إرسال الإشعار لـ {$sent} عميل");
    }
}
