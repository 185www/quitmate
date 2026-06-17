extension IntExtensions on int {
  String toChineseMoney() {
    if (this < 10000) return '¥$this';
    else if (this < 100000000) return '¥${(this / 10000).toStringAsFixed(1)}万';
    else return '¥${(this / 100000000).toStringAsFixed(2)}亿';
  }
  String toChineseDays() {
    if (this < 30) return '$this天';
    else if (this < 365) {
      final months = (this / 30).floor();
      final days = this % 30;
      return days > 0 ? '$months个月$days天' : '$months个月';
    } else {
      final years = (this / 365).floor();
      final months = ((this % 365) / 30).floor();
      return months > 0 ? '$years年$months个月' : '$years年';
    }
  }
}