import 'package:flutter/material.dart';

enum ErpThemeId { crimson, orange, emerald, ocean, indigo, dark }

class ErpThemeMeta {
  const ErpThemeMeta({
    required this.id,
    required this.labelEn,
    required this.labelUr,
    required this.swatchColor,
  });

  final ErpThemeId id;
  final String labelEn;
  final String labelUr;
  final Color swatchColor;
}

const List<ErpThemeMeta> kErpThemes = [
  ErpThemeMeta(
    id: ErpThemeId.crimson,
    labelEn: 'Bolan Red',
    labelUr: 'بولان ریڈ',
    swatchColor: Color(0xFFE11D48),
  ),
  ErpThemeMeta(
    id: ErpThemeId.orange,
    labelEn: 'Orange',
    labelUr: 'اورنج',
    swatchColor: Color(0xFFF97316),
  ),
  ErpThemeMeta(
    id: ErpThemeId.emerald,
    labelEn: 'Emerald',
    labelUr: 'سبز',
    swatchColor: Color(0xFF059669),
  ),
  ErpThemeMeta(
    id: ErpThemeId.ocean,
    labelEn: 'Ocean',
    labelUr: 'نیلا',
    swatchColor: Color(0xFF0284C7),
  ),
  ErpThemeMeta(
    id: ErpThemeId.indigo,
    labelEn: 'Indigo',
    labelUr: 'انڈیگو',
    swatchColor: Color(0xFF4F46E5),
  ),
  ErpThemeMeta(
    id: ErpThemeId.dark,
    labelEn: 'Dark',
    labelUr: 'ڈارک',
    swatchColor: Color(0xFF0F172A),
  ),
];

@immutable
class ErpPalette extends ThemeExtension<ErpPalette> {
  const ErpPalette({
    required this.primary,
    required this.primaryHover,
    required this.primarySoft,
    required this.primaryBorder,
    required this.sidebarBg,
    required this.appBg,
    required this.cardBg,
    required this.cardBorder,
    required this.subtleBg,
    required this.textMain,
    required this.textMuted,
    required this.isDark,
  });

  final Color primary;
  final Color primaryHover;
  final Color primarySoft;
  final Color primaryBorder;
  final Color sidebarBg;
  final Color appBg;
  final Color cardBg;
  final Color cardBorder;
  final Color subtleBg;
  final Color textMain;
  final Color textMuted;
  final bool isDark;

  Color get petrolColor => const Color(0xFFF97316);
  Color get petrolSoft =>
      isDark ? const Color(0x2AF97316) : const Color(0xFFFFF7ED);
  Color get dieselColor => const Color(0xFF0284C7);
  Color get dieselSoft =>
      isDark ? const Color(0x2A0284C7) : const Color(0xFFE0F2FE);
  Color get success => const Color(0xFF10B981);
  Color get successSoft =>
      isDark ? const Color(0x2A10B981) : const Color(0xFFECFDF5);
  Color get danger => const Color(0xFFE11D48);
  Color get dangerSoft =>
      isDark ? const Color(0x2AE11D48) : const Color(0xFFFFF1F2);
  Color get warning => const Color(0xFFF59E0B);
  Color get warningSoft =>
      isDark ? const Color(0x2AF59E0B) : const Color(0xFFFFFBEB);

  static ErpPalette forTheme(ErpThemeId id) {
    switch (id) {
      case ErpThemeId.crimson:
        return const ErpPalette(
          primary: Color(0xFFE11D48),
          primaryHover: Color(0xFFBE123C),
          primarySoft: Color(0xFFFFF1F2),
          primaryBorder: Color(0xFFFECDD3),
          sidebarBg: Color(0xFF141218),
          appBg: Color(0xFFFAF5F6),
          cardBg: Color(0xFFFFFFFF),
          cardBorder: Color(0xFFF1E4E7),
          subtleBg: Color(0xFFFDF8F9),
          textMain: Color(0xFF18181B),
          textMuted: Color(0xFF64748B),
          isDark: false,
        );
      case ErpThemeId.orange:
        return const ErpPalette(
          primary: Color(0xFFF97316),
          primaryHover: Color(0xFFEA580C),
          primarySoft: Color(0xFFFFF7ED),
          primaryBorder: Color(0xFFFED7AA),
          sidebarBg: Color(0xFF0F172A),
          appBg: Color(0xFFF4F7FE),
          cardBg: Color(0xFFFFFFFF),
          cardBorder: Color(0xFFE2E8F0),
          subtleBg: Color(0xFFF8FAFC),
          textMain: Color(0xFF0F172A),
          textMuted: Color(0xFF64748B),
          isDark: false,
        );
      case ErpThemeId.emerald:
        return const ErpPalette(
          primary: Color(0xFF059669),
          primaryHover: Color(0xFF047857),
          primarySoft: Color(0xFFECFDF5),
          primaryBorder: Color(0xFFA7F3D0),
          sidebarBg: Color(0xFF06281E),
          appBg: Color(0xFFF0F7F4),
          cardBg: Color(0xFFFFFFFF),
          cardBorder: Color(0xFFDCEEE5),
          subtleBg: Color(0xFFF4FBF7),
          textMain: Color(0xFF06281E),
          textMuted: Color(0xFF52796F),
          isDark: false,
        );
      case ErpThemeId.ocean:
        return const ErpPalette(
          primary: Color(0xFF0284C7),
          primaryHover: Color(0xFF0369A1),
          primarySoft: Color(0xFFE0F2FE),
          primaryBorder: Color(0xFFBAE6FD),
          sidebarBg: Color(0xFF0C192C),
          appBg: Color(0xFFF0F7FF),
          cardBg: Color(0xFFFFFFFF),
          cardBorder: Color(0xFFDBEAFE),
          subtleBg: Color(0xFFF5FAFF),
          textMain: Color(0xFF0F172A),
          textMuted: Color(0xFF64748B),
          isDark: false,
        );
      case ErpThemeId.indigo:
        return const ErpPalette(
          primary: Color(0xFF4F46E5),
          primaryHover: Color(0xFF4338CA),
          primarySoft: Color(0xFFEEF2FF),
          primaryBorder: Color(0xFFC7D2FE),
          sidebarBg: Color(0xFF1E1B4B),
          appBg: Color(0xFFF3F4FB),
          cardBg: Color(0xFFFFFFFF),
          cardBorder: Color(0xFFE0E7FF),
          subtleBg: Color(0xFFF8FAFF),
          textMain: Color(0xFF0F172A),
          textMuted: Color(0xFF64748B),
          isDark: false,
        );
      case ErpThemeId.dark:
        return const ErpPalette(
          primary: Color(0xFFF97316),
          primaryHover: Color(0xFFEA580C),
          primarySoft: Color(0x28F97316),
          primaryBorder: Color(0x55F97316),
          sidebarBg: Color(0xFF070B14),
          appBg: Color(0xFF0B1120),
          cardBg: Color(0xFF111827),
          cardBorder: Color(0xFF1E293B),
          subtleBg: Color(0xFF1E293B),
          textMain: Color(0xFFF8FAFC),
          textMuted: Color(0xFF94A3B8),
          isDark: true,
        );
    }
  }

