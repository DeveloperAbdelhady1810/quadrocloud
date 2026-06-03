@extends('layouts.dashboard')
@section('title', 'إرسال إشعار')
@section('page-title', 'إرسال إشعار للعملاء')

@section('content')
<div class="max-w-3xl mx-auto">
    <div class="bg-white rounded-xl shadow-sm p-8">
        <form method="POST" action="{{ route('dashboard.notifications.send') }}" id="notifForm">
            @csrf
            <div class="space-y-6">

                {{-- Title --}}
                <div>
                    <label class="block text-sm font-semibold text-gray-700 mb-1.5">
                        عنوان الإشعار * <span class="text-gray-400 font-normal text-xs">(100 حرف max)</span>
                    </label>
                    <input type="text" name="title" maxlength="100" value="{{ old('title') }}" required
                        placeholder="مثال: خدمة جديدة متاحة الآن!"
                        class="w-full border border-gray-300 rounded-lg px-4 py-2.5 focus:outline-none focus:ring-2 focus:ring-indigo-500">
                </div>

                {{-- Body --}}
                <div>
                    <label class="block text-sm font-semibold text-gray-700 mb-1.5">
                        نص الإشعار * <span class="text-gray-400 font-normal text-xs">(300 حرف max)</span>
                    </label>
                    <textarea name="body" maxlength="300" rows="3" required
                        placeholder="اكتب تفاصيل الإشعار هنا..."
                        class="w-full border border-gray-300 rounded-lg px-4 py-2.5 focus:outline-none focus:ring-2 focus:ring-indigo-500 resize-none">{{ old('body') }}</textarea>
                </div>

                {{-- Action (deep link) --}}
                <div>
                    <label class="block text-sm font-semibold text-gray-700 mb-1.5">
                        إجراء عند الضغط على الإشعار
                    </label>
                    <select name="action" id="actionSelect"
                        class="w-full border border-gray-300 rounded-lg px-4 py-2.5 focus:outline-none focus:ring-2 focus:ring-indigo-500"
                        onchange="toggleActionId()">
                        <option value="none" {{ old('action') == 'none' || !old('action') ? 'selected' : '' }}>لا شيء — فتح التطبيق فقط</option>
                        <option value="services" {{ old('action') == 'services' ? 'selected' : '' }}>📦 فتح صفحة الخدمات</option>
                        <option value="service_detail" {{ old('action') == 'service_detail' ? 'selected' : '' }}>🔍 فتح خدمة بعينها (بتمييزها)</option>
                        <option value="news" {{ old('action') == 'news' ? 'selected' : '' }}>📰 فتح صفحة الأخبار</option>
                        <option value="contracts" {{ old('action') == 'contracts' ? 'selected' : '' }}>📄 فتح صفحة العقود</option>
                        <option value="invoices" {{ old('action') == 'invoices' ? 'selected' : '' }}>🧾 فتح صفحة الفواتير</option>
                    </select>
                </div>

                {{-- Service picker (shown only when service_detail) --}}
                <div id="servicePickerWrap" class="{{ old('action') == 'service_detail' ? '' : 'hidden' }}">
                    <label class="block text-sm font-semibold text-gray-700 mb-1.5">اختر الخدمة</label>
                    <select name="action_id"
                        class="w-full border border-gray-300 rounded-lg px-4 py-2.5 focus:outline-none focus:ring-2 focus:ring-indigo-500">
                        <option value="">-- اختر --</option>
                        @foreach($services as $service)
                            <option value="{{ $service->id }}" {{ old('action_id') == $service->id ? 'selected' : '' }}>
                                {{ $service->name }}
                            </option>
                        @endforeach
                    </select>
                </div>

                {{-- Target --}}
                <div>
                    <label class="block text-sm font-semibold text-gray-700 mb-3">المستلمون</label>
                    <div class="flex gap-4 mb-4">
                        <label class="flex items-center gap-2 cursor-pointer">
                            <input type="radio" name="target" value="all" class="text-indigo-600"
                                {{ old('target', 'all') == 'all' ? 'checked' : '' }}
                                onchange="document.getElementById('clientList').classList.add('hidden')">
                            <span class="font-medium text-sm">كل العملاء النشطين</span>
                        </label>
                        <label class="flex items-center gap-2 cursor-pointer">
                            <input type="radio" name="target" value="selected" class="text-indigo-600"
                                {{ old('target') == 'selected' ? 'checked' : '' }}
                                onchange="document.getElementById('clientList').classList.remove('hidden')">
                            <span class="font-medium text-sm">عملاء محددون</span>
                        </label>
                    </div>

                    <div id="clientList" class="{{ old('target') == 'selected' ? '' : 'hidden' }} border border-gray-200 rounded-xl p-4 max-h-64 overflow-y-auto space-y-2">
                        <div class="flex gap-3 mb-3">
                            <button type="button" onclick="selectAll(true)"
                                class="text-xs text-indigo-600 hover:underline">تحديد الكل</button>
                            <button type="button" onclick="selectAll(false)"
                                class="text-xs text-gray-500 hover:underline">إلغاء الكل</button>
                        </div>
                        @foreach($clients as $client)
                        <label class="flex items-center gap-3 p-2 hover:bg-gray-50 rounded-lg cursor-pointer">
                            <input type="checkbox" name="client_ids[]" value="{{ $client->id }}" class="client-check text-indigo-600 rounded"
                                {{ in_array($client->id, old('client_ids', [])) ? 'checked' : '' }}>
                            <div>
                                <div class="text-sm font-medium text-gray-800">{{ $client->name }}</div>
                                <div class="text-xs text-gray-400">{{ $client->email }}</div>
                            </div>
                        </label>
                        @endforeach
                        @if($clients->isEmpty())
                            <p class="text-gray-400 text-sm text-center py-4">لا يوجد عملاء</p>
                        @endif
                    </div>
                </div>

                {{-- Preview --}}
                <div class="bg-gray-900 rounded-2xl p-5 text-white">
                    <p class="text-xs text-gray-400 mb-3 uppercase tracking-widest">معاينة الإشعار</p>
                    <div class="bg-gray-800 rounded-xl p-4 flex items-start gap-3">
                        <div class="w-10 h-10 rounded-xl bg-indigo-600 flex items-center justify-center shrink-0">
                            <svg class="w-5 h-5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6 6 0 10-12 0v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9"/>
                            </svg>
                        </div>
                        <div>
                            <p id="previewTitle" class="font-bold text-sm">عنوان الإشعار</p>
                            <p id="previewBody" class="text-gray-300 text-xs mt-1 leading-relaxed">نص الإشعار</p>
                        </div>
                    </div>
                </div>

            </div>

            <div class="flex gap-3 mt-8 pt-6 border-t border-gray-100">
                <button type="submit"
                    class="bg-indigo-600 hover:bg-indigo-700 text-white px-8 py-2.5 rounded-lg font-medium flex items-center gap-2">
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 19l9 2-9-18-9 18 9-2zm0 0v-8"/>
                    </svg>
                    إرسال الإشعار
                </button>
                <a href="{{ route('dashboard.home') }}"
                    class="border border-gray-300 text-gray-600 px-6 py-2.5 rounded-lg hover:bg-gray-50 font-medium">
                    إلغاء
                </a>
            </div>
        </form>
    </div>
</div>

@push('scripts')
<script>
function toggleActionId() {
    const wrap = document.getElementById('servicePickerWrap');
    const val = document.getElementById('actionSelect').value;
    wrap.classList.toggle('hidden', val !== 'service_detail');
}

function selectAll(state) {
    document.querySelectorAll('.client-check').forEach(c => c.checked = state);
}

// Live preview
const titleInput = document.querySelector('[name="title"]');
const bodyInput  = document.querySelector('[name="body"]');
function updatePreview() {
    document.getElementById('previewTitle').textContent = titleInput.value || 'عنوان الإشعار';
    document.getElementById('previewBody').textContent  = bodyInput.value  || 'نص الإشعار';
}
titleInput.addEventListener('input', updatePreview);
bodyInput.addEventListener('input',  updatePreview);
</script>
@endpush
@endsection
