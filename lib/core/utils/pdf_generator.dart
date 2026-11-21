import 'dart:convert';
import 'dart:typed_data';

/// Pure-Dart Adobe PDF 1.4 report generator for Bolan Gasoline ERP.
/// Zero external plugin dependencies — produces a standards-compliant A4 PDF
/// with branded header, summary metrics, and paginated table rows.
class ErpPdfGenerator {
  static Uint8List buildTableReportPdf({
    required String reportTitle,
    required String subtitle,
    required List<String> summaryItems,
    required List<String> headers,
    required List<List<String>> rows,
  }) {
    const int rowsPerPage = 26;
    final pageChunks = <List<List<String>>>[];
    if (rows.isEmpty) {
      pageChunks.add(const []);
    } else {
      for (int i = 0; i < rows.length; i += rowsPerPage) {
        final end = (i + rowsPerPage < rows.length) ? i + rowsPerPage : rows.length;
        pageChunks.add(rows.sublist(i, end));
      }
    }

    final objects = <String>[];
    // Obj 1: Catalog
    objects.add('1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n');
    // Obj 2: Pages placeholder (filled after page count known)
    objects.add('');
    // Obj 3: Helvetica regular
    objects.add(
      '3 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica /Encoding /WinAnsiEncoding >>\nendobj\n',
    );
    // Obj 4: Helvetica Bold
    objects.add(
      '4 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold /Encoding /WinAnsiEncoding >>\nendobj\n',
    );

    final pageObjIds = <int>[];
    for (int p = 0; p < pageChunks.length; p++) {
      final pageObjId = 5 + (p * 2);
      final contentObjId = pageObjId + 1;
      pageObjIds.add(pageObjId);

      final stream = _buildPageContentStream(
        reportTitle: reportTitle,
        subtitle: subtitle,
        summaryItems: summaryItems,
        headers: headers,
        pageRows: pageChunks[p],
        pageNumber: p + 1,
        totalPages: pageChunks.length,
      );
      final streamBytes = latin1.encode(stream);

      objects.add(
        '$pageObjId 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] '
        '/Resources << /Font << /F1 3 0 R /F2 4 0 R >> >> '
        '/Contents $contentObjId 0 R >>\nendobj\n',
      );
      objects.add(
        '$contentObjId 0 obj\n<< /Length ${streamBytes.length} >>\nstream\n$stream\nendstream\nendobj\n',
      );
    }

    final kidsStr = pageObjIds.map((id) => '$id 0 R').join(' ');
    objects[1] =
        '2 0 obj\n<< /Type /Pages /Kids [$kidsStr] /Count ${pageObjIds.length} >>\nendobj\n';

    final buf = StringBuffer();
    buf.write('%PDF-1.4\n');
    final offsets = <int>[0]; // 1-indexed offsets
    for (final obj in objects) {
      offsets.add(latin1.encode(buf.toString()).length);
      buf.write(obj);
    }

    final xrefOffset = latin1.encode(buf.toString()).length;
    buf.write('xref\n0 ${objects.length + 1}\n');
    buf.write('0000000000 65535 f \n');
    for (int i = 1; i <= objects.length; i++) {
      final off = offsets[i].toString().padLeft(10, '0');
      buf.write('$off 00000 n \n');
    }
    buf.write(
      'trailer\n<< /Size ${objects.length + 1} /Root 1 0 R >>\nstartxref\n$xrefOffset\n%%EOF\n',
    );

    return Uint8List.fromList(latin1.encode(buf.toString()));
  }

