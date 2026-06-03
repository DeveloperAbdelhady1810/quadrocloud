<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
<meta charset="UTF-8">
<style>
    body { font-family: DejaVu Sans, sans-serif; direction: rtl; color: #1a1a2e; font-size: 13px; margin: 0; padding: 30px; }
    .header { display: flex; justify-content: space-between; align-items: center; border-bottom: 3px solid #4f46e5; padding-bottom: 20px; margin-bottom: 30px; }
    .company-name { font-size: 26px; font-weight: bold; color: #4f46e5; }
    .company-sub { color: #666; font-size: 12px; }
    .invoice-title { font-size: 22px; font-weight: bold; color: #1a1a2e; }
    .invoice-meta { color: #555; font-size: 12px; margin-top: 4px; }
    .section { margin-bottom: 25px; }
    .section-title { font-size: 14px; font-weight: bold; color: #4f46e5; border-bottom: 1px solid #e0e0e0; padding-bottom: 5px; margin-bottom: 12px; }
    .grid { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; }
    .info-row { margin-bottom: 6px; }
    .label { color: #888; font-size: 11px; }
    .value { font-weight: bold; }
    table { width: 100%; border-collapse: collapse; margin-bottom: 20px; }
    th { background: #4f46e5; color: white; padding: 10px; text-align: right; font-size: 12px; }
    td { padding: 10px; border-bottom: 1px solid #f0f0f0; font-size: 12px; }
    tr:nth-child(even) td { background: #f8f8ff; }
    .total-row td { font-weight: bold; font-size: 14px; background: #f0efff; }
    .status-paid { color: #16a34a; font-weight: bold; }
    .status-unpaid { color: #dc2626; font-weight: bold; }
    .status-overdue { color: #b45309; font-weight: bold; }
    .footer { text-align: center; color: #aaa; font-size: 10px; border-top: 1px solid #e0e0e0; padding-top: 15px; margin-top: 30px; }
</style>
</head>
<body>

<div class="header">
    <div>
        <div class="company-name">Quadro Cloud</div>
        <div class="company-sub">كوادرو كلاود - خدمات البرمجيات</div>
    </div>
    <div style="text-align:left">
        <div class="invoice-title">فاتورة</div>
        <div class="invoice-meta"># {{ $invoice->invoice_number }}</div>
        <div class="invoice-meta">{{ now()->format('Y-m-d') }}</div>
    </div>
</div>

<div class="grid section">
    <div>
        <div class="section-title">بيانات العميل</div>
        <div class="info-row"><span class="label">الاسم: </span><span class="value">{{ $invoice->client->name }}</span></div>
        <div class="info-row"><span class="label">الشركة: </span><span class="value">{{ $invoice->client->company_name ?? '-' }}</span></div>
        <div class="info-row"><span class="label">البريد: </span><span class="value">{{ $invoice->client->email }}</span></div>
        <div class="info-row"><span class="label">الهاتف: </span><span class="value">{{ $invoice->client->phone ?? '-' }}</span></div>
    </div>
    <div>
        <div class="section-title">تفاصيل الفاتورة</div>
        <div class="info-row"><span class="label">رقم الفاتورة: </span><span class="value">{{ $invoice->invoice_number }}</span></div>
        <div class="info-row"><span class="label">تاريخ الاستحقاق: </span><span class="value">{{ $invoice->due_date?->format('Y-m-d') }}</span></div>
        <div class="info-row"><span class="label">الحالة: </span>
            <span class="status-{{ $invoice->status }}">
                @if($invoice->status === 'paid') مدفوعة
                @elseif($invoice->status === 'unpaid') غير مدفوعة
                @elseif($invoice->status === 'overdue') متأخرة
                @else ملغية @endif
            </span>
        </div>
        @if($invoice->paid_at)
        <div class="info-row"><span class="label">تاريخ الدفع: </span><span class="value">{{ $invoice->paid_at->format('Y-m-d') }}</span></div>
        @endif
    </div>
</div>

<div class="section">
    <div class="section-title">بنود الفاتورة</div>
    <table>
        <thead>
            <tr>
                <th>الوصف</th>
                <th style="width:120px">المبلغ</th>
            </tr>
        </thead>
        <tbody>
            <tr>
                <td>
                    @if($invoice->contract)
                        {{ $invoice->contract->display_name }}
                        ({{ match($invoice->contract->billing_cycle) { 'monthly' => 'شهري', 'quarterly' => 'ربع سنوي', 'annually' => 'سنوي' } }})
                    @elseif($invoice->additionalFee)
                        {{ $invoice->additionalFee->title }}
                        @if($invoice->additionalFee->description)
                            <br><small>{{ $invoice->additionalFee->description }}</small>
                        @endif
                    @else
                        خدمة Quadro Cloud
                    @endif
                </td>
                <td>{{ number_format($invoice->amount, 2) }} ج.م</td>
            </tr>
            <tr class="total-row">
                <td>الإجمالي</td>
                <td>{{ number_format($invoice->amount, 2) }} ج.م</td>
            </tr>
        </tbody>
    </table>
</div>

<div class="footer">
    Quadro Cloud | noreply@quadrocloud.com | هذه الفاتورة صادرة إلكترونياً وصالحة بدون توقيع
</div>

</body>
</html>
