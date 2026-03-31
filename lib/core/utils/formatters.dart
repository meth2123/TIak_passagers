import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

class FormatUtils {
  /// Format currency (FCFA)
  static String formatCurrency(int amount) {
    final formatter = NumberFormat('#,###');
    return '${formatter.format(amount)} FCFA';
  }

  /// Format distance
  static String formatDistance(double km) {
    if (km < 1) {
      return '${(km * 1000).toInt()} m';
    }
    return '${km.toStringAsFixed(1)} km';
  }

  /// Format duration
  static String formatDuration(int minutes) {
    if (minutes < 60) {
      return '~$minutes min';
    }
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '~${hours}h ${mins}min';
  }

  /// Format phone number (+221 format)
  static String formatPhoneNumber(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (!cleaned.startsWith('+')) {
      cleaned = '+221${cleaned.replaceFirst(RegExp(r'^0'), '')}';
    }
    return cleaned;
  }

  /// Validate Senegal phone number
  static bool isValidSenegalPhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');
    // Sénégal phone: +221 + 9 digits
    return cleaned.length == 12 && cleaned.startsWith('221');
  }

  /// Format date time
  static String formatDateTime(DateTime dateTime) {
    final formatter = DateFormat('dd/MM/yyyy HH:mm');
    return formatter.format(dateTime);
  }

  /// Format time only
  static String formatTime(DateTime dateTime) {
    final formatter = DateFormat('HH:mm');
    return formatter.format(dateTime);
  }

  /// Get relative time (e.g., "2 minutes ago")
  static String getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'À l\'instant';
    } else if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays}j';
    } else {
      return formatDateTime(dateTime);
    }
  }
}

class ValidationUtils {
  /// Validate email
  static bool isValidEmail(String email) {
    return RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(email);
  }

  /// Validate password
  static bool isValidPassword(String password) {
    // Min 8 chars, at least one uppercase, one digit
    return password.length >= 8 &&
        RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[0-9]').hasMatch(password);
  }

  /// Get password strength text
  static String getPasswordStrength(String password) {
    if (password.isEmpty) return '';
    if (password.length < 6) return 'Faible';
    if (password.length < 8) return 'Moyen';
    if (RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[0-9]').hasMatch(password)) {
      return 'Fort';
    }
    return 'Moyen';
  }
}

class DateTimeUtils {
  /// Check if time is between two times
  static bool isTimeBetween(
    TimeOfDay current,
    TimeOfDay start,
    TimeOfDay end,
  ) {
    // Convert to minutes for easier comparison
    int currentMin = current.hour * 60 + current.minute;
    int startMin = start.hour * 60 + start.minute;
    int endMin = end.hour * 60 + end.minute;

    // Handle overnight ranges
    if (startMin > endMin) {
      return currentMin >= startMin || currentMin < endMin;
    }
    return currentMin >= startMin && currentMin < endMin;
  }

  /// Get time difference in days
  static int getDaysDifference(DateTime date1, DateTime date2) {
    return date1.difference(date2).inDays.abs();
  }

  /// Check if date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}

