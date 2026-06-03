<?php

namespace App\Http\Controllers\Dashboard;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class FeeController extends Controller
{
    public function create(\App\Models\Client $client)
    {
        return view('dashboard.fees.create', compact('client'));
    }

    public function store(Request $request, \App\Models\Client $client)
    {
        $data = $request->validate([
            'title'               => 'required|string|max:255',
            'description'         => 'nullable|string',
            'amount'              => 'required|numeric|min:0.5',
            'due_date'            => 'required|date',
            'acceptance_deadline' => 'nullable|date|after_or_equal:today',
        ]);

        $data['client_id']  = $client->id;
        $data['created_by'] = auth()->id();
        $fee = \App\Models\AdditionalFee::create($data);

        // Create invoice for this fee
        \App\Models\Invoice::create([
            'client_id'         => $client->id,
            'additional_fee_id' => $fee->id,
            'amount'            => $fee->amount,
            'status'            => 'unpaid',
            'due_date'          => $fee->due_date,
        ]);

        // Notify client immediately
        $fcm = app(\App\Services\FcmService::class);
        $fcm->notifyAndLog(
            $client, 'fee_added',
            'رسوم إضافية جديدة',
            "تم إضافة رسوم إضافية: {$fee->title} بمبلغ {$fee->amount} ج.م",
            'push', $fee
        );

        \App\Models\ActivityLog::record('fee_added', $fee);
        return redirect()->route('dashboard.clients.show', $client)->with('success', 'تم إضافة الرسوم وإشعار العميل');
    }

    public function cancel(\App\Models\AdditionalFee $fee)
    {
        $fee->update(['status' => 'cancelled']);
        $fee->invoice?->update(['status' => 'cancelled']);
        \App\Models\ActivityLog::record('fee_cancelled', $fee);
        return back()->with('success', 'تم إلغاء الرسوم');
    }
}
