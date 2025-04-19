/// Utility functions for working with DateTime objects.
class DateTimeUtils {
  /// Returns a DateTime object representing the date part only (time set to 00:00:00).
  static DateTime dateOnly(DateTime dt) {
    return DateTime(dt.year, dt.month, dt.day);
  }

  /// Checks if two DateTime objects represent the same date (ignoring time).
  static bool isSameDate(DateTime dt1, DateTime dt2) {
    return dt1.year == dt2.year && dt1.month == dt2.month && dt1.day == dt2.day;
  }
}
