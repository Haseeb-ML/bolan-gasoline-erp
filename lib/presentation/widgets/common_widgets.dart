import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
                                    'ایکسل شیٹ دیکھیں اور ڈاؤن لوڈ (.csv)'),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: erp.success,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                tr(
                                  isUrdu,
                                  'Open Excel Sheet View in Software & Download (.csv)',
                                  'سافٹ ویئر کے اندر ایکسل شیٹ دیکھیں اور ڈاؤن لوڈ کریں',
                                ),
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
                        await openPdfReportViewer(
                          context,
                          isUrdu: isUrdu,
                          filename: 'bolan_voucher_${recordId.toLowerCase()}.pdf',
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
                      },
                      icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                      label: Text(
                        tr(isUrdu, 'Open / Print PDF', 'پی ڈی ایف کھولیں / پرنٹ'),
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

List<String> _splitCsvRow(String line) {
  final result = <String>[];
  final current = StringBuffer();
  bool inQuotes = false;
  for (int i = 0; i < line.length; i++) {
    final ch = line[i];
    if (ch == '"') {
      inQuotes = !inQuotes;
    } else if (ch == ',' && !inQuotes) {
      result.add(current.toString().trim());
      current.clear();
    } else {
      current.write(ch);
    }
  }
  result.add(current.toString().trim());
  return result;
}

String _excelColumnLetter(int index) {
  String col = '';
  int n = index;
  while (n >= 0) {
    col = String.fromCharCode(65 + (n % 26)) + col;
    n = (n ~/ 26) - 1;
  }
  return col;
}

Future<void> openExcelSheetViewer(
  BuildContext context, {
  required bool isUrdu,
  required String filename,
  required String sheetTitle,
  required String csvContent,
}) async {
  final rawLines = csvContent
      .split(RegExp(r'\r?\n'))
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();

  String subtitleInfo = 'Bolan Gasoline ERP — Official Excel Spreadsheet View';
  List<String> headers = [];
  final dataRows = <List<String>>[];

  if (rawLines.isNotEmpty) {
    int startIdx = 0;
    if (rawLines.first.startsWith('Bolan Gasoline ERP')) {
      if (rawLines.length > 1) {
        final metaParts = _splitCsvRow(rawLines[1]);
        final pairs = <String>[];
        for (int i = 0; i + 1 < metaParts.length; i += 2) {
          pairs.add('${metaParts[i]}: ${metaParts[i + 1]}');
        }
        subtitleInfo = pairs.join('   |   ');
      }
      startIdx = rawLines.indexWhere((l) => l.startsWith('Date,ID,'));
      if (startIdx == -1) startIdx = 0;
    }
    headers = _splitCsvRow(rawLines[startIdx]);
    for (int i = startIdx + 1; i < rawLines.length; i++) {
      final parsed = _splitCsvRow(rawLines[i]);
      if (parsed.every((cell) => cell.isEmpty)) continue;
      dataRows.add(parsed);
    }
  }

  if (headers.isEmpty) {
    headers = ['Column A'];
  }
  final colCount = headers.length;

  // Auto-generate a TOTAL summary row if the CSV doesn't already end with one
  final hasTotalRow = dataRows.isNotEmpty &&
      dataRows.last.isNotEmpty &&
      dataRows.last.first.toUpperCase().startsWith('TOTAL');
  if (!hasTotalRow && dataRows.isNotEmpty && colCount > 1) {
    final totalRow = List<String>.filled(colCount, '');
    totalRow[0] = 'TOTAL (${dataRows.length} Records)';
    bool anySummed = false;
    for (int c = 1; c < colCount; c++) {
      final h = headers[c].toLowerCase();
      final isRateOrIdOrPhone = h.contains('rate') ||
          h.contains('id') ||
          h.contains('phone') ||
          h.contains('date');
      if (isRateOrIdOrPhone) continue;
      double sum = 0;
      int numericCount = 0;
      for (final r in dataRows) {
        if (c < r.length) {
          final cleaned = r[c].replaceAll(RegExp(r'[^0-9.-]'), '');
          final val = double.tryParse(cleaned);
          if (val != null && cleaned.isNotEmpty) {
            sum += val;
            numericCount++;
          }
        }
      }
      if (numericCount == dataRows.length && numericCount > 0) {
        anySummed = true;
        if (h.contains('liter')) {
          totalRow[c] = '${formatNumber(sum)} L';
        } else if (h.contains('rs') ||
            h.contains('bill') ||
            h.contains('paid') ||
            h.contains('due') ||
            h.contains('balance') ||
            h.contains('amount') ||
            h.contains('purchased') ||
            h.contains('payable')) {
          totalRow[c] = formatRs(sum);
        } else {
          totalRow[c] = formatNumber(sum);
        }
      }
    }
    if (anySummed) {
      dataRows.add(totalRow);
    }
  }

  Future<void> triggerFileDownload(BuildContext dialogCtx) async {
    final ok = await downloadTextFile(
      filename: filename,
      content: csvContent,
      mimeType: 'text/csv',
    );
    if (!ok) {
      await Clipboard.setData(ClipboardData(text: csvContent));
    }
    if (!context.mounted) return;
    showErpSnackBar(
      context,
      tr(
        isUrdu,
        'Excel file ($filename) downloaded!',
        'ایکسل فائل ($filename) ڈاؤن لوڈ ہو گئی!',
      ),
    );
  }

  await showDialog<void>(
    context: context,
    useSafeArea: false,
    builder: (ctx) => _FullScreenExcelDialog(
      isUrdu: isUrdu,
      filename: filename,
      sheetTitle: sheetTitle,
      subtitleInfo: subtitleInfo,
      headers: headers,
      dataRows: dataRows,
      onDownloadFile: () => triggerFileDownload(ctx),
    ),
  );
}

class _FullScreenExcelDialog extends StatefulWidget {
  const _FullScreenExcelDialog({
    required this.isUrdu,
    required this.filename,
    required this.sheetTitle,
    required this.subtitleInfo,
    required this.headers,
    required this.dataRows,
    required this.onDownloadFile,
  });

  final bool isUrdu;
  final String filename;
  final String sheetTitle;
  final String subtitleInfo;
  final List<String> headers;
  final List<List<String>> dataRows;
  final VoidCallback onDownloadFile;

  @override
  State<_FullScreenExcelDialog> createState() => _FullScreenExcelDialogState();
}

class _FullScreenExcelDialogState extends State<_FullScreenExcelDialog> {
  final ScrollController _horizontalCtrl = ScrollController();
  final ScrollController _verticalCtrl = ScrollController();

  @override
  void dispose() {
    _horizontalCtrl.dispose();
    _verticalCtrl.dispose();
    super.dispose();
  }

  void _scrollHorizontalBy(double delta) {
    if (!_horizontalCtrl.hasClients) return;
    final target = (_horizontalCtrl.offset + delta).clamp(
      0.0,
      _horizontalCtrl.position.maxScrollExtent,
    );
    _horizontalCtrl.animateTo(
      target,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final erp = context.erp;
    final isUrdu = widget.isUrdu;
    final isMobile = MediaQuery.sizeOf(context).width < 640;
    final colCount = widget.headers.length;
    final recordCount = widget.dataRows
        .where(
            (r) => r.isEmpty || !r.first.toUpperCase().startsWith('TOTAL'))
        .length;

    const excelGreen = Color(0xFF107C41);
    const excelGreenDark = Color(0xFF0B5C2E);
    const excelGridBorder = Color(0xFFCBD5E1);

    return Directionality(
      textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
      child: Dialog.fullscreen(
        backgroundColor: erp.cardBg,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Microsoft Excel Style Top Green Ribbon Header (Full Screen)
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12 : 22,
                  vertical: isMobile ? 10 : 14,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [excelGreen, excelGreenDark],
                  ),
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
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.table_view_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.sheetTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: isMobile ? 15 : 17,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                              LtrText(
                                '${widget.filename}  •  $recordCount Records × $colCount Columns (Full Screen View)',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: excelGreenDark,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          onPressed: widget.onDownloadFile,
                          icon: const Icon(Icons.download_rounded, size: 17),
                          label: Text(
                            tr(
                              isUrdu,
                              'Download Excel File (.csv)',
                              'ایکسل فائل ڈاؤن لوڈ کریں',
                            ),
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        FilledButton.tonalIcon(
                          style: FilledButton.styleFrom(
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.16),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_fullscreen_rounded,
                              size: 16),
                          label: Text(
                            tr(isUrdu, 'Exit Full Screen', 'واپس جائیں'),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 2. Classic Excel Formula Bar (A1 | fx) + Horizontal Scroll Controls
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12 : 22,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: erp.subtleBg,
                  border: Border(
                    bottom: BorderSide(color: erp.cardBorder),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: erp.cardBg,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: erp.cardBorder),
                      ),
                      child: const LtrText(
                        'A1',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: excelGreen,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const LtrText(
                      'fx',
                      style: TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.subtitleInfo,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: erp.textMain,
                        ),
                      ),
                    ),
                    // Quick Horizontal Scroll Left / Right Buttons
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                      ),
                      onPressed: () => _scrollHorizontalBy(-260),
                      icon: const Icon(Icons.chevron_left_rounded, size: 16),
                      label: Text(
                        tr(isUrdu, 'Left', 'بائیں'),
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 6),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                      ),
                      onPressed: () => _scrollHorizontalBy(260),
                      icon: const Icon(Icons.chevron_right_rounded, size: 16),
                      label: Text(
                        tr(isUrdu, 'Right', 'دائیں'),
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),

              // 3. Full-Screen Interactive Excel Spreadsheet Grid with Pinned Bottom Horizontal Scrollbar
              Expanded(
                child: LayoutBuilder(
                  builder: (_, boxConstraints) {
                    final colWidths = <int, TableColumnWidth>{
                      0: const FixedColumnWidth(46),
                      for (int c = 0; c < colCount; c++)
                        c + 1: const IntrinsicColumnWidth(flex: 1),
                    };
                    return Container(
                      color: Colors.white,
                      child: RawScrollbar(
                        controller: _horizontalCtrl,
                        thumbVisibility: true,
                        trackVisibility: true,
                        interactive: true,
                        thickness: 14,
                        radius: const Radius.circular(7),
                        thumbColor: excelGreen.withValues(alpha: 0.78),
                        trackColor: const Color(0xFFE2E8F0),
                        trackBorderColor: const Color(0xFFCBD5E1),
                        scrollbarOrientation: ScrollbarOrientation.bottom,
                        notificationPredicate: (notif) =>
                            notif.metrics.axis == Axis.horizontal,
                        child: SingleChildScrollView(
                          controller: _horizontalCtrl,
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: boxConstraints.maxWidth,
                            ),
                            child: SizedBox(
                              height: boxConstraints.maxHeight,
                              child: RawScrollbar(
                                controller: _verticalCtrl,
                                thumbVisibility: true,
                                trackVisibility: true,
                                interactive: true,
                                thickness: 12,
                                radius: const Radius.circular(6),
                                thumbColor:
                                    const Color(0xFF64748B).withValues(alpha: 0.65),
                                trackColor: const Color(0xFFF1F5F9),
                                scrollbarOrientation:
                                    ScrollbarOrientation.right,
                                child: SingleChildScrollView(
                                  controller: _verticalCtrl,
                                  scrollDirection: Axis.vertical,
                                  padding: const EdgeInsets.only(
                                    right: 24,
                                    bottom: 24,
                                  ),
                                  child: Directionality(
                                    textDirection: TextDirection.ltr,
                                    child: Table(
                                      columnWidths: colWidths,
                                      defaultVerticalAlignment:
                                          TableCellVerticalAlignment.middle,
                                      border: TableBorder.all(
                                        color: excelGridBorder,
                                        width: 1,
                                      ),
                                      children: [
                                        // Excel Column Letters Row (# | A | B | C | D...)
                                        TableRow(
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFE2E8F0),
                                          ),
                                          children: [
                                            const _ExcelCell(
                                              text: '#',
                                              isHeader: true,
                                              align: TextAlign.center,
                                              textColor: Color(0xFF334155),
                                              minWidth: 46,
                                            ),
                                            for (int c = 0; c < colCount; c++)
                                              _ExcelCell(
                                                text: _excelColumnLetter(c),
                                                isHeader: true,
                                                align: TextAlign.center,
                                                textColor:
                                                    const Color(0xFF334155),
                                                minWidth: 74,
                                              ),
                                          ],
                                        ),
                                        // Row 1: Column Titles Header Row
                                        TableRow(
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFDCFCE7),
                                          ),
                                          children: [
                                            const _ExcelCell(
                                              text: '1',
                                              isHeader: true,
                                              align: TextAlign.center,
                                              textColor: excelGreenDark,
                                              bgColor: Color(0xFFE2E8F0),
                                              minWidth: 46,
                                            ),
                                            for (int c = 0; c < colCount; c++)
                                              _ExcelCell(
                                                text: widget.headers[c],
                                                isHeader: true,
                                                textColor: excelGreenDark,
                                                minWidth: 74,
                                              ),
                                          ],
                                        ),
                                        // Data Rows (Row 2..N)
                                        if (widget.dataRows.isEmpty)
                                          TableRow(
                                            children: [
                                              const _ExcelCell(
                                                text: '2',
                                                align: TextAlign.center,
                                                bgColor: Color(0xFFF1F5F9),
                                                textColor: Color(0xFF64748B),
                                                minWidth: 46,
                                              ),
                                              for (int c = 0;
                                                  c < colCount;
                                                  c++)
                                                _ExcelCell(
                                                  text: c == 0
                                                      ? 'No records in current filter'
                                                      : '',
                                                  textColor:
                                                      const Color(0xFF64748B),
                                                  minWidth: 74,
                                                ),
                                            ],
                                          )
                                        else
                                          for (int r = 0;
                                              r < widget.dataRows.length;
                                              r++)
                                            TableRow(
                                              decoration: BoxDecoration(
                                                color: widget.dataRows[r]
                                                            .isNotEmpty &&
                                                        widget.dataRows[r].first
                                                            .toUpperCase()
                                                            .startsWith('TOTAL')
                                                    ? const Color(0xFFFEF3C7)
                                                    : (r.isEven
                                                        ? Colors.white
                                                        : const Color(
                                                            0xFFF8FAFC)),
                                              ),
                                              children: [
                                                _ExcelCell(
                                                  text: '${r + 2}',
                                                  isHeader: true,
                                                  align: TextAlign.center,
                                                  bgColor:
                                                      const Color(0xFFF1F5F9),
                                                  textColor:
                                                      const Color(0xFF475569),
                                                  minWidth: 46,
                                                ),
                                                for (int c = 0;
                                                    c < colCount;
                                                    c++)
                                                  _ExcelCell(
                                                    text: c <
                                                            widget.dataRows[r]
                                                                .length
                                                        ? widget.dataRows[r][c]
                                                        : '',
                                                    isHeader: widget.dataRows[r]
                                                            .isNotEmpty &&
                                                        widget.dataRows[r].first
                                                            .toUpperCase()
                                                            .startsWith(
                                                                'TOTAL'),
                                                    textColor: const Color(
                                                        0xFF0F172A),
                                                    minWidth: 74,
                                                  ),
                                              ],
                                            ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // 4. Bottom Excel Sheet Status Bar & Actions
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12 : 22,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: erp.subtleBg,
                  border: Border(
                    top: BorderSide(color: erp.cardBorder),
                  ),
                ),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: excelGreen, width: 1.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.grid_on_rounded,
                              size: 15, color: excelGreen),
                          const SizedBox(width: 6),
                          LtrText(
                            'Sheet1  ($recordCount Records  •  $colCount Columns)',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: excelGreenDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: excelGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          onPressed: widget.onDownloadFile,
                          icon: const Icon(Icons.download_rounded, size: 16),
                          label: Text(
                            tr(
                              isUrdu,
                              'Download Excel (.csv)',
                              'ایکسل ڈاؤن لوڈ کریں (.csv)',
                            ),
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            tr(isUrdu, 'Close', 'بند کریں'),
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExcelCell extends StatelessWidget {
  const _ExcelCell({
    required this.text,
    this.isHeader = false,
    this.align = TextAlign.left,
    this.textColor,
    this.bgColor,
    this.minWidth = 90,
  });

  final String text;
  final bool isHeader;
  final TextAlign align;
  final Color? textColor;
  final Color? bgColor;
  final double minWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minWidth: minWidth),
      color: bgColor,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      child: Text(
        text,
        textAlign: align,
        softWrap: true,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: isHeader ? FontWeight.w800 : FontWeight.w600,
          color: textColor ?? const Color(0xFF0F172A),
        ),
      ),
    );
  }
}

String formatDateDdMmYyyy(DateTime d) {
  final dd = d.day.toString().padLeft(2, '0');
  final mm = d.month.toString().padLeft(2, '0');
  final yyyy = d.year.toString().padLeft(4, '0');
  return '$dd-$mm-$yyyy';
}

DateTime? parseDdMmYyyy(String input, {DateTime? timeSource}) {
  final match = RegExp(r'^(\d{2})-(\d{2})-(\d{4})$').firstMatch(input.trim());
  if (match == null) return null;
  final day = int.tryParse(match.group(1)!);
  final month = int.tryParse(match.group(2)!);
  final year = int.tryParse(match.group(3)!);
  if (day == null || month == null || year == null) return null;
  if (year < 2000 || year > 2100 || month < 1 || month > 12 || day < 1 || day > 31) {
    return null;
  }
  final ts = timeSource ?? DateTime.now();
  final dt = DateTime(year, month, day, ts.hour, ts.minute, ts.second);
  if (dt.year != year || dt.month != month || dt.day != day) {
    return null;
  }
  return dt;
}

class _DdMmYyyyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final clamped =
        digitsOnly.length > 8 ? digitsOnly.substring(0, 8) : digitsOnly;
    final buf = StringBuffer();
    for (int i = 0; i < clamped.length; i++) {
      if (i == 2 || i == 4) buf.write('-');
      buf.write(clamped[i]);
    }
    final formatted = buf.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Reusable Auto / Manual (dd-mm-yyyy with auto-dashes) Date selector for all create/edit forms.
class ErpDateEntryField extends StatefulWidget {
  const ErpDateEntryField({
    super.key,
    required this.isUrdu,
    required this.initialDate,
    required this.isEdit,
    required this.onChanged,
  });

  final bool isUrdu;
  final DateTime initialDate;
  final bool isEdit;
  final ValueChanged<DateTime> onChanged;

  @override
  State<ErpDateEntryField> createState() => _ErpDateEntryFieldState();
}

class _ErpDateEntryFieldState extends State<ErpDateEntryField> {
  late TextEditingController _dateCtrl;

  @override
  void initState() {
    super.initState();
    _dateCtrl =
        TextEditingController(text: formatDateDdMmYyyy(widget.initialDate));
  }

  @override
  void dispose() {
    _dateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final erp = context.erp;
    final isUrdu = widget.isUrdu;
    final todayStr = formatDateDdMmYyyy(DateTime.now());
    final isToday = _dateCtrl.text.trim() == todayStr;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr(isUrdu, 'Date (dd-mm-yyyy)', 'تاریخ (dd-mm-yyyy)'),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: erp.textMain,
          ),
        ),
        const SizedBox(height: 6),
        Directionality(
          textDirection: TextDirection.ltr,
          child: TextFormField(
            controller: _dateCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [_DdMmYyyyInputFormatter()],
            decoration: InputDecoration(
              hintText: 'dd-mm-yyyy',
              prefixIcon: const Icon(Icons.calendar_today_rounded, size: 17),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isToday)
                    TextButton(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      onPressed: () {
                        final now = DateTime.now();
                        setState(() {
                          _dateCtrl.text = formatDateDdMmYyyy(now);
                        });
                        widget.onChanged(now);
                      },
                      child: Text(
                        tr(isUrdu, 'Today', 'آج'),
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: erp.primary,
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: erp.successSoft,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          tr(isUrdu, 'Auto', 'آج'),
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: erp.success,
                          ),
                        ),
                      ),
                    ),
                  IconButton(
                    tooltip:
                        tr(isUrdu, 'Pick from Calendar', 'کیلنڈر سے منتخب کریں'),
                    icon: Icon(Icons.date_range_rounded,
                        size: 19, color: erp.primary),
                    onPressed: () async {
                      final current = parseDdMmYyyy(_dateCtrl.text,
                              timeSource: widget.initialDate) ??
                          DateTime.now();
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: current,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null && mounted) {
                        final now = DateTime.now();
                        final combined = DateTime(
                          picked.year,
                          picked.month,
                          picked.day,
                          now.hour,
                          now.minute,
                          now.second,
                        );
                        setState(() {
                          _dateCtrl.text = formatDateDdMmYyyy(combined);
                        });
                        widget.onChanged(combined);
                      }
                    },
                  ),
                ],
              ),
            ),
            onChanged: (val) {
              setState(() {});
              final parsed =
                  parseDdMmYyyy(val, timeSource: widget.initialDate);
              if (parsed != null) {
                widget.onChanged(parsed);
              }
            },
            validator: (val) {
              final parsed =
                  parseDdMmYyyy(val ?? '', timeSource: widget.initialDate);
              if (parsed == null) {
                return tr(
                  isUrdu,
                  'Enter valid date (dd-mm-yyyy)',
                  'درست تاریخ درج کریں (dd-mm-yyyy)',
                );
              }
              return null;
            },
          ),
        ),
      ],
    );
  }
}

