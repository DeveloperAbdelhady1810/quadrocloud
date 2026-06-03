@extends('layouts.dashboard')
@section('title', 'العملاء')
@section('page-title', 'إدارة العملاء')

@section('content')
<div class="flex justify-between items-center mb-6">
    <form class="flex gap-3">
        <input type="text" name="search" value="{{ request('search') }}" placeholder="بحث بالاسم أو البريد..."
            class="border border-gray-300 rounded-lg px-4 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500 w-72">
        <select name="status" class="border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500">
            <option value="">كل الحالات</option>
            <option value="active" {{ request('status') === 'active' ? 'selected' : '' }}>نشط</option>
            <option value="inactive" {{ request('status') === 'inactive' ? 'selected' : '' }}>غير نشط</option>
        </select>
        <button type="submit" class="bg-indigo-600 text-white px-4 py-2 rounded-lg text-sm hover:bg-indigo-700">بحث</button>
    </form>
    @can('create_clients')
    <a href="{{ route('dashboard.clients.create') }}" class="bg-indigo-600 hover:bg-indigo-700 text-white px-5 py-2.5 rounded-lg font-medium text-sm">
        + إضافة عميل
    </a>
    @endcan
</div>

<div class="bg-white rounded-xl shadow-sm overflow-hidden">
    <table class="w-full text-sm">
        <thead class="bg-gray-50 border-b border-gray-200">
            <tr>
                <th class="px-6 py-4 text-right font-semibold text-gray-600">العميل</th>
                <th class="px-6 py-4 text-right font-semibold text-gray-600">الشركة</th>
                <th class="px-6 py-4 text-right font-semibold text-gray-600">العقود</th>
                <th class="px-6 py-4 text-right font-semibold text-gray-600">الفواتير</th>
                <th class="px-6 py-4 text-right font-semibold text-gray-600">الحالة</th>
                <th class="px-6 py-4 text-right font-semibold text-gray-600">إجراءات</th>
            </tr>
        </thead>
        <tbody class="divide-y divide-gray-100">
            @forelse($clients as $client)
            <tr class="hover:bg-gray-50">
                <td class="px-6 py-4">
                    <div class="font-medium text-gray-800">{{ $client->name }}</div>
                    <div class="text-gray-400 text-xs">{{ $client->email }}</div>
                </td>
                <td class="px-6 py-4 text-gray-600">{{ $client->company_name ?? '-' }}</td>
                <td class="px-6 py-4">
                    <span class="bg-indigo-100 text-indigo-700 px-2 py-0.5 rounded-full text-xs font-medium">{{ $client->contracts_count }}</span>
                </td>
                <td class="px-6 py-4">
                    <span class="bg-gray-100 text-gray-700 px-2 py-0.5 rounded-full text-xs">{{ $client->invoices_count }}</span>
                </td>
                <td class="px-6 py-4">
                    @if($client->is_active)
                        <span class="bg-green-100 text-green-700 px-3 py-1 rounded-full text-xs font-medium">نشط</span>
                    @else
                        <span class="bg-red-100 text-red-700 px-3 py-1 rounded-full text-xs font-medium">غير نشط</span>
                    @endif
                </td>
                <td class="px-6 py-4">
                    <a href="{{ route('dashboard.clients.show', $client) }}" class="text-indigo-600 hover:underline text-sm ml-3">عرض</a>
                    @can('edit_clients')
                    <a href="{{ route('dashboard.clients.edit', $client) }}" class="text-gray-500 hover:underline text-sm">تعديل</a>
                    @endcan
                </td>
            </tr>
            @empty
            <tr><td colspan="6" class="px-6 py-12 text-center text-gray-400">لا يوجد عملاء</td></tr>
            @endforelse
        </tbody>
    </table>
    <div class="px-6 py-4">{{ $clients->withQueryString()->links() }}</div>
</div>
@endsection
