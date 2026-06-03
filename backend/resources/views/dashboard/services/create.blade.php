@extends('layouts.dashboard')
@section('title', 'إضافة خدمة')
@section('page-title', 'إضافة خدمة جديدة')

@section('content')
<div class="max-w-2xl mx-auto">
    <div class="bg-white rounded-xl shadow-sm p-8">
        <form method="POST" action="{{ route('dashboard.services.store') }}" enctype="multipart/form-data">
            @csrf

            <div class="space-y-5">

                {{-- Name --}}
                <div>
                    <label class="block text-sm font-semibold text-gray-700 mb-1.5">اسم الخدمة *</label>
                    <input type="text" name="name" value="{{ old('name') }}" required
                        placeholder="مثال: صيانة شبكات، تطوير تطبيق..."
                        class="w-full border border-gray-300 rounded-lg px-4 py-2.5 focus:outline-none focus:ring-2 focus:ring-indigo-500">
                </div>

                {{-- Description --}}
                <div>
                    <label class="block text-sm font-semibold text-gray-700 mb-1.5">وصف الخدمة</label>
                    <textarea name="description" rows="4"
                        placeholder="اشرح ما تقدمه هذه الخدمة للعميل..."
                        class="w-full border border-gray-300 rounded-lg px-4 py-2.5 focus:outline-none focus:ring-2 focus:ring-indigo-500 resize-y">{{ old('description') }}</textarea>
                </div>

                {{-- Price --}}
                <div>
                    <label class="block text-sm font-semibold text-gray-700 mb-1.5">السعر الافتراضي (ج.م) *</label>
                    <input type="number" name="default_price" value="{{ old('default_price', 0) }}" min="0" step="0.01" required
                        class="w-full border border-gray-300 rounded-lg px-4 py-2.5 focus:outline-none focus:ring-2 focus:ring-indigo-500">
                    <p class="text-xs text-gray-400 mt-1">يُستخدم كقيمة افتراضية عند إضافة عقد جديد</p>
                </div>

                {{-- Icon + Image row --}}
                <div class="grid grid-cols-2 gap-4">
                    <div>
                        <label class="block text-sm font-semibold text-gray-700 mb-1.5">أيقونة (إيموجي)</label>
                        <input type="text" name="icon" value="{{ old('icon') }}" maxlength="10"
                            placeholder="🖥️  📱  🔧  🌐"
                            class="w-full border border-gray-300 rounded-lg px-4 py-2.5 focus:outline-none focus:ring-2 focus:ring-indigo-500 text-2xl text-center">
                        <p class="text-xs text-gray-400 mt-1">انسخ أي إيموجي وضعه هنا</p>
                    </div>
                    <div>
                        <label class="block text-sm font-semibold text-gray-700 mb-1.5">صورة الخدمة</label>
                        <input type="file" name="image" accept="image/*"
                            class="w-full border border-gray-300 rounded-lg px-4 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500 file:ml-3 file:py-1 file:px-3 file:rounded file:border-0 file:bg-indigo-50 file:text-indigo-600">
                        <p class="text-xs text-gray-400 mt-1">JPG، PNG، WebP — حد 5 ميجا</p>
                    </div>
                </div>

                {{-- Toggles --}}
                <div class="border border-gray-200 rounded-xl divide-y divide-gray-100 overflow-hidden">

                    {{-- show_price --}}
                    <div class="flex items-center justify-between px-5 py-4">
                        <div>
                            <div class="font-medium text-gray-800 text-sm">عرض السعر في التطبيق</div>
                            <div class="text-xs text-gray-500 mt-0.5">إذا أوقفته، يُخفى السعر ويُعرض زر "طلب الخدمة" فقط</div>
                        </div>
                        <label class="relative inline-flex items-center cursor-pointer">
                            <input type="checkbox" name="show_price" value="1" class="sr-only peer" {{ old('show_price') ? 'checked' : '' }}>
                            <div class="w-11 h-6 bg-gray-200 rounded-full peer peer-checked:bg-indigo-600 after:content-[''] after:absolute after:top-0.5 after:start-[2px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:after:translate-x-full rtl:peer-checked:after:-translate-x-full"></div>
                        </label>
                    </div>

                    {{-- is_public --}}
                    <div class="flex items-center justify-between px-5 py-4">
                        <div>
                            <div class="font-medium text-gray-800 text-sm">إظهار في صفحة الاستكشاف (التطبيق)</div>
                            <div class="text-xs text-gray-500 mt-0.5">يُتيح للعملاء رؤية الخدمة والطلب عليها من التطبيق</div>
                        </div>
                        <label class="relative inline-flex items-center cursor-pointer">
                            <input type="checkbox" name="is_public" value="1" class="sr-only peer" {{ old('is_public') ? 'checked' : '' }}>
                            <div class="w-11 h-6 bg-gray-200 rounded-full peer peer-checked:bg-indigo-600 after:content-[''] after:absolute after:top-0.5 after:start-[2px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:after:translate-x-full rtl:peer-checked:after:-translate-x-full"></div>
                        </label>
                    </div>

                    {{-- is_active --}}
                    <div class="flex items-center justify-between px-5 py-4">
                        <div>
                            <div class="font-medium text-gray-800 text-sm">متاح للعقود</div>
                            <div class="text-xs text-gray-500 mt-0.5">يظهر في قائمة الخدمات عند إضافة عقد جديد</div>
                        </div>
                        <label class="relative inline-flex items-center cursor-pointer">
                            <input type="checkbox" name="is_active" value="1" class="sr-only peer" checked>
                            <div class="w-11 h-6 bg-gray-200 rounded-full peer peer-checked:bg-indigo-600 after:content-[''] after:absolute after:top-0.5 after:start-[2px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:after:translate-x-full rtl:peer-checked:after:-translate-x-full"></div>
                        </label>
                    </div>
                </div>

            </div>

            <div class="flex gap-3 mt-8 pt-6 border-t border-gray-100">
                <button type="submit" class="bg-indigo-600 hover:bg-indigo-700 text-white px-8 py-2.5 rounded-lg font-medium">
                    حفظ الخدمة
                </button>
                <a href="{{ route('dashboard.services.index') }}"
                    class="border border-gray-300 text-gray-600 px-6 py-2.5 rounded-lg hover:bg-gray-50 font-medium">
                    إلغاء
                </a>
            </div>
        </form>
    </div>
</div>
@endsection
