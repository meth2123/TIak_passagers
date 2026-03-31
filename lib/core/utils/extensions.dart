extension StringExtensions on String {
  /// Capitalize first letter
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }

  /// Check if valid email
  bool get isValidEmail {
    return RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(this);
  }

  /// Check if valid phone (Senegal)
  bool get isValidPhone {
    final cleaned = replaceAll(RegExp(r'[^\d]'), '');
    return cleaned.length == 12 && cleaned.startsWith('221');
  }

  /// Remove all non-digit characters
  String get digitsOnly {
    return replaceAll(RegExp(r'[^\d]'), '');
  }

  /// Truncate string with ellipsis
  String truncate(int length) {
    if (this.length <= length) return this;
    return '${substring(0, length)}...';
  }

  /// Format as phone number (+221 XX XXX XX XX)
  String get asPhoneNumber {
    String cleaned = digitsOnly;
    if (!cleaned.startsWith('221')) {
      cleaned = '221${cleaned.replaceFirst(RegExp(r'^0'), '')}';
    }
    if (cleaned.length == 12) {
      return '+${cleaned.substring(0, 3)} ${cleaned.substring(3, 5)} ${cleaned.substring(5, 8)} ${cleaned.substring(8)}';
    }
    return '+$cleaned';
  }
}

extension NumExtensions on num {
  /// Format as currency FCFA
  String get asCurrency {
    return '${toStringAsFixed(0).replaceAll(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), r'$1 ')} FCFA';
  }

  /// Format as distance
  String get asDistance {
    if (this < 1) {
      return '${(this * 1000).toInt()} m';
    }
    return '${toStringAsFixed(1)} km';
  }
}

extension DateTimeExtensions on DateTime {
  /// Format as "HH:mm"
  String get timeOnly {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  /// Format as "dd/MM/yyyy"
  String get dateOnly {
    return '${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}/$year';
  }

  /// Format as "dd/MM/yyyy HH:mm"
  String get dateTime {
    return '$dateOnly $timeOnly';
  }

  /// Check if today
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Check if tomorrow
  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return year == tomorrow.year &&
        month == tomorrow.month &&
        day == tomorrow.day;
  }

  /// Get relative time (e.g., "2 minutes ago")
  String get relative {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.inSeconds < 60) {
      return 'À l\'instant';
    } else if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inDays == 1) {
      return 'Hier';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays}j';
    } else {
      return dateTime;
    }
  }
}

