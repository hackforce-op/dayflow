# DayFlow

DayFlow 是一个使用 Flutter 构建的跨平台个人日常管理应用，当前可以直接运行在：

- Web 浏览器
- Linux 桌面
- Android / iOS

项目入口文件在 [lib/main.dart](lib/main.dart)。

## 第一次启动前要准备什么

1. 安装 Flutter 3.41 或更高版本。
2. 在 Supabase 控制台新建一个项目。
3. 打开 Supabase 控制台的 `Project Settings -> API`，记下这两个值：
	- `Project URL`
	- `anon public key`
4. 把仓库里的 [env.example.json](env.example.json) 复制成项目根目录下的 `env.json`，并填入你的真实值。
5. 在 Supabase 控制台执行 [supabase/migrations/001_initial_schema.sql](supabase/migrations/001_initial_schema.sql) 里的 SQL，初始化表结构和 RLS。

`env.json` 示例：

```json
{
  "SUPABASE_URL": "https://your-project-ref.supabase.co",
  "SUPABASE_ANON_KEY": "your-supabase-anon-key"
}
```

## Supabase 控制台还要配什么

为了让浏览器登录和邮箱验证能正确跳回应用，请在 Supabase 控制台配置：

1. `Authentication -> URL Configuration -> Site URL` 填 `http://localhost:3000`
2. `Authentication -> URL Configuration -> Redirect URLs` 至少加入：
	- `http://localhost:3000`
	- `io.supabase.dayflow://login-callback/`

如果你准备启用 Google 登录，还需要在 `Authentication -> Providers -> Google` 中打开 Google Provider，并按 Supabase 页面提示配置 Google Cloud OAuth。

## 第一次启动命令

先安装依赖并生成 Drift 数据库代码：

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

启动 Web 版：

```bash
flutter run -d chrome --web-port=3000 --dart-define-from-file=env.json
```

如果你是在 WSL 里运行，并且 Flutter 提示找不到 `chrome`，请改用：

```bash
CHROME_EXECUTABLE='/mnt/c/Users/<你的 Windows 用户名>/AppData/Local/Google/Chrome/Application/chrome.exe' flutter run -d chrome --web-port=3000 --dart-define-from-file=env.json
```

如果你不想让 Flutter 直接管理浏览器，也可以启动内置 Web Server，再手动用 Windows 浏览器打开：

```bash
flutter run -d web-server --web-port=3000 --dart-define-from-file=env.json
```

然后在 Windows 浏览器访问 `http://localhost:3000`。

启动 Linux 桌面版：

```bash
flutter run -d linux --dart-define-from-file=env.json
```

当前仓库已经内置中文字体资源。修改后第一次重新运行时，Flutter 会把字体打进 Linux/Web 构建产物里。

每次启动应用后，都会先进入“账号选择页”，可快速选择历史登录账号或切换到新账号登录。

## 常用验证命令

静态检查：

```bash
flutter analyze --no-fatal-infos
```

运行全部测试：

```bash
flutter test
```

只运行某一个测试文件：

```bash
flutter test test/diary_and_planner_pages_test.dart
```

只运行某个名字包含关键字的测试：

```bash
flutter test --plain-name "DiaryListPage"
```

清理单个用户全部记录（Supabase SQL，一条命令）：

```bash
psql "$SUPABASE_DB_URL" -v user_id="<USER_UUID>" -f scripts/clear_user_records.sql
```

## 现在的启动顺序

这个仓库没有你自己维护的后端服务器进程要先启动。

DayFlow 的启动顺序是：

1. 先准备 Supabase 云项目。
2. 再运行 Flutter 客户端。
3. 客户端启动时自动连接 Supabase。

也就是说，你不需要先开“本地后端服务”，只需要把 Supabase 云项目配置好，然后直接跑 Flutter 应用。