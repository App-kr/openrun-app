import 'package:freezed_annotation/freezed_annotation.dart';

part 'performance.freezed.dart';
part 'performance.g.dart';

enum PerformanceCategory { classic, gugak, all }

@freezed
class Performance with _$Performance {
  const factory Performance({
    required String id,
    required String title,
    required String venue,
    required String region,
    required String category,
    required DateTime ticketOpenAt,
    String? posterUrl,
    String? bookingUrl,
    @Default(false) bool isHot,
    @Default(false) bool isFree,
    @Default(false) bool isNational,
    @Default(false) bool hasAlarm,
  }) = _Performance;

  factory Performance.fromJson(Map<String, dynamic> json) => _$PerformanceFromJson(json);
}

extension PerformanceX on Performance {
  bool get isUrgent {
    final diff = ticketOpenAt.difference(DateTime.now());
    return diff.isNegative == false && diff.inMinutes <= 30;
  }

  bool get isOpen {
    return DateTime.now().isAfter(ticketOpenAt);
  }

  Duration get timeUntilOpen {
    return ticketOpenAt.difference(DateTime.now());
  }
}