  static String _buildPageContentStream({
    required String reportTitle,
    required String subtitle,
    required List<String> summaryItems,
    required List<String> headers,
    required List<List<String>> pageRows,
    required int pageNumber,
    required int totalPages,
  }) {
    final s = StringBuffer();

    // Top Crimson Brand Banner
    s.writeln('0.882 0.114 0.282 rg');
    s.writeln('32 772 531 44 re f');

    // Brand Title inside Banner
    s.writeln('1 1 1 rg');
    s.writeln(_textCmd(44, 797, 'F2', 14, 'BOLAN GASOLINE - PETROL & DIESEL STATION'));
    s.writeln(_textCmd(44, 781, 'F1', 9, _cleanAscii(reportTitle)));
    s.writeln(
      _textCmd(470, 790, 'F2', 9, 'Page $pageNumber / $totalPages'),
    );

    // Subtitle & Date
    s.writeln('0.2 0.25 0.33 rg');
    s.writeln(_textCmd(32, 754, 'F1', 9, _cleanAscii(subtitle)));

    // Summary Strip (2-column grid so Balance Due is never truncated!)
    double y = 734;
    if (summaryItems.isNotEmpty) {
      final cleanItems = summaryItems.map(_cleanAscii).toList();
      final rowCount = (cleanItems.length / 2).ceil();
      final boxHeight = rowCount > 1 ? 40.0 : 24.0;
      final boxBottom = 742.0 - boxHeight;
      s.writeln('0.96 0.97 0.98 rg');
      s.writeln('32 ${boxBottom.toStringAsFixed(1)} 531 ${boxHeight.toStringAsFixed(1)} re f');
      s.writeln('0.88 0.90 0.94 RG 0.6 w');
      s.writeln('32 ${boxBottom.toStringAsFixed(1)} 531 ${boxHeight.toStringAsFixed(1)} re S');

      for (int i = 0; i < cleanItems.length; i++) {
        final col = i % 2;
        final row = i ~/ 2;
        final itemX = col == 0 ? 42.0 : 306.0;
        final itemY = 727.0 - (row * 16.0);
        final itemText = cleanItems[i];
        final isBalanceHighlight = itemText.toLowerCase().contains('balance') ||
            itemText.toLowerCase().contains('payable') ||
            itemText.toLowerCase().contains('due');
        if (isBalanceHighlight) {
          s.writeln('0.82 0.08 0.24 rg');
        } else {
          s.writeln('0.08 0.09 0.12 rg');
        }
        s.writeln(_textCmd(itemX, itemY, 'F2', 8.5, _truncate(itemText, 48)));
      }
      y = boxBottom - 22.0;
    }

    // Table Header Bar
    final colCount = headers.isEmpty ? 1 : headers.length;
    final tableWidth = 531.0;
    final colWidth = tableWidth / colCount;
    final maxCharsPerCol = (colWidth / 4.8).floor().clamp(6, 36);

    s.writeln('0.09 0.09 0.11 rg');
    s.writeln('32 ${y.toStringAsFixed(1)} 531 20 re f');
    s.writeln('1 1 1 rg');
    for (int c = 0; c < headers.length; c++) {
      final x = 38 + (c * colWidth);
      s.writeln(
        _textCmd(
          x,
          y + 6,
          'F2',
          8,
          _truncate(_cleanAscii(headers[c]).toUpperCase(), maxCharsPerCol),
        ),
      );
    }
    y -= 20;

    // Table Rows
    if (pageRows.isEmpty) {
      s.writeln('0.4 0.45 0.52 rg');
      s.writeln(_textCmd(40, y - 14, 'F1', 9, 'No records found for this filter.'));
    } else {
      for (int r = 0; r < pageRows.length; r++) {
        final row = pageRows[r];
        if (r.isOdd) {
          s.writeln('0.975 0.98 0.99 rg');
          s.writeln('32 ${y.toStringAsFixed(1)} 531 19 re f');
        }
        // Bottom row divider line
        s.writeln('0.90 0.92 0.95 RG 0.5 w');
        s.writeln('32 ${y.toStringAsFixed(1)} m 563 ${y.toStringAsFixed(1)} l S');

        s.writeln('0.10 0.12 0.16 rg');
        for (int c = 0; c < row.length && c < colCount; c++) {
          final x = 38 + (c * colWidth);
          s.writeln(
            _textCmd(
              x,
              y + 6,
              c == 0 ? 'F2' : 'F1',
              8,
              _truncate(_cleanAscii(row[c]), maxCharsPerCol),
            ),
          );
        }
        y -= 19;
      }
    }

    // Footer
    s.writeln('0.45 0.50 0.58 rg');
    s.writeln(
      _textCmd(
        32,
        28,
        'F1',
        8,
        'Generated by Bolan Gasoline ERP System  |  Official Statement Report',
      ),
    );

    return s.toString();
  }

  static String _textCmd(
    double x,
    double y,
    String font,
    double size,
    String text,
  ) {
    final escaped = text
        .replaceAll(r'\', r'\\')
        .replaceAll('(', r'\(')
        .replaceAll(')', r'\)');
    return 'BT /$font ${size.toStringAsFixed(1)} Tf ${x.toStringAsFixed(1)} ${y.toStringAsFixed(1)} Td ($escaped) Tj ET';
  }

  /// Strips non-ASCII characters (such as Urdu script in bilingual strings)
  /// so standard Type1 PDF fonts render cleanly without encoding artifacts.
  static String _cleanAscii(String input) {
    final asciiOnly = input
        .replaceAll('•', '|')
        .replaceAll('—', '-')
        .replaceAll('–', '-')
        .replaceAll(RegExp(r'[^\x20-\x7E]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return asciiOnly.isEmpty ? '-' : asciiOnly;
  }

  static String _truncate(String s, int maxLen) {
    if (s.length <= maxLen) return s;
    return '${s.substring(0, maxLen - 2)}..';
  }
}
