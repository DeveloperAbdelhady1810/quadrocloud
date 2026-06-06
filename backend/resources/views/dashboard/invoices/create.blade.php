@extends('layouts.dashboard')
@section('title', 'إنشاء فاتورة يدوية')
@section('page-title', 'إنشاء فاتورة يدوية')

@section('content')
<div class="max-w-xl mx-auto">
  <div class="bg-white rounded-xl shadow-sm p-8">
    <p class="text-sm text-gray-500 mb-6">سيتم إرسال الفاتورة تلقائياً للعميل عبر البريد الإلكتروني بعد الإنشاء.</p>

    <form method="POST" action="{{ route('dashboard.invoices.store') }}" class="space-y-5">
      @csrf

      <div>
        <label class="block text-sm font-medium text-gray-700 mb-1">العميل</label>
        <select name="client_id" required
          class="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:ring-indigo-500 focus:border-indigo-500">
          <option value="">-- اختر عميل --</option>
          @foreach($clients as $c)
            <option value="{{ $c->id }}" {{ ($selected?->id == $c->id || old('client_id') == $c->id) ? 'selected' : '' }}>
              {{ $c->name }} ({{ $c->company_name ?? $c->email }})
            </option>
          @endforeach
        </select>
      </div>

      <div>
        <label class="block text-sm font-medium text-gray-700 mb-1">وصف الخدمة</label>
        <input type="text" name="description" value="{{ old('description') }}" required
          placeholder="مثال: استضافة شهر يناير 2026"
          class="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:ring-indigo-500 focus:border-indigo-500">
      </div>

      <div>
        <label class="block text-sm font-medium text-gray-700 mb-1">المبلغ (ج.م)</label>
        <input type="number" name="amount" value="{{ old('amount') }}" required min="1" step="0.01"
          placeholder="0.00"
          class="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:ring-indigo-500 focus:border-indigo-500">
      </div>

      <div>
        <label class="block text-sm font-medium text-gray-700 mb-1">تاريخ الاستحقاق</label>
        <input type="date" name="due_date" value="{{ old('due_date', now()->addDays(7)->format('Y-m-d')) }}" required
          min="{{ now()->format('Y-m-d') }}"
          class="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:ring-indigo-500 focus:border-indigo-500">
      </div>

      <div class="flex gap-3 pt-2">
        <button type="submit"
          class="flex-1 bg-indigo-600 hover:bg-indigo-700 text-white font-medium py-2.5 rounded-lg text-sm">
          إنشاء الفاتورة وإرسالها
        </button>
        <a href="{{ url()->previous() }}"
          class="px-5 py-2.5 border border-gray-300 text-gray-600 rounded-lg text-sm hover:bg-gray-50">
          إلغاء
        </a>
      </div>
    </form>
  </div>
</div>
@endsection
