@extends('layouts.dashboard')
@section('title', 'الأخبار والمقالات')
@section('page-title', 'الأخبار والمقالات')

@section('content')
<div class="flex justify-between items-center mb-6">
    <p class="text-gray-500 text-sm">{{ $posts->total() }} مقال</p>
    <a href="{{ route('dashboard.posts.create') }}"
        class="bg-indigo-600 hover:bg-indigo-700 text-white px-5 py-2.5 rounded-lg font-medium text-sm flex items-center gap-2">
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/></svg>
        إضافة مقال
    </a>
</div>

<div class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-6">
    @forelse($posts as $post)
    <div class="bg-white rounded-xl shadow-sm overflow-hidden flex flex-col">
        {{-- Media thumbnail --}}
        @if($post->media_path && $post->media_type === 'image')
            <div class="h-48 bg-gray-100 overflow-hidden">
                <img src="{{ asset('storage/' . $post->media_path) }}" alt="{{ $post->title }}"
                    class="w-full h-full object-cover">
            </div>
        @elseif($post->media_path && $post->media_type === 'video')
            <div class="h-48 bg-gray-900 flex items-center justify-center">
                <svg class="w-12 h-12 text-white opacity-70" fill="currentColor" viewBox="0 0 24 24">
                    <path d="M8 5v14l11-7z"/>
                </svg>
            </div>
        @else
            <div class="h-48 bg-gradient-to-br from-indigo-100 to-purple-100 flex items-center justify-center">
                <svg class="w-12 h-12 text-indigo-300" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M19 20H5a2 2 0 01-2-2V6a2 2 0 012-2h10a2 2 0 012 2v1m2 13a2 2 0 01-2-2V7m2 13a2 2 0 002-2V9a2 2 0 00-2-2h-2m-4-3H9M7 16h6M7 8h6v4H7V8z"/>
                </svg>
            </div>
        @endif

        <div class="p-5 flex flex-col flex-1">
            <div class="flex items-start justify-between gap-2 mb-2">
                <h3 class="font-bold text-gray-800 text-base leading-snug flex-1">{{ $post->title }}</h3>
                @if($post->is_published)
                    <span class="bg-green-100 text-green-700 text-xs px-2 py-0.5 rounded-full whitespace-nowrap font-medium">منشور</span>
                @else
                    <span class="bg-yellow-100 text-yellow-700 text-xs px-2 py-0.5 rounded-full whitespace-nowrap font-medium">مسودة</span>
                @endif
            </div>

            <p class="text-gray-500 text-sm leading-relaxed flex-1 mb-4">
                {{ Str::limit(strip_tags($post->content), 100) }}
            </p>

            <div class="flex items-center justify-between text-xs text-gray-400 border-t border-gray-100 pt-3">
                <span>{{ $post->creator?->name ?? 'غير معروف' }}</span>
                <span>{{ $post->created_at->format('Y-m-d') }}</span>
            </div>

            <div class="flex gap-2 mt-3">
                <a href="{{ route('dashboard.posts.edit', $post) }}"
                    class="flex-1 text-center border border-indigo-300 text-indigo-600 hover:bg-indigo-50 px-3 py-1.5 rounded-lg text-sm font-medium">
                    تعديل
                </a>
                <form method="POST" action="{{ route('dashboard.posts.destroy', $post) }}"
                    onsubmit="return confirm('هل أنت متأكد من الحذف؟')">
                    @csrf @method('DELETE')
                    <button type="submit"
                        class="border border-red-200 text-red-500 hover:bg-red-50 px-3 py-1.5 rounded-lg text-sm font-medium">
                        حذف
                    </button>
                </form>
            </div>
        </div>
    </div>
    @empty
    <div class="md:col-span-2 xl:col-span-3 bg-white rounded-xl shadow-sm p-16 text-center text-gray-400">
        <svg class="w-16 h-16 mx-auto mb-4 opacity-30" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M19 20H5a2 2 0 01-2-2V6a2 2 0 012-2h10a2 2 0 012 2v1m2 13a2 2 0 01-2-2V7m2 13a2 2 0 002-2V9a2 2 0 00-2-2h-2m-4-3H9M7 16h6M7 8h6v4H7V8z"/>
        </svg>
        <p>لا توجد مقالات بعد</p>
        <a href="{{ route('dashboard.posts.create') }}" class="mt-3 inline-block text-indigo-600 hover:underline text-sm">إضافة أول مقال</a>
    </div>
    @endforelse
</div>

<div class="mt-6">{{ $posts->links() }}</div>
@endsection
