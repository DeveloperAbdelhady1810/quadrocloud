@extends('layouts.dashboard')
@section('title', $client->name)
@section('page-title', $client->name)

@section('content')
<div class="flex gap-3 mb-6 flex-wrap">
    @can('edit_clients')
    <a href="{{ route('dashboard.clients.edit', $client) }}" class="border border-indigo-600 text-indigo-600 px-4 py-2 rounded-lg text-sm hover:bg-indigo-50">تعديل البيانات</a>
    @endcan
    @can('add_fees')
    <a href="{{ route('dashboard.fees.create', $client) }}" class="bg-orange-500 hover:bg-orange-600 text-white px-4 py-2 rounded-lg text-sm">+ رسوم إضافية</a>
    @endcan
    @can('manage_contracts')
    <a href="{{ route('dashboard.contracts.create', $client) }}" class="bg-indigo-600 hover:bg-indigo-700 text-white px-4 py-2 rounded-lg text-sm">+ عقد جديد</a>
    @endcan
    <a href="{{ route('dashboard.invoices.create', ['client_id' => $client->id]) }}" class="bg-green-600 hover:bg-green-700 text-white px-4 py-2 rounded-lg text-sm">+ فاتورة يدوية</a>
    <form method="POST" action="{{ route('dashboard.clients.send-login-link', $client) }}" class="inline">
        @csrf
        <button type="submit" class="border border-indigo-400 text-indigo-600 hover:bg-indigo-50 px-4 py-2 rounded-lg text-sm">📱 إرسال كود الدخول</button>
    </form>
    <a href="{{ route('dashboard.reports.per-client', $client) }}" class="border border-gray-300 text-gray-600 px-4 py-2 rounded-lg text-sm hover:bg-gray-50">تقرير العميل</a>
    @can('edit_clients')
    <form method="POST" action="{{ route('dashboard.clients.toggle', $client) }}" class="inline">
        @csrf
        <button class="{{ $client->is_active ? 'bg-red-100 text-red-600 hover:bg-red-200' : 'bg-green-100 text-green-600 hover:bg-green-200' }} px-4 py-2 rounded-lg text-sm">
            {{ $client->is_active ? 'تعطيل الحساب' : 'تفعيل الحساب' }}
        </button>
    </form>
    @endcan
</div>

<div class="grid grid-cols-1 lg:grid-cols-3 gap-6 mb-6">
    <!-- Info -->
    <div class="bg-white rounded-xl shadow-sm p-6">
        <h3 class="font-bold text-gray-800 mb-4">بيانات العميل</h3>
        <div class="space-y-3 text-sm">
            <div><span class="text-gray-400">البريد:</span> <span class="font-medium">{{ $client->email }}</span></div>
            <div><span class="text-gray-400">الهاتف:</span> <span class="font-medium">{{ $client->phone ?? '-' }}</span></div>
            <div><span class="text-gray-400">الشركة:</span> <span class="font-medium">{{ $client->company_name ?? '-' }}</span></div>
            <div><span class="text-gray-400">العنوان:</span> <span class="font-medium">{{ $client->address ?? '-' }}</span></div>
            <div><span class="text-gray-400">اللغة:</span> <span class="font-medium">{{ $client->locale === 'ar' ? 'العربية' : 'English' }}</span></div>
            <div><span class="text-gray-400">الحالة:</span>
                @if($client->is_active)
                    <span class="bg-green-100 text-green-700 px-2 py-0.5 rounded-full text-xs">نشط</span>
                @else
                    <span class="bg-red-100 text-red-700 px-2 py-0.5 rounded-full text-xs">غير نشط</span>
                @endif
            </div>
        </div>
        @if($client->notes)
        <div class="mt-4 pt-4 border-t border-gray-100">
            <div class="text-xs text-gray-400 mb-1">ملاحظات داخلية:</div>
            <div class="text-sm text-gray-600">{{ $client->notes }}</div>
        </div>
        @endif
    </div>

    <!-- Contracts -->
    <div class="lg:col-span-2 bg-white rounded-xl shadow-sm p-6">
        <div class="flex justify-between items-center mb-4">
            <h3 class="font-bold text-gray-800">العقود والخدمات</h3>
        </div>
        @forelse($client->contracts as $contract)
        <div class="flex items-center justify-between py-3 border-b border-gray-50 last:border-0">
            <div>
                <div class="font-medium text-sm">{{ $contract->display_name }}</div>
                <div class="text-xs text-gray-400">
                    {{ match($contract->billing_cycle) { 'monthly'=>'شهري','quarterly'=>'ربع سنوي','annually'=>'سنوي' } }} ·
                    الاستحقاق: {{ $contract->next_due_date?->format('Y-m-d') }}
                </div>
            </div>
            <div class="flex items-center gap-3">
                <span class="font-bold text-sm">{{ number_format($contract->price, 0) }} ج.م</span>
                @if($contract->status === 'active')
                    <span class="bg-green-100 text-green-700 text-xs px-2 py-0.5 rounded-full">نشط</span>
                @elseif($contract->status === 'paused')
                    <span class="bg-yellow-100 text-yellow-700 text-xs px-2 py-0.5 rounded-full">موقوف</span>
                @else
                    <span class="bg-red-100 text-red-700 text-xs px-2 py-0.5 rounded-full">ملغي</span>
                @endif
                @can('manage_contracts')
                <a href="{{ route('dashboard.contracts.edit', $contract) }}" class="text-xs text-indigo-600 hover:underline">تعديل</a>
                @endcan
            </div>
        </div>
        @empty
        <p class="text-gray-400 text-sm text-center py-4">لا يوجد عقود</p>
        @endforelse
    </div>
