import 'package:hive/hive.dart';
part 'chatModel.g.dart';

@HiveType(typeId: 0)
class ChatMessage extends HiveObject {
  @HiveField(0)
  final String message;

  @HiveField(1)
  final String userType;

  @HiveField(2)
  final DateTime timestamp;

  ChatMessage({
    required this.message,
    required this.userType,
    required this.timestamp,
  });
}
