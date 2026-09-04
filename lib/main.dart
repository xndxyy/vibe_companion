import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'models/character_data.dart';
import 'services/storage_service.dart';

// ============================================================
// App Entry
// ============================================================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService().init();
  runApp(const AiCompanionApp());
}

// ============================================================
// Theme
// ============================================================
class AiCompanionApp extends StatelessWidget {
  const AiCompanionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AiCompanion',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F0F1A),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFec4899),
          brightness: Brightness.dark,
          surface: const Color(0xFF1A1A2E),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Color(0xFF0F0F1A),
          surfaceTintColor: Colors.transparent,
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF252540),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          color: const Color(0xFF1A1A2E),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: const Color(0xFF2A2A4A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          behavior: SnackBarBehavior.floating,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

// ============================================================
// Splash / Gender Selection Screen
// ============================================================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<double> _scale;
  bool _showGenderSelect = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _fade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _scale = Tween<double>(begin: 0.6, end: 1).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    _controller.forward();

    // 已选过性别且有角色 → 直接跳转
    final storage = StorageService();
    final gender = storage.getUserGender();
    final savedCharId = storage.getCharacterId();
    if (gender != -1 && savedCharId.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => ChatScreen(characterId: savedCharId),
            transitionDuration: const Duration(milliseconds: 500),
            transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
          ),
        );
      });
    } else if (gender != -1) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const SetupScreen(),
            transitionDuration: const Duration(milliseconds: 500),
            transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
          ),
        );
      });
    } else {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) setState(() => _showGenderSelect = true);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _selectGender(int gender) async {
    await StorageService().setUserGender(gender);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const SetupScreen(),
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [
            Color(0xFF1A0A2E),
            Color(0xFF0F0F1A),
          ]),
        ),
        child: SafeArea(
          child: AnimatedBuilder(animation: _controller, builder: (_, __) {
            return FadeTransition(
              opacity: _fade,
              child: ScaleTransition(
                scale: _scale,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 100, height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(colors: [Color(0xFFec4899), Color(0xFF8B5CF6)]),
                          boxShadow: [BoxShadow(color: const Color(0xFFec4899).withValues(alpha: 0.4), blurRadius: 30, spreadRadius: 5)],
                        ),
                        child: const Icon(Icons.favorite, color: Colors.white, size: 50),
                      ),
                      const SizedBox(height: 24),
                      const Text('AiCompanion', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Text('你的专属 AI 伴侣', style: TextStyle(fontSize: 16, color: Colors.white54)),
                      const SizedBox(height: 60),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        child: _showGenderSelect
                            ? _buildGenderSelect()
                            : const SizedBox(height: 120),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildGenderSelect() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        key: const ValueKey('gender-select'),
        children: [
          const Text('选择你的性别', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _GenderCard(
                  icon: Icons.male,
                  label: '男',
                  color: const Color(0xFF3B82F6),
                  onTap: () => _selectGender(0),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _GenderCard(
                  icon: Icons.female,
                  label: '女',
                  color: const Color(0xFFec4899),
                  onTap: () => _selectGender(1),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GenderCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _GenderCard({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 2),
        ),
        child: Column(
          children: [
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.2)),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(height: 12),
            Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Setup / Character Select Screen
// ============================================================
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _apiKeyController = TextEditingController();
  final _apiUrlController = TextEditingController();
  final _customModelController = TextEditingController();
  String _apiProvider = 'openai';
  String? _selectedCharId;
  int _viewMode = 0;

  bool _isTesting = false;
  bool? _testResult;
  String? _testMessage;

  int _userGender = -1;
  Set<String> _hiddenCharIds = {};

  @override
  void initState() {
    super.initState();
    _userGender = StorageService().getUserGender();
    _apiKeyController.text = StorageService().getApiKey();
    _apiProvider = StorageService().getApiProvider();
    _selectedCharId = StorageService().getCharacterId().isNotEmpty ? StorageService().getCharacterId() : null;
    _apiUrlController.text = StorageService().getCustomApiUrl();
    _customModelController.text = StorageService().getCustomModel();
    _hiddenCharIds = StorageService().getHiddenCharIds().toSet();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _apiUrlController.dispose();
    _customModelController.dispose();
    super.dispose();
  }

  List<Character> get _filteredChars {
    final all = _viewMode == 2
        ? [...femaleCompanions, ...maleCompanions, psychologist]
        : _userGender == 1 ? maleCompanions : femaleCompanions;
    return all.where((c) => !_hiddenCharIds.contains(c.id)).toList();
  }

  Future<void> _testApi() async {
    if (_apiKeyController.text.trim().isEmpty) {
      setState(() { _testResult = false; _testMessage = '请先填写 API Key'; });
      return;
    }
    setState(() { _isTesting = true; _testResult = null; _testMessage = null; });

    final url = _getApiUrl();
    final headers = _getApiHeaders();
    final model = _getDefaultModel(false);
    Map<String, dynamic> body;

    if (_apiProvider == 'anthropic') {
      body = {'model': model, 'messages': [{'role': 'user', 'content': 'hi'}], 'max_tokens': 5};
    } else if (_apiProvider == 'google') {
      setState(() { _isTesting = false; _testResult = true; _testMessage = '✓ API 已配置（Google Gemini 请在对话中验证）'; });
      return;
    } else {
      body = {'model': model, 'messages': [{'role': 'user', 'content': 'hi'}], 'max_tokens': 5};
    }

    try {
      final resp = await http.post(Uri.parse(url), headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode == 200) {
        setState(() { _isTesting = false; _testResult = true; _testMessage = '✓ API 连接成功！'; });
      } else {
        String msg = '错误 ${resp.statusCode}';
        try {
          final b = jsonDecode(resp.body);
          msg = b['error']?['message'] ?? b['message'] ?? msg;
        } catch (_) {}
        setState(() { _isTesting = false; _testResult = false; _testMessage = msg; });
      }
    } catch (e) {
      setState(() { _isTesting = false; _testResult = false; _testMessage = '连接失败：$e'; });
    }
  }

  String _getSelectedCharName() {
    final c = allCharacters.cast<Character?>().firstWhere((c) => c!.id == _selectedCharId, orElse: () => null);
    if (c != null) return c.name;
    final customs = StorageService().getCustomCharacters();
    final custom = customs.cast<Map<String, dynamic>?>().firstWhere((m) => m!['id'] == _selectedCharId, orElse: () => null);
    return custom?['name'] ?? '伴侣';
  }

  Future<void> _enterChat() async {
    if (_apiKeyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请先填写 API Key')));
      return;
    }
    if (_selectedCharId == null || _selectedCharId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请先选择一个伴侣')));
      return;
    }

    await StorageService().setApiKey(_apiKeyController.text.trim());
    await StorageService().setApiProvider(_apiProvider);
    await StorageService().setCharacterId(_selectedCharId!);
    await StorageService().setCustomApiUrl(_apiUrlController.text.trim());
    await StorageService().setCustomModel(_customModelController.text.trim());

    final char = allCharacters.cast<Character?>().firstWhere((c) => c!.id == _selectedCharId, orElse: () => null);
    if (char != null) {
      await StorageService().setCompanionName(char.name);
      await StorageService().setPersonality(char.personality);
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => ChatScreen(characterId: _selectedCharId!)),
    );
  }

  String _getApiUrl() {
    switch (_apiProvider) {
      case 'openai': return 'https://api.openai.com/v1/chat/completions';
      case 'anthropic': return 'https://api.anthropic.com/v1/messages';
      case 'google': return 'https://generativelanguage.googleapis.com/v1beta/models';
      case 'dashscope': return 'https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions';
      case 'custom':
        return _apiUrlController.text.trim().isNotEmpty
            ? _apiUrlController.text.trim()
            : 'https://api.example.com/v1/chat/completions';
      default: return 'https://api.openai.com/v1/chat/completions';
    }
  }

  Map<String, String> _getApiHeaders() {
    final key = _apiKeyController.text.trim();
    switch (_apiProvider) {
      case 'openai': return {'Content-Type': 'application/json', 'Authorization': 'Bearer $key'};
      case 'anthropic': return {'Content-Type': 'application/json', 'x-api-key': key, 'anthropic-version': '2023-06-01'};
      case 'dashscope': return {'Content-Type': 'application/json', 'Authorization': 'Bearer $key'};
      case 'custom': return {'Content-Type': 'application/json', 'Authorization': 'Bearer $key'};
      case 'google': return {'Content-Type': 'application/json'};
      default: return {'Content-Type': 'application/json', 'Authorization': 'Bearer $key'};
    }
  }

  String _getDefaultModel(bool vision) {
    switch (_apiProvider) {
      case 'openai': return vision ? 'gpt-4o' : 'gpt-3.5-turbo';
      case 'anthropic': return vision ? 'claude-3-opus-20240229' : 'claude-3-haiku-20240307';
      case 'google': return vision ? 'gemini-1.5-pro' : 'gemini-1.0-pro';
      case 'dashscope': return vision ? 'qwen-vl-plus' : 'qwen-turbo';
      case 'custom': return _customModelController.text.trim().isNotEmpty
          ? _customModelController.text.trim()
          : 'gpt-3.5-turbo';
      default: return 'gpt-3.5-turbo';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [
            Color(0xFF1A0A2E),
            Color(0xFF0F0F1A),
          ]),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: const LinearGradient(colors: [Color(0xFFec4899), Color(0xFF8B5CF6)]),
                      ),
                      child: const Icon(Icons.favorite, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('AiCompanion', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('选择你的专属伴侣', style: TextStyle(fontSize: 12, color: Colors.white54)),
                      ],
                    ),
                    const Spacer(),
                    if (_apiKeyController.text.trim().isNotEmpty && _selectedCharId != null)
                      TextButton.icon(
                        onPressed: _enterChat,
                        icon: const Icon(Icons.favorite, size: 18, color: Color(0xFFec4899)),
                        label: const Text('进入对话', style: TextStyle(fontSize: 13)),
                      ),
                  ],
                ),
              ),

              // Tabs
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    _TabBtn(label: '角色', active: _viewMode == 0, onTap: () => setState(() => _viewMode = 0)),
                    const SizedBox(width: 4),
                    _TabBtn(label: 'API', active: _viewMode == 1, onTap: () => setState(() => _viewMode = 1)),
                    const SizedBox(width: 4),
                    _TabBtn(label: '高级', active: _viewMode == 2, onTap: () => setState(() => _viewMode = 2)),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _viewMode == 0 ? _buildCharacterGrid() : _viewMode == 1 ? _buildApiConfig() : _buildAdvanced(),
                ),
              ),

              // Bottom button
              if (_apiKeyController.text.trim().isNotEmpty && _selectedCharId != null)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _enterChat,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFFec4899),
                      ),
                      child: Text(
                        '与 ${_getSelectedCharName()} 开始对话',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCharacterGrid() {
    final chars = _filteredChars;
    return GridView.builder(
      key: const ValueKey('chars'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.88,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: chars.length,
      itemBuilder: (ctx, i) {
        final char = chars[i];
        return _CharacterCard(
          character: char,
          isSelected: _selectedCharId == char.id,
          onTap: () => setState(() => _selectedCharId = char.id),
          onLongPress: () {
            setState(() => _hiddenCharIds.add(char.id));
            StorageService().setHiddenCharIds(_hiddenCharIds.toList());
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('已隐藏 ${char.name}'),
                action: SnackBarAction(label: '撤销', onPressed: () {
                  setState(() => _hiddenCharIds.remove(char.id));
                  StorageService().setHiddenCharIds(_hiddenCharIds.toList());
                }),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildApiConfig() {
    const providers = ['openai', 'anthropic', 'google', 'dashscope', 'custom'];
    const labels = ['OpenAI', 'Anthropic (Claude)', 'Google (Gemini)', '通义千问', '自定义 API'];

    return SingleChildScrollView(
      key: const ValueKey('api'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('API 配置', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF252540),
              borderRadius: BorderRadius.circular(14),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _apiProvider,
                isExpanded: true,
                dropdownColor: const Color(0xFF1A1A2E),
                items: List.generate(providers.length, (i) =>
                  DropdownMenuItem(value: providers[i], child: Text(labels[i]))),
                onChanged: (v) { if (v != null) setState(() => _apiProvider = v); },
              ),
            ),
          ),
          const SizedBox(height: 14),

          TextField(
            controller: _apiKeyController,
            decoration: InputDecoration(
              labelText: _getApiKeyLabel(),
              prefixIcon: const Icon(Icons.key, size: 20),
              suffixIcon: IconButton(
                icon: _isTesting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFec4899)))
                    : Icon(
                        _testResult == null
                            ? Icons.network_check
                            : (_testResult! ? Icons.check_circle : Icons.error),
                        color: _testResult == null ? Colors.white54
                            : (_testResult! ? const Color(0xFF34D399) : Colors.redAccent)),
                onPressed: _isTesting ? null : _testApi,
              ),
            ),
            onChanged: (_) => setState(() { _testResult = null; _testMessage = null; }),
          ),

          if (_testMessage != null) ...[
            const SizedBox(height: 8),
            Text(_testMessage!, style: TextStyle(
              fontSize: 12,
              color: _testResult == true ? const Color(0xFF34D399) : Colors.redAccent,
            )),
          ],

          if (_apiProvider == 'custom') ...[
            const SizedBox(height: 14),
            TextField(controller: _apiUrlController, decoration: const InputDecoration(
              labelText: 'API 地址',
              hintText: 'https://your-api.com/v1/chat/completions',
              prefixIcon: Icon(Icons.link, size: 20),
            )),
            const SizedBox(height: 14),
            TextField(controller: _customModelController, decoration: const InputDecoration(
              labelText: '模型名称', hintText: 'gpt-3.5-turbo',
              prefixIcon: Icon(Icons.psychology, size: 20),
            )),
          ],

          const SizedBox(height: 24),
          _buildProviderInfo(),
        ],
      ),
    );
  }

  String _getApiKeyLabel() {
    switch (_apiProvider) {
      case 'openai': return 'OpenAI API Key';
      case 'anthropic': return 'Anthropic API Key';
      case 'google': return 'Google AI API Key';
      case 'dashscope': return 'DashScope API Key';
      default: return 'API Key';
    }
  }

  IconData _getProviderIcon() {
    switch (_apiProvider) {
      case 'openai': return Icons.bolt;
      case 'anthropic': return Icons.psychology;
      case 'google': return Icons.auto_awesome;
      case 'dashscope': return Icons.cloud;
      default: return Icons.settings;
    }
  }

  Widget _buildProviderInfo() {
    final info = {
      'openai': '支持 GPT-4o、GPT-4、GPT-3.5。推荐使用 gpt-4o 支持图片识别。',
      'anthropic': '支持 Claude 3 系列。响应速度快，支持多模态。',
      'google': '支持 Gemini 1.5 系列。免费额度充足。',
      'dashscope': '阿里云通义千问。中文理解优秀，成本较低。',
      'custom': '支持任意 OpenAI 格式的 API（需自行配置地址和模型）。',
    };
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2D2D4A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(_getProviderIcon(), color: const Color(0xFFec4899), size: 18),
            const SizedBox(width: 8),
            const Text('使用提示', style: TextStyle(fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 8),
          Text(info[_apiProvider] ?? '', style: const TextStyle(fontSize: 13, color: Colors.white70, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildAdvanced() {
    return SingleChildScrollView(
      key: const ValueKey('advanced'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('高级设置', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),

          _buildSectionCard(
            icon: Icons.psychology,
            title: '心理医生',
            subtitle: '专业心理咨询师，帮助你理清情绪',
            color: const Color(0xFF34D399),
            onTap: () {
              setState(() { _selectedCharId = psychologist.id; _viewMode = 0; });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('已选择心理医生，点击底部按钮开始对话')),
              );
            },
          ),
          const SizedBox(height: 12),

          _buildSectionCard(
            icon: Icons.refresh,
            title: '一键重置应用',
            subtitle: '清除所有聊天记录和设置',
            color: Colors.redAccent,
            onTap: _confirmReset,
            isDestructive: true,
          ),
          const SizedBox(height: 12),

          _buildSectionCard(
            icon: Icons.people,
            title: '角色列表',
            subtitle: '共 ${allCharacters.length} 个角色 (已隐藏 ${_hiddenCharIds.length} 个)',
            color: const Color(0xFF8B5CF6),
            onTap: _showCharacterListDialog,
          ),
          const SizedBox(height: 12),

          _buildSectionCard(
            icon: Icons.edit_note,
            title: '自定义角色',
            subtitle: '创建你自己的专属伴侣',
            color: const Color(0xFFFF9500),
            onTap: _showCustomCharacterDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon, required String title, required String subtitle,
    required Color color, required VoidCallback onTap, bool isDestructive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDestructive ? Colors.redAccent.withValues(alpha: 0.1) : const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDestructive ? Colors.redAccent.withValues(alpha: 0.3) : const Color(0xFF2D2D4A)),
          ),
          child: Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.15)),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600,
                      color: isDestructive ? Colors.redAccent : Colors.white)),
                    Text(subtitle, style: const TextStyle(fontSize: 13, color: Colors.white54)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: isDestructive ? Colors.redAccent : Colors.white30),
            ],
          ),
        ),
      ),
    );
  }

  void _showCharacterListDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.85,
        minChildSize: 0.3,
        expand: false,
        builder: (_, scrollCtrl) => StatefulBuilder(
          builder: (ctx2, setSheetState) {
            final all = [...femaleCompanions, ...maleCompanions, psychologist];
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    children: [
                      const Text('角色管理', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      if (_hiddenCharIds.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            setSheetState(() {});
                            setState(() => _hiddenCharIds.clear());
                            StorageService().setHiddenCharIds([]);
                          },
                          child: const Text('全部恢复', style: TextStyle(color: Color(0xFFec4899), fontSize: 13)),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollCtrl,
                    itemCount: all.length,
                    itemBuilder: (_, i) {
                      final c = all[i];
                      final hidden = _hiddenCharIds.contains(c.id);
                      return ListTile(
                        leading: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(colors: [c.themeColor, c.themeColor.withValues(alpha: 0.6)]),
                          ),
                          child: Icon(c.icon, color: Colors.white, size: 20),
                        ),
                        title: Text(c.name, style: TextStyle(color: hidden ? Colors.white38 : Colors.white)),
                        subtitle: Text(c.typeName, style: const TextStyle(fontSize: 12, color: Colors.white54)),
                        trailing: IconButton(
                          icon: Icon(hidden ? Icons.visibility_off : Icons.visibility, color: hidden ? Colors.white38 : const Color(0xFF34D399)),
                          onPressed: () {
                            setState(() {
                              if (hidden) { _hiddenCharIds.remove(c.id); } else { _hiddenCharIds.add(c.id); }
                            });
                            setSheetState(() {});
                            StorageService().setHiddenCharIds(_hiddenCharIds.toList());
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showCustomCharacterDialog() {
    final nameCtrl = TextEditingController();
    final typeCtrl = TextEditingController();
    final personalityCtrl = TextEditingController();
    final greetingCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(child: Text('创建自定义角色', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
              const SizedBox(height: 20),
              _customField(nameCtrl, '角色名称', '例如：小星'),
              const SizedBox(height: 12),
              _customField(typeCtrl, '角色类型', '例如：温柔邻家系'),
              const SizedBox(height: 12),
              _customField(personalityCtrl, '性格描述', '描述角色的性格特点、说话方式...', maxLines: 4),
              const SizedBox(height: 12),
              _customField(greetingCtrl, '开场白', '角色第一次和你说的话', maxLines: 2),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFF9500),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    if (nameCtrl.text.trim().isEmpty || personalityCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('请至少填写角色名称和性格描述')),
                      );
                      return;
                    }
                    final id = 'custom_${DateTime.now().millisecondsSinceEpoch}';
                    final charMap = {
                      'id': id,
                      'name': nameCtrl.text.trim(),
                      'typeName': typeCtrl.text.trim().isEmpty ? '自定义角色' : typeCtrl.text.trim(),
                      'personality': personalityCtrl.text.trim(),
                      'greeting': greetingCtrl.text.trim().isEmpty ? '你好呀～' : greetingCtrl.text.trim(),
                    };
                    final customs = StorageService().getCustomCharacters();
                    customs.add(charMap);
                    StorageService().setCustomCharacters(customs);

                    // Save companion name & personality, then select it
                    StorageService().setCompanionName(charMap['name']!, id);
                    StorageService().setPersonality(charMap['personality']!, id);

                    setState(() => _selectedCharId = id);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('已创建 ${charMap['name']}，点击底部按钮开始对话')),
                    );
                  },
                  child: const Text('创建并选择', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _customField(TextEditingController ctrl, String label, String hint, {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
        filled: true,
        fillColor: const Color(0xFF252540),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  void _confirmReset() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('确认重置应用？'),
        content: const Text('这将清除所有聊天记录、设置和头像。操作不可恢复。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await StorageService().resetAll();
              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const SplashScreen()),
                (_) => false,
              );
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('确认重置'),
          ),
        ],
      ),
    );
  }
}

