@extends('layouts.dashboard')
@section('title', 'تقرير العميل')
@section('page-title', 'تقرير: ' . $client->name)

@section('content')
<div class="mb-4">
    <a href="{{ route('dashboard.clients.show', $client) }}" class="text-indigo-600 hover:underline text-sm">← عودة للعميل</a>
</div>
<div class="bg-white rounded-xl shadow-sm p-6 mb-6">
    <div class="flex justify-between items-center">
        <div>
            <div class="text-2xl font-bold text-gray-800">{{ $client->name }}</div>
            <div class="text-gray-400">{{ $client->company_name }}</div>
        </div>
        <div class="text-left">
            <div class="text-sm text-gray-400">إجمالي المدفوع</div>
            <div class="text-3xl font-bold text-green-600">{{ number_format($total, 0) }} ج.م</div>
        </div>
    </div>
</div>
<div class="bg-white rounded-xl shadow-sm overflow-hidden">
    <table class="w-full text-sm">
        <thead class="bg-gray-50 border-b border-gray-200">
            <tr>
                <th class="px-6 py-4 text-right font-semibold text-gray-600">رقم الفاتورة</th>
                <th class="px-6 py-4 text-right font-semibold text-gray-600">المبلغ</th>
                <th class="px-6 py-4 text-right font-semibold text-gray-600">الطريقة</th>
                <th class="px-6 py-4 text-right font-semibold text-gray-600">تاريخ الدفع</th>
            </tr>
        </thead>
        <tbody class="divide-y divide-gray-100">
            @forelse($payments as $p)
            <tr>
                <td class="px-6 py-4">{{ $p->invoice?->invoice_number ?? '-' }}</td>
                <td class="px-6 py-4 font-bold">{{ number_format($p->amount, 0) }} ج.م</td>
                <td class="px-6 py-4">{{ $p->method === 'cash' ? 'نقدي' : 'Paymob' }}</td>
                <td class="px-6 py-4 text-gray-400">{{ $p->paid_at?->format('Y-m-d') }}</td>
            </tr>
            @empty
            <tr><td colspan="4" class="px-6 py-12 text-center text-gray-400">لا توجد مدفوعات</td></tr>
            @endforelse
        </tbody>
    </table>
</div>
@endsection
