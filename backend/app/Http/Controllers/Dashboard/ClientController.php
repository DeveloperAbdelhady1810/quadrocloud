<?php

namespace App\Http\Controllers\Dashboard;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class ClientController extends Controller
{
    public function index(Request $request)
    {
        $clients = \App\Models\Client::withCount(['contracts', 'invoices'])
            ->when($request->search, fn($q) => $q->where('name', 'like', '%'.$request->search.'%')
                ->orWhere('email', 'like', '%'.$request->search.'%')
                ->orWhere('company_name', 'like', '%'.$request->search.'%'))
            ->when($request->status, fn($q) => $q->where('is_active', $request->status === 'active'))
            ->latest()
            ->paginate(20);

        return view('dashboard.clients.index', compact('clients'));
    }

    public function create()
    {
        return view('dashboard.clients.create');
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'name'         => 'required|string|max:255',
            'email'        => 'required|email|unique:clients',
            'password'     => 'required|string|min:8',
            'phone'        => 'nullable|string|max:20',
            'company_name' => 'nullable|string|max:255',
            'address'      => 'nullable|string',
            'notes'        => 'nullable|string',
            'locale'       => 'required|in:ar,en',
        ]);

        $data['created_by'] = auth()->id();
        $client = \App\Models\Client::create($data);

        \App\Models\ActivityLog::record('client_created', $client, [], $client->toArray());
        return redirect()->route('dashboard.clients.show', $client)->with('success', 'تم إضافة العميل بنجاح');
    }

    public function show(\App\Models\Client $client)
    {
        $client->load(['contracts.service', 'additionalFees', 'invoices', 'payments', 'supportTickets']);
        return view('dashboard.clients.show', compact('client'));
    }

    public function edit(\App\Models\Client $client)
    {
        return view('dashboard.clients.edit', compact('client'));
    }

    public function update(Request $request, \App\Models\Client $client)
    {
        $data = $request->validate([
            'name'         => 'required|string|max:255',
            'email'        => 'required|email|unique:clients,email,'.$client->id,
            'phone'        => 'nullable|string|max:20',
            'company_name' => 'nullable|string|max:255',
            'address'      => 'nullable|string',
            'notes'        => 'nullable|string',
            'locale'       => 'required|in:ar,en',
            'is_active'    => 'boolean',
        ]);

        if ($request->filled('password')) {
            $request->validate(['password' => 'string|min:8']);
            $data['password'] = $request->password;
        }

        $old = $client->toArray();
        $client->update($data);
        \App\Models\ActivityLog::record('client_updated', $client, $old, $client->fresh()->toArray());

        return redirect()->route('dashboard.clients.show', $client)->with('success', 'تم تحديث بيانات العميل');
    }

    public function toggleActive(\App\Models\Client $client)
    {
        $client->update(['is_active' => !$client->is_active]);
        \App\Models\ActivityLog::record($client->is_active ? 'client_activated' : 'client_deactivated', $client);
        return back()->with('success', 'تم تغيير حالة العميل');
    }

    public function sendLoginLink(\App\Models\Client $client)
    {
        $otp = str_pad((string) random_int(0, 999999), 6, '0', STR_PAD_LEFT);

        $client->update([
            'login_otp'      => $otp,
            'otp_expires_at' => now()->addMinutes(15),
        ]);

        try {
            \Illuminate\Support\Facades\Mail::to($client->email)
                ->send(new \App\Mail\LoginOtpMail($client, $otp));
        } catch (\Throwable) {
            return back()->with('error', 'فشل إرسال البريد الإلكتروني');
        }

        return back()->with('success', 'تم إرسال كود الدخول إلى ' . $client->email);
    }
}
