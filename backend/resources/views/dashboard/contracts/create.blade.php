@extends('layouts.dashboard')
@section('title', 'إضافة عقد')
@section('page-title', 'إضافة عقد لـ ' . $client->name)

@section('content')
<div class="max-w-2xl mx-auto">
    <div class="bg-white rounded-xl shadow-sm p-8">
        <form method="POST" action="{{ route('dashboard.contracts.store', $client) }}">
            @csrf
            <div class="grid grid-cols-1 md:grid-cols-2 gap-5">
                <div class="md:col-span-2">
                    <label class="block text-sm font-medium text-gray-700 mb-1">الخدمة من الكتالوج</label>
                    <select name="service_id" id="service_select" class="w-full border border-gray-300 rounded-lg px-4 py-2.5 focus:outline-none focus:ring-2 focus:ring-indigo-500">
                        <option value="">-- اختر خدمة أو أدخل اسماً مخصصاً --</option>
                        @foreach($services as $s)
                        <option value="{{ $s->id }}" data-price="{{ $s->default_price }}">{{ $s->name }} ({{ number_format($s->default_price, 0) }} ج.م)</option>
                        @endforeach
                    </select>
                </div>
                <div class="md:col-span-2">
                    <label class="block text-sm font-medium text-gray-700 mb-1">اسم مخصص (اختياري)</label>
                    <input type="text" name="custom_name" value="{{ old('custom_name') }}" placeholder="مثال: استضافة موقع شركة ABC"
                        class="w-full border border-gray-300 rounded-lg px-4 py-2.5 focus:outline-none focus:ring-2 focus:ring-indigo-500">
                </div>
                <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1">السعر (ج.م) *</label>
                    <input type="number" name="price" id="price_field" value="{{ old('price') }}" step="0.01" min="0" required
                        class="w-full border border-gray-300 rounded-lg px-4 py-2.5 focus:outline-none focus:ring-2 focus:ring-indigo-500">
                </div>
                <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1">دورة الفوترة *</label>
                    <select name="billing_cycle" class="w-full border border-gray-300 rounded-lg px-4 py-2.5 focus:outline-none focus:ring-2 focus:ring-indigo-500">
                        <option value="monthly">شهري</option>
                        <option value="quarterly">ربع سنوي</option>
                        <option value="annually">سنوي</option>
                    </select>
                </div>
                <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1">تاريخ البداية *</label>
                    <input type="date" name="start_date" value="{{ old('start_date', now()->format('Y-m-d')) }}" required
                        class="w-full border border-gray-300 rounded-lg px-4 py-2.5 focus:outline-none focus:ring-2 focus:ring-indigo-500">
                </div>
                <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1">تاريخ الانتهاء (فارغ = مفتوح)</label>
                    <input type="date" name="end_date" value="{{ old('end_date') }}"
                        class="w-full border border-gray-300 rounded-lg px-4 py-2.5 focus:outline-none focus:ring-2 focus:ring-indigo-500">
                </div>
                <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1">فترة السماح (أيام)</label>
                    <input type="number" name="grace_period_days" value="{{ old('grace_period_days', 0) }}" min="0" max="90"
                        class="w-full border border-gray-300 rounded-lg px-4 py-2.5 focus:outline-none focus:ring-2 focus:ring-indigo-500">
                </div>
                <div class="md:col-span-2">
                    <label class="block text-sm font-medium text-gray-700 mb-1">ملاحظات</label>
                    <textarea name="notes" rows="2"
                        class="w-full border border-gray-300 rounded-lg px-4 py-2.5 focus:outline-none focus:ring-2 focus:ring-indigo-500">{{ old('notes') }}</textarea>
                </div>
            </div>
            <div class="flex gap-3 mt-6">
                <button type="submit" class="bg-indigo-600 hover:bg-indigo-700 text-white px-6 py-2.5 rounded-lg font-medium">إضافة العقد</button>
                <a href="{{ route('dashboard.clients.show', $client) }}" class="border border-gray-300 text-gray-600 px-6 py-2.5 rounded-lg hover:bg-gray-50">إلغاء</a>
            </div>
        </form>
    </div>
</div>

@push('scripts')
<script>
document.getElementById('service_select').addEventListener('change', function() {
    const price = this.options[this.selectedIndex].dataset.price;
    if (price) document.getElementById('price_field').value = price;
});
</script>
@endpush
@endsection
