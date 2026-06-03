<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class TicketController extends Controller
{
    public function index(Request $request)
    {
        $tickets = $request->user()
            ->supportTickets()
            ->latest()
            ->get()
            ->map(fn($t) => [
                'id'       => $t->id,
                'title'    => $t->title,
                'status'   => $t->status,
                'priority' => $t->priority,
                'created_at' => $t->created_at->format('Y-m-d H:i'),
            ]);

        return response()->json($tickets);
    }

    public function store(Request $request)
    {
        $request->validate([
            'title'   => 'required|string|max:255',
            'message' => 'required|string',
        ]);

        $ticket = $request->user()->supportTickets()->create([
            'title'    => $request->title,
            'status'   => 'open',
            'priority' => 'medium',
        ]);

        $ticket->messages()->create([
            'sender_type' => \App\Models\Client::class,
            'sender_id'   => $request->user()->id,
            'message'     => $request->message,
        ]);

        return response()->json(['id' => $ticket->id, 'message' => 'Ticket created'], 201);
    }

    public function show(Request $request, int $id)
    {
        $ticket = $request->user()->supportTickets()->with('messages')->findOrFail($id);

        return response()->json([
            'id'       => $ticket->id,
            'title'    => $ticket->title,
            'status'   => $ticket->status,
            'priority' => $ticket->priority,
            'messages' => $ticket->messages->map(fn($m) => [
                'id'          => $m->id,
                'sender_type' => $m->sender_type === \App\Models\Client::class ? 'client' : 'admin',
                'message'     => $m->message,
                'created_at'  => $m->created_at->format('Y-m-d H:i'),
            ]),
        ]);
    }

    public function reply(Request $request, int $id)
    {
        $request->validate(['message' => 'required|string']);

        $ticket = $request->user()->supportTickets()->findOrFail($id);

        if ($ticket->status === 'closed') {
            return response()->json(['message' => 'Ticket is closed'], 422);
        }

        $ticket->messages()->create([
            'sender_type' => \App\Models\Client::class,
            'sender_id'   => $request->user()->id,
            'message'     => $request->message,
        ]);

        return response()->json(['message' => 'Reply sent']);
    }
}
