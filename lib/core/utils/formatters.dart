import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

final _numFormat = NumberFormat('#,##0', 'en_US');

String formatRs(num value) => 'Rs. ${_numFormat.format(value.round())}';

String formatLiters(num value) => '${_numFormat.format(value.round())} L';

String formatNumber(num value) => _numFormat.format(value.round());

String formatDateShort(DateTime date) => DateFormat('dd MMM yyyy').format(date);

String tr(bool isUrdu, String en, String ur) => isUrdu ? ur : en;

/// Keeps numbers, IDs, and phone numbers strictly Left-to-Right even in RTL Urdu mode.
class LtrText extends StatelessWidget {
  const LtrText(
    this.text, {
    super.key,
    this.style,
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
    this.textAlign,
  });

  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Text(
        text,
        style: style,
        maxLines: maxLines,
        overflow: overflow,
        textAlign: textAlign,
      ),
    );
  }
}
