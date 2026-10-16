# Vibe Companion · AiCompanion

一个基于 Flutter 的**角色化 AI 文字陪伴应用原型**：在客户端选择或创建角色，配置自己的模型 API，并将对话与个性化设置保存在设备本地。

应用界面名为 AiCompanion，Dart 包名为 `aicompanybyyy`。仓库侧重角色设定、聊天界面与多供应商请求适配，**不包含自建模型、后端服务或可直接使用的 API Key**，也不是已验证的心理咨询或医疗产品。

## 当前实现

| 模块 | 代码中已有的能力 |
| --- | --- |
| 角色选择 | 10 个女性伴侣、10 个男性伴侣及 1 个情绪支持主题角色；支持隐藏与恢复预设角色 |
| 自定义角色 | 填写名称、类型、性格与开场白，创建后直接选用 |
| 文本对话 | 根据当前角色构造提示词，通过 HTTP 请求模型，并展示文字回复 |
| 图片消息 | 从相册选择图片、编码后随对话发送；是否可用取决于所选供应商、模型与平台 |
| 本地记录 | 按角色保存聊天记录、人设、名称及背景路径；提供清理聊天记录与重置设置入口 |
| 个性化 | 头像、聊天背景、角色名称与人设编辑界面 |
| 主动问候 | 聊天页面内的定时 API 请求，默认关闭；不是系统级后台推送 |
| 表情交互 | 本地素材加载与固定模板回复；不是模型生成的表情回复，素材路径仍需改造 |

主入口实际使用 [lib/models/character_data.dart](lib/models/character_data.dart) 中的角色数据；[lib/character.dart](lib/character.dart) 保留了另一版角色定义，但不是当前入口导入的角色表。

## 本地启动

### 环境要求

| 项目 | 当前仓库约束 |
| --- | --- |
| Flutter | `pubspec.lock` 声明 `>=3.38.4`，所用 SDK 还必须同时满足 Dart 约束 |
| Dart | `pubspec.yaml` 为 `^3.11.5`，锁文件为 `>=3.11.5 <4.0.0` |
| Android 开发 | 需要对应 Android 工具链；Gradle 配置使用 Java 17 |
| API | 自备所选服务的 Key、网络访问条件与可调用模型 |

仓库保留 Android、iOS、Windows、macOS、Linux、Web 工程目录，但没有经过本次跨平台构建验证。主程序直接使用 `dart:io`、本地文件与 `Image.file`，**不能仅凭存在 `web/` 目录就认为当前代码已适配浏览器**；图片权限与桌面网络权限也需要逐平台检查。

### 获取与运行

在本机安装 Flutter、配置目标平台工具链并连接设备后：

```bash
git clone https://github.com/xndxyy/vibe_companion.git
cd vibe_companion

flutter doctor
flutter pub get
flutter devices
flutter run
```

