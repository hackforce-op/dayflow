# DayFlow 项目计划书

> 一款跨平台（手机 / 电脑 / 网页）的个人日常管理应用，覆盖日记记录、每日规划与每日新闻摘要三大核心功能。

---

## 目录

1. [项目概述](#1-项目概述)
2. [功能需求](#2-功能需求)
3. [技术栈选型](#3-技术栈选型)
4. [系统架构](#4-系统架构)
5. [数据库设计](#5-数据库设计)
6. [开发阶段与里程碑](#6-开发阶段与里程碑)
7. [部署方案](#7-部署方案)
8. [风险与应对](#8-风险与应对)

---

## 1. 项目概述

**DayFlow** 致力于帮助用户在同一平台上完成每日生活与工作的闭环管理：

- 随时随地写日记，沉淀个人思考；
- 制定当日计划，提升执行效率；
- 一键获取当日重要新闻的 AI 摘要，节省阅读时间。

目标运行环境：

| 终端 | 目标平台 |
|------|---------|
| 手机 | iOS 16+、Android 10+ |
| 电脑 | macOS 12+、Windows 10+ |
| 网页 | 现代浏览器（Chrome / Safari / Firefox / Edge） |

---

## 2. 功能需求

### 2.1 日记模块

- 富文本编辑器（支持加粗、列表、图片插入）
- 按日期浏览 / 搜索历史日记
- 情绪标签（开心 / 平静 / 焦虑等）
- 本地加密存储 + 云端同步
- 导出为 PDF / Markdown

### 2.2 每日规划模块

- 任务创建：标题、描述、优先级、截止时间
- 拖拽排序，支持子任务
- 状态追踪：待办 / 进行中 / 完成
- 周 / 月维度统计报表
- 与系统日历集成（iOS Calendar / Google Calendar）

### 2.3 每日新闻摘要模块

- 接入多个新闻源（国内外）
- 按分类筛选：科技、财经、体育、娱乐等
- 每日自动生成 AI 摘要（200 字以内）
- 支持收藏与分享
- 推送通知（每日早间定时推送）

### 2.4 通用功能

- 账号体系（邮箱 / Apple / Google / GitHub 登录）
- 多设备数据实时同步
- 深色模式 / 主题自定义
- 多语言（简体中文 / 英文）
- 离线可用，联网后自动同步

---

## 3. 技术栈选型

### 3.1 跨平台前端框架 — **Flutter (Dart)**

| 维度 | 说明 |
|------|------|
| 选择原因 | Flutter 原生支持 iOS、Android、macOS、Windows 及 Web **同一套代码库**，不需要为每个平台分别维护项目。渲染引擎（Skia / Impeller）完全自绘，UI 一致性极高，性能接近原生。 |
| 替代方案 | React Native（JS Bridge 性能瓶颈）；Electron（桌面端打包体积过大，移动端需额外框架）；均无法用同一代码库覆盖所有五个平台。 |
| 版本 | Flutter 3.22+ / Dart 3.4+ |

### 3.2 状态管理 — **Riverpod 2.x**

选择原因：
- 编译期安全，无 `BuildContext` 依赖，可在任意层使用；
- 支持异步状态（`AsyncNotifier`），天然契合数据流场景；
- 与 Flutter Hooks 结合后代码简洁，测试友好。

### 3.3 本地数据库 — **Drift（SQLite）**

选择原因：
- 类型安全的 ORM，代码生成避免 SQL 字符串拼接错误；
- 支持响应式查询流（`Stream`），数据变更自动刷新 UI；
- 跨所有 Flutter 平台（移动 / 桌面 / Web via `sql.js`）。

### 3.4 后端服务 — **Supabase（Backend as a Service）**

| 维度 | 说明 |
|------|------|
| 选择原因 | Supabase 提供**开箱即用**的 PostgreSQL 数据库、实时订阅（Realtime）、身份认证（Auth）、文件存储（Storage）和 Edge Functions，极大降低后端开发与运维成本。其开源特性也支持私有化部署。 |
| 替代方案 | Firebase（闭源、定价不透明、NoSQL 查询能力弱）；自建 Node.js 后端（开发成本高、运维负担重）。 |

**Supabase 功能使用清单：**

- `supabase_flutter` SDK 负责客户端与 Supabase 通信
- **Auth**：邮箱密码 + OAuth（Apple / Google / GitHub）
- **PostgreSQL**：存储日记、任务、用户配置
- **Realtime**：多设备数据实时同步
- **Storage**：日记图片附件存储
- **Edge Functions**（Deno）：新闻拉取 + AI 摘要定时任务

### 3.5 AI 摘要服务 — **OpenAI API（GPT-4o-mini）**

选择原因：
- GPT-4o-mini 成本低（约 $0.15 / 百万 token），适合每日批量摘要；
- 中英文均表现出色，支持结构化输出（JSON mode）；
- API 接入简单，可随时替换为其他 LLM（如 Claude、Gemini）。

调用链路：Supabase Edge Function（定时触发）→ 新闻 RSS/API → GPT-4o-mini 摘要 → 写入 PostgreSQL。

### 3.6 新闻数据源

| 数据源 | 用途 |
|--------|------|
| **NewsAPI.org** | 全球新闻聚合，支持关键词 / 分类过滤 |
| **今日头条 / 腾讯新闻 RSS** | 国内新闻补充 |
| **The Guardian API** | 英文优质内容 |

### 3.7 推送通知 — **Firebase Cloud Messaging（FCM）**

选择原因：
- 业界标准，支持 iOS / Android / Web 三端统一推送；
- 免费额度满足大多数应用场景；
- `firebase_messaging` Flutter 插件成熟稳定。

### 3.8 富文本编辑器 — **flutter_quill**

选择原因：
- 基于 Quill.js 数据模型，Delta 格式可序列化存储；
- 原生支持图片、列表、标题等常见格式；
- 跨平台表现一致。

### 3.9 CI/CD — **GitHub Actions + Fastlane**

| 工具 | 用途 |
|------|------|
| GitHub Actions | 自动化测试、代码检查（`flutter analyze`）、Web 部署 |
| Fastlane | iOS（TestFlight）、Android（Play Store）自动化发布 |
| Vercel | Flutter Web 静态站点托管，支持 CDN 加速 |

### 3.10 完整技术栈总览

```
┌─────────────────────────────────────────────────────┐
│                    客户端（Flutter）                    │
│  iOS │ Android │ macOS │ Windows │ Flutter Web       │
│  状态管理: Riverpod  │  本地DB: Drift(SQLite)          │
│  富文本: flutter_quill │ 推送: FCM                     │
└──────────────────────┬──────────────────────────────┘
                       │ HTTPS / WebSocket
┌──────────────────────▼──────────────────────────────┐
│                  Supabase（BaaS）                     │
│  PostgreSQL │ Auth │ Realtime │ Storage              │
│  Edge Functions（Deno）                               │
│    ├─ 每日新闻拉取（NewsAPI / RSS）                    │
│    └─ OpenAI GPT-4o-mini 摘要生成                    │
└─────────────────────────────────────────────────────┘
```

---

## 4. 系统架构

采用**客户端优先（Client-first）+ BaaS**架构：

1. **离线优先**：所有数据先写入本地 Drift 数据库，网络恢复后通过 Supabase Realtime 同步到云端。
2. **实时同步**：Supabase Realtime（基于 PostgreSQL logical replication）将变更推送到所有已登录设备。
3. **定时任务**：Supabase Edge Function 每天早上 7:00（用户本地时间）拉取新闻并生成摘要，写入数据库后通过 FCM 推送通知。

**Flutter 项目目录结构（Feature-first）：**

```
lib/
├── core/                  # 全局配置、路由、主题、依赖注入
│   ├── router/
│   ├── theme/
│   └── supabase/
├── features/
│   ├── auth/              # 登录 / 注册
│   ├── diary/             # 日记模块
│   ├── planner/           # 每日规划模块
│   └── news/              # 新闻摘要模块
├── shared/                # 通用 Widget、工具类
└── main.dart
```

---

## 5. 数据库设计

### PostgreSQL（Supabase）核心表

```sql
-- 用户扩展信息
CREATE TABLE profiles (
  id          UUID PRIMARY KEY REFERENCES auth.users(id),
  display_name TEXT,
  avatar_url  TEXT,
  settings    JSONB DEFAULT '{}',
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- 日记
CREATE TABLE diary_entries (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID REFERENCES profiles(id) ON DELETE CASCADE,
  content     JSONB NOT NULL,        -- Quill Delta 格式
  mood        TEXT,
  date        DATE NOT NULL,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  updated_at  TIMESTAMPTZ DEFAULT NOW()
);

-- 任务
CREATE TABLE tasks (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID REFERENCES profiles(id) ON DELETE CASCADE,
  title       TEXT NOT NULL,
  description TEXT,
  priority    SMALLINT DEFAULT 2,    -- 1:高 2:中 3:低
  status      TEXT DEFAULT 'todo',  -- todo / in_progress / done
  due_date    DATE,
  sort_order  INTEGER DEFAULT 0,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- 新闻摘要（全局共享，非用户级别）
CREATE TABLE news_summaries (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  date        DATE NOT NULL,
  category    TEXT NOT NULL,
  headline    TEXT NOT NULL,
  summary     TEXT NOT NULL,         -- AI 生成摘要
  source_url  TEXT,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- 用户收藏的新闻
CREATE TABLE news_bookmarks (
  user_id     UUID REFERENCES profiles(id) ON DELETE CASCADE,
  news_id     UUID REFERENCES news_summaries(id) ON DELETE CASCADE,
  PRIMARY KEY (user_id, news_id)
);
```

---

## 6. 开发阶段与里程碑

### Phase 0 — 基础搭建（第 1 周）

- [x] 初始化 Flutter 项目，配置 `flutter_flavors`（dev / prod）
- [ ] 集成 Supabase：Auth + 数据库初始化
- [ ] 配置 GitHub Actions 基础流水线
- [ ] 搭建 Riverpod 状态管理骨架
- [ ] 实现路由（`go_router`）与深色/浅色主题

### Phase 1 — 核心功能 MVP（第 2–4 周）

- [ ] **Auth 模块**：邮箱注册/登录、Google OAuth
- [ ] **日记模块**：创建、编辑、浏览、情绪标签
- [ ] **规划模块**：任务 CRUD、状态切换、今日视图
- [ ] 本地 Drift 数据库 + 基础云同步

### Phase 2 — 新闻摘要（第 5–6 周）

- [ ] Supabase Edge Function：NewsAPI 拉取 + OpenAI 摘要
- [ ] 新闻列表 UI、分类筛选、收藏功能
- [ ] FCM 推送集成（iOS / Android / Web）

### Phase 3 — 完善与打磨（第 7–8 周）

- [ ] 离线优先完整实现（冲突解决策略）
- [ ] 多设备 Realtime 同步测试
- [ ] 周 / 月任务统计报表（`fl_chart`）
- [ ] 日记导出（PDF / Markdown）
- [ ] 多语言 i18n（`flutter_localizations`）
- [ ] 无障碍优化（Semantics）

### Phase 4 — 上线准备（第 9–10 周）

- [ ] App Store / Google Play 上架材料准备
- [ ] 桌面端（macOS / Windows）打包测试
- [ ] Flutter Web 部署至 Vercel
- [ ] 性能优化：首屏加载 < 2s，帧率 ≥ 60fps
- [ ] 安全审计：RLS 策略、API Key 轮换

---

## 7. 部署方案

| 平台 | 方案 |
|------|------|
| iOS | App Store（Fastlane + GitHub Actions） |
| Android | Google Play（Fastlane + GitHub Actions） |
| macOS | Mac App Store / 直接分发 DMG |
| Windows | Microsoft Store / 直接分发 MSIX |
| Web | Vercel（Flutter Web，自动从 main 分支部署） |
| 后端 | Supabase Cloud（免费套餐起步，按需升级） |

---

## 8. 风险与应对

| 风险 | 概率 | 影响 | 应对措施 |
|------|------|------|---------|
| OpenAI API 费用超预期 | 中 | 中 | 限制每日摘要数量；评估切换至本地 LLM（Ollama） |
| Flutter Web 性能不佳 | 中 | 中 | 关键页面使用 `CanvasKit` 渲染；考虑 PWA 优化 |
| Supabase 免费限额触达 | 低 | 低 | 升级至 Pro 计划（$25/月），或迁移至自托管实例 |
| 国内新闻 API 不稳定 | 高 | 中 | 多数据源冗余；本地缓存兜底 |
| iOS 审核周期延长 | 低 | 中 | 预留 2 周审核缓冲；优先发布 Web 版和 Android 版 |

---

## 附录：主要依赖包

```yaml
# pubspec.yaml 关键依赖
dependencies:
  # 状态管理
  flutter_riverpod: ^2.5.0
  riverpod_annotation: ^2.3.0
  # 路由
  go_router: ^14.0.0
  # 本地数据库
  drift: ^2.20.0
  drift_sqflite: ^2.2.0          # 移动端
  drift_wasm: ^0.0.1             # Web 端
  # 后端
  supabase_flutter: ^2.5.0
  # 推送
  firebase_messaging: ^15.0.0
  # 富文本编辑
  flutter_quill: ^10.0.0
  # 图表
  fl_chart: ^0.68.0
  # 国际化
  flutter_localizations: sdk: flutter
  intl: ^0.19.0

dev_dependencies:
  build_runner: ^2.4.0
  riverpod_generator: ^2.4.0
  drift_dev: ^2.20.0
  flutter_lints: ^4.0.0
```

---

*文档版本：v1.0.0 | 创建日期：2026-03-24 | 项目：DayFlow*
