import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class AppUtils {
  AppUtils._();

  /// Formats date for card subtitles: e.g. "Today, 4:15 PM" or "Oct 12, 2026"
  static String formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final itemDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    final timeString = DateFormat.jm().format(dateTime);

    if (itemDate == today) {
      return 'Today, $timeString';
    } else if (itemDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday, $timeString';
    } else if (now.year == dateTime.year) {
      return '${DateFormat.MMMd().format(dateTime)}, $timeString';
    } else {
      return '${DateFormat.yMMMd().format(dateTime)}, $timeString';
    }
  }

  /// Formats detailed timestamp with both date and exact time.
  static String formatDetailedDateTime(DateTime dateTime) {
    return DateFormat('EEE, MMM d, yyyy • h:mm a').format(dateTime);
  }

  /// Trims and prepends https:// if scheme is missing.
  static String normalizeUrl(String rawUrl) {
    var trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return '';

    // Check if starts with a known scheme
    final hasScheme = RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*://').hasMatch(trimmed);
    if (!hasScheme) {
      trimmed = 'https://$trimmed';
    }
    return trimmed;
  }

  /// Checks if the string is a valid HTTP/HTTPS URL.
  static bool isValidUrl(String rawUrl) {
    final normalized = normalizeUrl(rawUrl);
    final uri = Uri.tryParse(normalized);
    if (uri == null) return false;
    return (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  /// Extracts domain / host name cleanly.
  static String extractDomain(String rawUrl) {
    try {
      final uri = Uri.parse(normalizeUrl(rawUrl));
      if (uri.host.isNotEmpty) {
        return uri.host.replaceFirst(RegExp(r'^www\.'), '');
      }
    } catch (_) {}
    return rawUrl;
  }

  /// Safely attempts to open a URL in the browser, showing feedback if it fails.
  static Future<bool> openUrl(BuildContext context, String rawUrl) async {
    final normalized = normalizeUrl(rawUrl);
    final uri = Uri.tryParse(normalized);

    if (uri == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid web address format.')),
        );
      }
      return false;
    }

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open link: $normalized')),
        );
      }
      return launched;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to open link: $e')));
      }
      return false;
    }
  }

  /// Copies text to clipboard and displays brief snackbar confirmation.
  static Future<void> copyToClipboard(
    BuildContext context,
    String text, {
    String message = 'Copied to clipboard',
  }) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