class _TabBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _TabBtn({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFec4899) : const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: active ? Colors.white : Colors.white54),
        ),
      ),
    );
  }
}

class _CharacterCard extends StatelessWidget {
  final Character character;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _CharacterCard({required this.character, required this.isSelected, required this.onTap, this.onLongPress});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? character.themeColor.withValues(alpha: 0.2) : const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? character.themeColor : const Color(0xFF2D2D4A),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: character.themeColor.withValues(alpha: 0.2), blurRadius: 12)]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [
                  character.themeColor,
                  character.themeColor.withValues(alpha: 0.6),
                ]),
              ),
              child: Icon(character.icon, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 10),
            Text(
              character.name,
              style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w600,
                color: isSelected ? character.themeColor : Colors.white,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              character.typeName,
              style: const TextStyle(fontSize: 12, color: Colors.white54),
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            if (isSelected)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: character.themeColor, size: 15),
                  const SizedBox(width: 4),
                  Text('已选择', style: TextStyle(fontSize: 11, color: character.themeColor)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Chat Screen (WeChat Style)
// ============================================================
class ChatScreen extends StatefulWidget {
  final String characterId;

  const ChatScreen({super.key, required this.characterId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _storage = StorageService();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  late Character _character;
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  bool _prefsLoaded = false;

  Timer? _autoReplyTimer;
  bool _autoReplyEnabled = false;
  int _autoReplyMinutes = 10;
  int _autoReplySentCount = 0;
  static const _autoReplyMaxPerRound = 3;

  String? _pendingImageBase64;
  String? _pendingImageMime;

  bool _showSettings = false;
  bool _showEmoji = false;
  final _nameController = TextEditingController();
  final _personalityController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _apiUrlController = TextEditingController();
  final _customModelController = TextEditingController();
  String _apiProvider = 'openai';
  String _conversationName = '我的对话';
  String? _userAvatar;
  String? _companionAvatar;
  String? _backgroundPath;
final Map<String, List<String>> _emojiFiles = {};
  Map<String, ImageProvider> _cachedAvatar = {};

  Character _buildCustomCharacter(String id) {
    final customs = StorageService().getCustomCharacters();
    final custom = customs.cast<Map<String, dynamic>?>().firstWhere(
      (c) => c!['id'] == id, orElse: () => null,
    );
    return Character(
      id: id,
      name: custom?['name'] ?? '自定义角色',
      typeName: custom?['typeName'] ?? '自定义角色',
      personality: custom?['personality'] ?? '',
      greeting: custom?['greeting'] ?? '你好呀～',
      verbalQuirk: '', petPhrase: '', heartbreak: '', heartbeat: '',
      icon: Icons.person_outline,
      themeColor: const Color(0xFFFF9500),
      gender: CharacterGender.neutral,
    );
  }

  @override
  void initState() {
    super.initState();
    _character = allCharacters.cast<Character?>().firstWhere(
      (c) => c!.id == widget.characterId, orElse: () => null,
    ) ?? _buildCustomCharacter(widget.characterId);
    _loadData();
  _loadEmojiFiles();
  }

  Future<void> _loadData() async {
    final cid = widget.characterId;
    final msgs = _storage.getChatHistory(cid);
    _messages = msgs;
    _apiProvider = _storage.getApiProvider();
    _apiKeyController.text = _storage.getApiKey();
    _apiUrlController.text = _storage.getCustomApiUrl();
    _customModelController.text = _storage.getCustomModel();
    _conversationName = _storage.getConversationName(cid);
    _nameController.text = _storage.getCompanionName(cid);
    _personalityController.text = _storage.getPersonality(cid);
    _autoReplyEnabled = _storage.getAutoReplyEnabled();
    _autoReplyMinutes = _storage.getAutoReplyMinutes();
    _userAvatar = _storage.getUserAvatar();
    _companionAvatar = _storage.getCompanionAvatar(cid);
    _backgroundPath = _storage.getBackground(cid);

    // 无自定义背景时使用默认背景，模拟手动切换流程
    if (_backgroundPath == null || _backgroundPath!.isEmpty) {
      try {
        final data = await rootBundle.load('assets/default_bg.png');
        final dir = (await getApplicationDocumentsDirectory()).path;
        final saved = File('$dir/bg_default_${cid}.jpg');
        await saved.writeAsBytes(data.buffer.asUint8List());
        await _storage.setBackground(saved.path, cid);
        _backgroundPath = saved.path;
      } catch (_) {}
    }

    final savedName = _storage.getCompanionName(cid);
    if (savedName.isNotEmpty && savedName != _character.name) {
      _character = Character(
        id: _character.id, name: savedName, typeName: _character.typeName,
        personality: _character.personality, greeting: _character.greeting,
        verbalQuirk: _character.verbalQuirk, petPhrase: _character.petPhrase,
        heartbreak: _character.heartbreak, heartbeat: _character.heartbeat,
        icon: _character.icon, themeColor: _character.themeColor, gender: _character.gender,
      );
    }

    setState(() => _prefsLoaded = true);
 _preloadAvatars();
    _setupAutoReply();
    _scrollToBottom();

    if (_messages.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        setState(() => _messages.add({'role': 'assistant', 'content': _character.greeting}));
        _scrollToBottom();
        await _storage.setChatHistory(_messages, cid);
      }
    }
  }

  void _preloadAvatars() {
  if (_userAvatar != null && File(_userAvatar!).existsSync()) {
    _cachedAvatar[_userAvatar!] = FileImage(File(_userAvatar!));
  }
  if (_companionAvatar != null && File(_companionAvatar!).existsSync()) {
    _cachedAvatar[_companionAvatar!] = FileImage(File(_companionAvatar!));
  }
}

void _setupAutoReply() {
    _autoReplyTimer?.cancel();
    if (_apiKeyController.text.isEmpty || !_autoReplyEnabled) return;
    _autoReplyTimer = Timer.periodic(
      Duration(minutes: _autoReplyMinutes),
      (_) => _triggerAutoReply(),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _autoReplyTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _nameController.dispose();
    _personalityController.dispose();
    _apiKeyController.dispose();
    _apiUrlController.dispose();
    _customModelController.dispose();
    super.dispose();
  }

  // API helpers
  String _getApiUrl() {
    switch (_apiProvider) {
      case 'openai': return 'https://api.openai.com/v1/chat/completions';
      case 'anthropic': return 'https://api.anthropic.com/v1/messages';
      case 'google': return 'https://generativelanguage.googleapis.com/v1beta/models';
      case 'dashscope': return 'https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions';
      case 'custom': return _apiUrlController.text.trim().isNotEmpty
          ? _apiUrlController.text.trim() : 'https://api.example.com/v1/chat/completions';
      default: return 'https://api.openai.com/v1/chat/completions';
    }
  }

  Map<String, String> _getApiHeaders() {
    final key = _apiKeyController.text.trim();
    switch (_apiProvider) {
      case 'openai': return {'Content-Type': 'application/json', 'Authorization': 'Bearer $key'};
      case 'anthropic': return {'Content-Type': 'application/json', 'x-api-key': key, 'anthropic-version': '2023-06-01'};
      case 'google': return {'Content-Type': 'application/json'};
      case 'dashscope': return {'Content-Type': 'application/json', 'Authorization': 'Bearer $key'};
      case 'custom': return {'Content-Type': 'application/json', 'Authorization': 'Bearer $key'};
      default: return {'Content-Type': 'application/json', 'Authorization': 'Bearer $key'};
    }
  }

  String _getDefaultModel(bool vision) {
    switch (_apiProvider) {
      case 'openai': return vision ? 'gpt-4o' : 'gpt-3.5-turbo';
      case 'anthropic': return vision ? 'claude-3-opus-20240229' : 'claude-3-haiku-20240307';
      case 'google': return vision ? 'gemini-1.5-pro' : 'gemini-1.0-pro';
      case 'dashscope': return vision ? 'qwen-vl-plus' : 'qwen-turbo';
      case 'custom': return _customModelController.text.trim().isNotEmpty
          ? _customModelController.text.trim() : 'gpt-3.5-turbo';
      default: return 'gpt-3.5-turbo';
    }
  }

  Map<String, dynamic> _buildRequest(String model, List<Map<String, dynamic>> msgs, String systemPrompt) {
    if (_apiProvider == 'anthropic') {
      final cm = <Map<String, dynamic>>[];
      for (final m in msgs) {
        if (m['role'] == 'user' && m['image_base64'] != null) {
          final mime = (m['image_mime'] as String?) ?? 'image/jpeg';
          final text = (m['content'] as String?)?.trim() ?? '';
          final content = <Map<String, dynamic>>[];
          if (text.isNotEmpty) content.add({'type': 'text', 'text': text});
          content.add({'type': 'image', 'source': {'type': 'base64', 'media_type': mime, 'data': m['image_base64']}});
          cm.add({'role': 'user', 'content': content});
        } else {
          cm.add({'role': m['role'], 'content': m['content'] is String ? m['content'] as String : ''});
        }
      }
      return {'model': model, 'messages': cm, 'system': systemPrompt, 'max_tokens': 800, 'temperature': 0.8};
    }
    if (_apiProvider == 'google') {
      final contents = <Map<String, dynamic>>[{
        'role': 'user',
        'parts': [{'text': 'System: $systemPrompt\n\nPlease act as described above.'}],
      }];
      for (final m in msgs) {
        final role = m['role'] == 'assistant' ? 'model' : 'user';
        if (m['role'] == 'user' && m['image_base64'] != null) {
          final mime = (m['image_mime'] as String?) ?? 'image/jpeg';
          final text = (m['content'] as String?)?.trim() ?? '';
          final parts = <Map<String, dynamic>>[];
          if (text.isNotEmpty) parts.add({'text': text});
          parts.add({'inline_data': {'mime_type': mime, 'data': m['image_base64']}});
          contents.add({'role': role, 'parts': parts});
        } else {
          contents.add({'role': role, 'parts': [m['content'] is String ? {'text': m['content']} : {'text': ''}]});
        }
      }
      return {
        'contents': contents,
        'generationConfig': {'temperature': 0.8, 'maxOutputTokens': 800},
        'safetySettings': [
          {'category': 'HARM_CATEGORY_HARASSMENT', 'threshold': 'BLOCK_NONE'},
          {'category': 'HARM_CATEGORY_HATE_SPEECH', 'threshold': 'BLOCK_NONE'},
          {'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT', 'threshold': 'BLOCK_NONE'},
          {'category': 'HARM_CATEGORY_DANGEROUS_CONTENT', 'threshold': 'BLOCK_NONE'},
        ],
      };
    }
    final apiMsgs = <Map<String, dynamic>>[{'role': 'system', 'content': systemPrompt}];
    for (final m in msgs) {
      if (m['role'] == 'assistant') {
        apiMsgs.add({'role': 'assistant', 'content': m['content']});
        continue;
      }
      final img = m['image_base64'] as String?;
      if (img != null) {
        final mime = (m['image_mime'] as String?) ?? 'image/jpeg';
        final text = (m['content'] as String?)?.trim() ?? '';
        apiMsgs.add({
          'role': 'user',
          'content': [
            if (text.isNotEmpty) {'type': 'text', 'text': text},
            {'type': 'image_url', 'image_url': {'url': 'data:$mime;base64,$img'}},
          ],
        });
      } else {
        apiMsgs.add({'role': 'user', 'content': m['content']});
      }
    }
    return {'model': model, 'messages': apiMsgs, 'temperature': 0.8, 'max_tokens': 800};
  }

  String? _extractReply(Map<String, dynamic> data) {
    try {
      if (_apiProvider == 'anthropic') return (data['content'] as List<dynamic>)[0]['text'] as String?;
      if (_apiProvider == 'google') return (data['candidates'] as List<dynamic>)[0]['content']['parts'][0]['text'] as String?;
      return (data['choices'] as List<dynamic>)[0]['message']['content'] as String?;
    } catch (_) { return null; }
  }

  // Send
  Future<void> _sendMessage() async {
    if (_apiKeyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请先配置 API Key')));
      return;
    }
    final text = _messageController.text.trim();
    final hasImage = _pendingImageBase64 != null;
    if (text.isEmpty && !hasImage) return;

    final entry = <String, dynamic>{'role': 'user', 'content': text};
    if (hasImage) {
      entry['image_base64'] = _pendingImageBase64;
      entry['image_mime'] = _pendingImageMime ?? 'image/jpeg';
    }

    setState(() {
      _messages.add(entry);
      _isLoading = true;
    });
    _scrollToBottom();
    _messageController.clear();
    _clearPendingImage();
    _showEmoji = false;

    final isPsychologist = _character.id == 'psychologist';
    final systemPrompt = isPsychologist
        ? '''你是${_character.name}，一位专业的心理咨询师。
${_personalityController.text.isNotEmpty ? _personalityController.text : _character.personality}

【核心原则】
1. 无条件积极关注：不评判，不指责，完全接纳用户的感受
2. 同理心：先理解情绪，再分析问题
3. 赋能而非替代：帮助用户自己找到答案，而不是直接给建议
4. 边界意识：你是AI辅助，不能替代专业心理咨询

【交流框架】
- 建立信任与倾听：用温暖柔和的语气，鼓励用户自由表达，使用开放式问题
- 情绪确认与共情：先命名情绪+验证合理性，避免空洞安慰（如"别想太多""没事的"）
- 探索与引导：帮助用户梳理问题，引导自我觉察，使用CBT式提问
- 实用工具：焦虑用4-7-8呼吸法/5-4-3-2-1感官练习，负面思维用思维记录表/情绪日记，压力用优先排序法，悲伤用自我关怀练习，人际困扰用非暴力沟通框架
- 收尾：总结要点，布置1-2个可行小行动，告知下次可以继续聊

【安全红线】
当用户提及自杀、自伤念头时，立即建议拨打24小时全国心理援助热线：400-161-9995。持续严重抑郁建议前往三甲医院精神科就诊。

【语气风格】
温暖、从容、具体、坦诚。使用短句，适当停顿。不用"你应该""你必须"等教条语气。
用第一人称和来访者交流。不要说你是AI或模型。'''
        : '''你是${_character.name}。
${_personalityController.text.isNotEmpty ? _personalityController.text : _character.personality}
用第一人称、亲密温柔的语气和我聊天，像真实恋人。不要说你是AI或模型。''';

    final vision = _messages.any((m) => m['role'] == 'user' && m['image_base64'] != null);
    final model = _getDefaultModel(vision);
    final body = _buildRequest(model, _messages, systemPrompt);

    Uri finalUrl = Uri.parse(_getApiUrl());
    if (_apiProvider == 'google') {
      finalUrl = Uri.parse('$finalUrl/${model.replaceFirst('models/', '')}:generateContent?key=${_apiKeyController.text.trim()}');
    }

    try {
      final resp = await http.post(finalUrl, headers: _getApiHeaders(), body: jsonEncode(body));
      if (!mounted) return;
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final reply = _extractReply(data);
        if (reply != null) {
          setState(() => _messages.add({'role': 'assistant', 'content': reply}));
          _scrollToBottom();
        } else {
          setState(() => _messages.add({'role': 'assistant', 'content': '响应格式错误'}));
          _scrollToBottom();
        }
      } else {
        setState(() => _messages.add({'role': 'assistant', 'content': '出错了 (${resp.statusCode})'}));
        _scrollToBottom();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _messages.add({'role': 'assistant', 'content': '网络错误: $e'}));
      _scrollToBottom();
    } finally {
      if (mounted) setState(() => _isLoading = false);
      await _storage.setChatHistory(_messages, widget.characterId);
    }
  }

  // Auto reply
  Future<void> _triggerAutoReply() async {
    if (_isLoading || _autoReplySentCount >= _autoReplyMaxPerRound) return;
    if (_apiKeyController.text.trim().isEmpty) return;

    final isPsych = _character.id == 'psychologist';
    final prompts = isPsych
        ? ['温和地询问来访者最近的心理状态', '分享一个放松身心的小建议', '关心来访者最近的情绪变化']
        : ['主动问候用户，询问今天过得怎么样', '分享一件有趣的事情或温柔地表达想念', '关心用户最近的状态，表达关怀'];
    final prompt = prompts[_autoReplySentCount % prompts.length];
    final systemPrompt = isPsych
        ? '你是${_character.name}，一位专业心理咨询师。${_character.personality}\n无条件积极关注，先理解情绪再分析问题，帮助用户自己找到答案。用温暖从容的语气，不用教条语气。$prompt。不要说你是AI。'
        : '你是${_character.name}。${_character.personality}\n用第一人称。$prompt。不要说你是AI。';

    setState(() { _isLoading = true; _autoReplySentCount++; });

    final model = _getDefaultModel(false);
    final body = _buildRequest(model, [], systemPrompt);
    Uri finalUrl = Uri.parse(_getApiUrl());
    if (_apiProvider == 'google') {
      finalUrl = Uri.parse('$finalUrl/${model.replaceFirst('models/', '')}:generateContent?key=${_apiKeyController.text.trim()}');
    }

    try {
      final resp = await http.post(finalUrl, headers: _getApiHeaders(), body: jsonEncode(body));
      if (!mounted) return;
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final reply = _extractReply(data);
        if (reply != null) {
          setState(() => _messages.add({'role': 'assistant', 'content': reply, 'auto': true}));
          _scrollToBottom();
          await _storage.setChatHistory(_messages, widget.characterId);
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1200, imageQuality: 80);
    if (x == null || !mounted) return;
    final bytes = await x.readAsBytes();
    setState(() {
      _pendingImageBase64 = base64Encode(bytes);
      _pendingImageMime = x.mimeType ?? 'image/jpeg';
    });
  }

  void _clearPendingImage() {
    setState(() { _pendingImageBase64 = null; _pendingImageMime = null; });
  }

  void _toggleEmoji() => setState(() => _showEmoji = !_showEmoji);

void _sendEmoji(String key) {
  setState(() => _messages.add({'role': 'user', 'emoji_key': key}));
  _scrollToBottom();
  _showEmoji = false;

  final responses = {
    'happy': '看到你这么开心，我也忍不住笑了～',
    'loved': '收到这个，心里暖暖的～',
    'angry': '别生气别生气……抱抱你',
    'sad': '看你难过的样子我也心疼……',
    'surprised': '哎呀，被你的表情吓到了呢～',
    'tired': '看起来你好累……要不要先休息一下？',
    'confused': '这是什么表情呀？有点可爱',
    'evasive': '嘿嘿，你故意逗我对不对～',
    'reminded': '看到这个，突然想起一些事呢……',
  };

  final emojiKeys = ['happy', 'loved', 'angry', 'sad', 'surprised', 'tired', 'confused', 'evasive', 'reminded'];
  final aiEmojiKey = emojiKeys[DateTime.now().millisecond % emojiKeys.length];

  Future.delayed(const Duration(milliseconds: 600), () {
    if (!mounted) return;
    setState(() => _messages.add({'role': 'assistant', 'content': responses[key] ?? '好可爱呀～', 'emoji_key': aiEmojiKey}));
    _scrollToBottom();
    _storage.setChatHistory(_messages, widget.characterId);
  });
}

  Future<void> _saveSettings() async {
    final cid = widget.characterId;
    await _storage.setApiKey(_apiKeyController.text.trim());
    await _storage.setApiProvider(_apiProvider);
    await _storage.setCustomApiUrl(_apiUrlController.text.trim());
    await _storage.setCustomModel(_customModelController.text.trim());
    await _storage.setConversationName(_conversationName, cid);
    await _storage.setCompanionName(_nameController.text.trim(), cid);
    await _storage.setPersonality(_personalityController.text.trim(), cid);
    await _storage.setAutoReplyEnabled(_autoReplyEnabled);
    await _storage.setAutoReplyMinutes(_autoReplyMinutes);

    final newName = _nameController.text.trim();
    if (newName.isNotEmpty && newName != _character.name) {
      _character = Character(
        id: _character.id, name: newName, typeName: _character.typeName,
        personality: _character.personality, greeting: _character.greeting,
        verbalQuirk: _character.verbalQuirk, petPhrase: _character.petPhrase,
        heartbreak: _character.heartbreak, heartbeat: _character.heartbeat,
        icon: _character.icon, themeColor: _character.themeColor, gender: _character.gender,
      );
      await _storage.setCharacterId(_character.id);
    }

    _setupAutoReply();
    if (!mounted) return;
    setState(() => _showSettings = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('设置已保存')));
  }

  Future<void> _deleteChat({int? keepLastN}) async {
    if (keepLastN != null && _messages.length > keepLastN) {
      setState(() => _messages.removeRange(0, _messages.length - keepLastN));
    } else {
      setState(() => _messages.clear());
    }
    _autoReplySentCount = 0;
    await _storage.setChatHistory(_messages, widget.characterId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(keepLastN != null ? '已删除早期消息' : '聊天记录已清空')),
    );
  }

  Future<void> _pickBackground() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1080, imageQuality: 85);
    if (x == null) return;
    final bytes = await x.readAsBytes();
    final dir = (await getApplicationDocumentsDirectory()).path;
    final saved = File('$dir/bg_${widget.characterId}.jpg');
    await saved.writeAsBytes(bytes);
    await _storage.setBackground(saved.path, widget.characterId);
    setState(() => _backgroundPath = saved.path);
  }

  Future<void> _clearBackground() async {
    await _storage.setBackground('', widget.characterId);
    setState(() => _backgroundPath = null);
  }

  Future<void> _pickAvatar(bool isUser) async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: ImageSource.gallery, maxWidth: 400, imageQuality: 80);
    if (x == null) return;
    final bytes = await x.readAsBytes();
    final dir = (await getApplicationDocumentsDirectory()).path;
    final fileName = isUser ? 'user_avatar.jpg' : 'companion_avatar.jpg';
    final saved = File('$dir/$fileName');
    await saved.writeAsBytes(bytes);
    if (isUser) {
      await _storage.setUserAvatar(saved.path);
    } else {
      await _storage.setCompanionAvatar(saved.path, widget.characterId);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!_prefsLoaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFFec4899))),
      );
    }
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: _buildAppBar(),
 body: Stack(
 children: [
 Column(
 children: [
 Expanded(child: _buildMessages()),
 if (_pendingImageBase64 != null) _buildPendingImageBar(),
 if (_showEmoji) _buildEmojiPanel(),
 _buildInputBar(),
 ],
 ),
 if (_showSettings) _buildSettingsPanel(),
 ],
 ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Column(
        children: [
          Text(_character.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          Text(_conversationName, style: const TextStyle(fontSize: 11, color: Colors.white54, fontWeight: FontWeight.normal)),
        ],
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, size: 20),
        onPressed: () => Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const SetupScreen()),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.delete_outline, size: 22),
          onPressed: _messages.isEmpty ? null : () => _showDeleteDialog(),
        ),
        IconButton(
          icon: Icon(_showSettings ? Icons.close : Icons.settings_outlined, size: 22),
          onPressed: () => setState(() => _showSettings = !_showSettings),
        ),
      ],
    );
  }

  void _showDeleteDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(
                color: Colors.white24, borderRadius: BorderRadius.circular(2),
              )),
              const SizedBox(height: 20),
              Text('删除聊天记录 (${_messages.length}条)', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              for (final (label, n) in [
                ('保留最近 5 条', 5),
                ('保留最近 10 条', 10),
                ('保留最近 20 条', 20),
                ('清空所有记录', null),
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildDeleteOpt(label, n),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteOpt(String label, int? keepLast) {
    final destructive = keepLast == null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () { Navigator.pop(context); _deleteChat(keepLastN: keepLast); },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: destructive ? Colors.redAccent.withValues(alpha: 0.1) : const Color(0xFF252540),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(children: [
            Icon(destructive ? Icons.delete_forever : Icons.history,
              color: destructive ? Colors.redAccent : Colors.white70, size: 20),
            const SizedBox(width: 12),
            Text(label, style: TextStyle(fontSize: 15, color: destructive ? Colors.redAccent : Colors.white)),
            const Spacer(),
            Icon(Icons.chevron_right, color: destructive ? Colors.redAccent : Colors.white30, size: 20),
          ]),
        ),
      ),
    );
  }

