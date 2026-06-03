<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class ContractController extends Controller
{
    public function index(Request $request)
    {
        $contracts = $request->user()
            ->contracts()
            ->with('service')
            ->where('status', 'active')
            ->get()
            ->map(fn($c) => [
                'id'             => $c->id,
                'name'           => $c->display_name,
                'price'          => (float) $c->price,
                'billing_cycle'  => $c->billing_cycle,
                'next_due_date'  => $c->next_due_date?->format('Y-m-d'),
                'days_until_due' => $c->next_due_date
                    ? (int) now()->startOfDay()->diffInDays($c->next_due_date, false)
                    : 0,
                'start_date'     => $c->start_date?->format('Y-m-d'),
                'end_date'       => $c->end_date?->format('Y-m-d'),
                'status'         => $c->status,
            ]);

        return response()->json($contracts);
    }
}
