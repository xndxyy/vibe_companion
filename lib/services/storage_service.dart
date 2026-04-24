import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  static const String _keyUserGender = 'user_gender';
  static const String _keyApi = 'api_key';
  static const String _keyApiProvider = 'api_provider';
  static const String _keyCharacterId = 'character_id';
  static const String _keyConversationName = 'conversation_name';
  static const String _keyCompanionName = 'companion_name';
  static const String _keyPersonality = 'personality';
  static const String _keyChatHistory = 'chat_history';
  static const String _keyUserAvatar = 'user_avatar_path';
  static const String _keyCompanionAvatar = 'companion_avatar_path';
  static const String _keyBackground = 'background_path';
  static const String _keyAutoReplyEnabled = 'auto_reply_enabled';
  static const String _keyAutoReplyMinutes = 'auto_reply_minutes';
  static const String _keyFirstLaunch = 'first_launch';

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  SharedPreferences get prefs {
    if (_prefs == null) throw StateError('StorageService not initialized');
    return _prefs!;
  }

  // User gender
  Future<void> setUserGender(int gender) async => await prefs.setInt(_keyUserGender, gender);
  int getUserGender() => prefs.getInt(_keyUserGender) ?? -1;

  // First launch
  bool isFirstLaunch() => prefs.getBool(_keyFirstLaunch) ?? true;
  Future<void> setFirstLaunchDone() async => await prefs.setBool(_keyFirstLaunch, false);

  // API
  String getApiKey() => prefs.getString(_keyApi) ?? '';
  Future<void> setApiKey(String v) async => await prefs.setString(_keyApi, v);
  String getApiProvider() => prefs.getString(_keyApiProvider) ?? 'openai';
  Future<void> setApiProvider(String v) async => await prefs.setString(_keyApiProvider, v);

  // Character
  String getCharacterId() => prefs.getString(_keyCharacterId) ?? '';
  Future<void> setCharacterId(String v) async => await prefs.setString(_keyCharacterId, v);

  // Conversation
  String getConversationName() => prefs.getString(_keyConversationName) ?? '我的对话';
  Future<void> setConversationName(String v) async => await prefs.setString(_keyConversationName, v);
  String getCompanionName() => prefs.getString(_keyCompanionName) ?? '小雨';
  Future<void> setCompanionName(String v) async => await prefs.setString(_keyCompanionName, v);
  String getPersonality() => prefs.getString(_keyPersonality) ?? '';
  Future<void> setPersonality(String v) async => await prefs.setString(_keyPersonality, v);

  // Chat history
  List<Map<String, dynamic>> getChatHistory() {
    final json = prefs.getString(_keyChatHistory) ?? '[]';
    try {
      final List<dynamic> list = jsonDecode(json);
      return list.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> setChatHistory(List<Map<String, dynamic>> messages) async {
    await prefs.setString(_keyChatHistory, jsonEncode(messages));
  }

  Future<void> clearChatHistory() async => await prefs.remove(_keyChatHistory);

  // Avatars
  String? getUserAvatar() => prefs.getString(_keyUserAvatar);
  Future<void> setUserAvatar(String? v) async {
    if (v != null) {
      await prefs.setString(_keyUserAvatar, v);
    } else {
      await prefs.remove(_keyUserAvatar);
    }
  }

  String? getCompanionAvatar() => prefs.getString(_keyCompanionAvatar);
  Future<void> setCompanionAvatar(String? v) async {
    if (v != null) {
      await prefs.setString(_keyCompanionAvatar, v);
    } else {
      await prefs.remove(_keyCompanionAvatar);
    }
  }

  String? getBackground() => prefs.getString(_keyBackground);
  Future<void> setBackground(String? v) async {
    if (v != null) {
      await prefs.setString(_keyBackground, v);
    } else {
      await prefs.remove(_keyBackground);
    }
  }

  // Auto reply
  bool getAutoReplyEnabled() => prefs.getBool(_keyAutoReplyEnabled) ?? false;
  Future<void> setAutoReplyEnabled(bool v) async => await prefs.setBool(_keyAutoReplyEnabled, v);
  int getAutoReplyMinutes() => prefs.getInt(_keyAutoReplyMinutes) ?? 10;
  Future<void> setAutoReplyMinutes(int v) async => await prefs.setInt(_keyAutoReplyMinutes, v);

  // One-click reset
  Future<void> resetAll() async {
    final keys = [
      _keyApi, _keyApiProvider, _keyCharacterId, _keyConversationName,
      _keyCompanionName, _keyPersonality, _keyChatHistory, _keyUserAvatar,
      _keyCompanionAvatar, _keyBackground, _keyAutoReplyEnabled,
      _keyAutoReplyMinutes,
    ];
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}