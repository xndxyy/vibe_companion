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
  static const String _keyCustomApiUrl = 'custom_api_url';
  static const String _keyCustomModel = 'custom_model';
  static const String _keyHiddenCharIds = 'hidden_char_ids';

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

  // Conversation (per character)
  String getConversationName([String? charId]) {
    final key = charId != null ? '${_keyConversationName}_$charId' : _keyConversationName;
    return prefs.getString(key) ?? '我的对话';
  }
  Future<void> setConversationName(String v, [String? charId]) async {
    final key = charId != null ? '${_keyConversationName}_$charId' : _keyConversationName;
    await prefs.setString(key, v);
  }
  String getCompanionName([String? charId]) {
    final key = charId != null ? '${_keyCompanionName}_$charId' : _keyCompanionName;
    return prefs.getString(key) ?? '';
  }
  Future<void> setCompanionName(String v, [String? charId]) async {
    final key = charId != null ? '${_keyCompanionName}_$charId' : _keyCompanionName;
    await prefs.setString(key, v);
  }
  String getPersonality([String? charId]) {
    final key = charId != null ? '${_keyPersonality}_$charId' : _keyPersonality;
    return prefs.getString(key) ?? '';
  }
  Future<void> setPersonality(String v, [String? charId]) async {
    final key = charId != null ? '${_keyPersonality}_$charId' : _keyPersonality;
    await prefs.setString(key, v);
  }

  // Chat history (per character)
  List<Map<String, dynamic>> getChatHistory([String? charId]) {
    final key = charId != null ? '${_keyChatHistory}_$charId' : _keyChatHistory;
    final json = prefs.getString(key) ?? '[]';
    try {
      final List<dynamic> list = jsonDecode(json);
      return list.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> setChatHistory(List<Map<String, dynamic>> messages, [String? charId]) async {
    final key = charId != null ? '${_keyChatHistory}_$charId' : _keyChatHistory;
    await prefs.setString(key, jsonEncode(messages));
  }

  Future<void> clearChatHistory([String? charId]) async {
    final key = charId != null ? '${_keyChatHistory}_$charId' : _keyChatHistory;
    await prefs.remove(key);
  }

  // Avatars
  String? getUserAvatar() => prefs.getString(_keyUserAvatar);
  Future<void> setUserAvatar(String? v) async {
    if (v != null) {
      await prefs.setString(_keyUserAvatar, v);
    } else {
      await prefs.remove(_keyUserAvatar);
    }
  }

  String? getCompanionAvatar([String? charId]) {
    final key = charId != null ? '${_keyCompanionAvatar}_$charId' : _keyCompanionAvatar;
    return prefs.getString(key);
  }
  Future<void> setCompanionAvatar(String? v, [String? charId]) async {
    final key = charId != null ? '${_keyCompanionAvatar}_$charId' : _keyCompanionAvatar;
    if (v != null) {
      await prefs.setString(key, v);
    } else {
      await prefs.remove(key);
    }
  }

  String? getBackground([String? charId]) {
    final key = charId != null ? '${_keyBackground}_$charId' : _keyBackground;
    return prefs.getString(key);
  }
  Future<void> setBackground(String? v, [String? charId]) async {
    final key = charId != null ? '${_keyBackground}_$charId' : _keyBackground;
    if (v != null) {
      await prefs.setString(key, v);
    } else {
      await prefs.remove(key);
    }
  }

  // Auto reply
  bool getAutoReplyEnabled() => prefs.getBool(_keyAutoReplyEnabled) ?? false;
  Future<void> setAutoReplyEnabled(bool v) async => await prefs.setBool(_keyAutoReplyEnabled, v);
  int getAutoReplyMinutes() => prefs.getInt(_keyAutoReplyMinutes) ?? 10;
  Future<void> setAutoReplyMinutes(int v) async => await prefs.setInt(_keyAutoReplyMinutes, v);

  // Custom API
  String getCustomApiUrl() => prefs.getString(_keyCustomApiUrl) ?? '';
  Future<void> setCustomApiUrl(String v) async => await prefs.setString(_keyCustomApiUrl, v);
  String getCustomModel() => prefs.getString(_keyCustomModel) ?? '';
  Future<void> setCustomModel(String v) async => await prefs.setString(_keyCustomModel, v);

  // Hidden characters
  List<String> getHiddenCharIds() {
    final json = prefs.getString(_keyHiddenCharIds) ?? '[]';
    try {
      return List<String>.from(jsonDecode(json));
    } catch (_) {
      return [];
    }
  }
  Future<void> setHiddenCharIds(List<String> ids) async =>
      await prefs.setString(_keyHiddenCharIds, jsonEncode(ids));

  // Custom characters
  static const String _keyCustomChars = 'custom_characters';
  List<Map<String, dynamic>> getCustomCharacters() {
    final json = prefs.getString(_keyCustomChars) ?? '[]';
    try {
      return List<Map<String, dynamic>>.from(
        (jsonDecode(json) as List).map((e) => Map<String, dynamic>.from(e)),
      );
    } catch (_) {
      return [];
    }
  }
  Future<void> setCustomCharacters(List<Map<String, dynamic>> chars) async =>
      await prefs.setString(_keyCustomChars, jsonEncode(chars));

  // One-click reset
  Future<void> resetAll() async {
    // Remove all keys including per-character keys
    final allKeys = prefs.getKeys().toList();
    for (final key in allKeys) {
      await prefs.remove(key);
    }
  }
}