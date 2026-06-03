<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class FeeController extends Controller
{
    public function index(Request $request)
    {
        $fees = $request->user()
            ->additionalFees()
            ->orderBy('due_date')
            ->get()
            ->map(fn($f) => $this->format($f));

        return response()->json($fees);
    }

    public function show(Request $request, int $id)
    {
        $fee = $request->user()->additionalFees()->findOrFail($id);
        return response()->json($this->format($fee));
    }

    private function format($f): array
    {
        return [
            'id'                  => $f->id,
            'title'               => $f->title,
            'description'         => $f->description,
            'amount'              => (float) $f->amount,
            'due_date'            => $f->due_date?->format('Y-m-d'),
            'acceptance_deadline' => $f->acceptance_deadline?->format('Y-m-d'),
            'status'              => $f->status,
            'days_until_due'      => (int) now()->startOfDay()->diffInDays($f->due_date, false),
        ];
    }
}