  @override
  ErpPalette copyWith({
    Color? primary,
    Color? primaryHover,
    Color? primarySoft,
    Color? primaryBorder,
    Color? sidebarBg,
    Color? appBg,
    Color? cardBg,
    Color? cardBorder,
    Color? subtleBg,
    Color? textMain,
    Color? textMuted,
    bool? isDark,
  }) {
    return ErpPalette(
      primary: primary ?? this.primary,
      primaryHover: primaryHover ?? this.primaryHover,
      primarySoft: primarySoft ?? this.primarySoft,
      primaryBorder: primaryBorder ?? this.primaryBorder,
      sidebarBg: sidebarBg ?? this.sidebarBg,
      appBg: appBg ?? this.appBg,
      cardBg: cardBg ?? this.cardBg,
      cardBorder: cardBorder ?? this.cardBorder,
      subtleBg: subtleBg ?? this.subtleBg,
      textMain: textMain ?? this.textMain,
      textMuted: textMuted ?? this.textMuted,
      isDark: isDark ?? this.isDark,
    );
  }

  @override
  ErpPalette lerp(ThemeExtension<ErpPalette>? other, double t) {
    if (other is! ErpPalette) return this;
    return ErpPalette(
      primary: Color.lerp(primary, other.primary, t)!,
      primaryHover: Color.lerp(primaryHover, other.primaryHover, t)!,
      primarySoft: Color.lerp(primarySoft, other.primarySoft, t)!,
      primaryBorder: Color.lerp(primaryBorder, other.primaryBorder, t)!,
      sidebarBg: Color.lerp(sidebarBg, other.sidebarBg, t)!,
      appBg: Color.lerp(appBg, other.appBg, t)!,
      cardBg: Color.lerp(cardBg, other.cardBg, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      subtleBg: Color.lerp(subtleBg, other.subtleBg, t)!,
      textMain: Color.lerp(textMain, other.textMain, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      isDark: t < 0.5 ? isDark : other.isDark,
    );
  }
}

ThemeData buildErpTheme(ErpThemeId id, {required bool isUrdu}) {
  final palette = ErpPalette.forTheme(id);
  final brightness = palette.isDark ? Brightness.dark : Brightness.light;
  final colorScheme = ColorScheme.fromSeed(
    seedColor: palette.primary,
    brightness: brightness,
    primary: palette.primary,
    surface: palette.cardBg,
  );

  final baseFont = isUrdu ? 'Noto Sans Arabic' : 'Plus Jakarta Sans';
  final fallbackFonts = isUrdu
      ? const ['Noto Sans Arabic', 'Plus Jakarta Sans', 'Segoe UI', 'sans-serif']
      : const ['Plus Jakarta Sans', 'Noto Sans Arabic', 'Segoe UI', 'sans-serif'];

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: palette.appBg,
    fontFamily: baseFont,
    fontFamilyFallback: fallbackFonts,
    extensions: [palette],
    cardTheme: CardThemeData(
      color: palette.cardBg,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: palette.cardBorder),
      ),
    ),
    dividerColor: palette.cardBorder,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: palette.subtleBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: palette.cardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: palette.cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: palette.primary, width: 1.6),
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return palette.primary;
        return Colors.transparent;
      }),
      side: BorderSide(color: palette.textMuted.withValues(alpha: 0.55), width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: palette.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
  );
}

extension ErpThemeContext on BuildContext {
  ErpPalette get erp => Theme.of(this).extension<ErpPalette>()!;
}
