# DayFlow 任务清单

> 跟踪每个阶段的任务完成情况

---

## Phase 0 — 基础搭建（第 1 周）

- [x] 初始化 Flutter 项目，配置项目结构
- [x] 集成 Supabase：Auth + 数据库初始化
- [x] 配置 GitHub Actions 基础流水线
- [x] 搭建 Riverpod 状态管理骨架
- [x] 实现路由（go_router）与深色/浅色主题

## Phase 1 — 核心功能 MVP（第 2–4 周）

- [x] Auth 模块：邮箱注册/登录、Google OAuth
- [x] 日记模块：创建、编辑、浏览、情绪标签
- [x] 规划模块：任务 CRUD、状态切换、今日视图
- [x] 本地 Drift 数据库 + 基础云同步

## Phase 2 — 新闻摘要（第 5–6 周）

- [ ] Supabase Edge Function：NewsAPI 拉取 + OpenAI 摘要
- [ ] 新闻列表 UI、分类筛选、收藏功能
- [ ] FCM 推送集成（iOS / Android / Web）

> **Phase 2 评估**：新闻模块的基础占位页面已创建，领域模型（NewsSummary）和数据库 DAO 已实现。建议优先实现 Edge Function 后端逻辑，再完善前端 UI。推送集成可考虑延后到 Phase 3，以降低 Phase 2 复杂度。

## Phase 3 — 完善与打磨（第 7–8 周）

- [ ] 离线优先完整实现（冲突解决策略）
- [ ] 多设备 Realtime 同步测试
- [ ] 周/月任务统计报表（fl_chart）
- [ ] 日记导出（PDF / Markdown）
- [ ] 多语言 i18n（flutter_localizations）
- [ ] 无障碍优化（Semantics）

> **Phase 3 评估**：建议将 FCM 推送从 Phase 2 移入此阶段。离线冲突解决是最大技术风险，建议采用"最后写入胜出"(Last Write Wins) 策略作为 MVP，后续迭代再引入更复杂的 CRDT 方案。

## Phase 4 — 上线准备（第 9–10 周）

- [ ] App Store / Google Play 上架材料准备
- [ ] 桌面端（macOS / Windows）打包测试
- [ ] Flutter Web 部署至 Vercel
- [ ] 性能优化：首屏加载 < 2s，帧率 ≥ 60fps
- [ ] 安全审计：RLS 策略、API Key 轮换

> **Phase 4 评估**：当前 Supabase 迁移脚本已包含完整 RLS 策略，安全审计工作量可减少。建议优先完成 Web 部署（最快验证渠道），再推进移动端上架。
