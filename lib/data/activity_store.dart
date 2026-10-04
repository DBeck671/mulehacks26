import 'package:shared_preferences/shared_preferences.dart';

abstract class ActivityStore {
  Future<String?> read();
  Future<void> write(String value);
}

class LocalActivityStore implements ActivityStore {
  LocalActivityStore(String accountId)
    : key = 'sidequest.activity.v1.$accountId';
  final String key;
  final preferences = SharedPreferencesAsync();

  @override
  Future<String?> read() => preferences.getString(key);
  @override
  Future<void> write(String value) => preferences.setString(key, value);
}
