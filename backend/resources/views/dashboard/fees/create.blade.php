@extends('layouts.dashboard')
@section('title', 'رسوم إضافية')
@section('page-title', 'إضافة رسوم لـ ' . $client->name)

@section('content')
<div class="max-w-xl mx-auto">
    <div class="bg-orange-50 border border-orange-200 rounded-xl p-4 mb-6 text-sm text-orange-800">
        ⚠️ سيتم إشعار العميل فور إضافة الرسوم عبر الإشعارات الفورية
    </div>
    <div class="bg-white rounded-xl shadow-sm p-8">
        <form method="POST" action="{{ route('dashboard.fees.store', $client) }}">
            @csrf
            <div class="space-y-5">
                <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1">عنوان الرسوم *</label>
                    <input type="text" name="title" value="{{ old('title') }}" required placeholder="مثال: رسوم صيانة طارئة"
                        class="w-full border border-gray-300 rounded-lg px-4 py-2.5 focus:outline-none focus:ring-2 focus:ring-orange-400">
                </div>
                <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1">وصف تفصيلي</label>
                    <textarea name="description" rows="3" placeholder="اشرح سبب الرسوم..."
                        class="w-full border border-gray-300 rounded-lg px-4 py-2.5 focus:outline-none focus:ring-2 focus:ring-orange-400">{{ old('description') }}</textarea>
                </div>
                <div class="grid grid-cols-2 gap-4">
                    <div>
                        <label class="block text-sm font-medium text-gray-700 mb-1">المبلغ (ج.م) *</label>
                        <input type="number" name="amount" value="{{ old('amount') }}" step="0.01" min="0.5" required
                            class="w-full border border-gray-300 rounded-lg px-4 py-2.5 focus:outline-none focus:ring-2 focus:ring-orange-400">
                    </div>
                    <div>
                        <label class="block text-sm font-medium text-gray-700 mb-1">تاريخ الاستحقاق *</label>
                        <input type="date" name="due_date" value="{{ old('due_date') }}" required
                            class="w-full border border-gray-300 rounded-lg px-4 py-2.5 focus:outline-none focus:ring-2 focus:ring-orange-400">
                    </div>
                </div>
                <div>
                    <label class="block text-sm font-medium text-gray-700 mb-1">الموعد النهائي للقبول (اختياري)</label>
                    <input type="date" name="acceptance_deadline" value="{{ old('acceptance_deadline') }}"
                        class="w-full border border-gray-300 rounded-lg px-4 py-2.5 focus:outline-none focus:ring-2 focus:ring-orange-400">
                    <p class="text-xs text-gray-400 mt-1">التاريخ الذي يجب أن يدفع فيه العميل أو يتفق معك</p>
                </div>
            </div>
            <div class="flex gap-3 mt-6">
                <button type="submit" class="bg-orange-500 hover:bg-orange-600 text-white px-6 py-2.5 rounded-lg font-medium">إرسال الرسوم وإشعار العميل</button>
                <a href="{{ route('dashboard.clients.show', $client) }}" class="border border-gray-300 text-gray-600 px-6 py-2.5 rounded-lg hover:bg-gray-50">إلغاء</a>
            </div>
        </form>
    </div>
</div>
@endsection
