import 'package:flutter/material.dart';

import '../../core/storage/file_transfer.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/pdf_generator.dart';
import '../../data/models/erp_models.dart';

class BolanLogoBadge extends StatelessWidget {
  const BolanLogoBadge({
    super.key,
    this.size = 44,
    this.isCircle = false,
  });

  final double size;
  final bool isCircle;

  @override
  Widget build(BuildContext context) {
    final img = Transform.scale(
      scale: isCircle ? 1.06 : 1.02,
      child: Image.asset(
        'assets/images/bolan_logo.jpeg',
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => Icon(
          Icons.local_gas_station_rounded,
          color: context.erp.primary,
          size: size * 0.58,
        ),
      ),
    );

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(isCircle ? size * 0.08 : 3),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircle ? null : BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: isCircle ? 22 : 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: isCircle
          ? ClipOval(child: img)
          : ClipRRect(
              borderRadius: BorderRadius.circular(size * 0.22),
              child: img,
            ),
    );
  }
}

class KpiStatCard extends StatelessWidget {
  const KpiStatCard({
    super.key,
    required this.icon,
    required this.iconBg,
    required this.pillText,
    required this.pillBg,
    required this.pillColor,
    required this.valueText,
    required this.label,
    this.onTap,
    this.compact = false,
  });