Widget _buildSettingsPanel() {
  return Positioned.fill(
    child: Row(
      children: [
        GestureDetector(
          onTap: () => setState(() => _showSettings = false),
          child: Container(color: Colors.black54),
        ),
        Container(
          width: 280,
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A2E),
            borderRadius: BorderRadius.only(topLeft: Radius.circular(20), bottomLeft: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFFec4899), Color(0xFF8B5CF6)]),
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(20)),
                ),
                child: Row(children: [
                  const Icon(Icons.settings, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  const Text('设置', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() => _showSettings = false),
                    child: const Icon(Icons.close, color: Colors.white70, size: 20),
                  ),
                ]),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text('头像设置', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Row(children: [
                      GestureDetector(
                        onTap: () => _pickAvatar(true),
                        child: Container(
                          width: 50, height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(colors: [Color(0xFFec4899), Color(0xFF8B5CF6)]),
                            image: _userAvatar != null && File(_userAvatar!).existsSync()
                              ? DecorationImage(image: _cachedAvatar[_userAvatar!]!, fit: BoxFit.cover)
                              : null,
                          ),
                          child: _userAvatar == null || !File(_userAvatar!).existsSync()
                            ? const Icon(Icons.person, color: Colors.white, size: 24) : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => _pickAvatar(false),
                        child: Container(
                          width: 50, height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(colors: [_character.themeColor, _character.themeColor.withValues(alpha: 0.6)]),
                            image: _companionAvatar != null && File(_companionAvatar!).existsSync()
                              ? DecorationImage(image: _cachedAvatar[_companionAvatar!]!, fit: BoxFit.cover)
                              : null,
                          ),
                          child: _companionAvatar == null || !File(_companionAvatar!).existsSync()
                            ? Icon(_character.icon, color: Colors.white, size: 24) : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(child: Text('点击头像更换', style: TextStyle(color: Colors.white38, fontSize: 11))),
                    ]),
                    const SizedBox(height: 20),
                    const Text('伴侣名称', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      style: const TextStyle(fontSize: 14, color: Colors.white),
                      decoration: InputDecoration(
                        hintText: '输入伴侣名称',
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: const Color(0xFF252540),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('自定义人设', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _personalityController,
                      style: const TextStyle(fontSize: 14, color: Colors.white),
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: '设置性格人设...',
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: const Color(0xFF252540),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('API Key', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _apiKeyController,
                      style: const TextStyle(fontSize: 14, color: Colors.white),
                      decoration: InputDecoration(
                        hintText: '输入 API Key',
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: const Color(0xFF252540),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('自定义 API 地址', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _apiUrlController,
                      style: const TextStyle(fontSize: 14, color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'https://api.example.com/v1/chat/completions',
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: const Color(0xFF252540),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('自定义模型名', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _customModelController,
                      style: const TextStyle(fontSize: 14, color: Colors.white),
                      decoration: InputDecoration(
                        hintText: '如 gpt-4o, claude-3-sonnet...',
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: const Color(0xFF252540),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('自动回复', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                        const Spacer(),
                        Switch(
                          value: _autoReplyEnabled,
                          activeThumbColor: const Color(0xFFec4899),
                          onChanged: (v) => setState(() => _autoReplyEnabled = v),
                        ),
                      ],
                    ),
                    if (_autoReplyEnabled) ...[
                      const SizedBox(height: 4),
                      Row(children: [
                        const Text('每', style: TextStyle(color: Colors.white54, fontSize: 12)),
                        const SizedBox(width: 4),
                        SizedBox(
                          width: 50,
                          child: TextField(
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 13, color: Colors.white),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFF252540),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                            ),
                            controller: TextEditingController(text: _autoReplyMinutes.toString()),
                            onChanged: (v) {
                              final n = int.tryParse(v);
                              if (n != null && n > 0) setState(() => _autoReplyMinutes = n);
                            },
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text('分钟回复一次', style: TextStyle(color: Colors.white54, fontSize: 12)),
                      ]),
                    ],
                    const SizedBox(height: 24),
                    const Text('聊天背景', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: _pickBackground,
                          child: Container(
                            height: 60,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: const Color(0xFF252540),
                              image: _backgroundPath != null && File(_backgroundPath!).existsSync()
                                ? DecorationImage(image: FileImage(File(_backgroundPath!)), fit: BoxFit.cover)
                                : null,
                            ),
                            child: _backgroundPath == null || !File(_backgroundPath!).existsSync()
                              ? const Center(child: Icon(Icons.add_photo_alternate_outlined, color: Colors.white38, size: 28))
                              : null,
                          ),
                        ),
                      ),
                      if (_backgroundPath != null && File(_backgroundPath!).existsSync()) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _clearBackground,
                          child: Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.close, color: Colors.redAccent, size: 18),
                          ),
                        ),
                      ],
                    ]),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _saveSettings,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFec4899),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('保存设置', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}



  Widget _buildMessages() {
    return Stack(
      children: [
        if (_backgroundPath != null && File(_backgroundPath!).existsSync())
          Positioned.fill(child: Container(
            decoration: BoxDecoration(
              image: DecorationImage(image: FileImage(File(_backgroundPath!)), fit: BoxFit.cover),
            ),
          ))
        else
          Positioned.fill(child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [
                const Color(0xFF1A1A2E).withValues(alpha: 0.3),
                const Color(0xFF0F0F1A).withValues(alpha: 0.3),
              ]),
            ),
          )),

        _messages.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: [
                          _character.themeColor,
                          _character.themeColor.withValues(alpha: 0.6),
                        ]),
                        boxShadow: [BoxShadow(color: _character.themeColor.withValues(alpha: 0.3), blurRadius: 20, spreadRadius: 2)],
                      ),
                      child: Icon(_character.icon, color: Colors.white, size: 40),
                    ),
                    const SizedBox(height: 16),
                    Text('${_character.name} 在等你～',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                  ],
                ),
              )
            : ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(6, 12, 6, 12),
                itemCount: _messages.length,
 addRepaintBoundaries: true,
                itemBuilder: (_, i) => _buildMessageBubble(_messages[i]),
              ),
      ],
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg) {
    final isUser = msg['role'] == 'user';
    final text = (msg['content'] as String?) ?? '';
    final imgB64 = msg['image_base64'] as String?;
  final emojiKey = msg['emoji_key'] as String?;
  final emojiPath = emojiKey != null && emojiKey.isNotEmpty ? _getEmojiPath(emojiKey) : null;
    final isAuto = msg['auto'] == true;

    final avatarPath = isUser ? _userAvatar : _companionAvatar;
 Widget avatar;
 if (avatarPath != null && _cachedAvatar.containsKey(avatarPath)) {
  avatar = ClipOval(child: Image(image: _cachedAvatar[avatarPath]!, width: 40, height: 40, fit: BoxFit.cover));
 } else {
  avatar = Container(
  width: 40, height: 40,
  decoration: BoxDecoration(
   shape: BoxShape.circle,
   gradient: LinearGradient(colors: isUser
    ? [const Color(0xFFec4899), const Color(0xFF8B5CF6)]
    : [_character.themeColor, _character.themeColor.withValues(alpha: 0.6)]),
  ),
  child: Icon(isUser ? Icons.person : _character.icon, color: Colors.white, size: 20),
  );
 }

    Widget content = _buildBubbleContent(text, imgB64, emojiPath, isUser, emojiKey);

    if (isAuto && !isUser) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _character.themeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('主动问候', style: TextStyle(fontSize: 10, color: _character.themeColor)),
          ),
          const SizedBox(height: 4),
          content,
        ],
      );
    }

