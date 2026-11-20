import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/storage/file_transfer.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/erp_models.dart';
import '../../data/repository/erp_store.dart';
import '../widgets/common_widgets.dart';

class SettingsAdminScreen extends StatefulWidget {
  const SettingsAdminScreen({super.key, required this.store});

  final ErpStore store;

  @override
  State<SettingsAdminScreen> createState() => _SettingsAdminScreenState();
}

class _SettingsAdminScreenState extends State<SettingsAdminScreen> {
  final Set<String> _selectedUserIds = {};

  Future<void> _handleExportJson() async {
    final isUrdu = widget.store.isUrdu;
    final jsonText = widget.store.exportBackupJson();
    final dateTag = DateTime.now().toIso8601String().split('T').first;
    final downloaded = await downloadTextFile(
      filename: 'bolan_gasoline_backup_$dateTag.json',
      content: jsonText,
      mimeType: 'application/json',
    );
    if (!mounted) return;
    if (downloaded) {
      showErpSnackBar(
        context,
        tr(isUrdu, 'Full backup JSON downloaded!',
            'مکمل بیک اپ JSON فائل ڈاؤن لوڈ ہو گئی!'),
      );
    } else {
      await Clipboard.setData(ClipboardData(text: jsonText));
      if (!mounted) return;
      showErpSnackBar(
        context,
        tr(isUrdu, 'Backup JSON copied to clipboard!',
            'بیک اپ JSON کلپ بورڈ پر کاپی ہو گیا!'),
      );
    }
  }

  Future<void> _handleExportCsv() async {
    final isUrdu = widget.store.isUrdu;
    final csvText = widget.store.exportSalesCsv();
    final dateTag = DateTime.now().toIso8601String().split('T').first;
    final downloaded = await downloadTextFile(
      filename: 'bolan_gasoline_sales_$dateTag.csv',
      content: csvText,
      mimeType: 'text/csv',
    );
    if (!mounted) return;
    if (downloaded) {
      showErpSnackBar(
        context,
        tr(isUrdu, 'Sales CSV exported for Excel!',
            'فروخت کی CSV فائل ڈاؤن لوڈ ہو گئی!'),
      );
    } else {
      await Clipboard.setData(ClipboardData(text: csvText));
      if (!mounted) return;
      showErpSnackBar(
        context,
        tr(isUrdu, 'Sales CSV copied to clipboard!',
            'فروخت CSV کلپ بورڈ پر کاپی ہو گئی!'),
      );
    }
  }

