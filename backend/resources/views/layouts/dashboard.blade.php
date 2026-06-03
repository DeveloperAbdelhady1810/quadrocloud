<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>@yield('title', 'لوحة التحكم') - Quadro Cloud</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link href="https://fonts.googleapis.com/css2?family=Cairo:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
    @vite(['resources/css/app.css', 'resources/js/app.js'])
    <style>
        body { font-family: 'Cairo', sans-serif; }
        .sidebar { width: 260px; min-height: 100vh; }
        .main-content { margin-right: 260px; }
        @media(max-width:768px) { .sidebar { position: fixed; z-index: 50; transform: translateX(100%); transition: .3s; } .sidebar.open { transform: translateX(0); } .main-content { margin-right: 0; } }
    </style>
</head>
<body class="bg-gray-50">

<div class="flex min-h-screen">
    <!-- Sidebar -->
    <aside class="sidebar bg-indigo-900 text-white fixed top-0 right-0 flex flex-col shadow-xl" id="sidebar">
        <!-- Logo -->
        <div class="p-6 border-b border-indigo-700">
            <div class="text-2xl font-bold text-white">Quadro Cloud</div>
            <div class="text-indigo-300 text-sm">لوحة إدارة العملاء</div>
        </div>

        <!-- Nav -->
        <nav class="flex-1 p-4 space-y-1">
            <a href="{{ route('dashboard.home') }}" class="flex items-center gap-3 px-4 py-3 rounded-lg hover:bg-indigo-800 {{ request()->routeIs('dashboard.home') ? 'bg-indigo-700' : '' }}">
                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6"/></svg>
                الرئيسية
            </a>
            <a href="{{ route('dashboard.clients.index') }}" class="flex items-center gap-3 px-4 py-3 rounded-lg hover:bg-indigo-800 {{ request()->routeIs('dashboard.clients.*') ? 'bg-indigo-700' : '' }}">
                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0z"/></svg>
                العملاء
            </a>
            <a href="{{ route('dashboard.payments.index') }}" class="flex items-center gap-3 px-4 py-3 rounded-lg hover:bg-indigo-800 {{ request()->routeIs('dashboard.payments.*') ? 'bg-indigo-700' : '' }}">
                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 9V7a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2m2 4h10a2 2 0 002-2v-6a2 2 0 00-2-2H9a2 2 0 00-2 2v6a2 2 0 002 2zm7-5a2 2 0 11-4 0 2 2 0 014 0z"/></svg>
                المدفوعات
            </a>
            <a href="{{ route('dashboard.tickets.index') }}" class="flex items-center gap-3 px-4 py-3 rounded-lg hover:bg-indigo-800 {{ request()->routeIs('dashboard.tickets.*') ? 'bg-indigo-700' : '' }}">
                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M18.364 5.636l-3.536 3.536m0 5.656l3.536 3.536M9.172 9.172L5.636 5.636m3.536 9.192l-3.536 3.536M21 12a9 9 0 11-18 0 9 9 0 0118 0zm-5 0a4 4 0 11-8 0 4 4 0 018 0z"/></svg>
                تذاكر الدعم
                @php $openTickets = \App\Models\SupportTicket::where('status','open')->count() @endphp
                @if($openTickets > 0)
                    <span class="mr-auto bg-red-500 text-white text-xs rounded-full px-2 py-0.5">{{ $openTickets }}</span>
                @endif
            </a>
            <a href="{{ route('dashboard.reports.index') }}" class="flex items-center gap-3 px-4 py-3 rounded-lg hover:bg-indigo-800 {{ request()->routeIs('dashboard.reports.*') ? 'bg-indigo-700' : '' }}">
                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"/></svg>
                التقارير
            </a>
            <a href="{{ route('dashboard.posts.index') }}" class="flex items-center gap-3 px-4 py-3 rounded-lg hover:bg-indigo-800 {{ request()->routeIs('dashboard.posts.*') ? 'bg-indigo-700' : '' }}">
                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 20H5a2 2 0 01-2-2V6a2 2 0 012-2h10a2 2 0 012 2v1m2 13a2 2 0 01-2-2V7m2 13a2 2 0 002-2V9a2 2 0 00-2-2h-2m-4-3H9M7 16h6M7 8h6v4H7V8z"/></svg>
                الأخبار
            </a>
            <a href="{{ route('dashboard.services.index') }}" class="flex items-center gap-3 px-4 py-3 rounded-lg hover:bg-indigo-800 {{ request()->routeIs('dashboard.services.*') ? 'bg-indigo-700' : '' }}">
                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 3H5a2 2 0 00-2 2v4m6-6h10a2 2 0 012 2v4M9 3v18m0 0h10a2 2 0 002-2V9M9 21H5a2 2 0 01-2-2V9m0 0h18"/></svg>
                الخدمات
            </a>
            @can('manage_team')
            <a href="{{ route('dashboard.team.index') }}" class="flex items-center gap-3 px-4 py-3 rounded-lg hover:bg-indigo-800 {{ request()->routeIs('dashboard.team.*') ? 'bg-indigo-700' : '' }}">
                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z"/></svg>
                الفريق
            </a>
            @endcan
        </nav>

        <!-- User -->
        <div class="p-4 border-t border-indigo-700">
            <div class="flex items-center gap-3 mb-3">
                <div class="w-9 h-9 rounded-full bg-indigo-600 flex items-center justify-center font-bold text-sm">
                    {{ substr(auth()->user()->name, 0, 1) }}
                </div>
                <div>
                    <div class="text-sm font-medium">{{ auth()->user()->name }}</div>
                    <div class="text-xs text-indigo-300">{{ auth()->user()->getRoleNames()->first() }}</div>
                </div>
            </div>
            <form method="POST" action="{{ route('dashboard.logout') }}">
                @csrf
                <button class="w-full text-sm text-indigo-300 hover:text-white text-right">تسجيل الخروج ←</button>
            </form>
        </div>
    </aside>

    <!-- Main content -->
    <main class="main-content flex-1">
        <!-- Top bar -->
        <header class="bg-white shadow-sm px-6 py-4 flex items-center justify-between sticky top-0 z-40">
            <button onclick="document.getElementById('sidebar').classList.toggle('open')" class="md:hidden p-2">
                <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16"/></svg>
            </button>
            <h1 class="text-xl font-bold text-gray-800">@yield('page-title', 'الرئيسية')</h1>
            <div class="text-sm text-gray-500">{{ now()->format('Y-m-d') }}</div>
        </header>

        <div class="p-6">
            @if(session('success'))
                <div class="mb-4 bg-green-50 border border-green-200 text-green-800 px-4 py-3 rounded-lg">{{ session('success') }}</div>
            @endif
            @if(session('error'))
                <div class="mb-4 bg-red-50 border border-red-200 text-red-800 px-4 py-3 rounded-lg">{{ session('error') }}</div>
            @endif
            @if($errors->any())
                <div class="mb-4 bg-red-50 border border-red-200 text-red-800 px-4 py-3 rounded-lg">
                    <ul class="list-disc list-inside text-sm">@foreach($errors->all() as $e)<li>{{ $e }}</li>@endforeach</ul>
                </div>
            @endif

            @yield('content')
        </div>
    </main>
</div>

<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
@stack('scripts')
</body>
</html>
