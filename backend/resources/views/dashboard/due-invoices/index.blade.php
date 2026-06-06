@extends('layouts.dashboard')
@section('title', 'المستحقات التلقائية')
@section('page-title', 'إنشاء فواتير المستحقات')

@section('content')

{{-- Generate All --}}
<div class="flex items-center justify-between mb-6">
    <div>
        <p class="text-sm text-gray-500 mt-1">العقود التي حلّ موعد سدادها ولم تُنشأ لها فاتورة بعد</p>
    </div>
    @if($due->count() > 0)
    <form method="POST" action="{{ route('dashboard.due-invoices.generate-all') }}">
        @csrf
        <button type="submit"
            onclick="return confirm('إنشاء {{ $due->count() }} فاتورة لجميع المستحقات؟')"
            class="bg-indigo-600 hover:bg-indigo-700 text-white px-5 py-2.5 rounded-lg text-sm font-semibold flex items-center gap-2">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/>
            </svg>
            إنشاء الكل ({{ $due->count() }})
        </button>
    </form>
    @endif
</div>

{{-- Due contracts table --}}
<div class="bg-white rounded-2xl shadow-sm border border-gray-100 mb-8">
    <div class="px-6 py-4 border-b border-gray-100 flex items-center justify-between">
        <h2 class="font-bold text-gray-800 flex items-center gap-2">
            <span class="w-2 h-2 rounded-full bg-red-500 inline-block"></span>
            مستحقة — بدون فاتورة
            <span class="bg-red-100 text-red-700 text-xs font-bold px-2 py-0.5 rounded-full">{{ $due->count() }}</span>
        </h2>
    </div>

    @if($due->isEmpty())
        <div class="text-center py-16 text-gray-400">
            <svg class="w-12 h-12 mx-auto mb-3 text-gray-300" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/>
            </svg>
            <p class="font-medium">لا توجد مستحقات جديدة</p>
            <p class="text-sm mt-1">جميع العقود المستحقة لديها فواتير بالفعل</p>
        </div>
    @else
        <form method="POST" action="{{ route('dashboard.due-invoices.generate') }}" id="due-form">
            @csrf
            <table class="w-full text-sm">
                <thead>
                    <tr class="text-right bg-gray-50 text-gray-500 text-xs uppercase">
                        <th class="px-6 py-3 font-semibold">
                            <input type="checkbox" id="select-all" class="rounded" title="تحديد الكل">
                        </th>
                        <th class="px-6 py-3 font-semibold">العميل</th>
                        <th class="px-6 py-3 font-semibold">العقد</th>
                        <th class="px-6 py-3 font-semibold">دورة الفوترة</th>
                        <th class="px-6 py-3 font-semibold">تاريخ الاستحقاق</th>
                        <th class="px-6 py-3 font-semibold">المبلغ</th>
                        <th class="px-6 py-3 font-semibold">التأخير</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-gray-50">
                    @foreach($due as $contract)
                    @php
                        $overdueDays = now()->startOfDay()->diffInDays($contract->next_due_date, false) * -1;
                    @endphp
                    <tr class="hover:bg-gray-50 transition-colors">
                        <td class="px-6 py-4">
                            <input type="checkbox" name="contract_ids[]" value="{{ $contract->id }}"
                                class="rounded contract-cb" checked>
                        </td>
                        <td class="px-6 py-4">
                            <a href="{{ route('dashboard.clients.show', $contract->client) }}"
                               class="font-semibold text-gray-800 hover:text-indigo-600">
                                {{ $contract->client->name }}
                            </a>
                            <div class="text-xs text-gray-400">{{ $contract->client->email }}</div>
                        </td>
                        <td class="px-6 py-4 text-gray-700">{{ $contract->display_name }}</td>
                        <td class="px-6 py-4">
                            <span class="bg-indigo-50 text-indigo-700 text-xs font-semibold px-2 py-1 rounded-full">
                                @switch($contract->billing_cycle)
                                    @case('monthly') شهري @break
                                    @case('quarterly') ربع سنوي @break
                                    @case('annually') سنوي @break
                                    @default {{ $contract->billing_cycle }}
                                @endswitch
                            </span>
                        </td>
                        <td class="px-6 py-4 text-gray-700">{{ $contract->next_due_date->format('Y-m-d') }}</td>
                        <td class="px-6 py-4 font-bold text-gray-800">{{ number_format($contract->price, 0) }} ج.م</td>
                        <td class="px-6 py-4">
                            @if($overdueDays > 0)
                                <span class="bg-red-100 text-red-700 text-xs font-bold px-2 py-1 rounded-full">
                                    متأخر {{ $overdueDays }} يوم
                                </span>
                            @else
                                <span class="bg-orange-100 text-orange-700 text-xs font-bold px-2 py-1 rounded-full">
                                    اليوم
                                </span>
                            @endif
                        </td>
                    </tr>
                    @endforeach
                </tbody>
            </table>

            <div class="px-6 py-4 border-t border-gray-100 flex items-center justify-between bg-gray-50 rounded-b-2xl">
                <span class="text-sm text-gray-500">إجمالي المبلغ المحدد:
                    <strong class="text-gray-800" id="total-amount">
                        {{ number_format($due->sum('price'), 0) }} ج.م
                    </strong>
                </span>
                <button type="submit"
                    class="bg-indigo-600 hover:bg-indigo-700 text-white px-6 py-2.5 rounded-lg text-sm font-semibold">
                    إنشاء فواتير للمحددين
                </button>
            </div>
        </form>
    @endif
