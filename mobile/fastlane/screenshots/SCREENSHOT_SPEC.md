# App Store Screenshot Specifications

## Required Sizes

| Device                | Resolution      | Folder name              | Required |
|-----------------------|-----------------|--------------------------|----------|
| iPhone 6.9" (16 Pro Max) | 1320 × 2868 px | `iPhone69`           | YES      |
| iPhone 6.7" (14/15 Pro Max) | 1290 × 2796 px | `iPhone67`        | YES      |
| iPhone 5.5" (8 Plus)  | 1242 × 2208 px  | `iPhone55`               | Optional |
| iPad Pro 13" (M4)     | 2064 × 2752 px  | `iPadPro129`             | Optional |

Apple requires at least the 6.7" set. The 6.9" set is strongly recommended as it becomes the primary display on the App Store listing.

---

## Planned Screenshots (6 total per locale)

### Screenshot 1 — Dashboard / Home
**Screen:** Home tab  
**State to show:** Next payment card (indigo gradient, 12 days left), overdue banner (if possible), quick action grid  
**Caption (EN):** "Your payments, at a glance"  
**Caption (AR):** "مدفوعاتك دائماً في متناول يدك"

### Screenshot 2 — Invoices
**Screen:** Invoices tab  
**State to show:** List of invoices — mix of Paid (green), Unpaid (orange), including one invoice detail open  
**Caption (EN):** "View & pay invoices instantly"  
**Caption (AR):** "استعرض فواتيرك وادفعها فوراً"

### Screenshot 3 — Contracts
**Screen:** Contracts tab  
**State to show:** List of active contracts, renewal alert banner visible at top  
**Caption (EN):** "Track every contract & renewal"  
**Caption (AR):** "تابع عقودك وتجديداتها"

### Screenshot 4 — Payment History
**Screen:** Payments tab  
**State to show:** Scrollable list of past payments, each showing amount, date, invoice number  
**Caption (EN):** "Full payment history, always accessible"  
**Caption (AR):** "سجل مدفوعاتك كاملاً في أي وقت"

### Screenshot 5 — Support Tickets
**Screen:** Tickets tab  
**State to show:** List of open & resolved tickets, one ticket detail open showing conversation  
**Caption (EN):** "Get support without the wait"  
**Caption (AR):** "تواصل مع الدعم الفني بسهولة"

### Screenshot 6 — Explore / Services
**Screen:** Explore tab → Services sub-tab  
**State to show:** Grid of available services with icons and pricing  
**Caption (EN):** "Discover our full range of services"  
**Caption (AR):** "استكشف جميع خدماتنا"

---

## How to Capture

### Option A — Manual (recommended for v1.0)
1. Run the app on an iPhone 15 Pro Max simulator (6.7")
2. Navigate to each screen in the state described above
3. Press `Cmd+S` in Simulator or use `xcrun simctl io booted screenshot <file>.png`
4. Place each file in `fastlane/screenshots/en-US/` (or `ar-SA/`)
5. Name them: `01_dashboard.png`, `02_invoices.png`, etc.

### Option B — Fastlane Snapshot (automated)
See `Snapfile` in this directory for the automated capture configuration.
Run: `cd ios && bundle exec fastlane snapshot`

---

## Naming Convention
```
fastlane/screenshots/
  en-US/
    iPhone67/
      01_dashboard.png
      02_invoices.png
      03_contracts.png
      04_payments.png
      05_tickets.png
      06_explore.png
    iPhone69/
      (same files)
  ar-SA/
    iPhone67/
      01_dashboard.png
      ...
```

## Tips
- Use Light Mode for screenshots unless you want to also submit a Dark Mode set
- Populate the app with realistic-looking dummy data before capturing
- Remove any debug banners: set `debugShowCheckedModeBanner: false` in `MaterialApp` (already should be false in production builds)