/// Full-Screen In-App PDF Statement Viewer with Download, Native Share (WhatsApp/Apps), & Print!
Future<void> openPdfReportViewer(
  BuildContext context, {
  required bool isUrdu,
  required String filename,
  required String reportTitle,
  required String subtitle,
  required List<String> summaryItems,
  required List<String> headers,
  required List<List<String>> rows,
}) async {
  final pdfBytes = ErpPdfGenerator.buildTableReportPdf(
    reportTitle: reportTitle,
    subtitle: subtitle,
    summaryItems: summaryItems,
    headers: headers,
    rows: rows,
  );

  await showDialog<void>(
    context: context,
    useSafeArea: false,
    builder: (ctx) {
      final isMobile = MediaQuery.sizeOf(ctx).width < 640;
      const crimson = Color(0xFFE11D48);
      const crimsonDark = Color(0xFF9F1239);

      return Directionality(
        textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
        child: Dialog.fullscreen(
          backgroundColor: const Color(0xFF1E293B),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Top Action Bar (Open PDF inside App + Download + Share + Print + Close)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 10 : 20,
                    vertical: isMobile ? 10 : 12,
                  ),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [crimson, crimsonDark],
                    ),
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.picture_as_pdf_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tr(isUrdu, 'PDF Report Viewer',
                                      'پی ڈی ایف رپورٹ ویور'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: isMobile ? 14 : 16,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                                LtrText(
                                  '$filename  •  ${rows.length} Records',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withValues(alpha: 0.88),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: crimsonDark,
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999)),
                            ),
                            onPressed: () async {
                              final ok = await downloadBinaryFile(
                                filename: filename,
                                bytes: pdfBytes,
                                mimeType: 'application/pdf',
                              );
                              if (!ctx.mounted) return;
                              final savedAt = lastSavedFilePath;
                              showErpSnackBar(
                                ctx,
                                ok
                                    ? (savedAt != null
                                        ? tr(
                                            isUrdu,
                                            'Saved PDF: $savedAt',
                                            'پی ڈی ایف محفوظ ہو گئی: $savedAt',
                                          )
                                        : tr(
                                            isUrdu,
                                            'PDF downloaded ($filename)!',
                                            'پی ڈی ایف ڈاؤن لوڈ ہو گئی ($filename)!',
                                          ))
                                    : tr(
                                        isUrdu,
                                        'Could not save PDF file.',
                                        'پی ڈی ایف محفوظ نہ ہو سکی۔',
                                      ),
                              );
                            },
                            icon: const Icon(Icons.download_rounded, size: 16),
                            label: Text(
                              tr(isUrdu, 'Download', 'ڈاؤن لوڈ'),
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w800),
                            ),
                          ),
                          FilledButton.tonalIcon(
                            style: FilledButton.styleFrom(
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.2),
                              foregroundColor: Colors.white,
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999)),
                            ),
                            onPressed: () async {
                              final ok = await sharePdfFile(
                                filename: filename,
                                bytes: pdfBytes,
                              );
                              if (!ctx.mounted) return;
                              if (!ok) {
                                showErpSnackBar(
                                  ctx,
                                  tr(isUrdu, 'Could not open Share sheet.',
                                      'شیئر آپشن نہیں کھل سکا۔'),
                                );
                              }
                            },
                            icon: const Icon(Icons.share_rounded, size: 16),
                            label: Text(
                              tr(isUrdu, 'Share', 'شیئر'),
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w800),
                            ),
                          ),
                          FilledButton.tonalIcon(
                            style: FilledButton.styleFrom(
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.2),
                              foregroundColor: Colors.white,
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999)),
                            ),
                            onPressed: () async {
                              final ok = await printPdfFile(
                                filename: filename,
                                bytes: pdfBytes,
                              );
                              if (!ctx.mounted) return;
                              if (!ok) {
                                showErpSnackBar(
                                  ctx,
                                  tr(isUrdu, 'Could not open Print dialog.',
                                      'پرنٹ آپشن نہیں کھل سکا۔'),
                                );
                              }
                            },
                            icon: const Icon(Icons.print_rounded, size: 16),
                            label: Text(
                              tr(isUrdu, 'Print', 'پرنٹ'),
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w800),
                            ),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            tooltip: tr(isUrdu, 'Close', 'بند کریں'),
                            onPressed: () => Navigator.of(ctx).pop(),
                            icon: const Icon(Icons.close_rounded,
                                color: Colors.white),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 2. Authentic A4 Paper Statement View Inside App
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(isMobile ? 10 : 24),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 920),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.35),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Directionality(
                            textDirection: TextDirection.ltr,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Branded Crimson Header
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 16),
                                  color: crimson,
                                  child: Row(
                                    children: [
                                      const BolanLogoBadge(
                                          size: 40, isCircle: true),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'BOLAN GASOLINE - PETROL & DIESEL STATION',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w900,
                                                color: Colors.white,
                                                letterSpacing: 0.4,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              reportTitle,
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white
                                                    .withValues(alpha: 0.92),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                Padding(
                                  padding: EdgeInsets.all(isMobile ? 14 : 20),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        subtitle,
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF475569),
                                        ),
                                      ),
                                      if (summaryItems.isNotEmpty) ...[
                                        const SizedBox(height: 12),
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF8FAFC),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            border: Border.all(
                                                color:
                                                    const Color(0xFFE2E8F0)),
                                          ),
                                          child: Wrap(
                                            spacing: 18,
                                            runSpacing: 8,
                                            children: summaryItems.map((item) {
                                              final lower = item.toLowerCase();
                                              final isBal =
                                                  lower.contains('balance') ||
                                                      lower.contains('payable') ||
                                                      lower.contains('due');
                                              return Text(
                                                item,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w800,
                                                  color: isBal
                                                      ? crimsonDark
                                                      : const Color(0xFF0F172A),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 14),
                                      SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: ConstrainedBox(
                                          constraints: const BoxConstraints(
                                              minWidth: 680),
                                          child: Table(
                                            defaultColumnWidth:
                                                const IntrinsicColumnWidth(
                                                    flex: 1),
                                            border: TableBorder.all(
                                              color: const Color(0xFFE2E8F0),
                                              width: 1,
                                            ),
                                            children: [
                                              TableRow(
                                                decoration: const BoxDecoration(
                                                  color: Color(0xFF0F172A),
                                                ),
                                                children: [
                                                  for (final h in headers)
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets
                                                              .symmetric(
                                                              horizontal: 10,
                                                              vertical: 9),
                                                      child: Text(
                                                        h.toUpperCase(),
                                                        style: const TextStyle(
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.w800,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              if (rows.isEmpty)
                                                TableRow(
                                                  children: [
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              12),
                                                      child: Text(
                                                        'No records found for this filter.',
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          color:
                                                              Color(0xFF64748B),
                                                        ),
                                                      ),
                                                    ),
                                                    for (int i = 1;
                                                        i < headers.length;
                                                        i++)
                                                      const SizedBox.shrink(),
                                                  ],
                                                )
                                              else
                                                for (int r = 0;
                                                    r < rows.length;
                                                    r++)
                                                  TableRow(
                                                    decoration: BoxDecoration(
                                                      color: r.isOdd
                                                          ? const Color(
                                                              0xFFF8FAFC)
                                                          : Colors.white,
                                                    ),
                                                    children: [
                                                      for (int c = 0;
                                                          c < headers.length;
                                                          c++)
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal:
                                                                      10,
                                                                  vertical: 8),
                                                          child: Text(
                                                            c < rows[r].length
                                                                ? rows[r][c]
                                                                : '-',
                                                            style: TextStyle(
                                                              fontSize: 11.5,
                                                              fontWeight: c == 0
                                                                  ? FontWeight
                                                                      .w800
                                                                  : FontWeight
                                                                      .w600,
                                                              color: const Color(
                                                                  0xFF0F172A),
                                                            ),
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      const Divider(height: 1),
                                      const SizedBox(height: 10),
                                      const Text(
                                        'Generated by Bolan Gasoline ERP System  |  Official Statement Report',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
