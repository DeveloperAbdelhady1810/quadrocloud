@extends('layouts.dashboard')
@section('title', 'الخدمات')
@section('page-title', 'إدارة الخدمات')

@section('content')
<div class="flex justify-between items-center mb-6">
    <p class="text-gray-500 text-sm">{{ $services->count() }} خدمة</p>
    <a href="{{ route('dashboard.services.create') }}"
        class="bg-indigo-600 hover:bg-indigo-700 text-white px-5 py-2.5 rounded-lg font-medium text-sm flex items-center gap-2">
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/></svg>
        إضافة خدمة
    </a>
</div>

<div class="bg-white rounded-xl shadow-sm overflow-hidden">
    <table class="w-full text-sm">
        <thead class="bg-gray-50 border-b border-gray-200">
            <tr>
                <th class="px-6 py-4 text-right font-semibold text-gray-600">الخدمة</th>
                <th class="px-6 py-4 text-right font-semibold text-gray-600">السعر</th>
                <th class="px-6 py-4 text-right font-semibold text-gray-600">عرض السعر</th>
                <th class="px-6 py-4 text-right font-semibold text-gray-600">في التطبيق</th>
                <th class="px-6 py-4 text-right font-semibold text-gray-600">للعقود</th>
                <th class="px-6 py-4 text-right font-semibold text-gray-600">إجراءات</th>
            </tr>
        </thead>
        <tbody class="divide-y divide-gray-100">
            @forelse($services as $service)
            <tr class="hover:bg-gray-50">
                <td class="px-6 py-4">
                    <div class="flex items-center gap-3">
                        @if($service->icon)
                            <span class="text-2xl">{{ $service->icon }}</span>
                        @elseif($service->image_path)
                            <img src="{{ asset('storage/' . $service->image_path) }}"
                                class="w-10 h-10 rounded-lg object-cover">
                        @else
                            <div class="w-10 h-10 rounded-lg bg-indigo-100 flex items-center justify-center">
                                <svg class="w-5 h-5 text-indigo-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 3H5a2 2 0 00-2 2v4m6-6h10a2 2 0 012 2v4M9 3v18m0 0h10a2 2 0 002-2V9M9 21H5a2 2 0 01-2-2V9m0 0h18"/>
                                </svg>
                            </div>
                        @endif
                        <div>
                            <div class="font-semibold text-gray-800">{{ $service->name }}</div>
                            @if($service->description)
                                <div class="text-gray-400 text-xs mt-0.5">{{ Str::limit($service->description, 50) }}</div>
                            @endif
                        </div>
                    </div>
                </td>
                <td class="px-6 py-4 text-gray-700 font-medium">
                    {{ number_format($service->default_price, 0) }} ج.م
                </td>
                <td class="px-6 py-4">
                    @if($service->show_price)
                        <span class="bg-green-100 text-green-700 px-2.5 py-1 rounded-full text-xs font-medium">يظهر</span>
                    @else
                        <span class="bg-gray-100 text-gray-500 px-2.5 py-1 rounded-full text-xs">مخفي</span>
                    @endif
                </td>
                <td class="px-6 py-4">
                    @if($service->is_public)
                        <span class="bg-indigo-100 text-indigo-700 px-2.5 py-1 rounded-full text-xs font-medium">ظاهر في التطبيق</span>
                    @else
                        <span class="bg-gray-100 text-gray-500 px-2.5 py-1 rounded-full text-xs">مخفي</span>
                    @endif
                </td>
                <td class="px-6 py-4">
                    @if($service->is_active)
                        <span class="bg-green-100 text-green-700 px-2.5 py-1 rounded-full text-xs font-medium">متاح</span>
                    @else
                        <span class="bg-red-100 text-red-700 px-2.5 py-1 rounded-full text-xs font-medium">معطّل</span>
                    @endif
                </td>
                <td class="px-6 py-4">
                    <div class="flex items-center gap-2">
                        <a href="{{ route('dashboard.services.edit', $service) }}"
                            class="text-indigo-600 hover:underline text-sm">تعديل</a>
                        <span class="text-gray-200">|</span>
                        <form method="POST" action="{{ route('dashboard.services.destroy', $service) }}"
                            onsubmit="return confirm('سيؤثر الحذف على العقود المرتبطة. متأكد؟')">
                            @csrf @method('DELETE')
                            <button type="submit" class="text-red-500 hover:underline text-sm">حذف</button>
                        </form>
                    </div>
                </td>
            </tr>
            @empty
            <tr>
                <td colspan="6" class="px-6 py-16 text-center text-gray-400">
                    <svg class="w-12 h-12 mx-auto mb-3 opacity-30" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M9 3H5a2 2 0 00-2 2v4m6-6h10a2 2 0 012 2v4M9 3v18m0 0h10a2 2 0 002-2V9M9 21H5a2 2 0 01-2-2V9m0 0h18"/>
                    </svg>
                    لا توجد خدمات
                </td>
            </tr>
            @endforelse
        </tbody>
    </table>
</div>

<div class="mt-4 bg-blue-50 border border-blue-200 rounded-lg px-4 py-3 text-sm text-blue-700">
    <strong>ملاحظة:</strong>
    الخدمات المُفعَّلة لـ"العقود" تظهر عند إنشاء عقد جديد.
    الخدمات المُفعَّلة لـ"التطبيق" تظهر لعملائك في صفحة الاستكشاف — السعر يظهر فقط إذا فعّلت "عرض السعر".
</div>
@endsection
