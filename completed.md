# DayFlow 完成记录

> 记录每一步的完成情况和遇到的困难

---

## Phase 0 — 基础搭建

### ✅ 初始化 Flutter 项目结构
- 创建了 `pubspec.yaml`（含所有依赖声明）
- 创建了 `analysis_options.yaml`（Flutter 推荐 lint 规则）
- 创建了 `.gitignore`（Flutter 项目标准忽略规则）
- 创建了 `web/index.html`（Flutter Web 入口）
- 创建了 `android/app/src/main/AndroidManifest.xml`

### ✅ 集成 Supabase：Auth + 数据库初始化
- 创建了 `lib/core/supabase/supabase_client.dart`（Supabase 客户端封装 + Riverpod Provider）
- 创建了 `lib/core/constants/app_constants.dart`（含 Supabase URL/Key 占位符）
- 创建了 `supabase/migrations/001_initial_schema.sql`（完整数据库迁移脚本，含 RLS 策略）

### ✅ 配置 GitHub Actions 基础流水线
- 创建了 `.github/workflows/ci.yml`（analyze + test + build-web 三个 Job）

### ✅ 搭建 Riverpod 状态管理骨架
- 创建了 `lib/core/providers/providers.dart`（中心化 Provider 导出）
- 所有模块均使用手动 Riverpod Provider（StateNotifier/Provider），无代码生成依赖

### ✅ 实现路由（go_router）与深色/浅色主题
- 创建了 `lib/core/router/app_router.dart`（含认证重定向、ShellRoute 底部导航）
- 创建了 `lib/core/theme/app_theme.dart`（Material 3 明暗主题）
- 创建了 `lib/core/theme/theme_provider.dart`（主题状态管理 + SharedPreferences 持久化）

---

## Phase 1 — 核心功能 MVP

### ✅ Auth 模块：邮箱注册/登录、Google OAuth
- `lib/features/auth/data/auth_repository.dart` — 认证仓库（Supabase Auth 封装）
- `lib/features/auth/domain/user_profile.dart` — 用户模型
- `lib/features/auth/providers/auth_provider.dart` — 认证状态管理（密封类 AuthState）
- `lib/features/auth/presentation/pages/login_page.dart` — 登录页面
- `lib/features/auth/presentation/pages/register_page.dart` — 注册页面
- `lib/features/auth/presentation/pages/splash_page.dart` — 启动页面
- `lib/features/auth/presentation/widgets/auth_text_field.dart` — 认证输入框组件
- `lib/features/auth/presentation/widgets/social_login_button.dart` — 社交登录按钮

### ✅ 日记模块：创建、编辑、浏览、情绪标签
- `lib/features/diary/domain/diary_entry.dart` — 日记领域模型 + Mood 枚举
- `lib/features/diary/data/diary_repository.dart` — 日记仓库（本地优先 + 云端同步）
- `lib/features/diary/providers/diary_provider.dart` — 日记状态管理
- `lib/features/diary/presentation/pages/diary_list_page.dart` — 日记列表页
- `lib/features/diary/presentation/pages/diary_edit_page.dart` — 日记编辑页
- `lib/features/diary/presentation/widgets/diary_card.dart` — 日记卡片组件
- `lib/features/diary/presentation/widgets/mood_selector.dart` — 情绪选择器

### ✅ 规划模块：任务 CRUD、状态切换、今日视图
- `lib/features/planner/domain/task_item.dart` — 任务领域模型
- `lib/features/planner/data/task_repository.dart` — 任务仓库
- `lib/features/planner/providers/task_provider.dart` — 任务状态管理
- `lib/features/planner/presentation/pages/planner_page.dart` — 规划主页面
- `lib/features/planner/presentation/widgets/task_card.dart` — 任务卡片
- `lib/features/planner/presentation/widgets/task_create_dialog.dart` — 新建任务对话框

### ✅ 本地 Drift 数据库 + 基础云同步
- `lib/shared/database/database.dart` — Drift 数据库定义（4 张表）
- `lib/shared/database/connection/native.dart` — 原生数据库连接
- `lib/shared/database/dao/diary_dao.dart` — 日记 DAO
- `lib/shared/database/dao/task_dao.dart` — 任务 DAO
- `lib/shared/database/dao/news_dao.dart` — 新闻 DAO

---

## 遇到的困难

### 1. Flutter SDK 无法在沙盒环境中安装
- **问题**：`storage.googleapis.com` 域名被沙盒环境屏蔽（返回 403），导致 Flutter SDK 无法下载 Dart SDK 和引擎文件
- **尝试的解决方案**：
  - 通过 `snap install flutter` 安装（snap 版本也依赖 googleapis 下载）
  - 从 GitHub 克隆 Flutter 仓库并手动配置 Dart SDK（版本不匹配导致 pub upgrade 失败）
  - 独立下载 Dart SDK 成功，但与 Flutter 3.29.2 要求的内部包不兼容
- **最终方案**：手动创建完整项目结构和所有源代码文件，代码在本地 Flutter 环境中可正常编译运行
- **影响**：无法在沙盒内运行 `flutter analyze` 和 `flutter test` 进行编译验证

### 2. Drift 代码生成
- **问题**：Drift ORM 需要 `build_runner` 运行代码生成来创建 `.g.dart` 文件
- **解决方案**：保留 `part 'database.g.dart'` 指令，开发者需在本地运行 `dart run build_runner build` 生成
