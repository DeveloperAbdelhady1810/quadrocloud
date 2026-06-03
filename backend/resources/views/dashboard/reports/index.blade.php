@extends('layouts.dashboard')
@section('title', 'التقارير')
@section('page-title', 'التقارير والإحصائيات')

@section('content')
<!-- KPI Cards -->
<div class="grid grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
    <div class="bg-white rounded-xl shadow-sm p-6 border-t-4 border-indigo-500">
        <div class="text-sm text-gray-400 mb-1">إيرادات هذا الشهر</div>
        <div class="text-2xl font-bold text-gray-800">{{ number_format($monthlyRevenue, 0) }} ج.م</div>
    </div>
    <div class="bg-white rounded-xl shadow-sm p-6 border-t-4 border-green-500">
        <div class="text-sm text-gray-400 mb-1">إجمالي هذا العام</div>
        <div class="text-2xl font-bold text-gray-800">{{ number_format($totalRevenue, 0) }} ج.م</div>
    </div>
    <div class="bg-white rounded-xl shadow-sm p-6 border-t-4 border-blue-500">
        <div class="text-sm text-gray-400 mb-1">نسبة التحصيل</div>
        <div class="text-2xl font-bold text-gray-800">{{ $collectionRate }}%</div>
    </div>
    <div class="bg-white rounded-xl shadow-sm p-6 border-t-4 border-red-500">
        <div class="text-sm text-gray-400 mb-1">فواتير متأخرة</div>
        <div class="text-2xl font-bold text-red-600">{{ $overdueCount }}</div>
    </div>
</div>

<!-- Revenue Chart -->
<div class="bg-white rounded-xl shadow-sm p-6 mb-6">
    <h3 class="font-bold text-gray-800 mb-4">الإيرادات الشهرية {{ now()->year }}</h3>
    <canvas id="revenueChart" height="100"></canvas>
</div>

<div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
    <!-- Overdue -->
    <div class="bg-white rounded-xl shadow-sm p-6">
        <div class="flex justify-between items-center mb-4">
            <h3 class="font-bold text-gray-800">الفواتير المتأخرة</h3>
            <a href="{{ route('dashboard.reports.export-overdue') }}" class="text-sm bg-red-50 text-red-600 hover:bg-red-100 px-3 py-1.5 rounded-lg">تصدير CSV</a>
        </div>
        <div class="space-y-3 max-h-80 overflow-y-auto">
            @forelse($overdueInvoices as $inv)
            <div class="flex items-center justify-between py-2 border-b border-gray-50 last:border-0">
                <div>
                    <a href="{{ route('dashboard.clients.show', $inv->client) }}" class="font-medium text-sm text-indigo-600 hover:underline">{{ $inv->client->name }}</a>
                    <div class="text-xs text-gray-400">{{ $inv->invoice_number }} · استحق {{ $inv->due_date->format('Y-m-d') }}</div>
                </div>
                <span class="text-red-600 font-bold text-sm">{{ number_format($inv->amount, 0) }} ج.م</span>
            </div>
            @empty
            <p class="text-gray-400 text-sm text-center py-4">لا توجد فواتير متأخرة 🎉</p>
            @endforelse
        </div>
    </div>

    <!-- Upcoming -->
    <div class="bg-white rounded-xl shadow-sm p-6">
        <h3 class="font-bold text-gray-800 mb-4">مدفوعات خلال 30 يوماً ({{ $upcomingCount }})</h3>
        <div class="space-y-3 max-h-80 overflow-y-auto">
            @forelse($upcomingInvoices as $inv)
            <div class="flex items-center justify-between py-2 border-b border-gray-50 last:border-0">
                <div>
                    <a href="{{ route('dashboard.clients.show', $inv->client) }}" class="font-medium text-sm text-indigo-600 hover:underline">{{ $inv->client->name }}</a>
                    <div class="text-xs text-gray-400">{{ $inv->invoice_number }} · {{ $inv->due_date->format('Y-m-d') }}</div>
                </div>
                <span class="font-bold text-sm">{{ number_format($inv->amount, 0) }} ج.م</span>
            </div>
            @empty
            <p class="text-gray-400 text-sm text-center py-4">لا توجد مدفوعات قادمة</p>
            @endforelse
        </div>
    </div>
</div>

@push('scripts')
<script>
const months = ['يناير','فبراير','مارس','أبريل','مايو','يونيو','يوليو','أغسطس','سبتمبر','أكتوبر','نوفمبر','ديسمبر'];
const data = @json($monthlyData);
const values = months.map((_, i) => data[i+1] || 0);

new Chart(document.getElementById('revenueChart'), {
    type: 'bar',
    data: {
        labels: months,
        datasets: [{
            label: 'الإيرادات (ج.م)',
            data: values,
            backgroundColor: 'rgba(99, 102, 241, 0.7)',
            borderColor: '#4f46e5',
            borderWidth: 1,
            borderRadius: 6,
        }]
    },
    options: {
        responsive: true,
        plugins: { legend: { display: false } },
        scales: { y: { beginAtZero: true } }
    }
});
</script>
@endpush
@endsection
