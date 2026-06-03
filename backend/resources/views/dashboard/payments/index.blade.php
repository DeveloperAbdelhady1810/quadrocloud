@extends('layouts.dashboard')
@section('title', 'المدفوعات')
@section('page-title', 'سجل المدفوعات')

@section('content')
<div class="mb-6">
    <form class="flex gap-3 flex-wrap">
        <input type="text" name="search" value="{{ request('search') }}" placeholder="بحث بالعميل..."
            class="border border-gray-300 rounded-lg px-4 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500 w-64">
        <select name="method" class="border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500">
            <option value="">كل الطرق</option>
            <option value="paymob" {{ request('method') === 'paymob' ? 'selected' : '' }}>أونلاين (Paymob)</option>
            <option value="cash" {{ request('method') === 'cash' ? 'selected' : '' }}>نقدي</option>
        </select>
        <select name="status" class="border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500">
            <option value="">كل الحالات</option>
            <option value="success" {{ request('status') === 'success' ? 'selected' : '' }}>ناجح</option>
            <option value="pending" {{ request('status') === 'pending' ? 'selected' : '' }}>معلق</option>
            <option value="failed" {{ request('status') === 'failed' ? 'selected' : '' }}>فاشل</option>
        </select>
        <button type="submit" class="bg-indigo-600 text-white px-4 py-2 rounded-lg text-sm hover:bg-indigo-700">بحث</button>
    </form>
</div>

<div class="bg-white rounded-xl shadow-sm overflow-hidden">
    <table class="w-full text-sm">
        <thead class="bg-gray-50 border-b border-gray-200">
            <tr>
                <th class="px-6 py-4 text-right font-semibold text-gray-600">العميل</th>
                <th class="px-6 py-4 text-right font-semibold text-gray-600">رقم الفاتورة</th>
                <th class="px-6 py-4 text-right font-semibold text-gray-600">المبلغ</th>
                <th class="px-6 py-4 text-right font-semibold text-gray-600">الطريقة</th>
                <th class="px-6 py-4 text-right font-semibold text-gray-600">الحالة</th>
                <th class="px-6 py-4 text-right font-semibold text-gray-600">التاريخ</th>
            </tr>
        </thead>
        <tbody class="divide-y divide-gray-100">
            @forelse($payments as $p)
            <tr class="hover:bg-gray-50">
                <td class="px-6 py-4">
                    <a href="{{ route('dashboard.clients.show', $p->client) }}" class="font-medium text-indigo-600 hover:underline">{{ $p->client->name }}</a>
                </td>
                <td class="px-6 py-4 text-gray-500">{{ $p->invoice?->invoice_number ?? '-' }}</td>
                <td class="px-6 py-4 font-bold">{{ number_format($p->amount, 0) }} ج.م</td>
                <td class="px-6 py-4">
                    @if($p->method === 'cash')
                        <span class="bg-gray-100 text-gray-700 px-2 py-0.5 rounded-full text-xs">نقدي</span>
                    @else
                        <span class="bg-blue-100 text-blue-700 px-2 py-0.5 rounded-full text-xs">Paymob</span>
                    @endif
                </td>
                <td class="px-6 py-4">
                    @if($p->status === 'success') <span class="bg-green-100 text-green-700 px-2 py-0.5 rounded-full text-xs">ناجح</span>
                    @elseif($p->status === 'pending') <span class="bg-yellow-100 text-yellow-700 px-2 py-0.5 rounded-full text-xs">معلق</span>
                    @else <span class="bg-red-100 text-red-700 px-2 py-0.5 rounded-full text-xs">فاشل</span>
                    @endif
                </td>
                <td class="px-6 py-4 text-gray-400 text-xs">{{ $p->paid_at?->format('Y-m-d H:i') ?? $p->created_at->format('Y-m-d') }}</td>
            </tr>
            @empty
            <tr><td colspan="6" class="px-6 py-12 text-center text-gray-400">لا توجد مدفوعات</td></tr>
            @endforelse
        </tbody>
    </table>
    <div class="px-6 py-4">{{ $payments->withQueryString()->links() }}</div>
</div>
@endsection
