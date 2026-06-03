@extends('layouts.dashboard')
@section('title', 'تذاكر الدعم')
@section('page-title', 'تذاكر الدعم الفني')

@section('content')
<div class="mb-6">
    <form class="flex gap-3">
        <select name="status" class="border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500">
            <option value="">كل الحالات</option>
            <option value="open" {{ request('status') === 'open' ? 'selected' : '' }}>مفتوحة</option>
            <option value="in_progress" {{ request('status') === 'in_progress' ? 'selected' : '' }}>قيد المعالجة</option>
            <option value="closed" {{ request('status') === 'closed' ? 'selected' : '' }}>مغلقة</option>
        </select>
        <select name="priority" class="border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500">
            <option value="">كل الأولويات</option>
            <option value="high" {{ request('priority') === 'high' ? 'selected' : '' }}>عالية</option>
            <option value="medium" {{ request('priority') === 'medium' ? 'selected' : '' }}>متوسطة</option>
            <option value="low" {{ request('priority') === 'low' ? 'selected' : '' }}>منخفضة</option>
        </select>
        <button type="submit" class="bg-indigo-600 text-white px-4 py-2 rounded-lg text-sm hover:bg-indigo-700">فلتر</button>
    </form>
</div>

<div class="bg-white rounded-xl shadow-sm overflow-hidden">
    <table class="w-full text-sm">
        <thead class="bg-gray-50 border-b border-gray-200">
            <tr>
                <th class="px-6 py-4 text-right font-semibold text-gray-600">#</th>
                <th class="px-6 py-4 text-right font-semibold text-gray-600">العنوان</th>
                <th class="px-6 py-4 text-right font-semibold text-gray-600">العميل</th>
                <th class="px-6 py-4 text-right font-semibold text-gray-600">الأولوية</th>
                <th class="px-6 py-4 text-right font-semibold text-gray-600">الحالة</th>
                <th class="px-6 py-4 text-right font-semibold text-gray-600">التاريخ</th>
                <th class="px-6 py-4 text-right font-semibold text-gray-600">إجراء</th>
            </tr>
        </thead>
        <tbody class="divide-y divide-gray-100">
            @forelse($tickets as $t)
            <tr class="hover:bg-gray-50">
                <td class="px-6 py-4 text-gray-400">#{{ $t->id }}</td>
                <td class="px-6 py-4 font-medium">{{ $t->title }}</td>
                <td class="px-6 py-4">
                    <a href="{{ route('dashboard.clients.show', $t->client) }}" class="text-indigo-600 hover:underline">{{ $t->client->name }}</a>
                </td>
                <td class="px-6 py-4">
                    @if($t->priority === 'high') <span class="bg-red-100 text-red-700 text-xs px-2 py-0.5 rounded-full">عالية</span>
                    @elseif($t->priority === 'medium') <span class="bg-yellow-100 text-yellow-700 text-xs px-2 py-0.5 rounded-full">متوسطة</span>
                    @else <span class="bg-gray-100 text-gray-600 text-xs px-2 py-0.5 rounded-full">منخفضة</span>
                    @endif
                </td>
                <td class="px-6 py-4">
                    @if($t->status === 'open') <span class="bg-blue-100 text-blue-700 text-xs px-2 py-0.5 rounded-full">مفتوحة</span>
                    @elseif($t->status === 'in_progress') <span class="bg-orange-100 text-orange-700 text-xs px-2 py-0.5 rounded-full">قيد المعالجة</span>
                    @else <span class="bg-gray-100 text-gray-500 text-xs px-2 py-0.5 rounded-full">مغلقة</span>
                    @endif
                </td>
                <td class="px-6 py-4 text-gray-400 text-xs">{{ $t->created_at->format('Y-m-d') }}</td>
                <td class="px-6 py-4">
                    <a href="{{ route('dashboard.tickets.show', $t) }}" class="text-indigo-600 hover:underline text-sm">رد / عرض</a>
                </td>
            </tr>
            @empty
            <tr><td colspan="7" class="px-6 py-12 text-center text-gray-400">لا توجد تذاكر</td></tr>
            @endforelse
        </tbody>
    </table>
    <div class="px-6 py-4">{{ $tickets->withQueryString()->links() }}</div>
</div>
@endsection