`flutter doctor` 用于检查开发环境，`flutter devices` 用于确认运行目标；`flutter run` 会在需要时提示选择设备。参见 [Flutter 官方文档](https://docs.flutter.dev/)。

以上为对仓库入口与配置的静态核对，**本次文档整理未实际执行依赖安装、Flutter 构建、模型调用或真机测试**。

## 首次配置与使用

> **先了解存储方式：当前 API Key 与聊天记录使用 SharedPreferences 保存，未实现加密密钥保管。请仅用于你能接受这一风险的本地实验，不要在共享设备上填写生产 Key 或敏感对话。**

1. 首次启动后完成界面中的性别选择，进入角色与 API 设置页。
2. 在“角色”页选择预设角色，或在“高级”页创建自定义角色。
3. 切换到“API”页，选择供应商并填写自己的 Key。
4. 若使用“自定义 API”，填写**完整接口地址**与模型名称。代码不会自动补全接口路径。
5. 点击 Key 输入框旁的连接检查按钮，再选择“进入对话”。Google 分支的该按钮只显示“已配置”，**并未发出实际验证请求**，需要在真实对话中验证。
6. 对话页右上角可打开设置，编辑当前角色人设、头像、背景与主动问候选项。

当前进入对话的流程要求 Key 非空，因此即便接入无需认证的本地接口，也需要自行调整这一校验逻辑。

### 供应商适配范围

设置页提供以下代码分支。它们代表**仓库中存在的请求适配**，不代表服务、模型或所有功能已经实测可用。

| 选项 | 当前请求方式 |
| --- | --- |
| OpenAI | Chat Completions 格式，Bearer Key |
| Anthropic / Claude | Messages 格式，`x-api-key` 与版本请求头 |
| Google / Gemini | `generateContent` 格式，Key 放在请求 URL 查询参数中 |
| 通义千问 / DashScope | OpenAI 兼容模式的 Chat Completions 格式 |
| 自定义 API | 完整 URL + 自定义模型名，使用 OpenAI Chat Completions 请求与回复结构、Bearer Key |

预设分支的模型名写在 `lib/main.dart` 的 `_getDefaultModel` 中，区分文字与含图片历史的请求；这些名称可能需要随服务变化更新。“自定义模型名”仅在**自定义 API 模式**下生效，不会覆盖其他预设分支。

不要将 `https://api.example.com/v1/chat/completions` 这样的占位地址当作真实服务。API 额度、费用、地域与模型可用性均需自行确认，仓库不承诺免费或离线模型推理。

## 数据流与隐私

```text
角色设定 + 当前角色聊天历史 + 可选图片
                 ↓
        客户端构造供应商请求
                 ↓
        用户选择的模型 API
                 ↓
       展示回复，并写入本地记录
```

- 没有仓库内自建的服务端或账号同步系统；模型请求由客户端直接发出。
- 常规消息发送会携带当前角色的聊天历史，含历史图片时也会携带图片数据；当前没有历史裁剪或长期记忆检索机制，长对话会增加请求体、上下文占用与费用。
- Key、聊天文本、图片 Base64 与角色配置会进入本地偏好存储；头像与背景另写入应用文档目录。**本地保存不等于加密保存，也不等于消息不出设备。**
- “一键重置”当前清除偏好存储中的键，不是已验证的文件安全擦除；复制到应用目录的图片文件也需要另行处理。
- 不要把 Key、私密聊天、图片或包含 Key 的请求 URL 提交到仓库、日志或问题反馈中。

## 已知限制与使用边界

- **主动问候不是后台服务**：实现依赖聊天页面生命周期中的 `Timer.periodic`，页面销毁会取消定时器；当前页面实例最多尝试 3 次，清理聊天记录会重置计数。它不保证应用切到后台后继续工作。
- **表情素材不随仓库提供**：加载路径硬编码为开发机素材目录（见 `lib/main.dart`），按情绪分类读取本地图片。普通克隆环境可能只看到缺失图片占位；表情回复文字来自本地模板。
- **“心理医生”只是角色提示词**：不具备真实医生资质，不构成诊断、治疗或专业心理咨询。现有提示词与危机应对流程未经专业验证，不应将其部署为面向公众的医疗或紧急求助服务。
- **网络与界面仍需测试**：尚未提供 Flutter 业务 `test/` 目录或 CI 流程，图片读写、不同供应商错误格式、长时间请求与多平台行为均需实际验证。
- **正式分发配置未完成**：Android 保留示例应用标识且 release 使用 debug 签名；iOS 媒体权限说明、桌面沙箱网络权限与正式签名仍需逐项核对。

## 代码导航

| 路径 | 内容 |
| --- | --- |
| [lib/main.dart](lib/main.dart) | 初始化、角色设置页、聊天页、供应商适配、图片消息与本地表情逻辑 |
| [lib/models/character_data.dart](lib/models/character_data.dart) | 当前实际使用的 21 个预设角色 |
| [lib/services/storage_service.dart](lib/services/storage_service.dart) | SharedPreferences 初始化、配置与分角色历史读写、重置 |
| [assets/default_bg.png](assets/default_bg.png) | 默认聊天背景 |
| [pubspec.yaml](pubspec.yaml) / [pubspec.lock](pubspec.lock) | 依赖与资源声明、锁定版本 |
| [android/app/build.gradle.kts](android/app/build.gradle.kts) | Android 工具链、标识与签名配置 |

## 授权说明

仓库当前未附带 LICENSE 文件。公开可读不等于授予任意复制、修改、分发或商用权；复用代码、角色文案及图片素材前，请向作者确认授权并核对第三方素材权利。

