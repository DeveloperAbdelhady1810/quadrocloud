@extends('layouts.dashboard')
@section('title', 'إضافة مقال')
@section('page-title', 'إضافة مقال جديد')

@section('content')
<div class="max-w-3xl mx-auto">
    <div class="bg-white rounded-xl shadow-sm p-8">
        <form method="POST" action="{{ route('dashboard.posts.store') }}" enctype="multipart/form-data">
            @csrf

            <div class="space-y-6">
                {{-- Title --}}
                <div>
                    <label class="block text-sm font-semibold text-gray-700 mb-1.5">عنوان المقال *</label>
                    <input type="text" name="title" value="{{ old('title') }}" required placeholder="اكتب عنواناً جذاباً..."
                        class="w-full border border-gray-300 rounded-lg px-4 py-3 focus:outline-none focus:ring-2 focus:ring-indigo-500 text-gray-800 text-base">
                </div>

                {{-- Content --}}
                <div>
                    <label class="block text-sm font-semibold text-gray-700 mb-1.5">المحتوى *</label>
                    <textarea name="content" rows="10" required placeholder="اكتب محتوى المقال هنا..."
                        class="w-full border border-gray-300 rounded-lg px-4 py-3 focus:outline-none focus:ring-2 focus:ring-indigo-500 text-gray-800 leading-relaxed resize-y">{{ old('content') }}</textarea>
                </div>

                {{-- Media upload --}}
                <div>
                    <label class="block text-sm font-semibold text-gray-700 mb-1.5">صورة أو فيديو (اختياري)</label>
                    <div class="border-2 border-dashed border-gray-300 rounded-xl p-8 text-center hover:border-indigo-400 transition-colors cursor-pointer"
                        onclick="document.getElementById('mediaInput').click()">
                        <svg class="w-10 h-10 mx-auto text-gray-300 mb-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"/>
                        </svg>
                        <p class="text-sm text-gray-500">اضغط لاختيار صورة أو فيديو</p>
                        <p class="text-xs text-gray-400 mt-1">JPG، PNG، GIF، WebP، MP4، MOV — حد أقصى 50 ميجا</p>
                        <input type="file" id="mediaInput" name="media" accept="image/*,video/*" class="hidden"
                            onchange="previewMedia(this)">
                    </div>
                    {{-- Preview --}}
                    <div id="mediaPreview" class="mt-3 hidden">
                        <img id="imgPreview" class="w-full max-h-64 object-cover rounded-lg hidden">
                        <video id="vidPreview" class="w-full max-h-64 rounded-lg hidden" controls></video>
                        <p id="previewName" class="text-xs text-gray-500 mt-1"></p>
                    </div>
                </div>

                {{-- Published toggle --}}
                <div class="flex items-center justify-between p-4 bg-gray-50 rounded-xl">
                    <div>
                        <div class="font-medium text-gray-800 text-sm">نشر الآن</div>
                        <div class="text-xs text-gray-500 mt-0.5">إذا أوقفته، سيُحفظ كمسودة ولن يظهر في التطبيق</div>
                    </div>
                    <label class="relative inline-flex items-center cursor-pointer">
                        <input type="checkbox" name="is_published" value="1" class="sr-only peer" {{ old('is_published') ? 'checked' : 'checked' }}>
                        <div class="w-11 h-6 bg-gray-200 peer-focus:outline-none rounded-full peer peer-checked:bg-indigo-600 after:content-[''] after:absolute after:top-0.5 after:start-[2px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:after:translate-x-full rtl:peer-checked:after:-translate-x-full"></div>
                    </label>
                </div>
            </div>

            <div class="flex gap-3 mt-8 pt-6 border-t border-gray-100">
                <button type="submit" class="bg-indigo-600 hover:bg-indigo-700 text-white px-8 py-2.5 rounded-lg font-medium">
                    نشر المقال
                </button>
                <a href="{{ route('dashboard.posts.index') }}"
                    class="border border-gray-300 text-gray-600 px-6 py-2.5 rounded-lg hover:bg-gray-50 font-medium">
                    إلغاء
                </a>
            </div>
        </form>
    </div>
</div>

@push('scripts')
<script>
function previewMedia(input) {
    if (!input.files || !input.files[0]) return;
    const file = input.files[0];
    const preview = document.getElementById('mediaPreview');
    const img = document.getElementById('imgPreview');
    const vid = document.getElementById('vidPreview');
    const name = document.getElementById('previewName');
    preview.classList.remove('hidden');
    img.classList.add('hidden');
    vid.classList.add('hidden');
    name.textContent = file.name;
    const url = URL.createObjectURL(file);
    if (file.type.startsWith('video/')) {
        vid.src = url;
        vid.classList.remove('hidden');
    } else {
        img.src = url;
        img.classList.remove('hidden');
    }
}
</script>
@endpush
@endsection
