/// 과거 시각을 "방금 전 / N분 전 / N시간 전 / N일 전" 으로 표현한다(BK 공용).
///
/// 외부 패키지 없이 [DateTime.difference] 만으로 계산한다.
String bookRelativeTime(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inDays >= 1) return '${diff.inDays}일 전';
  if (diff.inHours >= 1) return '${diff.inHours}시간 전';
  if (diff.inMinutes >= 1) return '${diff.inMinutes}분 전';
  return '방금 전';
}
