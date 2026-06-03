<?php

namespace App\Http\Controllers\Dashboard;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class TeamController extends Controller
{
    public function index()
    {
        $this->authorize('manage_team');
        $members = \App\Models\User::with('roles')->get();
        $roles   = \Spatie\Permission\Models\Role::all();
        return view('dashboard.team.index', compact('members', 'roles'));
    }

    public function store(Request $request)
    {
        $this->authorize('manage_team');
        $data = $request->validate([
            'name'     => 'required|string|max:255',
            'email'    => 'required|email|unique:users',
            'password' => 'required|string|min:8',
            'role'     => 'required|exists:roles,name',
        ]);

        $user = \App\Models\User::create([
            'name'      => $data['name'],
            'email'     => $data['email'],
            'password'  => $data['password'],
            'is_active' => true,
        ]);
        $user->assignRole($data['role']);

        \App\Models\ActivityLog::record('team_member_added', $user);
        return back()->with('success', 'تم إضافة عضو الفريق');
    }

    public function toggleActive(\App\Models\User $user)
    {
        $this->authorize('manage_team');
        if ($user->hasRole('super-admin') && $user->id === auth()->id()) {
            return back()->with('error', 'لا يمكنك تعطيل حسابك');
        }
        $user->update(['is_active' => !$user->is_active]);
        return back()->with('success', 'تم تغيير حالة العضو');
    }
}