  final IconData icon;
  final Color iconBg;
  final String pillText;
  final Color pillBg;
  final Color pillColor;
  final String valueText;
  final String label;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final erp = context.erp;
    final radius = compact ? 18.0 : 22.0;
    return Material(
      color: erp.cardBg,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Container(
          padding: EdgeInsets.all(compact ? 13 : 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: erp.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: compact ? 34 : 42,
                    height: compact ? 34 : 42,
                    decoration: BoxDecoration(
                      color: iconBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon,
                        color: Colors.white, size: compact ? 17 : 20),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: compact ? 7 : 10,
                          vertical: compact ? 3 : 4,
                        ),
                        decoration: BoxDecoration(
                          color: pillBg,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          pillText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: compact ? 10 : 11,
                            fontWeight: FontWeight.w700,
                            color: pillColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: compact ? 10 : 14),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: LtrText(
                  valueText,
                  style: TextStyle(
                    fontSize: compact ? 17 : 22,
                    fontWeight: FontWeight.w800,
                    color: erp.textMain,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: compact ? 11 : 12,
                  fontWeight: FontWeight.w600,
                  color: erp.textMuted,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TankStockCard extends StatelessWidget {
  const TankStockCard({
    super.key,
    required this.stock,
    required this.isUrdu,
    this.stockValueRs,
    this.onEditTank,
  });

  final FuelStock stock;
  final bool isUrdu;
  final double? stockValueRs;
  final VoidCallback? onEditTank;

  @override
  Widget build(BuildContext context) {
    final erp = context.erp;
    final isPetrol = stock.type == FuelType.petrol;
    final accent = isPetrol ? erp.petrolColor : erp.dieselColor;
    final accentSoft = isPetrol ? erp.petrolSoft : erp.dieselSoft;
    final computedValueRs = stockValueRs ??
        (stock.remainingLiters * stock.lastPurchaseRate).roundToDouble();

    return Container(
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
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accentSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isPetrol
                      ? Icons.local_gas_station_rounded
                      : Icons.oil_barrel_rounded,
                  color: accent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isPetrol
                          ? tr(isUrdu, 'Unit 1: Petrol Tank Stock',
                              'یونٹ 1: پٹرول ٹینک اسٹاک')
                          : tr(isUrdu, 'Unit 2: Diesel Tank Stock',
                              'یونٹ 2: ڈیزل ٹینک اسٹاک'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: erp.textMain,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${tr(isUrdu, 'Purchase:', 'خرید ریٹ:')} Rs. ${stock.lastPurchaseRate.round()}/L • ${tr(isUrdu, 'Cash:', 'کیش ریٹ:')} Rs. ${stock.cashSaleRate.round()}/L',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: erp.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: accentSoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: LtrText(
                  '${stock.fillPercent}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                ),
              ),
              if (onEditTank != null) ...[
                const SizedBox(width: 4),
                IconButton(
                  tooltip: tr(isUrdu, 'Edit Tank Rates / Capacity',
                      'ٹینک ریٹ / گنجائش تبدیل کریں'),
                  onPressed: onEditTank,
                  icon: Icon(Icons.tune_rounded, size: 18, color: erp.textMuted),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: stock.fillFraction,
              minHeight: 11,
              backgroundColor: erp.subtleBg,
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${tr(isUrdu, 'Available:', 'موجودہ تیل:')} ',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: erp.textMuted),
                  ),
                  LtrText(
                    formatLiters(stock.remainingLiters),
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: erp.textMain),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${tr(isUrdu, 'Capacity:', 'گنجائش:')} ',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: erp.textMuted),
                  ),
                  LtrText(
                    formatLiters(stock.capacityLiters),
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: erp.textMuted),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accentSoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: LtrText(
                  '${tr(isUrdu, 'Value:', 'مالیت:')} ${formatRs(computedValueRs)}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: accent,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class FuelBadge extends StatelessWidget {
  const FuelBadge({super.key, required this.fuel, required this.isUrdu});

  final FuelType fuel;
  final bool isUrdu;

  @override
  Widget build(BuildContext context) {
    final erp = context.erp;
    final isPetrol = fuel == FuelType.petrol;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isPetrol ? erp.petrolSoft : erp.dieselSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isPetrol
            ? tr(isUrdu, 'Petrol', 'پٹرول')
            : tr(isUrdu, 'Diesel', 'ڈیزل'),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: isPetrol ? erp.petrolColor : erp.dieselColor,
        ),
      ),
    );
  }
}

class BulkSelectionBar extends StatelessWidget {
  const BulkSelectionBar({
    super.key,
    required this.selectedCount,
    required this.totalCount,
    required this.isUrdu,
    required this.onSelectAllToggle,
    required this.onClear,
    required this.onDeleteSelected,
  });

  final int selectedCount;
  final int totalCount;
  final bool isUrdu;
  final VoidCallback onSelectAllToggle;
  final VoidCallback onClear;
  final VoidCallback onDeleteSelected;

  @override
  Widget build(BuildContext context) {
    if (selectedCount <= 0) return const SizedBox.shrink();
    final erp = context.erp;
    final allSelected = selectedCount >= totalCount && totalCount > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: erp.dangerSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: erp.danger.withValues(alpha: 0.35)),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_box_rounded, color: erp.danger, size: 20),
              const SizedBox(width: 8),
              Text(
                tr(
                  isUrdu,
                  '$selectedCount selected',
                  '$selectedCount منتخب شدہ',
                ),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: erp.danger,
                ),
              ),
              const SizedBox(width: 10),
              TextButton(
                onPressed: onSelectAllToggle,
                child: Text(
                  allSelected
                      ? tr(isUrdu, 'Deselect All', 'سب ہٹائیں')
                      : tr(isUrdu, 'Select All ($totalCount)',
                          'سب منتخب کریں ($totalCount)'),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: onClear,
                child: Text(tr(isUrdu, 'Cancel', 'بند کریں')),
              ),
              const SizedBox(width: 6),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: erp.danger,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999)),
                ),
                onPressed: onDeleteSelected,
                icon: const Icon(Icons.delete_sweep_rounded, size: 18),
                label: Text(
                  tr(isUrdu, 'Delete Selected ($selectedCount)',
                      'منتخب حذف کریں ($selectedCount)'),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final erp = context.erp;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: erp.subtleBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: erp.textMuted),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: erp.textMain,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: erp.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

Future<bool> confirmDeleteDialog(
  BuildContext context, {
  required bool isUrdu,
  required int count,
  String? itemLabel,
}) async {
  final erp = context.erp;
  final res = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: erp.danger),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              count > 1
                  ? tr(isUrdu, 'Delete $count Records?',
                      'کیا $count ریکارڈز حذف کریں؟')
                  : tr(isUrdu, 'Confirm Delete', 'حذف کرنے کی تصدیق'),
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ),
        ],
      ),
      content: Text(
        itemLabel ??
            (count > 1
                ? tr(
                    isUrdu,
                    'Are you sure you want to delete these $count selected records? Stock and khata balances will automatically recalculate.',
                    'کیا آپ واقعی یہ $count منتخب ریکارڈز حذف کرنا چاہتے ہیں؟ اسٹاک اور کھاتہ بیلنس خود بخود اپڈیٹ ہو جائیں گے۔',
                  )
                : tr(
                    isUrdu,
                    'Are you sure you want to delete this record? Stock and khata balances will automatically recalculate.',
                    'کیا آپ واقعی یہ ریکارڈ حذف کرنا چاہتے ہیں؟ اسٹاک اور کھاتہ بیلنس خود بخود اپڈیٹ ہو جائیں گے۔',
                  )),
        style: TextStyle(color: erp.textMuted, fontSize: 13),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(tr(isUrdu, 'Cancel', 'نہیں')),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: erp.danger),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(tr(isUrdu, 'Delete', 'حذف کریں')),
        ),
      ],
    ),
  );
  return res ?? false;
}