</div>

{{-- Pending payment --}}
@if($pending->count() > 0)
<div class="bg-white rounded-2xl shadow-sm border border-gray-100">
    <div class="px-6 py-4 border-b border-gray-100">
        <h2 class="font-bold text-gray-800 flex items-center gap-2">
            <span class="w-2 h-2 rounded-full bg-yellow-400 inline-block"></span>
            فواتير معلقة — بانتظار الدفع
            <span class="bg-yellow-100 text-yellow-700 text-xs font-bold px-2 py-0.5 rounded-full">{{ $pending->count() }}</span>
        </h2>
    </div>
    <table class="w-full text-sm">
        <thead>
            <tr class="text-right bg-gray-50 text-gray-500 text-xs uppercase">
                <th class="px-6 py-3 font-semibold">العميل</th>
                <th class="px-6 py-3 font-semibold">العقد</th>
                <th class="px-6 py-3 font-semibold">رقم الفاتورة</th>
                <th class="px-6 py-3 font-semibold">المبلغ</th>
                <th class="px-6 py-3 font-semibold">تاريخ الاستحقاق</th>
                <th class="px-6 py-3 font-semibold">الحالة</th>
                <th class="px-6 py-3 font-semibold"></th>
            </tr>
        </thead>
        <tbody class="divide-y divide-gray-50">
            @foreach($pending as $contract)
            @php $inv = $contract->invoices->first(); @endphp
            @if($inv)
            <tr class="hover:bg-gray-50 transition-colors">
                <td class="px-6 py-4">
                    <a href="{{ route('dashboard.clients.show', $contract->client) }}"
                       class="font-semibold text-gray-800 hover:text-indigo-600">
                        {{ $contract->client->name }}
                    </a>
                    <div class="text-xs text-gray-400">{{ $contract->client->email }}</div>
                </td>
                <td class="px-6 py-4 text-gray-700">{{ $contract->display_name }}</td>
                <td class="px-6 py-4 font-mono text-xs text-gray-500">{{ $inv->invoice_number ?? '#'.$inv->id }}</td>
                <td class="px-6 py-4 font-bold text-gray-800">{{ number_format($inv->amount, 0) }} ج.م</td>
                <td class="px-6 py-4 text-gray-600">{{ $inv->due_date?->format('Y-m-d') }}</td>
                <td class="px-6 py-4">
                    @if($inv->status === 'overdue')
                        <span class="bg-red-100 text-red-700 text-xs font-bold px-2 py-1 rounded-full">متأخرة</span>
                    @else
                        <span class="bg-yellow-100 text-yellow-700 text-xs font-bold px-2 py-1 rounded-full">غير مدفوعة</span>
                    @endif
                </td>
                <td class="px-6 py-4">
                    <a href="{{ route('dashboard.clients.show', $contract->client) }}"
                       class="text-indigo-600 hover:text-indigo-800 text-xs font-semibold">
                        عرض العميل ←
                    </a>
                </td>
            </tr>
            @endif
            @endforeach
        </tbody>
    </table>
</div>
@endif

@endsection

@push('scripts')
<script>
// Select all checkbox
document.getElementById('select-all')?.addEventListener('change', function() {
    document.querySelectorAll('.contract-cb').forEach(cb => cb.checked = this.checked);
    updateTotal();
});

document.querySelectorAll('.contract-cb').forEach(cb => {
    cb.addEventListener('change', updateTotal);
});

function updateTotal() {
    const prices = @json($due->pluck('price', 'id'));
    let total = 0;
    document.querySelectorAll('.contract-cb:checked').forEach(cb => {
        total += parseFloat(prices[cb.value] || 0);
    });
    const el = document.getElementById('total-amount');
    if (el) el.textContent = total.toLocaleString('ar-EG') + ' ج.م';
}
</script>
@endpush
