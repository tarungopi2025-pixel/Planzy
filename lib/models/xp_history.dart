import 'package:hive/hive.dart';

part 'xp_history.g.dart';

@HiveType(typeId: 6)
class XPHistory extends HiveObject {
  @HiveField(0)
  DateTime date;

  @HiveField(1)
  int xpEarned;

  @HiveField(2)
  int tasksCompleted;

  @HiveField(3)
  double productivityScore;

  XPHistory({
    required this.date,
    required this.xpEarned,
    required this.tasksCompleted,
    required this.productivityScore,
  });
}
