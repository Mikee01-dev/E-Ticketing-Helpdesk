import 'package:flutter/material.dart';

// ==================== WARNA ====================
class AppColors {
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color primaryLight = Color(0xFF60A5FA);
  
  static const Color secondary = Color(0xFF7C3AED);
  static const Color secondaryDark = Color(0xFF6D28D9);
  static const Color secondaryLight = Color(0xFFA78BFA);
  
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
  
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color text = Color(0xFF1E293B);
  static const Color textLight = Color(0xFF64748B);
  static const Color border = Color(0xFFE2E8F0);
  
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color textDark = Color(0xFFF1F5F9);
  static const Color borderDark = Color(0xFF334155);
}

// ==================== SPACING ====================
class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

// ==================== BORDER RADIUS ====================
class AppBorderRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double full = 9999.0;
}

// ==================== FONT SIZE ====================
class AppFontSize {
  static const double xs = 12.0;
  static const double sm = 14.0;
  static const double md = 16.0;
  static const double lg = 18.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;
}

// ==================== TICKET STATUS ====================
class TicketStatus {
  static const String open = 'open';
  static const String inProgress = 'in_progress';
  static const String resolved = 'resolved';
  static const String closed = 'closed';
  
  static List<String> get all => [open, inProgress, resolved, closed];
  
  static String getDisplayName(String status) {
    switch (status) {
      case open: return 'Open';
      case inProgress: return 'In Progress';
      case resolved: return 'Resolved';
      case closed: return 'Closed';
      default: return status;
    }
  }
  
  static Color getColor(String status) {
    switch (status) {
      case open: return AppColors.warning;
      case inProgress: return AppColors.info;
      case resolved: return AppColors.success;
      case closed: return AppColors.textLight;
      default: return AppColors.textLight;
    }
  }
}

// ==================== TICKET PRIORITY ====================
class TicketPriority {
  static const String low = 'low';
  static const String medium = 'medium';
  static const String high = 'high';
  static const String urgent = 'urgent';
  
  static List<String> get all => [low, medium, high, urgent];
  
  static String getDisplayName(String priority) {
    switch (priority) {
      case low: return 'Low';
      case medium: return 'Medium';
      case high: return 'High';
      case urgent: return 'Urgent';
      default: return priority;
    }
  }
  
  static Color getColor(String priority) {
    switch (priority) {
      case low: return AppColors.success;
      case medium: return AppColors.warning;
      case high: return AppColors.error;
      case urgent: return AppColors.error;
      default: return AppColors.textLight;
    }
  }
}

// ==================== USER ROLE ====================
class UserRole {
  static const String user = 'user';
  static const String helpdesk = 'helpdesk';
  static const String admin = 'admin';
  
  static List<String> get all => [user, helpdesk, admin];
  
  static bool isAdmin(String role) => role == admin;
  static bool isHelpdesk(String role) => role == helpdesk || role == admin;
  static bool isUser(String role) => role == user;
}

// ==================== STORAGE ====================
class StorageConstants {
  static const String ticketImagesBucket = 'ticket_images';
  static const int maxImageSizeMB = 2;
  static const int maxImageWidth = 1200;
  static const int maxImageHeight = 1200;
  static const int imageQuality = 75;
}