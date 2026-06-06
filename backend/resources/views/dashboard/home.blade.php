@extends('layouts.dashboard')
@section('title', 'الرئيسية')
@section('page-title', 'لوحة التحكم')

@section('content')
@php
    $totalClients    = \App\Models\Client::where('is_active', true)->count();
    $overdueCount    = \App\Models\Invoice::where('status', 'overdue')->count();
    $upcomingCount   = \App\Models\Invoice::where('status','unpaid')->whereBetween('due_date',[now(),now()->addDays(7)])->count();
    $monthRevenue    = \App\Models\Payment::where('status','success')->whereMonth('paid_at',now()->month)->whereYear('paid_at',now()->year)->sum('amount');
    $recentPayments  = \App\Models\Payment::with(['client','invoice'])->where('status','success')->latest()->limit(5)->get();
    $overdueInvoices = \App\Models\Invoice::with('client')->where('status','overdue')->orderBy('due_date')->limit(5)->get();

    // Last 6 months revenue for chart
    $revenueChart = collect(range(5, 0))->map(function ($i) {
        $d = now()->subMonths($i);
        return [
            'label'  => $d->locale('ar')->isoFormat('MMM YY'),
            'amount' => (float) \App\Models\Payment::where('status','success')
                ->whereYear('paid_at', $d->year)->whereMonth('paid_at', $d->month)->sum('amount'),
        ];
    });

    // Invoice status breakdown
    $invoiceStatus = [
        'paid'    => \App\Models\Invoice::where('status','paid')->count(),
        'unpaid'  => \App\Models\Invoice::where('status','unpaid')->count(),
        'overdue' => \App\Models\Invoice::where('status','overdue')->count(),
    ];
@endphp

{{-- Stats row --}}
<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
    <div class="bg-white rounded-xl shadow-sm p-6 border-r-4 border-indigo-500">
        <div class="text-sm text-gray-500 mb-1">إجمالي العملاء النشطين</div>
        <div class="text-3xl font-bold text-gray-800">{{ $totalClients }}</div>
    </div>
    <div class="bg-white rounded-xl shadow-sm p-6 border-r-4 border-green-500">
        <div class="text-sm text-gray-500 mb-1">إيرادات هذا الشهر</div>
        <div class="text-3xl font-bold text-gray-800">{{ number_format($monthRevenue, 0) }} ج.م</div>
    </div>
    <div class="bg-white rounded-xl shadow-sm p-6 border-r-4 border-yellow-500">
        <div class="text-sm text-gray-500 mb-1">مدفوعات خلال 7 أيام</div>
        <div class="text-3xl font-bold text-gray-800">{{ $upcomingCount }}</div>
    </div>
    <div class="bg-white rounded-xl shadow-sm p-6 border-r-4 border-red-500">
        <div class="text-sm text-gray-500 mb-1">فواتير متأخرة</div>
        <div class="text-3xl font-bold text-red-600">{{ $overdueCount }}</div>
    </div>
</div>

{{-- Charts row --}}
<div class="grid grid-cols-1 lg:grid-cols-3 gap-6 mb-8">
    <div class="lg:col-span-2 bg-white rounded-xl shadow-sm p-6">
        <h3 class="font-bold text-gray-800 mb-4">الإيرادات — آخر 6 أشهر</h3>
        <canvas id="revenueChart" height="100"></canvas>
    </div>
    <div class="bg-white rounded-xl shadow-sm p-6">
        <h3 class="font-bold text-gray-800 mb-4">حالة الفواتير</h3>
        <canvas id="statusChart"></canvas>
        <div class="mt-4 space-y-1 text-sm">
            <div class="flex justify-between"><span class="flex items-center gap-2"><span class="w-3 h-3 rounded-full bg-green-500 inline-block"></span>مدفوعة</span><span class="font-bold">{{ $invoiceStatus['paid'] }}</span></div>
            <div class="flex justify-between"><span class="flex items-center gap-2"><span class="w-3 h-3 rounded-full bg-yellow-400 inline-block"></span>غير مدفوعة</span><span class="font-bold">{{ $invoiceStatus['unpaid'] }}</span></div>
            <div class="flex justify-between"><span class="flex items-center gap-2"><span class="w-3 h-3 rounded-full bg-red-500 inline-block"></span>متأخرة</span><span class="font-bold">{{ $invoiceStatus['overdue'] }}</span></div>
        </div>
    </div>