void showErpSnackBar(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      duration: const Duration(seconds: 2),
    ),
  );
}

List<T> filterByPeriod<T>({
  required List<T> items,
  required DateTime Function(T) getDate,
  required String period, // 'all' | 'today' | 'week' | 'month' | 'year' | 'custom'
  DateTimeRange? customRange,
}) {
  if (period == 'all' || items.isEmpty) return items;
  final refNow =
      items.map(getDate).reduce((a, b) => a.isAfter(b) ? a : b);
  return items.where((item) {
    final d = getDate(item);
    switch (period) {
      case 'today':
        return d.year == refNow.year &&
            d.month == refNow.month &&
            d.day == refNow.day;
      case 'week':
        return !d.isBefore(refNow.subtract(const Duration(days: 7)));
      case 'month':
        return d.year == refNow.year && d.month == refNow.month;
      case 'year':
        return d.year == refNow.year;
      case 'custom':
        if (customRange == null) return true;
        final start = DateTime(
          customRange.start.year,
          customRange.start.month,
          customRange.start.day,
        );
        final end = DateTime(
          customRange.end.year,
          customRange.end.month,
          customRange.end.day,
          23,
          59,
          59,
        );
        return !d.isBefore(start) && !d.isAfter(end);
      default:
        return true;
    }
  }).toList();
}

