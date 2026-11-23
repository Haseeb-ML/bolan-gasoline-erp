# Bolan Gasoline ERP — Complete Project Documentation & Summary

**Last Updated:** 2026-11-23  
**Project Path:** `C:\Users\Haseeb\.gemini\antigravity\scratch\bolan_gasoline_erp`  
**GitHub Repository:** [https://github.com/Haseeb-ML/bolan-gasoline-erp.git](https://github.com/Haseeb-ML/bolan-gasoline-erp.git)  
**Live Web Deployment:** [https://bolan-gasoline-erp.web.app](https://bolan-gasoline-erp.web.app)  
**Android Release APK:** `C:\Users\Haseeb\Desktop\testing app\Bolan_Gasoline_ERP.apk`

---

## 1. Project Overview
**Bolan Gasoline ERP** is a cross-platform (Android Mobile, Web, Desktop) fuel station management software built with Flutter & Dart, featuring native Android Kotlin capabilities for sharing and printing receipts/reports.

---

## 2. Key Modules & Features

### 1. Dashboard
- 4 Key KPIs: Today's Total Sales, Tank Stock Value, Outstanding Purchaser Credit, Net Balance.
- Real-time Petrol & Diesel tank levels (Remaining Liters, Total Capacity, and Stock Value in PKR).
- **Pump Cash & Bank Funds Section:**
  - **Cash in Hand (Counter / Drawer):** Shows exact cash available in drawer from walk-in sales & cash recoveries.
  - **Bank Account Balance (Online):** Shows exact bank account balance from online transfers, cheques & bank receipts.
  - **Total Available Liquid Funds:** Aggregate total of Cash + Bank.
  - **Instant Cash <-> Bank Transfer:** Quick deposit / withdrawal modal with date entry directly accessible from Dashboard.
  - One-tap navigation from Cash/Bank cards straight to the detailed Cash & Bank account ledger.
- Quick Action buttons and Recent Activity feed.

### 2. Fuel Sales (Counter & Account Holders)
- Walk-in counter cash sales & registered purchaser khata credit sales.
- Real-time stock deduction upon sale.
- Printable single fuel sale voucher receipt with In-App PDF viewer.

### 3. Stock & Tanker Purchases
- Tanker arrival recording with supplier billing.
- Stock capacity and automatic purchase rate updates.
- Tank capacity management for Petrol & Diesel.

### 4. Purchasers Khata & Ledgers
- Individual running balance statements (e.g. Arsalan, Launch, Coach services).
- Date filters: Today, Weekly, Monthly, Yearly, Calendar Range, All Time.
- In-app PDF & Excel (.csv) export.

### 5. Suppliers Khata & History
- Complete supply agency records, tanker payments, and purchase ledgers.
- Detailed supplier statement history with period filters.

### 6. Expenses & Staff Salaries
- Category-wise expenses (Salaries, Electricity, Generator, Misc, Custom categories).
- Add new custom categories on-the-fly.

### 7. Cash & Bank Management
- Dual payment method tracking: **Cash** vs **Bank Transfer**.
- Daily cash drawer vs bank balance ledger.

### 8. Roles & Permissions (RBAC)
- **Owner (Admin):** Full access to all modules, editing, deleting, backup restore, and zero-zero system reset.
- **Employee:** View and create permissions restricted per module, edit/delete disabled.
- **Default Credentials:**
  - Owner: `owner` / `Bolan123`
  - Employee: `raziq` / `Raziq123`

### 9. Date Selection (Auto vs Manual)
- **Auto:** Automatically picks current system date.
- **Manual (dd-mm-yyyy):** Formatted entry with automatic dashes as the user types.

### 10. In-App Document Viewers
- **In-App PDF Report Viewer (`openPdfReportViewer`):**
  - Full-screen A4 visual report preview inside the app.
  - **Download:** Saves PDF to disk/device.
  - **Share:** Opens native Android share sheet (`Intent.ACTION_SEND` via `FileProvider`) for WhatsApp/Email sharing.
  - **Print:** Direct printing via Android `PrintManager` and Web print dialog.
- **In-App Excel Sheet Viewer (`openExcelSheetViewer`):**
  - Instant tabular spreadsheet preview inside the app with download option.

---

## 3. Tech Stack & Architecture
- **Framework:** Flutter (Channel stable, Dart 3)
- **State Management:** Reactive Store (`ErpStore`) with auto-recalculation
- **Offline & Local Storage:** Browser `localStorage` / Android native file storage (`bolan_gasoline_erp_state.json`)
- **Cloud Backend:** Firebase Hosting & Firebase Realtime State Sync
- **Native Android Integration:**
  - Kotlin `MethodChannel` (`bolan_gasoline_erp/native_actions`) in `MainActivity.kt`
  - `androidx.core.content.FileProvider` (`com.bolangasoline.bolan_gasoline_erp.fileprovider`)
  - Android `PrintManager` (`PdfFilePrintAdapter`)

---

## 4. Project File Structure
```
bolan_gasoline_erp/
├── android/                   # Native Android project (Kotlin, FileProvider, Launcher icons)
├── build/                     # Compiled Web & APK artifacts
├── lib/
│   ├── core/
│   │   ├── models/erp_models.dart       # Data schemas (Sales, Purchases, Khata, Users, etc.)
│   │   ├── state/erp_store.dart         # Business logic, state, auto-sync, RBAC
│   │   ├── storage/
│   │   │   ├── file_transfer.dart       # Cross-platform file transfer interface
│   │   │   ├── file_transfer_io.dart    # Android IO implementation (Share, Print, Save)
│   │   │   ├── file_transfer_web.dart   # Web implementation (Download, Print tab)
│   │   │   └── pdf_generator.dart       # Pure-Dart Adobe PDF 1.4 binary engine
│   ├── presentation/
│   │   ├── screens/                     # Sales, Stock, Khata, Suppliers, Expenses, etc.
│   │   └── widgets/common_widgets.dart  # In-App PDF & Excel viewers, Date picker, Dialogs
│   └── main.dart                        # Entry point, responsive layout, theme engine
├── test/                                # 100% automated test suite (widget & full E2E)
├── README.md                            # Quick start guide
├── VERIFICATION_REPORT.md               # Test & analyzer verification log
└── PROJECT_SUMMARY.md                   # Full comprehensive project specification (this file)
```

---

## 5. Verification & Tests Status
- `flutter analyze`: **0 issues**
- `flutter test`: **All tests passed (7/7 passed)**
- Zero UI overflow errors on Mobile (360x800) and Desktop (1440x900) in both English (LTR) and Urdu (RTL).
