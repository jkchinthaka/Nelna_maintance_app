import 'package:flutter/material.dart';

class AppColors {
  // ── Primary Palette (Modern Nelna Brand) ─────────────────────────────
  static const Color primary = Color(0xFF17663A); // Deep modern green
  static const Color primaryLight = Color(0xFF2F8A57); // Fresh green
  static const Color primaryDark = Color(0xFF0D2F1C); // Ink green

  // ── Secondary & Accent ────────────────────────────────────────────────
  static const Color secondary = Color(0xFF233044); // Slate navy
  static const Color accent = Color(0xFFF59E0B); // Amber / Gold
  static const Color accentLight = Color(0xFFFBBF24); // Light Amber

  // ── Semantic Colors ───────────────────────────────────────────────────
  static const Color success = Color(0xFF10B981); // Bright Green
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color error = Color(0xFFEF4444); // Rose Red
  static const Color info = Color(0xFF3B82F6); // Blue

  // ── Backgrounds & Surfaces ────────────────────────────────────────────
  // Light mode
  static const Color background = Color(0xFFF4F7F5); // Soft neutral mist
  static const Color surface = Color(0xFFFFFFFF); // Pure white
  static const Color surfaceAlt = Color(0xFFF8FAFC); // Subtle cool surface
  static const Color shellBackground = Color(0xFFF0F5F1); // App frame

  // ── Text ──────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF0F172A); // Almost black slate
  static const Color textSecondary = Color(0xFF64748B); // Slate gray

  // ── Borders & Dividers ────────────────────────────────────────────────
  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFF1F5F9);
  static const Color subtleBorder = Color(0xFFD8E2D9);

  // ── Status Colors (aliases) ───────────────────────────────────────────
  static const Color statusActive = success;
  static const Color statusInactive = error;
  static const Color statusPending = warning;
  static const Color statusInProgress = info;

  // ── Dark Theme Overrides ──────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF07111A); // Deep navy
  static const Color darkSurface = Color(0xFF0F1A25); // Dark slate
  static const Color darkCard = Color(0xFF162232); // Elevated dark card
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkBorder = Color(0xFF334155);
  static const Color darkDivider = Color(0xFF1E293B);
}
