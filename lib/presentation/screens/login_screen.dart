import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/repository/erp_store.dart';
import '../widgets/common_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.store});

  final ErpStore store;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _rememberMe = true;
  String? _errorMsg;

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final err = widget.store.login(
      _userCtrl.text,
      _passCtrl.text,
      rememberMe: _rememberMe,
    );
    if (err != null) {
      setState(() => _errorMsg = err);
    } else {
      setState(() => _errorMsg = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final erp = context.erp;
    final isUrdu = widget.store.isUrdu;
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 900;

    final formCard = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: erp.cardBg,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: erp.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: erp.isDark ? 0.35 : 0.06),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!isWide) ...[
              const Center(child: BolanLogoBadge(size: 92, isCircle: true)),
              const SizedBox(height: 14),
              Text(
                tr(isUrdu, 'BOLAN GASOLINE', 'بولان گیسولین'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: erp.textMain,
                ),
              ),
              Text(
                tr(isUrdu, 'Petrol & Diesel Pump ERP',
                    'پٹرول اور ڈیزل پمپ سسٹم'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: erp.textMuted,
                ),
              ),
              const SizedBox(height: 20),
            ],
            Text(
              tr(isUrdu, 'Sign In to ERP', 'سسٹم میں لاگ ان کریں'),
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w900,
                color: erp.textMain,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              tr(
                isUrdu,
                'Enter your Owner or Employee credentials — role & permissions load automatically.',
                'اپنا مالک یا ملازم یوزر نیم اور پاس ورڈ درج کریں — رول خود بخود پہچان لیا جائے گا۔',
              ),
              style: TextStyle(fontSize: 12, color: erp.textMuted),
            ),
            const SizedBox(height: 20),
            if (_errorMsg != null) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: erp.dangerSoft,
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: erp.danger.withValues(alpha: 0.35)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline_rounded,
                        size: 18, color: erp.danger),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMsg!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: erp.danger,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],
            TextField(
              controller: _userCtrl,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: tr(isUrdu, 'Username', 'یوزر نیم'),
                hintText: 'owner / staff',
                prefixIcon: const Icon(Icons.person_outline_rounded),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _passCtrl,
              obscureText: _obscurePass,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: tr(isUrdu, 'Password / PIN', 'پاس ورڈ / پن'),
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  onPressed: () =>
                      setState(() => _obscurePass = !_obscurePass),
                  icon: Icon(_obscurePass
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Checkbox(
                  value: _rememberMe,
                  onChanged: (v) => setState(() => _rememberMe = v ?? true),
                ),
                Expanded(
                  child: Text(
                    tr(isUrdu, 'Keep me signed in', 'لاگ ان محفوظ رکھیں'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: erp.textMuted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 48,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: erp.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _submit,
                icon: const Icon(Icons.login_rounded, size: 19),
                label: Text(
                  tr(isUrdu, 'Sign In', 'لاگ ان کریں'),
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return Scaffold(
      backgroundColor: erp.appBg,
      body: SafeArea(
        child: Column(
          children: [
            // Top Utility Bar (Language toggle)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(
                      backgroundColor: erp.primarySoft,
                      foregroundColor: erp.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999)),
                    ),
                    onPressed: widget.store.toggleLanguage,
                    icon: const Icon(Icons.translate_rounded, size: 16),
                    label: Text(
                      isUrdu ? 'English' : 'اردو',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: isWide
                  ? Row(
                      children: [
                        // Left Luxury Minimal Branding Panel (Circular Logo & Name Only)
                        Expanded(
                          flex: 5,
                          child: Container(
                            margin: const EdgeInsets.fromLTRB(24, 0, 12, 24),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.24),
                                  blurRadius: 34,
                                  offset: const Offset(0, 14),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(28),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      erp.sidebarBg,
                                      Color.lerp(
                                          erp.sidebarBg, erp.primary, 0.24)!,
                                      Color.lerp(
                                          erp.sidebarBg, erp.primary, 0.36)!,
                                    ],
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    // Soft ambient circles (cleanly clipped inside borderRadius)
                                    Positioned(
                                      top: -80,
                                      right: -80,
                                      child: Container(
                                        width: 260,
                                        height: 260,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: erp.primary
                                              .withValues(alpha: 0.14),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: -100,
                                      left: -70,
                                      child: Container(
                                        width: 280,
                                        height: 280,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white
                                              .withValues(alpha: 0.04),
                                        ),
                                      ),
                                    ),
                                    Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(36),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            // Outer halo ring + big crisp circular logo
                                            Container(
                                              padding: const EdgeInsets.all(14),
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Colors.white
                                                    .withValues(alpha: 0.06),
                                                border: Border.all(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.18),
                                                  width: 1.5,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: erp.primary
                                                        .withValues(
                                                            alpha: 0.34),
                                                    blurRadius: 42,
                                                    spreadRadius: 4,
                                                  ),
                                                ],
                                              ),
                                              child: const BolanLogoBadge(
                                                size: 172,
                                                isCircle: true,
                                              ),
                                            ),
                                            const SizedBox(height: 32),
                                            Text(
                                              tr(isUrdu, 'BOLAN GASOLINE',
                                                  'بولان گیسولین'),
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 36,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: 1.8,
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            Container(
                                              width: 72,
                                              height: 3.5,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    erp.primary
                                                        .withValues(alpha: 0.4),
                                                    erp.primary,
                                                    erp.primary
                                                        .withValues(alpha: 0.4),
                                                  ],
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(99),
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              tr(
                                                isUrdu,
                                                'PETROL & DIESEL STATION',
                                                'پٹرول اور ڈیزل اسٹیشن',
                                              ),
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: Colors.white
                                                    .withValues(alpha: 0.78),
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing:
                                                    isUrdu ? 0.2 : 2.6,
                                              ),
                                            ),
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
                        // Right Login Card
                        Expanded(
                          flex: 6,
                          child: Center(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(24),
                              child: formCard,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: formCard,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
