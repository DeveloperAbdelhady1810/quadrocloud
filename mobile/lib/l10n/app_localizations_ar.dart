// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'Quadro Cloud';

  @override
  String get login => 'تسجيل الدخول';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get password => 'كلمة المرور';

  @override
  String get loginButton => 'دخول';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get home => 'الرئيسية';

  @override
  String get contracts => 'العقود';

  @override
  String get payments => 'المدفوعات';

  @override
  String get invoices => 'الفواتير';

  @override
  String get support => 'الدعم';

  @override
  String get settings => 'الإعدادات';

  @override
  String get nextPayment => 'الدفعة القادمة';

  @override
  String daysLeft(int days) {
    return '$days يوم متبقي';
  }

  @override
  String get dueToday => 'مستحقة اليوم!';

  @override
  String get overdue => 'متأخرة';

  @override
  String overdueWarning(int count) {
    return 'لديك $count فاتورة متأخرة';
  }

  @override
  String get payNow => 'ادفع الآن';

  @override
  String get paid => 'مدفوعة';

  @override
  String get unpaid => 'غير مدفوعة';

  @override
  String get cancelled => 'ملغية';

  @override
  String get active => 'نشط';

  @override
  String get paused => 'موقوف';

  @override
  String get monthly => 'شهري';

  @override
  String get quarterly => 'ربع سنوي';

  @override
  String get annually => 'سنوي';

  @override
  String get amount => 'المبلغ';

  @override
  String get dueDate => 'تاريخ الاستحقاق';

  @override
  String get paidAt => 'تاريخ الدفع';

  @override
  String get invoiceNumber => 'رقم الفاتورة';

  @override
  String get newTicket => 'تذكرة جديدة';

  @override
  String get ticketTitle => 'عنوان التذكرة';

  @override
  String get message => 'الرسالة';

  @override
  String get send => 'إرسال';

  @override
  String get open => 'مفتوحة';

  @override
  String get inProgress => 'قيد المعالجة';

  @override
  String get closed => 'مغلقة';

  @override
  String get changeLanguage => 'تغيير اللغة';

  @override
  String get changePassword => 'تغيير كلمة المرور';

  @override
  String get currentPassword => 'كلمة المرور الحالية';

  @override
  String get newPassword => 'كلمة المرور الجديدة';

  @override
  String get confirmPassword => 'تأكيد كلمة المرور';

  @override
  String get save => 'حفظ';

  @override
  String get cancel => 'إلغاء';

  @override
  String get error => 'حدث خطأ';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get noData => 'لا توجد بيانات';

  @override
  String get loading => 'جاري التحميل...';

  @override
  String get additionalFee => 'رسوم إضافية';

  @override
  String get pendingFees => 'رسوم معلقة';

  @override
  String get paymentHistory => 'سجل المدفوعات';

  @override
  String get onlinePay => 'دفع أونلاين';

  @override
  String get cashPay => 'دفع نقدي';

  @override
  String get downloadInvoice => 'تحميل الفاتورة';

  @override
  String get reply => 'رد';

  @override
  String get ticketClosed => 'التذكرة مغلقة';

  @override
  String get noContracts => 'لا توجد عقود نشطة';

  @override
  String get noPayments => 'لا توجد مدفوعات';

  @override
  String get noInvoices => 'لا توجد فواتير';

  @override
  String get noTickets => 'لا توجد تذاكر دعم';

  @override
  String get noPendingFees => 'لا توجد رسوم معلقة';
}
