// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Quadro Cloud';

  @override
  String get login => 'Login';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get loginButton => 'Sign In';

  @override
  String get logout => 'Logout';

  @override
  String get home => 'Home';

  @override
  String get contracts => 'Contracts';

  @override
  String get payments => 'Payments';

  @override
  String get invoices => 'Invoices';

  @override
  String get support => 'Support';

  @override
  String get settings => 'Settings';

  @override
  String get nextPayment => 'Next Payment';

  @override
  String daysLeft(int days) {
    return '$days days left';
  }

  @override
  String get dueToday => 'Due Today!';

  @override
  String get overdue => 'Overdue';

  @override
  String overdueWarning(int count) {
    return 'You have $count overdue invoice(s)';
  }

  @override
  String get payNow => 'Pay Now';

  @override
  String get paid => 'Paid';

  @override
  String get unpaid => 'Unpaid';

  @override
  String get cancelled => 'Cancelled';

  @override
  String get active => 'Active';

  @override
  String get paused => 'Paused';

  @override
  String get monthly => 'Monthly';

  @override
  String get quarterly => 'Quarterly';

  @override
  String get annually => 'Annually';

  @override
  String get amount => 'Amount';

  @override
  String get dueDate => 'Due Date';

  @override
  String get paidAt => 'Paid At';

  @override
  String get invoiceNumber => 'Invoice #';

  @override
  String get newTicket => 'New Ticket';

  @override
  String get ticketTitle => 'Ticket Title';

  @override
  String get message => 'Message';

  @override
  String get send => 'Send';

  @override
  String get open => 'Open';

  @override
  String get inProgress => 'In Progress';

  @override
  String get closed => 'Closed';

  @override
  String get changeLanguage => 'Change Language';

  @override
  String get changePassword => 'Change Password';

  @override
  String get currentPassword => 'Current Password';

  @override
  String get newPassword => 'New Password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get error => 'An error occurred';

  @override
  String get retry => 'Retry';

  @override
  String get noData => 'No data found';

  @override
  String get loading => 'Loading...';

  @override
  String get additionalFee => 'Additional Fee';

  @override
  String get pendingFees => 'Pending Fees';

  @override
  String get paymentHistory => 'Payment History';

  @override
  String get onlinePay => 'Pay Online';

  @override
  String get cashPay => 'Cash Payment';

  @override
  String get downloadInvoice => 'Download Invoice';

  @override
  String get reply => 'Reply';

  @override
  String get ticketClosed => 'Ticket is closed';

  @override
  String get noContracts => 'No active contracts';

  @override
  String get noPayments => 'No payments yet';

  @override
  String get noInvoices => 'No invoices';

  @override
  String get noTickets => 'No support tickets';

  @override
  String get noPendingFees => 'No pending fees';
}
