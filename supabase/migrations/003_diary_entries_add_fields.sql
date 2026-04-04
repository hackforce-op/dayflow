-- ============================================================
-- DayFlow - 日记表新增字段迁移
-- ============================================================
--
-- 为 diary_entries 表添加 v3 所需的新字段：
-- - location: 地理位置坐标（"纬度,经度"）
-- - location_name: 经 geocoding 解析后的可读地址
-- - image_urls: 图片 URL 列表（逗号分隔）
--
-- 这些字段在本地 Drift 数据库 v3 迁移中已添加，
-- 此 SQL 脚本用于同步 Supabase 云端表结构。
-- ============================================================

ALTER TABLE diary_entries
  ADD COLUMN IF NOT EXISTS location      TEXT,
  ADD COLUMN IF NOT EXISTS location_name TEXT,
  ADD COLUMN IF NOT EXISTS image_urls    TEXT;
