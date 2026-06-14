import 'package:hive/hive.dart';

part 'user_profile.g.dart';

@HiveType(typeId: 8)
class UserProfile extends HiveObject {
  @HiveField(0)
  String name;

  UserProfile({
    required this.name,
  });
}
