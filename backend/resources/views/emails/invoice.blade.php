<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { font-family: Arial, sans-serif; background: #f0f0f8; color: #1a1a2e; direction: rtl; }
    .wrapper { max-width: 600px; margin: 0 auto; padding: 24px 16px; }
    .card { background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 24px rgba(79,70,229,0.08); }
    .header { background: linear-gradient(135deg, #4338ca 0%, #4f46e5 50%, #6366f1 100%); padding: 32px 28px; }
    .header-brand { color: rgba(255,255,255,0.9); font-size: 13px; margin-bottom: 6px; letter-spacing: 1px; text-transform: uppercase; }
    .header-title { color: #ffffff; font-size: 26px; font-weight: bold; }
    .header-sub { color: rgba(255,255,255,0.7); font-size: 13px; margin-top: 4px; }
    .body { padding: 28px; }
    .greeting { font-size: 17px; font-weight: bold; color: #1a1a2e; margin-bottom: 8px; }
    .intro { color: #64748b; font-size: 14px; line-height: 1.7; margin-bottom: 24px; }
    .invoice-box { background: #f8f8ff; border: 1px solid #e0e0f0; border-radius: 12px; padding: 20px; margin-bottom: 24px; }
    .invoice-row { display: flex; justify-content: space-between; align-items: center; padding: 8px 0; border-bottom: 1px solid #eeeef8; }
    .invoice-row:last-child { border-bottom: none; }
    .row-label { color: #64748b; font-size: 13px; }
    .row-value { font-weight: bold; color: #1a1a2e; font-size: 13px; }
    .amount-value { font-size: 20px; font-weight: bold; color: #4f46e5; }
    .status-paid { color: #16a34a; background: #f0fdf4; padding: 3px 10px; border-radius: 20px; font-size: 12px; }
    .status-unpaid { color: #d97706; background: #fffbeb; padding: 3px 10px; border-radius: 20px; font-size: 12px; }
    .status-overdue { color: #dc2626; background: #fef2f2; padding: 3px 10px; border-radius: 20px; font-size: 12px; }
    .cta-section { text-align: center; margin-bottom: 24px; }
    .cta-text { color: #64748b; font-size: 13px; margin-bottom: 14px; }
    .cta-btn { display: inline-block; background: linear-gradient(135deg, #4338ca, #6366f1); color: #ffffff !important; text-decoration: none; padding: 13px 32px; border-radius: 12px; font-size: 15px; font-weight: bold; }
    .pdf-note { background: #f0f0ff; border-right: 4px solid #4f46e5; padding: 12px 16px; border-radius: 0 8px 8px 0; margin-bottom: 24px; color: #4f46e5; font-size: 13px; }
    .footer { padding: 20px 28px; background: #fafafa; border-top: 1px solid #f0f0f8; text-align: center; }
    .footer-text { color: #94a3b8; font-size: 12px; line-height: 1.8; }
    .footer-brand { color: #4f46e5; font-weight: bold; }
</style>
</head>
<body>
<div class="wrapper">
    <div class="card">

        <div class="header">
            <div class="header-brand">Quadro Cloud</div>
            <div class="header-title">فاتورتك الجديدة</div>
            <div class="header-sub">{{ $invoice->invoice_number }}</div>
        </div>

        <div class="body">
            <p class="greeting">مرحباً {{ $invoice->client->name }}،</p>
            <p class="intro">
                يسعدنا إرسال فاتورتك الخاصة بالخدمات المقدمة من Quadro Cloud.
                تجد أدناه تفاصيل الفاتورة، كما يمكنك الاطلاع على النسخة الكاملة بصيغة PDF المرفقة.
            </p>

            <div class="invoice-box">
                <div class="invoice-row">
                    <span class="row-label">رقم الفاتورة</span>
                    <span class="row-value">{{ $invoice->invoice_number }}</span>
                </div>
                <div class="invoice-row">
                    <span class="row-label">الخدمة</span>
                    <span class="row-value">
                        @if($invoice->contract)
                            {{ $invoice->contract->display_name }}
                        @elseif($invoice->additionalFee)
                            {{ $invoice->additionalFee->title }}
                        @else
                            خدمة Quadro Cloud
                        @endif
                    </span>
                </div>
                <div class="invoice-row">
                    <span class="row-label">تاريخ الاستحقاق</span>
                    <span class="row-value">{{ $invoice->due_date?->format('Y-m-d') ?? '-' }}</span>
                </div>
                <div class="invoice-row">
                    <span class="row-label">الحالة</span>
                    <span>
                        @if($invoice->status === 'paid')
                            <span class="status-paid">مدفوعة</span>
                        @elseif($invoice->status === 'overdue')
                            <span class="status-overdue">متأخرة</span>
                        @else
                            <span class="status-unpaid">غير مدفوعة</span>
                        @endif
                    </span>
                </div>
                <div class="invoice-row">
                    <span class="row-label">المبلغ الإجمالي</span>
                    <span class="amount-value">{{ number_format($invoice->amount, 2) }} ج.م</span>
                </div>
            </div>

            <div class="pdf-note">
                📎 الفاتورة مرفقة بهذا البريد كملف PDF — يمكنك حفظها أو طباعتها في أي وقت.
            </div>

            @if($invoice->status !== 'paid')
            <div class="cta-section">
                <p class="cta-text">يمكنك الدفع الإلكتروني مباشرة من خلال تطبيق Quadro Cloud</p>
                <a href="https://quadrocloud.net" class="cta-btn">فتح التطبيق للدفع</a>
            </div>
            @endif
        </div>

        <div class="footer">
            <p class="footer-text">
                هذا البريد أُرسل تلقائياً من منصة <span class="footer-brand">Quadro Cloud</span>
                <br>للاستفسارات تواصل معنا عبر تطبيق الدعم الفني
                <br>© {{ date('Y') }} Quadro Cloud — جميع الحقوق محفوظة
            </p>
        </div>

    </div>
</div>
</body>
</html>
