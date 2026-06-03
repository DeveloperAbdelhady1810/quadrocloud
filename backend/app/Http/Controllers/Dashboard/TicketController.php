<?php

namespace App\Http\Controllers\Dashboard;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class TicketController extends Controller
{
    public function index(Request $request)
    {
        $tickets = \App\Models\SupportTicket::with('client')
            ->when($request->status, fn($q) => $q->where('status', $request->status))
            ->when($request->priority, fn($q) => $q->where('priority', $request->priority))
            ->latest()
            ->paginate(20);

        return view('dashboard.tickets.index', compact('tickets'));
    }

    public function show(\App\Models\SupportTicket $ticket)
    {
        $ticket->load(['client', 'messages', 'assignedUser']);
        return view('dashboard.tickets.show', compact('ticket'));
    }

    public function reply(Request $request, \App\Models\SupportTicket $ticket)
    {
        $request->validate(['message' => 'required|string']);

        $ticket->messages()->create([
            'sender_type' => \App\Models\User::class,
            'sender_id'   => auth()->id(),
            'message'     => $request->message,
        ]);

        if ($ticket->status === 'open') {
            $ticket->update(['status' => 'in_progress']);
        }

        $fcm = app(\App\Services\FcmService::class);
        $fcm->notifyAndLog(
            $ticket->client, 'manual',
            'رد على تذكرة دعم',
            'تم الرد على تذكرتك: ' . $ticket->title,
            'push', $ticket
        );

        return back()->with('success', 'تم إرسال الرد');
    }

    public function updateStatus(Request $request, \App\Models\SupportTicket $ticket)
    {
        $request->validate(['status' => 'required|in:open,in_progress,closed']);
        $ticket->update(['status' => $request->status]);
        return back()->with('success', 'تم تحديث حالة التذكرة');
    }
}
