@extends('layouts.dashboard')
@section('title', 'تعديل الخدمة')
@section('page-title', 'تعديل الخدمة')

@section('content')
<div class="max-w-2xl mx-auto">
    <div class="bg-white rounded-xl shadow-sm p-8">
        <form method="POST" action="{{ route('dashboard.services.update', $service) }}" enctype="multipart/form-data">
            @csrf @method('PUT')

            <div class="space-y-5">

                {{-- Name --}}
                <div>
                    <label class="block text-sm font-semibold text-gray-700 mb-1.5">اسم الخدمة *</label>
                    <input type="text" name="name" value="{{ old('name', $service->name) }}" required
                        class="w-full border border-gray-300 rounded-lg px-4 py-2.5 focus:outline-none focus:ring-2 focus:ring-indigo-500">
                </div>

                {{-- Description --}}
                <div>
                    <label class="block text-sm font-semibold text-gray-700 mb-1.5">وصف الخدمة</label>
                    <textarea name="description" rows="4"
                        class="w-full border border-gray-300 rounded-lg px-4 py-2.5 focus:outline-none focus:ring-2 focus:ring-indigo-500 resize-y">{{ old('description', $service->description) }}</textarea>
                </div>

                {{-- Price --}}
                <div>
                    <label class="block text-sm font-semibold text-gray-700 mb-1.5">السعر الافتراضي (ج.م) *</label>
                    <input type="number" name="default_price" value="{{ old('default_price', $service->default_price) }}"
                        min="0" step="0.01" required
                        class="w-full border border-gray-300 rounded-lg px-4 py-2.5 focus:outline-none focus:ring-2 focus:ring-indigo-500">
                </div>

                {{-- Icon + Image --}}
                <div class="grid grid-cols-2 gap-4">
                    <div>
                        <label class="block text-sm font-semibold text-gray-700 mb-1.5">أيقونة (إيموجي)</label>
                        <input type="text" name="icon" value="{{ old('icon', $service->icon) }}" maxlength="10"
                            placeholder="🖥️  📱  🔧"
                            class="w-full border border-gray-300 rounded-lg px-4 py-2.5 focus:outline-none focus:ring-2 focus:ring-indigo-500 text-2xl text-center">
                    </div>
                    <div>
                        <label class="block text-sm font-semibold text-gray-700 mb-1.5">
                            {{ $service->image_path ? 'استبدال الصورة' : 'صورة الخدمة' }}
                        </label>
                        @if($service->image_path)
                            <img src="{{ asset('storage/' . $service->image_path) }}"
                                class="w-16 h-16 rounded-lg object-cover mb-2">
                        @endif
                        <input type="file" name="image" accept="image/*"
                            class="w-full border border-gray-300 rounded-lg px-4 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500 file:ml-3 file:py-1 file:px-3 file:rounded file:border-0 file:bg-indigo-50 file:text-indigo-600">
                    </div>
                </div>

                {{-- Toggles --}}
                <div class="border border-gray-200 rounded-xl divide-y divide-gray-100 overflow-hidden">

                    <div class="flex items-center justify-between px-5 py-4">
                        <div>
                            <div class="font-medium text-gray-800 text-sm">عرض السعر في التطبيق</div>
                            <div class="text-xs text-gray-500 mt-0.5">إذا أوقفته، يُخفى السعر ويظهر زر "طلب الخدمة" فقط</div>
                        </div>
                        <label class="relative inline-flex items-center cursor-pointer">
                            <input type="checkbox" name="show_price" value="1" class="sr-only peer"
                                {{ old('show_price', $service->show_price) ? 'checked' : '' }}>
                            <div class="w-11 h-6 bg-gray-200 rounded-full peer peer-checked:bg-indigo-600 after:content-[''] after:absolute after:top-0.5 after:start-[2px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:after:translate-x-full rtl:peer-checked:after:-translate-x-full"></div>
                        </label>
                    </div>

                    <div class="flex items-center justify-between px-5 py-4">
                        <div>
                            <div class="font-medium text-gray-800 text-sm">إظهار في صفحة الاستكشاف (التطبيق)</div>
                            <div class="text-xs text-gray-500 mt-0.5">يُتيح للعملاء رؤية الخدمة والطلب عليها</div>
                        </div>
                        <label class="relative inline-flex items-center cursor-pointer">
                            <input type="checkbox" name="is_public" value="1" class="sr-only peer"
                                {{ old('is_public', $service->is_public) ? 'checked' : '' }}>
                            <div class="w-11 h-6 bg-gray-200 rounded-full peer peer-checked:bg-indigo-600 after:content-[''] after:absolute after:top-0.5 after:start-[2px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:after:translate-x-full rtl:peer-checked:after:-translate-x-full"></div>
                        </label>
                    </div>

                    <div class="flex items-center justify-between px-5 py-4">
                        <div>
                            <div class="font-medium text-gray-800 text-sm">متاح للعقود</div>
                            <div class="text-xs text-gray-500 mt-0.5">يظهر في قائمة الخدمات عند إضافة عقد جديد</div>
                        </div>
                        <label class="relative inline-flex items-center cursor-pointer">
                            <input type="checkbox" name="is_active" value="1" class="sr-only peer"
                                {{ old('is_active', $service->is_active) ? 'checked' : '' }}>
                            <div class="w-11 h-6 bg-gray-200 rounded-full peer peer-checked:bg-indigo-600 after:content-[''] after:absolute after:top-0.5 after:start-[2px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:after:translate-x-full rtl:peer-checked:after:-translate-x-full"></div>
                        </label>
                    </div>
                </div>

                {{-- Contracts using this service --}}
                @php $contractCount = $service->contracts()->count(); @endphp
                @if($contractCount > 0)
                <div class="bg-amber-50 border border-amber-200 rounded-lg px-4 py-3 text-sm text-amber-700">
                    <strong>تنبيه:</strong> هذه الخدمة مرتبطة بـ {{ $contractCount }} عقد.
                </div>
                @endif

            </div>

            <div class="flex gap-3 mt-8 pt-6 border-t border-gray-100">
                <button type="submit" class="bg-indigo-600 hover:bg-indigo-700 text-white px-8 py-2.5 rounded-lg font-medium">
                    حفظ التغييرات
                </button>
                <a href="{{ route('dashboard.services.index') }}"
                    class="border border-gray-300 text-gray-600 px-6 py-2.5 rounded-lg hover:bg-gray-50 font-medium">
                    إلغاء
                </a>
                <form method="POST" action="{{ route('dashboard.services.destroy', $service) }}"
                    class="mr-auto" onsubmit="return confirm('سيؤثر الحذف على العقود المرتبطة. متأكد؟')">
                    @csrf @method('DELETE')
                    <button type="submit" class="text-red-500 hover:text-red-700 px-4 py-2.5 text-sm font-medium">
                        حذف الخدمة
                    </button>
                </form>
            </div>
        </form>
    </div>
</div>
@endsection