</div>

{{-- Tables row --}}
<div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
    <div class="bg-white rounded-xl shadow-sm p-6">
        <div class="flex justify-between items-center mb-4">
            <h3 class="font-bold text-gray-800">آخر المدفوعات</h3>
            <a href="{{ route('dashboard.payments.index') }}" class="text-sm text-indigo-600 hover:underline">عرض الكل</a>
        </div>
        <div class="space-y-3">
            @forelse($recentPayments as $p)
            <div class="flex items-center justify-between py-2 border-b border-gray-50 last:border-0">
                <div>
                    <div class="font-medium text-sm">{{ $p->client->name }}</div>
                    <div class="text-xs text-gray-400">{{ $p->invoice?->invoice_number }} · {{ $p->method === 'cash' ? 'نقدي' : 'أونلاين' }}</div>
                </div>
                <div class="text-green-600 font-bold text-sm">{{ number_format($p->amount, 0) }} ج.م</div>
            </div>
            @empty
            <p class="text-gray-400 text-sm text-center py-4">لا توجد مدفوعات بعد</p>
            @endforelse
        </div>
    </div>

    <div class="bg-white rounded-xl shadow-sm p-6">
        <div class="flex justify-between items-center mb-4">
            <h3 class="font-bold text-gray-800">فواتير متأخرة</h3>
            <a href="{{ route('dashboard.reports.index') }}" class="text-sm text-indigo-600 hover:underline">عرض التقارير</a>
        </div>
        <div class="space-y-3">
            @forelse($overdueInvoices as $inv)
            <div class="flex items-center justify-between py-2 border-b border-gray-50 last:border-0">
                <div>
                    <div class="font-medium text-sm">{{ $inv->client->name }}</div>
                    <div class="text-xs text-gray-400">{{ $inv->invoice_number }} · استحق {{ $inv->due_date->format('Y-m-d') }}</div>
                </div>
                <div class="flex items-center gap-2">
                    <span class="text-red-600 font-bold text-sm">{{ number_format($inv->amount, 0) }} ج.م</span>
                    <form method="POST" action="{{ route('dashboard.invoices.mark-cash', $inv) }}">
                        @csrf
                        <button class="text-xs bg-green-100 hover:bg-green-200 text-green-700 px-2 py-1 rounded">نقدي</button>
                    </form>
                </div>
            </div>
            @empty
            <p class="text-gray-400 text-sm text-center py-4">لا توجد فواتير متأخرة 🎉</p>
            @endforelse
        </div>
    </div>
</div>

@push('scripts')
<script>
const revenueLabels  = @json($revenueChart->pluck('label'));
const revenueData    = @json($revenueChart->pluck('amount'));
const statusData     = @json(array_values($invoiceStatus));

new Chart(document.getElementById('revenueChart'), {
    type: 'bar',
    data: {
        labels: revenueLabels,
        datasets: [{
            label: 'الإيرادات (ج.م)',
            data: revenueData,
            backgroundColor: 'rgba(79,70,229,0.15)',
            borderColor: '#4f46e5',
            borderWidth: 2,
            borderRadius: 6,
        }]
    },
    options: {
        responsive: true,
        plugins: { legend: { display: false } },
        scales: { y: { beginAtZero: true, ticks: { callback: v => v.toLocaleString('ar') + ' ج.م' } } }
    }
});

new Chart(document.getElementById('statusChart'), {
    type: 'doughnut',
    data: {
        labels: ['مدفوعة', 'غير مدفوعة', 'متأخرة'],
        datasets: [{
            data: statusData,
            backgroundColor: ['#22c55e', '#facc15', '#ef4444'],
            borderWidth: 0,
        }]
    },
    options: {
        responsive: true,
        cutout: '70%',
        plugins: { legend: { display: false } }
    }
});
</script>
@endpush
@endsection
