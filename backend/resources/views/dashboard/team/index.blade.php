@extends('layouts.dashboard')
@section('title', 'الفريق')
@section('page-title', 'إدارة الفريق')

@section('content')
<div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
    <!-- Add member form -->
    <div class="bg-white rounded-xl shadow-sm p-6">
        <h3 class="font-bold text-gray-800 mb-4">إضافة عضو جديد</h3>
        <form method="POST" action="{{ route('dashboard.team.store') }}">
            @csrf
            <div class="space-y-4">
                <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1">الاسم *</label>
                    <input type="text" name="name" required class="w-full border border-gray-300 rounded-lg px-4 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500">
                </div>
                <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1">البريد الإلكتروني *</label>
                    <input type="email" name="email" required class="w-full border border-gray-300 rounded-lg px-4 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500">
                </div>
                <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1">كلمة المرور *</label>
                    <input type="password" name="password" required class="w-full border border-gray-300 rounded-lg px-4 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500">
                </div>
                <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1">الصلاحية *</label>
                    <select name="role" class="w-full border border-gray-300 rounded-lg px-4 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500">
                        @foreach($roles as $role)
                        <option value="{{ $role->name }}">{{ $role->name }}</option>
                        @endforeach
                    </select>
                </div>
                <button type="submit" class="w-full bg-indigo-600 hover:bg-indigo-700 text-white py-2.5 rounded-lg font-medium text-sm">إضافة العضو</button>
            </div>
        </form>
    </div>

    <!-- Members list -->
    <div class="lg:col-span-2 bg-white rounded-xl shadow-sm overflow-hidden">
        <table class="w-full text-sm">
            <thead class="bg-gray-50 border-b border-gray-200">
                <tr>
                    <th class="px-6 py-4 text-right font-semibold text-gray-600">العضو</th>
                    <th class="px-6 py-4 text-right font-semibold text-gray-600">الدور</th>
                    <th class="px-6 py-4 text-right font-semibold text-gray-600">الحالة</th>
                    <th class="px-6 py-4 text-right font-semibold text-gray-600">إجراء</th>
                </tr>
            </thead>
            <tbody class="divide-y divide-gray-100">
                @foreach($members as $m)
                <tr class="hover:bg-gray-50">
                    <td class="px-6 py-4">
                        <div class="font-medium">{{ $m->name }}</div>
                        <div class="text-xs text-gray-400">{{ $m->email }}</div>
                    </td>
                    <td class="px-6 py-4">
                        <span class="bg-indigo-100 text-indigo-700 text-xs px-2 py-0.5 rounded-full">{{ $m->getRoleNames()->first() ?? '-' }}</span>
                    </td>
                    <td class="px-6 py-4">
                        @if($m->is_active)
                            <span class="bg-green-100 text-green-700 text-xs px-2 py-0.5 rounded-full">نشط</span>
                        @else
                            <span class="bg-red-100 text-red-700 text-xs px-2 py-0.5 rounded-full">غير نشط</span>
                        @endif
                    </td>
                    <td class="px-6 py-4">
                        @if($m->id !== auth()->id())
                        <form method="POST" action="{{ route('dashboard.team.toggle', $m) }}" class="inline">
                            @csrf
                            <button class="{{ $m->is_active ? 'text-red-500' : 'text-green-600' }} hover:underline text-xs">
                                {{ $m->is_active ? 'تعطيل' : 'تفعيل' }}
                            </button>
                        </form>
                        @else
                        <span class="text-gray-300 text-xs">أنت</span>
                        @endif
                    </td>
                </tr>
                @endforeach
            </tbody>
        </table>
    </div>
</div>
@endsection
