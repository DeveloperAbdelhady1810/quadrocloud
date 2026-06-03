@extends('layouts.dashboard')
@section('title', 'تعديل عقد')
@section('page-title', 'تعديل العقد')

@section('content')
<div class="max-w-xl mx-auto">
    <div class="bg-white rounded-xl shadow-sm p-8">
        <form method="POST" action="{{ route('dashboard.contracts.update', $contract) }}">
            @csrf @method('PUT')
            <div class="space-y-5">
                <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1">السعر (ج.م) *</label>
                    <input type="number" name="price" value="{{ old('price', $contract->price) }}" step="0.01" min="0" required
                        class="w-full border border-gray-300 rounded-lg px-4 py-2.5 focus:outline-none focus:ring-2 focus:ring-indigo-500">
                </div>
                <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1">الحالة *</label>
                    <select name="status" class="w-full border border-gray-300 rounded-lg px-4 py-2.5 focus:outline-none focus:ring-2 focus:ring-indigo-500">
                        <option value="active" {{ $contract->status === 'active' ? 'selected' : '' }}>نشط</option>
                        <option value="paused" {{ $contract->status === 'paused' ? 'selected' : '' }}>موقوف</option>
                        <option value="cancelled" {{ $contract->status === 'cancelled' ? 'selected' : '' }}>ملغي</option>
                    </select>
                </div>
                <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1">تاريخ الانتهاء (فارغ = مفتوح)</label>
                    <input type="date" name="end_date" value="{{ old('end_date', $contract->end_date?->format('Y-m-d')) }}"
                        class="w-full border border-gray-300 rounded-lg px-4 py-2.5 focus:outline-none focus:ring-2 focus:ring-indigo-500">
                </div>
                <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1">فترة السماح (أيام)</label>
                    <input type="number" name="grace_period_days" value="{{ old('grace_period_days', $contract->grace_period_days) }}" min="0" max="90"
                        class="w-full border border-gray-300 rounded-lg px-4 py-2.5 focus:outline-none focus:ring-2 focus:ring-indigo-500">
                </div>
                <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1">ملاحظات</label>
                    <textarea name="notes" rows="2"
                        class="w-full border border-gray-300 rounded-lg px-4 py-2.5 focus:outline-none focus:ring-2 focus:ring-indigo-500">{{ old('notes', $contract->notes) }}</textarea>
                </div>
            </div>
            <div class="flex gap-3 mt-6">
                <button type="submit" class="bg-indigo-600 hover:bg-indigo-700 text-white px-6 py-2.5 rounded-lg font-medium">حفظ التعديلات</button>
                <a href="{{ route('dashboard.clients.show', $contract->client) }}" class="border border-gray-300 text-gray-600 px-6 py-2.5 rounded-lg hover:bg-gray-50">إلغاء</a>
            </div>
        </form>
    </div>
</div>
@endsection