  Future<void> _handleImportJson() async {
    final isUrdu = widget.store.isUrdu;
    final picked = await pickJsonFileContent();
    if (!mounted) return;

    if (picked != null && picked.isNotEmpty) {
      final err = widget.store.importBackupJson(picked);
      showErpSnackBar(
        context,
        err ??
            tr(isUrdu, 'Backup imported & restored successfully!',
                'بیک اپ کامیابی سے بحال ہو گیا!'),
      );
      return;
    }

    // Fallback: Paste JSON backup dialog (great for desktop/mobile testing)
    final pasteCtrl = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr(isUrdu, 'Import Backup JSON', 'بیک اپ JSON امپورٹ کریں')),
        content: SizedBox(
          width: 460,
          child: TextField(
            controller: pasteCtrl,
            maxLines: 8,
            decoration: InputDecoration(
              hintText: tr(
                isUrdu,
                'Paste your exported Bolan Gasoline JSON backup here...',
                'اپنا محفوظ شدہ بیک اپ JSON یہاں پیسٹ کریں...',
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(tr(isUrdu, 'Cancel', 'بند کریں')),
          ),
          FilledButton(
            onPressed: () {
              final err = widget.store.importBackupJson(pasteCtrl.text);
              Navigator.of(ctx).pop();
              showErpSnackBar(
                context,
                err ??
                    tr(isUrdu, 'Backup imported successfully!',
                        'بیک اپ کامیابی سے بحال ہو گیا!'),
              );
            },
            child: Text(tr(isUrdu, 'Restore Backup', 'بحال کریں')),
          ),
        ],
      ),
    );
  }

  Future<void> _handleResetToZero() async {
    final isUrdu = widget.store.isUrdu;
    final erp = context.erp;
    final passCtrl = TextEditingController();
    final owner = widget.store.users.firstWhere((u) => u.isOwner);
    String? errText;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.delete_forever_rounded, color: erp.danger),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tr(isUrdu, 'Reset All Data to Zero (0-0)?',
                      'کیا تمام ڈیٹا زیرو (0-0) کر دیں؟'),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                tr(
                  isUrdu,
                  'This will clear ALL sales, purchases, purchasers, suppliers, payments, and expenses, and set Petrol & Diesel tank stocks to 0 L so you can start completely fresh.',
                  'اس سے تمام فروخت، خریداری، پرچیزرز، سپلائرز، وصولیاں اور اخراجات حذف ہو جائیں گے اور پٹرول/ڈیزل ٹینک 0 لیٹر پر ری سیٹ ہو جائیں گے تاکہ بالکل نئے سرے سے کام شروع ہو سکے۔',
                ),
                style: TextStyle(fontSize: 12, color: erp.textMuted),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: passCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: tr(isUrdu, 'Confirm Owner Password',
                      'تصدیق کے لیے مالک کا پاس ورڈ درج کریں'),
                  errorText: errText,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(tr(isUrdu, 'Cancel', 'نہیں')),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: erp.danger),
              onPressed: () {
                if (passCtrl.text.trim() != owner.password) {
                  setDlgState(() {
                    errText = tr(isUrdu, 'Incorrect owner password',
                        'مالک کا پاس ورڈ غلط ہے');
                  });
                  return;
                }
                widget.store.resetAllDataToZero();
                Navigator.of(ctx).pop();
                showErpSnackBar(
                  context,
                  tr(isUrdu, 'All ERP data reset to 0-0 fresh start!',
                      'تمام ڈیٹا کامیابی سے 0-0 ری سیٹ ہو گیا!'),
                );
              },
              child: Text(tr(isUrdu, 'Reset to Zero', 'زیرو ری سیٹ کریں')),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEmployeeDialog({AppUser? existing}) async {
    final isUrdu = widget.store.isUrdu;
    final isEdit = existing != null;
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final userCtrl = TextEditingController(text: existing?.username ?? '');
    final passCtrl = TextEditingController(text: existing?.password ?? '');
    bool isActive = existing?.isActive ?? true;
    UserPermissions perms =
        existing?.permissions ?? UserPermissions.defaultEmployee();
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) {
          final erp = ctx.erp;
          return Dialog(
            insetPadding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              isEdit
                                  ? tr(isUrdu, 'Edit Employee & Permissions',
                                      'ملازم اور اختیارات ترمیم کریں')
                                  : tr(isUrdu, 'Add New Employee Account',
                                      'نیا ملازم اکاؤنٹ بنائیں'),
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: erp.textMain),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      TextFormField(
                        controller: nameCtrl,
                        decoration: InputDecoration(
                          labelText:
                              tr(isUrdu, 'Employee Full Name', 'ملازم کا نام'),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? tr(isUrdu, 'Required', 'لازمی')
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: userCtrl,
                              decoration: InputDecoration(
                                labelText: tr(isUrdu, 'Username', 'یوزر نیم'),
                              ),
                              validator: (v) {
                                final clean = (v ?? '').trim().toLowerCase();
                                if (clean.isEmpty) {
                                  return tr(isUrdu, 'Required', 'لازمی');
                                }
                                final dup = widget.store.users.any((u) =>
                                    u.username.toLowerCase() == clean &&
                                    u.id != existing?.id);
                                if (dup) {
                                  return tr(
                                      isUrdu, 'Already used', 'پہلے سے موجود');
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: passCtrl,
                              decoration: InputDecoration(
                                labelText: tr(
                                    isUrdu, 'Password / PIN', 'پاس ورڈ / پن'),
                              ),
                              validator: (v) => (v == null || v.trim().length < 4)
                                  ? tr(isUrdu, 'Min 4 chars', 'کم از کم 4 حروف')
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          tr(isUrdu, 'Account Active (Allow Login)',
                              'اکاؤنٹ فعال (لاگ ان کی اجازت)'),
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                        value: isActive,
                        onChanged: (v) => setDlgState(() => isActive = v),
                      ),
                      const Divider(height: 16),
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            tr(isUrdu, 'Assign Role Permissions (Table):',
                                'ملازم کے اختیارات (ٹیبل):'),
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: erp.primary),
                          ),
                          Wrap(
                            spacing: 6,
                            children: [
                              ActionChip(
                                visualDensity: VisualDensity.compact,
                                label: Text(
                                  tr(isUrdu, 'Default Staff', 'ڈیفالٹ اسٹاف'),
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700),
                                ),
                                onPressed: () => setDlgState(() =>
                                    perms = UserPermissions.defaultEmployee()),
                              ),
                              ActionChip(
                                visualDensity: VisualDensity.compact,
                                label: Text(
                                  tr(isUrdu, 'Pump Boy (Entry Only)',
                                      'پمپ آپریٹر (صرف انٹری)'),
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700),
                                ),
                                onPressed: () => setDlgState(
                                  () => perms = const UserPermissions(
                                    dashboard: ModuleCrudPermission(view: true),
                                    sales: ModuleCrudPermission(
                                        view: true, create: true),
                                    purchases: ModuleCrudPermission(
                                        view: true, create: true),
                                    purchasers: ModuleCrudPermission(
                                        view: true, create: true),
                                    suppliers: ModuleCrudPermission(
                                        view: true, create: true),
                                    expenses: ModuleCrudPermission(
                                        view: true, create: true),
                                  ),
                                ),
                              ),
                              ActionChip(
                                visualDensity: VisualDensity.compact,
                                label: Text(
                                  tr(isUrdu, 'Full Access', 'مکمل اختیار'),
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700),
                                ),
                                onPressed: () => setDlgState(
                                    () => perms = UserPermissions.all()),
                              ),
                              ActionChip(
                                visualDensity: VisualDensity.compact,
                                label: Text(
                                  tr(isUrdu, 'Clear All', 'سب صاف'),
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700),
                                ),
                                onPressed: () => setDlgState(
                                    () => perms = UserPermissions.none()),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: erp.subtleBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: erp.cardBorder),
                        ),
                        child: LayoutBuilder(
                          builder: (_, constraints) => SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minWidth: constraints.maxWidth > 540
                                    ? constraints.maxWidth
                                    : 540,
                              ),
                              child: DataTable(
                                headingRowHeight: 40,
                                dataRowMinHeight: 44,
                                dataRowMaxHeight: 50,
                                columnSpacing: 16,
                                horizontalMargin: 14,
                                columns: [
                                  DataColumn(
                                    label: Text(
                                      tr(isUrdu, 'MODULE', 'ماڈیول'),
                                      style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      tr(isUrdu, 'VIEW', 'دیکھنا'),
                                      style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      tr(isUrdu, 'CREATE', 'شامل کرنا'),
                                      style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      tr(isUrdu, 'UPDATE', 'ترمیم'),
                                      style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      tr(isUrdu, 'DELETE', 'حذف'),
                                      style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                ],
                                rows: [
                                  _buildMatrixRow(
                                    label: tr(isUrdu, 'Dashboard & Tanks',
                                        'ڈیش بورڈ اور ٹینک'),
                                    perm: perms.dashboard,
                                    supportsCreate: false,
                                    supportsDelete: false,
                                    onChanged: (np) => setDlgState(() =>
                                        perms = perms.copyWith(dashboard: np)),
                                  ),
                                  _buildMatrixRow(
                                    label: tr(isUrdu, 'Fuel Sales',
                                        'تیل فروخت (Sales)'),
                                    perm: perms.sales,
                                    onChanged: (np) => setDlgState(
                                        () => perms = perms.copyWith(sales: np)),
                                  ),
                                  _buildMatrixRow(
                                    label: tr(isUrdu, 'Fuel Stock & Purchase',
                                        'اسٹاک اور خریداری'),
                                    perm: perms.purchases,
                                    onChanged: (np) => setDlgState(() =>
                                        perms = perms.copyWith(purchases: np)),
                                  ),
                                  _buildMatrixRow(
                                    label: tr(isUrdu, 'Purchasers Khata',
                                        'پرچیزرز کھاتہ'),
                                    perm: perms.purchasers,
                                    onChanged: (np) => setDlgState(() =>
                                        perms = perms.copyWith(purchasers: np)),
                                  ),
                                  _buildMatrixRow(
                                    label: tr(isUrdu, 'Suppliers Ledger',
                                        'سپلائرز کھاتہ'),
                                    perm: perms.suppliers,
                                    onChanged: (np) => setDlgState(() =>
                                        perms = perms.copyWith(suppliers: np)),
                                  ),
                                  _buildMatrixRow(
                                    label: tr(isUrdu, 'Expenses & Salaries',
                                        'اخراجات اور تنخواہیں'),
                                    perm: perms.expenses,
                                    onChanged: (np) => setDlgState(() =>
                                        perms = perms.copyWith(expenses: np)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: Text(tr(isUrdu, 'Cancel', 'بند کریں')),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: erp.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999)),
                            ),
                            onPressed: () {
                              if (!formKey.currentState!.validate()) return;
                              if (isEdit) {
                                widget.store.updateUser(
                                  existing.copyWith(
                                    name: nameCtrl.text.trim(),
                                    username:
                                        userCtrl.text.trim().toLowerCase(),
                                    password: passCtrl.text.trim(),
                                    isActive: isActive,
                                    permissions: perms,
                                  ),
                                );
                              } else {
                                widget.store.addEmployee(
                                  name: nameCtrl.text.trim(),
                                  username: userCtrl.text.trim(),
                                  password: passCtrl.text.trim(),
                                  isActive: isActive,
                                  permissions: perms,
                                );
                              }
                              Navigator.of(ctx).pop();
                              showErpSnackBar(
                                context,
                                isEdit
                                    ? tr(isUrdu, 'Employee updated!',
                                        'ملازم اپڈیٹ ہو گیا!')
                                    : tr(isUrdu, 'New employee added!',
                                        'نیا ملازم شامل ہو گیا!'),
                              );
                            },
                            icon: const Icon(Icons.check_rounded, size: 18),
                            label: Text(isEdit
                                ? tr(isUrdu, 'Update', 'اپڈیٹ کریں')
                                : tr(isUrdu, 'Save Employee', 'محفوظ کریں')),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  DataRow _buildMatrixRow({
    required String label,
    required ModuleCrudPermission perm,
    required ValueChanged<ModuleCrudPermission> onChanged,
    bool supportsCreate = true,
    bool supportsUpdate = true,
    bool supportsDelete = true,
  }) {
    final erp = context.erp;
    Widget dashCell() => Padding(
          padding: const EdgeInsets.only(left: 14),
          child: Text('—',
              style: TextStyle(
                  color: erp.textMuted, fontWeight: FontWeight.w700)),
        );

    return DataRow(
      cells: [
        DataCell(
          Text(
            label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: erp.textMain),
          ),
        ),
        DataCell(
          Checkbox(
            value: perm.view,
            onChanged: (v) => onChanged(perm.withView(v ?? false)),
          ),
        ),
        DataCell(
          supportsCreate
              ? Checkbox(
                  value: perm.create,
                  onChanged: (v) => onChanged(perm.withCreate(v ?? false)),
                )
              : dashCell(),
        ),
        DataCell(
          supportsUpdate
              ? Checkbox(
                  value: perm.update,
                  onChanged: (v) => onChanged(perm.withUpdate(v ?? false)),
                )
              : dashCell(),
        ),
        DataCell(
          supportsDelete
              ? Checkbox(
                  value: perm.delete,
                  onChanged: (v) => onChanged(perm.withDelete(v ?? false)),
                )
              : dashCell(),
        ),
      ],
    );
  }

  String _formatModPerm(String name, ModuleCrudPermission p,
      {bool hasCreate = true, bool hasDelete = true}) {
    if (!p.view) return '';
    final tags = <String>['V'];
    if (hasCreate && p.create) tags.add('C');
    if (p.update) tags.add('U');
    if (hasDelete && p.delete) tags.add('D');
    return '$name (${tags.join('/')})';
  }

  Future<void> _showOwnerPasswordDialog() async {
    final isUrdu = widget.store.isUrdu;
    final owner = widget.store.users.firstWhere((u) => u.isOwner);
    final userCtrl = TextEditingController(text: owner.username);
    final passCtrl = TextEditingController(text: owner.password);
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr(isUrdu, 'Update Owner Credentials',
            'مالک کا یوزر نیم اور پاس ورڈ تبدیل کریں')),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: userCtrl,
                decoration: InputDecoration(
                    labelText: tr(isUrdu, 'Owner Username', 'مالک یوزر نیم')),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: passCtrl,
                decoration: InputDecoration(
                    labelText: tr(isUrdu, 'New Password / PIN',
                        'نیا پاس ورڈ / پن')),
                validator: (v) =>
                    (v == null || v.trim().length < 4) ? 'Min 4 chars' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(tr(isUrdu, 'Cancel', 'بند کریں')),
          ),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              widget.store.updateUser(
                owner.copyWith(
                  username: userCtrl.text.trim().toLowerCase(),
                  password: passCtrl.text.trim(),
                ),
              );
              Navigator.of(ctx).pop();
              showErpSnackBar(
                context,
                tr(isUrdu, 'Owner credentials updated!',
                    'مالک کا پاس ورڈ اپڈیٹ ہو گیا!'),
              );
            },
            child: Text(tr(isUrdu, 'Save', 'محفوظ کریں')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final erp = context.erp;
    final isUrdu = widget.store.isUrdu;
    final employees = widget.store.users.where((u) => !u.isOwner).toList();
    _selectedUserIds.removeWhere((id) => !employees.any((u) => u.id == id));
    final allSelected =
        employees.isNotEmpty && _selectedUserIds.length == employees.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. DATA MANAGEMENT PANEL (ZERO-ZERO RESET, EXPORT, IMPORT)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: erp.cardBg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: erp.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.storage_rounded, color: erp.primary, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr(isUrdu, 'Data Management (Import / Export / Reset)',
                              'ڈیٹا مینجمنٹ (امپورٹ، ایکسپورٹ اور زیرو ری سیٹ)'),
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: erp.textMain),
                        ),
                        Text(
                          tr(
                            isUrdu,
                            'Start from 0-0 for client launch, export JSON/CSV backups, or restore anytime.',
                            'نئے سرے سے 0-0 شروع کریں، مکمل بیک اپ ڈاؤن لوڈ کریں یا فائل سے بحال کریں۔',
                          ),
                          style: TextStyle(fontSize: 12, color: erp.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: erp.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999)),
                    ),
                    onPressed: _handleExportJson,
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: Text(
                      tr(isUrdu, 'Export Full Backup (.json)',
                          'مکمل بیک اپ ایکسپورٹ (.json)'),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(
                      backgroundColor: erp.successSoft,
                      foregroundColor: erp.success,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999)),
                    ),
                    onPressed: _handleExportCsv,
                    icon: const Icon(Icons.table_view_rounded, size: 18),
                    label: Text(
                      tr(isUrdu, 'Export Sales Excel (.csv)',
                          'فروخت ایکسل فائل (.csv)'),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: erp.primaryBorder),
                      foregroundColor: erp.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999)),
                    ),
                    onPressed: _handleImportJson,
                    icon: const Icon(Icons.upload_file_rounded, size: 18),
                    label: Text(
                      tr(isUrdu, 'Import / Restore Backup',
                          'بیک اپ امپورٹ / بحال کریں'),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: erp.danger,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999)),
                    ),
                    onPressed: _handleResetToZero,
                    icon: const Icon(Icons.delete_forever_rounded, size: 18),
                    label: Text(
                      tr(isUrdu, 'Reset All Data to Zero (0-0)',
                          'تمام ڈیٹا زیرو (0-0) کریں'),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      widget.store.loadDemoData();
                      showErpSnackBar(
                        context,
                        tr(isUrdu, 'Sample demo data loaded!',
                            'ڈیمو ڈیٹا لوڈ ہو گیا!'),
                      );
                    },
                    icon: const Icon(Icons.restore_rounded, size: 18),
                    label: Text(tr(isUrdu, 'Load Demo Data', 'ڈیمو ڈیٹا لوڈ')),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // 2. OWNER & EMPLOYEE ROLE-BASED ACCESS MANAGEMENT
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: erp.cardBg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: erp.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 10,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr(isUrdu, 'Owner & Employee Role Management',
                            'مالک اور ملازمین کے رولز اور اختیارات'),
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: erp.textMain),
                      ),
                      Text(
                        tr(
                          isUrdu,
                          'Create employee logins and control exactly which screens & actions they can access.',
                          'ملازمین کے لاگ ان بنائیں اور طے کریں کہ کون کیا دیکھ یا تبدیل کر سکتا ہے۔',
                        ),
                        style: TextStyle(fontSize: 12, color: erp.textMuted),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _showOwnerPasswordDialog,
                        icon: const Icon(Icons.key_rounded, size: 17),
                        label: Text(tr(isUrdu, 'Change Owner Password',
                            'مالک پاس ورڈ بدلیں')),
                      ),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: erp.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999)),
                        ),
                        onPressed: () => _showEmployeeDialog(),
                        icon: const Icon(Icons.person_add_alt_1_rounded,
                            size: 18),
                        label: Text(
                          tr(isUrdu, '+ Add Employee', '+ نیا ملازم شامل کریں'),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              BulkSelectionBar(
                selectedCount: _selectedUserIds.length,
                totalCount: employees.length,
                isUrdu: isUrdu,
                onSelectAllToggle: () {
                  setState(() {
                    if (allSelected) {
                      _selectedUserIds.clear();
                    } else {
                      _selectedUserIds.addAll(employees.map((e) => e.id));
                    }
                  });
                },
                onClear: () => setState(() => _selectedUserIds.clear()),
                onDeleteSelected: () async {
                  final ok = await confirmDeleteDialog(context,
                      isUrdu: isUrdu, count: _selectedUserIds.length);
                  if (!ok || !mounted) return;
                  widget.store.deleteUsers(_selectedUserIds);
                  setState(() => _selectedUserIds.clear());
                },
              ),
              if (employees.isEmpty)
                EmptyStateView(
                  icon: Icons.badge_outlined,
                  title: tr(isUrdu, 'No employees added yet',
                      'ابھی کوئی ملازم شامل نہیں کیا گیا'),
                  subtitle: tr(isUrdu,
                      'Tap + Add Employee to create a staff login with custom permissions.',
                      'محدود اختیارات کے ساتھ اسٹاف لاگ ان بنانے کے لیے نیا ملازم شامل کریں۔'),
                )
              else
                LayoutBuilder(
                  builder: (_, constraints) => SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: constraints.maxWidth > 780
                            ? constraints.maxWidth
                            : 780,
                      ),
                      child: DataTable(
                        headingRowHeight: 44,
                        dataRowMinHeight: 58,
                        dataRowMaxHeight: 74,
                        columnSpacing: 16,
                        horizontalMargin: 10,
                        columns: [
                          DataColumn(
                            label: Checkbox(
                              value: allSelected,
                              onChanged: (v) {
                                setState(() {
                                  if (v == true) {
                                    _selectedUserIds
                                        .addAll(employees.map((e) => e.id));
                                  } else {
                                    _selectedUserIds.clear();
                                  }
                                });
                              },
                            ),
                          ),
                          DataColumn(
                              label: Text(tr(isUrdu, 'EMPLOYEE', 'ملازم'))),
                          DataColumn(
                              label: Text(tr(isUrdu, 'USERNAME', 'یوزر نیم'))),
                          DataColumn(
                              label: Text(tr(isUrdu, 'PERMISSIONS', 'اختیارات'))),
                          DataColumn(
                              label: Text(tr(isUrdu, 'STATUS', 'اسٹیٹس'))),
                          DataColumn(label: Text(tr(isUrdu, 'ACTIONS', 'عمل'))),
                        ],
                        rows: employees.map((u) {
                          final checked = _selectedUserIds.contains(u.id);
                          final permsList = <String>[
                            _formatModPerm('Dashboard', u.permissions.dashboard,
                                hasCreate: false, hasDelete: false),
                            _formatModPerm('Sales', u.permissions.sales),
                            _formatModPerm('Stock', u.permissions.purchases),
                            _formatModPerm('Khata', u.permissions.purchasers),
                            _formatModPerm('Suppliers', u.permissions.suppliers),
                            _formatModPerm('Expenses', u.permissions.expenses),
                          ].where((s) => s.isNotEmpty).toList();
                          return DataRow(
                            selected: checked,
                            cells: [
                              DataCell(
                                Checkbox(
                                  value: checked,
                                  onChanged: (v) {
                                    setState(() {
                                      if (v == true) {
                                        _selectedUserIds.add(u.id);
                                      } else {
                                        _selectedUserIds.remove(u.id);
                                      }
                                    });
                                  },
                                ),
                              ),
                              DataCell(Text(u.name,
                                  style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: erp.textMain))),
                              DataCell(LtrText(u.username,
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: erp.primary))),
                              DataCell(
                                SizedBox(
                                  width: 240,
                                  child: Text(
                                    permsList.isEmpty
                                        ? 'No Access'
                                        : permsList.join(' • '),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: 11, color: erp.textMuted),
                                  ),
                                ),
                              ),
                              DataCell(
                                Switch(
                                  value: u.isActive,
                                  onChanged: (v) => widget.store
                                      .updateUser(u.copyWith(isActive: v)),
                                ),
                              ),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      tooltip: tr(isUrdu, 'Edit Permissions',
                                          'اختیارات ترمیم'),
                                      icon: Icon(Icons.edit_outlined,
                                          size: 18, color: erp.primary),
                                      onPressed: () =>
                                          _showEmployeeDialog(existing: u),
                                    ),
                                    IconButton(
                                      tooltip: tr(isUrdu, 'Delete', 'حذف'),
                                      icon: Icon(Icons.delete_outline_rounded,
                                          size: 18, color: erp.danger),
                                      onPressed: () async {
                                        final ok = await confirmDeleteDialog(
                                            context,
                                            isUrdu: isUrdu,
                                            count: 1);
                                        if (!ok || !mounted) return;
                                        widget.store.deleteUsers([u.id]);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
