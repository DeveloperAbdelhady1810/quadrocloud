<!DOCTYPE html>
<html dir="rtl" lang="ar">
<head><meta charset="UTF-8"><style>
body{font-family:Arial,sans-serif;background:#f4f4f4;margin:0;padding:20px}
.card{background:white;border-radius:12px;padding:32px;max-width:600px;margin:0 auto;box-shadow:0 2px 8px rgba(0,0,0,.08)}
.header{background:linear-gradient(135deg,#4F46E5,#6366F1);color:white;padding:24px;border-radius:8px;margin-bottom:24px;text-align:center}
.field{margin-bottom:16px;padding:12px;background:#f8f9fa;border-radius:8px;border-right:4px solid #4F46E5}
.label{font-size:12px;color:#6b7280;margin-bottom:4px}
.value{font-size:15px;color:#1a1a2e;font-weight:600}
</style></head>
<body>
<div class="card">
  <div class="header">
    <h2 style="margin:0">طلب خدمة جديد</h2>
    <p style="margin:8px 0 0">Quadro Cloud</p>
  </div>
  <div class="field"><div class="label">الخدمة المطلوبة</div><div class="value">{{ $serviceName }}</div></div>
  <div class="field"><div class="label">الاسم</div><div class="value">{{ $senderName }}</div></div>
  <div class="field"><div class="label">البريد الإلكتروني</div><div class="value">{{ $senderEmail }}</div></div>
  <div class="field"><div class="label">رقم الهاتف</div><div class="value">{{ $senderPhone }}</div></div>
  <div class="field"><div class="label">الرسالة</div><div class="value">{{ $clientMessage }}</div></div>
  <p style="text-align:center;color:#9ca3af;font-size:12px;margin-top:24px">Quadro Cloud — Client Portal</p>
</div>
</body></html>