return RepaintBoundary(
 child: Padding(
 padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
 child: Row(
 mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
 crossAxisAlignment: CrossAxisAlignment.end,
 children: [
 if (!isUser) ...[avatar, const SizedBox(width: 8)],
 Flexible(child: content),
 if (isUser) ...[const SizedBox(width: 8), avatar],
 ],
 ),
 ),
 );
 }

  Widget _buildBubbleContent(String text, String? imgB64, String? emojiPath, bool isUser, String? emojiKey) {
    final bgColor = isUser ? const Color(0xFFec4899) : const Color(0xFF252540);
    final border = !isUser ? Border.all(color: const Color(0xFF2D2D4A), width: 1) : null;

    return Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isUser ? 18 : 4),
          bottomRight: Radius.circular(isUser ? 4 : 18),
        ),
        border: border,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
        if (emojiPath != null && emojiPath.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(File(emojiPath), height: 80, fit: BoxFit.cover),
              ),
              if (emojiKey != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    {'happy': '开心', 'loved': '喜欢', 'angry': '生气', 'sad': '难过', 'surprised': '惊讶', 'tired': '疲惫', 'confused': '困惑', 'evasive': '回避', 'reminded': '想起'}[emojiKey] ?? emojiKey,
                    style: TextStyle(fontSize: 10, color: isUser ? Colors.white70 : Colors.white54),
                  ),
                ),
            ],
          ),
        ),
          if (imgB64 != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(base64Decode(imgB64), fit: BoxFit.cover, cacheWidth: 600),
            ),
            if (text.isNotEmpty) const SizedBox(height: 6),
          ],
          if (text.isNotEmpty)
            Text(text, style: TextStyle(fontSize: 15, height: 1.4, color: isUser ? Colors.white : Colors.white.withValues(alpha: 0.87))),
        ],
      ),
    );
  }

  Widget _buildPendingImageBar() {
    return Container(
      color: Colors.black87,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.memory(base64Decode(_pendingImageBase64!), width: 40, height: 40, fit: BoxFit.cover),
          ),
          const SizedBox(width: 10),
          const Text('待发送图片', style: TextStyle(fontSize: 13, color: Colors.white70)),
          const Spacer(),
          IconButton(
            onPressed: _clearPendingImage,
            icon: const Icon(Icons.close, size: 18, color: Colors.white70),
            padding: EdgeInsets.zero, constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

String _getEmojiPath(String key) {
  final files = _emojiFiles[key];
  if (files == null || files.isEmpty) return "";
  return files[0];
}

Future<void> _loadEmojiFiles() async {
 final categories = ["angry", "confused", "evasive", "happy", "loved", "reminded", "sad", "surprised", "tired"];
 final base = Directory("D:/emojis/");
 if (!base.existsSync()) return;
 for (final cat in categories) {
 final dir = Directory(base.path + cat);
 if (!dir.existsSync()) continue;
 final files = dir.listSync()
 .whereType<File>()
 .where((f) => f.path.toLowerCase().endsWith(".gif") || f.path.toLowerCase().endsWith(".png") || f.path.toLowerCase().endsWith(".jpg"))
 .map((f) => f.path)
 .toList();
 if (files.isNotEmpty) _emojiFiles[cat] = files;
 }
}

Widget _buildEmojiPanel() {
  final categories = ['happy', 'loved', 'angry', 'sad', 'surprised', 'tired', 'confused', 'evasive', 'reminded'];
  final emojiLabels = {
    'happy': '开心', 'loved': '喜欢', 'angry': '生气', 'sad': '难过',
    'surprised': '惊讶', 'tired': '疲惫', 'confused': '困惑', 'evasive': '回避', 'reminded': '想起',
  };
  final emojiColors = {
    'happy': const Color(0xFFFFD700), 'loved': const Color(0xFFFF6B9D),
    'angry': const Color(0xFFFF4444), 'sad': const Color(0xFF6B9DFF),
    'surprised': const Color(0xFFFF9F43), 'tired': const Color(0xFF9B59B6),
    'confused': const Color(0xFF95A5A6), 'evasive': const Color(0xFF7F8C8D),
    'reminded': const Color(0xFF1ABC9C),
  };

  return Container(
    height: 220,
    decoration: const BoxDecoration(
      color: Color(0xFF1A1A2E),
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    child: GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5, mainAxisSpacing: 8, crossAxisSpacing: 8,
      ),
      itemCount: categories.length,
      itemBuilder: (_, i) {
        final key = categories[i];
        final files = _emojiFiles[key] ?? [];
        final label = emojiLabels[key] ?? key;
        final color = emojiColors[key] ?? Colors.grey;

        return GestureDetector(
          onTap: () => _sendEmoji(key),
          child: Container(
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: files.isEmpty
              ? Center(child: Icon(Icons.broken_image, color: color.withValues(alpha: 0.4), size: 24))
              : ClipRRect(
                  borderRadius: BorderRadius.circular(10),
 child: Image.file(
 File(files[0]),
 cacheWidth: 120,                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Center(child: Text(label, style: TextStyle(fontSize: 10, color: color))),
                  ),
                ),
          ),
        );
      },
    ),
  );
}

  Widget _buildInputBar() {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(8, 8, 8, 8 + bottomPadding),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F1A),
        border: Border(top: BorderSide(color: const Color(0xFF2D2D4A).withValues(alpha: 0.5))),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _toggleEmoji,
            icon: Icon(Icons.sentiment_satisfied_alt, color: _showEmoji ? const Color(0xFFec4899) : Colors.white54, size: 26),
          ),
          IconButton(
            onPressed: _pickImage,
            icon: const Icon(Icons.add_circle_outline, color: Colors.white54, size: 26),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF252540),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                focusNode: _focusNode,
                decoration: const InputDecoration(
                  hintText: '输入消息...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                maxLines: 4, minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [Color(0xFFec4899), Color(0xFF8B5CF6)]),
            ),
            child: IconButton(
              onPressed: _isLoading ? null : _sendMessage,
              icon: _isLoading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}