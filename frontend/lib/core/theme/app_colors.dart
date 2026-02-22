import 'package:flutter/material.dart';

class AppColors {
  // ── Primary Palette ───────────────────────────────────────────────────
  static const Color primary = Color(0xFF1B4F72);
  static const Color primaryLight = Color(0xFF2E86C1);
  static const Color primaryDark = Color(0xFF154360);

  // ── Secondary & Accent ────────────────────────────────────────────────
  static const Color secondary = Color(0xFF148F77);
  static const Color accent = Color(0xFFF39C12);

  // ── Semantic Colors ───────────────────────────────────────────────────
  static const Color success = Color(0xFF27AE60);
  static const Color warning = Color(0xFFF39C12);
  static const Color error = Color(0xFFE74C3C);
  static const Color info = Color(0xFF3498DB);

  // ── Backgrounds & Surfaces ────────────────────────────────────────────
  static const Color background = Color(0xFFF5F6FA);
  static const Color surface = Color(0xFFFFFFFF);

  // ── Text ──────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF2C3E50);
  static const Color textSecondary = Color(0xFF7F8C8D);

  // ── Borders & Dividers ────────────────────────────────────────────────
  static const Color border = Color(0xFFDDE1E6);
  static const Color divider = Color(0xFFE8EAED);

  // ── Status Colors (aliases) ───────────────────────────────────────────
  static const Color statusActive = success;
  static const Color statusInactive = error;
  static const Color statusPending = warning;
  static const Color statusInProgress = info;

  // ── Dark Theme Overrides ──────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkCard = Color(0xFF2C2C2C);
  static const Color darkTextPrimary = Color(0xFFECEFF1);
  static const Color darkTextSecondary = Color(0xFFB0BEC5);
  static const Color darkBorder = Color(0xFF424242);
  static const Color darkDivider = Color(0xFF373737);
}
