import 'package:flutter/material.dart';

class AppColors {
  // ── Primary Palette (Nelna Theme - Modern Eco/Agri Enterprise) ────────
  static const Color primary = Color(0xFF0F5132); // Deep Forest Green
  static const Color primaryLight = Color(0xFF28794C); // Soft Green
  static const Color primaryDark = Color(0xFF073A21); // Very Dark Green

  // ── Secondary & Accent ────────────────────────────────────────────────
  static const Color secondary = Color(0xFF1E293B); // Slate
  static const Color accent = Color(0xFFF59E0B); // Amber / Gold
  static const Color accentLight = Color(0xFFFBBF24); // Light Amber

  // ── Semantic Colors ───────────────────────────────────────────────────
  static const Color success = Color(0xFF10B981); // Bright Green
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color error = Color(0xFFEF4444); // Rose Red
  static const Color info = Color(0xFF3B82F6); // Blue

  // ── Backgrounds & Surfaces ────────────────────────────────────────────
  // Light mode
  static const Color background = Color(0xFFF8FAFC); // Very light slate
  static const Color surface = Color(0xFFFFFFFF); // Pure white

  // ── Text ──────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF0F172A); // Almost blackslate
  static const Color textSecondary = Color(0xFF64748B); // Slate gray

  // ── Borders & Dividers ────────────────────────────────────────────────
  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFF1F5F9);

  // ── Status Colors (aliases) ───────────────────────────────────────────
  static const Color statusActive = success;
  static const Color statusInactive = error;
  static const Color statusPending = warning;
  static const Color statusInProgress = info;

  // ── Dark Theme Overrides ──────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF0B1120); // Deep navy/black
  static const Color darkSurface = Color(0xFF141E33); // Dark slate
  static const Color darkCard = Color(0xFF1E293B); // Slightly lighter slate
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkBorder = Color(0xFF334155);
  static const Color darkDivider = Color(0xFF1E293B);
}
