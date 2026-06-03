@extends('layouts.dashboard')
@section('title', $ticket->title)
@section('page-title', 'تذكرة #' . $ticket->id)

@section('content')
<div class="max-w-3xl mx-auto">
    <div class="flex gap-3 mb-6 flex-wrap">
        <a href="{{ route('dashboard.tickets.index') }}" class="border border-gray-300 text-gray-600 px-4 py-2 rounded-lg text-sm hover:bg-gray-50">← العودة</a>
        <form method="POST" action="{{ route('dashboard.tickets.status', $ticket) }}" class="flex gap-2">
            @csrf
            <select name="status" class="border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500">
                <option value="open" {{ $ticket->status === 'open' ? 'selected' : '' }}>مفتوحة</option>
                <option value="in_progress" {{ $ticket->status === 'in_progress' ? 'selected' : '' }}>قيد المعالجة</option>
                <option value="closed" {{ $ticket->status === 'closed' ? 'selected' : '' }}>مغلقة</option>
            </select>
            <button class="bg-gray-600 hover:bg-gray-700 text-white px-4 py-2 rounded-lg text-sm">تحديث الحالة</button>
        </form>
    </div>

    <div class="bg-white rounded-xl shadow-sm p-6 mb-6">
        <div class="flex justify-between items-start">
            <div>
                <h2 class="text-xl font-bold text-gray-800">{{ $ticket->title }}</h2>
                <div class="text-sm text-gray-400 mt-1">
                    العميل: <a href="{{ route('dashboard.clients.show', $ticket->client) }}" class="text-indigo-600 hover:underline">{{ $ticket->client->name }}</a>
                    · {{ $ticket->created_at->format('Y-m-d H:i') }}
                </div>
            </div>
        </div>
    </div>

    <!-- Messages -->
    <div class="space-y-4 mb-6">
        @foreach($ticket->messages as $msg)
        @php $isAdmin = $msg->sender_type === \App\Models\User::class; @endphp
        <div class="{{ $isAdmin ? 'flex flex-row-reverse' : '' }}">
            <div class="max-w-lg {{ $isAdmin ? 'bg-indigo-600 text-white' : 'bg-white border border-gray-200' }} rounded-2xl px-5 py-4 shadow-sm">
                <div class="text-xs opacity-70 mb-1">{{ $isAdmin ? 'Quadro Cloud' : $ticket->client->name }} · {{ $msg->created_at->format('H:i') }}</div>
                <div class="{{ $isAdmin ? '' : 'text-gray-800' }}">{{ $msg->message }}</div>
            </div>
        </div>
        @endforeach
    </div>

    <!-- Reply form -->
    @if($ticket->status !== 'closed')
    <div class="bg-white rounded-xl shadow-sm p-6">
        <form method="POST" action="{{ route('dashboard.tickets.reply', $ticket) }}">
            @csrf
            <textarea name="message" rows="4" placeholder="اكتب ردك هنا..." required
                class="w-full border border-gray-300 rounded-lg px-4 py-3 focus:outline-none focus:ring-2 focus:ring-indigo-500 mb-3"></textarea>
            <button type="submit" class="bg-indigo-600 hover:bg-indigo-700 text-white px-6 py-2.5 rounded-lg font-medium">إرسال الرد وإشعار العميل</button>
        </form>
    </div>
    @else
    <div class="bg-gray-50 border border-gray-200 rounded-xl p-4 text-center text-gray-400 text-sm">التذكرة مغلقة</div>
    @endif
</div>
@endsection