Future<void> showDownloadFormatDialog(
  BuildContext context, {
  required bool isUrdu,
  required VoidCallback onDownloadPdf,
  required VoidCallback onDownloadExcel,
}) async {
  final erp = context.erp;
  await showDialog<void>(
    context: context,
    builder: (ctx) => Directionality(
      textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
      child: Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.download_rounded, color: erp.primary, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        tr(isUrdu, 'Choose Download Format',
                            'ڈاؤن لوڈ فارمیٹ منتخب کریں'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: erp.textMain,
                        ),
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  tr(
                    isUrdu,
                    'Select PDF for a printable statement report or Excel (.csv) for spreadsheet analysis.',
                    'پرنٹ اور اسٹیٹمنٹ کے لیے PDF منتخب کریں یا ایکسل شیٹ کے لیے Excel (.csv) منتخب کریں۔',
                  ),
                  style: TextStyle(fontSize: 12, color: erp.textMuted),
                ),
                const SizedBox(height: 16),
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    onDownloadPdf();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: erp.dangerSoft,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: erp.danger.withValues(alpha: 0.35)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: erp.danger,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.picture_as_pdf_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tr(isUrdu, 'Download PDF (.pdf)',
                                    'پی ڈی ایف ڈاؤن لوڈ (.pdf)'),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: erp.danger,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                tr(isUrdu, 'Official A4 Printable PDF Report',
                                    'آفیشل A4 پرنٹ ایبل پی ڈی ایف رپورٹ'),
                                style: TextStyle(
                                    fontSize: 11.5, color: erp.textMuted),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios_rounded,
                            size: 14, color: erp.danger),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    onDownloadExcel();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: erp.successSoft,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: erp.success.withValues(alpha: 0.35)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: erp.success,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.table_view_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tr(isUrdu, 'Download Excel (.csv)',
                                    'ایکسل شیٹ ڈاؤن لوڈ (.csv)'),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: erp.success,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                tr(isUrdu, 'Microsoft Excel / Google Sheets CSV',
                                    'مائیکروسافٹ ایکسل / شیٹ فائل'),
                                style: TextStyle(
                                    fontSize: 11.5, color: erp.textMuted),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios_rounded,
                            size: 14, color: erp.success),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class ExportActionButtons extends StatelessWidget {
  const ExportActionButtons({
    super.key,
    required this.isUrdu,
    required this.onDownloadExcel,
    required this.onDownloadPdf,
  });

  final bool isUrdu;
  final VoidCallback onDownloadExcel;
  final VoidCallback onDownloadPdf;

  @override
  Widget build(BuildContext context) {
    final erp = context.erp;
    return FilledButton.tonalIcon(
      style: FilledButton.styleFrom(
        backgroundColor: erp.primarySoft,
        foregroundColor: erp.primary,
        visualDensity: VisualDensity.compact,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      onPressed: () => showDownloadFormatDialog(
        context,
        isUrdu: isUrdu,
        onDownloadPdf: onDownloadPdf,
        onDownloadExcel: onDownloadExcel,
      ),
      icon: const Icon(Icons.download_rounded, size: 16),
      label: Text(
        tr(isUrdu, 'Download Report', 'رپورٹ ڈاؤن لوڈ'),
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class PeriodFilterBar extends StatelessWidget {
  const PeriodFilterBar({
    super.key,
    required this.selectedPeriod,
    required this.customRange,
    required this.isUrdu,
    required this.onSelectPeriod,
    required this.onPickCalendar,
    this.onDownloadReport,
    this.onDownloadPdf,
  });

  final String selectedPeriod;
  final DateTimeRange? customRange;
  final bool isUrdu;
  final ValueChanged<String> onSelectPeriod;
  final VoidCallback onPickCalendar;
  final VoidCallback? onDownloadReport;
  final VoidCallback? onDownloadPdf;

  @override
  Widget build(BuildContext context) {
    final erp = context.erp;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Icon(Icons.date_range_rounded, size: 16, color: erp.textMuted),
            Text(
              tr(isUrdu, 'Period:', 'مدت:'),
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: erp.textMuted),
            ),
            ChoiceChip(
              visualDensity: VisualDensity.compact,
              label: Text(tr(isUrdu, 'All Time', 'پوری ہسٹری')),
              selected: selectedPeriod == 'all',
              onSelected: (_) => onSelectPeriod('all'),
            ),
            ChoiceChip(
              visualDensity: VisualDensity.compact,
              label: Text(tr(isUrdu, 'Today', 'آج')),
              selected: selectedPeriod == 'today',
              onSelected: (_) => onSelectPeriod('today'),
            ),
            ChoiceChip(
              visualDensity: VisualDensity.compact,
              label: Text(tr(isUrdu, 'Weekly', 'ہفتہ وار')),
              selected: selectedPeriod == 'week',
              onSelected: (_) => onSelectPeriod('week'),
            ),
            ChoiceChip(
              visualDensity: VisualDensity.compact,
              label: Text(tr(isUrdu, 'Monthly', 'ماہانہ')),
              selected: selectedPeriod == 'month',
              onSelected: (_) => onSelectPeriod('month'),
            ),
            ChoiceChip(
              visualDensity: VisualDensity.compact,
              label: Text(tr(isUrdu, 'Yearly', 'سالانہ')),
              selected: selectedPeriod == 'year',
              onSelected: (_) => onSelectPeriod('year'),
            ),
            ActionChip(
              visualDensity: VisualDensity.compact,
              avatar: Icon(Icons.calendar_month_rounded,
                  size: 15, color: erp.primary),
              label: Text(
                selectedPeriod == 'custom' && customRange != null
                    ? '${formatDateShort(customRange!.start)} - ${formatDateShort(customRange!.end)}'
                    : tr(isUrdu, 'Calendar', 'کیلنڈر'),
                style: TextStyle(
                  fontWeight: selectedPeriod == 'custom'
                      ? FontWeight.w800
                      : FontWeight.w600,
                  color: selectedPeriod == 'custom'
                      ? erp.primary
                      : erp.textMain,
                ),
              ),
              onPressed: onPickCalendar,
            ),
          ],
        ),
        if (onDownloadReport != null || onDownloadPdf != null)
          ExportActionButtons(
            isUrdu: isUrdu,
            onDownloadPdf: onDownloadPdf ?? () {},
            onDownloadExcel: onDownloadReport ?? () {},
          ),
      ],
    );
  }
}

