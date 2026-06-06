<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
<meta charset="UTF-8">
<style>
  body { font-family: Arial, sans-serif; background: #f4f4f8; margin: 0; padding: 30px; }
  .card { background: white; max-width: 480px; margin: 0 auto; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 24px rgba(0,0,0,0.08); }
  .header { background: linear-gradient(135deg, #4f46e5, #6366f1); padding: 32px; text-align: center; }
  .header h1 { color: white; font-size: 24px; margin: 0; }
  .header p { color: rgba(255,255,255,0.8); margin: 6px 0 0; font-size: 13px; }
  .body { padding: 32px; text-align: center; }
  .otp { font-size: 48px; font-weight: bold; letter-spacing: 12px; color: #4f46e5; background: #f0efff; border-radius: 12px; padding: 20px 30px; display: inline-block; margin: 20px 0; }
  .note { color: #888; font-size: 12px; margin-top: 16px; }
  .footer { text-align: center; color: #aaa; font-size: 11px; padding: 16px; border-top: 1px solid #f0f0f0; }
</style>
</head>
<body>
<div class="card">
  <div class="header">
    <h1>Quadro Cloud</h1>
    <p>كود الدخول السريع</p>
  </div>
  <div class="body">
    <p style="color:#333; font-size:15px;">مرحباً <strong>{{ $client->name }}</strong>،</p>
    <p style="color:#555; font-size:14px;">استخدم الكود التالي لتسجيل الدخول في تطبيق Quadro Cloud:</p>
    <div class="otp">{{ $otp }}</div>
    <p class="note">⏱ هذا الكود صالح لمدة <strong>15 دقيقة</strong> فقط</p>
    <p class="note">إذا لم تطلب هذا الكود، يمكنك تجاهل هذا البريد</p>
  </div>
  <div class="footer">Quadro Cloud · noreply@quadrocloud.net</div>
</div>
</body>
</html>