</div>

<!-- Invoices -->
<div class="bg-white rounded-xl shadow-sm p-6 mb-6">
    <h3 class="font-bold text-gray-800 mb-4">الفواتير</h3>
    <div class="overflow-x-auto">
        <table class="w-full text-sm">
            <thead class="text-right">
                <tr class="border-b border-gray-100">
                    <th class="pb-3 font-semibold text-gray-500">رقم الفاتورة</th>
                    <th class="pb-3 font-semibold text-gray-500">المبلغ</th>
                    <th class="pb-3 font-semibold text-gray-500">الاستحقاق</th>
                    <th class="pb-3 font-semibold text-gray-500">الحالة</th>
                    <th class="pb-3 font-semibold text-gray-500">إجراء</th>
                </tr>
            </thead>
            <tbody class="divide-y divide-gray-50">
                @forelse($client->invoices->sortByDesc('created_at') as $inv)
                <tr>
                    <td class="py-3 font-medium">{{ $inv->invoice_number }}</td>
                    <td class="py-3">{{ number_format($inv->amount, 0) }} ج.م</td>
                    <td class="py-3 text-gray-500">{{ $inv->due_date?->format('Y-m-d') }}</td>
                    <td class="py-3">
                        @if($inv->status === 'paid') <span class="bg-green-100 text-green-700 text-xs px-2 py-0.5 rounded-full">مدفوعة</span>
                        @elseif($inv->status === 'overdue') <span class="bg-red-100 text-red-700 text-xs px-2 py-0.5 rounded-full">متأخرة</span>
                        @elseif($inv->status === 'cancelled') <span class="bg-gray-100 text-gray-500 text-xs px-2 py-0.5 rounded-full">ملغية</span>
                        @else <span class="bg-yellow-100 text-yellow-700 text-xs px-2 py-0.5 rounded-full">غير مدفوعة</span>
                        @endif
                    </td>
                    <td class="py-3">
                        @if(in_array($inv->status, ['unpaid','overdue']))
                        @can('mark_cash_payments')
                        <form method="POST" action="{{ route('dashboard.invoices.mark-cash', $inv) }}" class="inline">
                            @csrf
                            <button class="text-xs bg-green-50 hover:bg-green-100 text-green-700 border border-green-200 px-3 py-1 rounded-lg">تسجيل نقدي</button>
                        </form>
                        @endcan
                        @endif
                    </td>
                </tr>
                @empty
                <tr><td colspan="5" class="py-8 text-center text-gray-400">لا توجد فواتير</td></tr>
                @endforelse
            </tbody>
        </table>
    </div>
</div>

<!-- Additional Fees -->
<div class="bg-white rounded-xl shadow-sm p-6">
    <h3 class="font-bold text-gray-800 mb-4">الرسوم الإضافية</h3>
    @forelse($client->additionalFees as $fee)
    <div class="flex items-center justify-between py-3 border-b border-gray-50 last:border-0">
        <div>
            <div class="font-medium text-sm">{{ $fee->title }}</div>
            <div class="text-xs text-gray-400">{{ $fee->description }} · الاستحقاق: {{ $fee->due_date?->format('Y-m-d') }}</div>
        </div>
        <div class="flex items-center gap-3">
            <span class="font-bold text-sm">{{ number_format($fee->amount, 0) }} ج.م</span>
            @if($fee->status === 'paid') <span class="bg-green-100 text-green-700 text-xs px-2 py-0.5 rounded-full">مدفوعة</span>
            @elseif($fee->status === 'cancelled') <span class="bg-gray-100 text-gray-500 text-xs px-2 py-0.5 rounded-full">ملغية</span>
            @else <span class="bg-orange-100 text-orange-700 text-xs px-2 py-0.5 rounded-full">معلقة</span>
            @endif
            @if($fee->status === 'pending')
            @can('cancel_fees')
            <form method="POST" action="{{ route('dashboard.fees.cancel', $fee) }}" class="inline">
                @csrf
                <button class="text-xs text-red-500 hover:underline">إلغاء</button>
            </form>
            @endcan
            @endif
        </div>
    </div>
    @empty
    <p class="text-gray-400 text-sm text-center py-4">لا توجد رسوم إضافية</p>
    @endforelse
</div>
@endsection
