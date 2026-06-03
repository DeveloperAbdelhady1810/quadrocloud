<?php

namespace App\Http\Controllers\Dashboard;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class ContractController extends Controller
{
    public function create(\App\Models\Client $client)
    {
        $services = \App\Models\ServiceCatalog::where('is_active', true)->get();
        return view('dashboard.contracts.create', compact('client', 'services'));
    }

    public function store(Request $request, \App\Models\Client $client)
    {
        $data = $request->validate([
            'service_id'      => 'nullable|exists:service_catalog,id',
            'custom_name'     => 'nullable|string|max:255',
            'price'           => 'required|numeric|min:0',
            'billing_cycle'   => 'required|in:monthly,quarterly,annually',
            'start_date'      => 'required|date',
            'end_date'        => 'nullable|date|after:start_date',
            'grace_period_days' => 'integer|min:0|max:90',
            'notes'           => 'nullable|string',
        ]);

        $data['client_id']   = $client->id;
        $data['created_by']  = auth()->id();
        $data['next_due_date'] = $data['start_date'];

        $contract = \App\Models\Contract::create($data);
        \App\Models\ActivityLog::record('contract_created', $contract);

        return redirect()->route('dashboard.clients.show', $client)->with('success', 'تم إضافة العقد');
    }

    public function edit(\App\Models\Contract $contract)
    {
        $services = \App\Models\ServiceCatalog::where('is_active', true)->get();
        return view('dashboard.contracts.edit', compact('contract', 'services'));
    }

    public function update(Request $request, \App\Models\Contract $contract)
    {
        $data = $request->validate([
            'price'           => 'required|numeric|min:0',
            'status'          => 'required|in:active,paused,cancelled',
            'end_date'        => 'nullable|date',
            'grace_period_days' => 'integer|min:0|max:90',
            'notes'           => 'nullable|string',
        ]);

        $old = $contract->toArray();
        $contract->update($data);
        \App\Models\ActivityLog::record('contract_updated', $contract, $old, $contract->fresh()->toArray());

        return redirect()->route('dashboard.clients.show', $contract->client)->with('success', 'تم تحديث العقد');
    }
}