class RecordDetailField {
  const RecordDetailField({
    required this.label,
    required this.value,
    this.isBold = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool isBold;
  final Color? valueColor;
}

Future<void> showRecordDetailDialog(
  BuildContext context, {
  required bool isUrdu,
  required String title,
  required String recordId,
  required DateTime date,
  required List<RecordDetailField> fields,
  String? statusLabel,
  Color? statusColor,
}) async {
  final erp = context.erp;
  await showDialog<void>(
    context: context,
    builder: (ctx) => Directionality(
      textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
      child: Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const BolanLogoBadge(size: 40),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: erp.textMain,
                            ),
                          ),
                          const SizedBox(height: 2),
                          LtrText(
                            '$recordId  •  ${formatDateShort(date)}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: erp.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (statusLabel != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: (statusColor ?? erp.primary)
                              .withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: statusColor ?? erp.primary,
                          ),
                        ),
                      ),
                    const SizedBox(width: 4),
                    IconButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: erp.subtleBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: erp.cardBorder),
                  ),
                  child: Column(
                    children: [
                      for (int i = 0; i < fields.length; i++) ...[
                        if (i > 0)
                          Divider(
                              height: 18,
                              color: erp.cardBorder.withValues(alpha: 0.8)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fields[i].label,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: erp.textMuted,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                fields[i].value,
                                textAlign:
                                    isUrdu ? TextAlign.left : TextAlign.right,
                                style: TextStyle(
                                  fontSize: fields[i].isBold ? 14 : 13,
                                  fontWeight: fields[i].isBold
                                      ? FontWeight.w900
                                      : FontWeight.w700,
                                  color: fields[i].valueColor ?? erp.textMain,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.tonalIcon(
                      style: FilledButton.styleFrom(
                        backgroundColor: erp.dangerSoft,
                        foregroundColor: erp.danger,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999)),
                      ),
                      onPressed: () async {
                        final bytes = ErpPdfGenerator.buildTableReportPdf(
                          reportTitle: '$title ($recordId)',
                          subtitle:
                              'Record ID: $recordId  |  Date: ${formatDateShort(date)}',
                          summaryItems: [
                            if (statusLabel != null) 'Status: $statusLabel',
                          ],
                          headers: const ['FIELD', 'VALUE'],
                          rows: fields
                              .map((f) => [f.label, f.value])
                              .toList(),
                        );
                        await downloadBinaryFile(
                          filename: 'bolan_voucher_${recordId.toLowerCase()}.pdf',
                          bytes: bytes,
                          mimeType: 'application/pdf',
                        );
                        if (!ctx.mounted) return;
                        showErpSnackBar(
                          context,
                          tr(isUrdu, 'Voucher PDF downloaded!',
                              'رسید پی ڈی ایف ڈاؤن لوڈ ہو گئی!'),
                        );
                      },
                      icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                      label: Text(
                        tr(isUrdu, 'Download PDF', 'پی ڈی ایف رسید'),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: erp.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999)),
                      ),
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: Text(
                        tr(isUrdu, 'Close', 'بند کریں'),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
