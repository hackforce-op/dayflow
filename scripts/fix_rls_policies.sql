-- ================================================================
-- DayFlow - 一键修复脚本
--
-- 请在 Supabase Dashboard → SQL Editor 中运行此脚本！
-- 此脚本修复 Storage 和 Profiles 表的 RLS 策略。
-- 安全：使用 DROP IF EXISTS 和 ON CONFLICT，可重复运行。
-- ================================================================

-- ============================================================
-- 1. 修复 profiles 表 RLS 策略（使用 (select auth.uid()) 防缓存）
-- ============================================================
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
CREATE POLICY "Users can view own profile"
  ON profiles FOR SELECT USING ((select auth.uid()) = id);

DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE USING ((select auth.uid()) = id);

DROP POLICY IF EXISTS "Users can insert own profile" ON profiles;
CREATE POLICY "Users can insert own profile"
  ON profiles FOR INSERT WITH CHECK ((select auth.uid()) = id);

-- ============================================================
-- 2. 确保 Storage Buckets 存在且是 public
-- ============================================================
INSERT INTO storage.buckets (id, name, public)
VALUES
  ('avatars', 'avatars', true),
  ('diary-images', 'diary-images', true),
  ('notebook-covers', 'notebook-covers', true)
ON CONFLICT (id) DO UPDATE
SET public = EXCLUDED.public;

-- ============================================================
-- 3. 修复 avatars bucket 所有 RLS 策略
-- ============================================================
DROP POLICY IF EXISTS "avatars are publicly readable" ON storage.objects;
CREATE POLICY "avatars are publicly readable"
ON storage.objects FOR SELECT TO anon
USING (bucket_id = 'avatars');

DROP POLICY IF EXISTS "avatars are readable by authenticated" ON storage.objects;
CREATE POLICY "avatars are readable by authenticated"
ON storage.objects FOR SELECT TO authenticated
USING (bucket_id = 'avatars');

DROP POLICY IF EXISTS "users can upload own avatars" ON storage.objects;
CREATE POLICY "users can upload own avatars"
ON storage.objects FOR INSERT TO authenticated
WITH CHECK (
  bucket_id = 'avatars'
  AND (select auth.uid())::text = (storage.foldername(name))[1]
);

DROP POLICY IF EXISTS "users can update own avatars" ON storage.objects;
CREATE POLICY "users can update own avatars"
ON storage.objects FOR UPDATE TO authenticated
USING (
  bucket_id = 'avatars'
  AND (select auth.uid())::text = (storage.foldername(name))[1]
)
WITH CHECK (
  bucket_id = 'avatars'
  AND (select auth.uid())::text = (storage.foldername(name))[1]
);

DROP POLICY IF EXISTS "users can delete own avatars" ON storage.objects;
CREATE POLICY "users can delete own avatars"
ON storage.objects FOR DELETE TO authenticated
USING (
  bucket_id = 'avatars'
  AND (select auth.uid())::text = (storage.foldername(name))[1]
);

-- ============================================================
-- 4. 修复 diary-images bucket 所有 RLS 策略
-- ============================================================
DROP POLICY IF EXISTS "diary images are publicly readable" ON storage.objects;
CREATE POLICY "diary images are publicly readable"
ON storage.objects FOR SELECT TO anon
USING (bucket_id = 'diary-images');

DROP POLICY IF EXISTS "diary images are readable by authenticated" ON storage.objects;
CREATE POLICY "diary images are readable by authenticated"
ON storage.objects FOR SELECT TO authenticated
USING (bucket_id = 'diary-images');

DROP POLICY IF EXISTS "users can upload own diary images" ON storage.objects;
CREATE POLICY "users can upload own diary images"
ON storage.objects FOR INSERT TO authenticated
WITH CHECK (
  bucket_id = 'diary-images'
  AND (select auth.uid())::text = (storage.foldername(name))[1]
);

DROP POLICY IF EXISTS "users can update own diary images" ON storage.objects;
CREATE POLICY "users can update own diary images"
ON storage.objects FOR UPDATE TO authenticated
USING (
  bucket_id = 'diary-images'
  AND (select auth.uid())::text = (storage.foldername(name))[1]
)
WITH CHECK (
  bucket_id = 'diary-images'
  AND (select auth.uid())::text = (storage.foldername(name))[1]
);

DROP POLICY IF EXISTS "users can delete own diary images" ON storage.objects;
CREATE POLICY "users can delete own diary images"
ON storage.objects FOR DELETE TO authenticated
USING (
  bucket_id = 'diary-images'
  AND (select auth.uid())::text = (storage.foldername(name))[1]
);

-- ============================================================
-- 5. notebook-covers bucket RLS 策略
-- ============================================================
DROP POLICY IF EXISTS "notebook covers are publicly readable by anon" ON storage.objects;
CREATE POLICY "notebook covers are publicly readable by anon"
ON storage.objects FOR SELECT TO anon
USING (bucket_id = 'notebook-covers');

DROP POLICY IF EXISTS "notebook covers are readable by authenticated" ON storage.objects;
CREATE POLICY "notebook covers are readable by authenticated"
ON storage.objects FOR SELECT TO authenticated
USING (bucket_id = 'notebook-covers');

DROP POLICY IF EXISTS "users can upload own notebook covers" ON storage.objects;
CREATE POLICY "users can upload own notebook covers"
ON storage.objects FOR INSERT TO authenticated
WITH CHECK (
  bucket_id = 'notebook-covers'
  AND (select auth.uid())::text = (storage.foldername(name))[1]
);

DROP POLICY IF EXISTS "users can update own notebook covers" ON storage.objects;
CREATE POLICY "users can update own notebook covers"
ON storage.objects FOR UPDATE TO authenticated
USING (
  bucket_id = 'notebook-covers'
  AND (select auth.uid())::text = (storage.foldername(name))[1]
)
WITH CHECK (
  bucket_id = 'notebook-covers'
  AND (select auth.uid())::text = (storage.foldername(name))[1]
);

DROP POLICY IF EXISTS "users can delete own notebook covers" ON storage.objects;
CREATE POLICY "users can delete own notebook covers"
ON storage.objects FOR DELETE TO authenticated
USING (
  bucket_id = 'notebook-covers'
  AND (select auth.uid())::text = (storage.foldername(name))[1]
);

-- ============================================================
-- 6. 修复其他表的 RLS 策略
-- ============================================================
DROP POLICY IF EXISTS "Users can CRUD own diary entries" ON diary_entries;
CREATE POLICY "Users can CRUD own diary entries"
  ON diary_entries FOR ALL USING ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can CRUD own tasks" ON tasks;
CREATE POLICY "Users can CRUD own tasks"
  ON tasks FOR ALL USING ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can CRUD own bookmarks" ON news_bookmarks;
CREATE POLICY "Users can CRUD own bookmarks"
  ON news_bookmarks FOR ALL USING ((select auth.uid()) = user_id);

-- ============================================================
-- 完成！如果以上全部成功执行，头像上传问题应该已修复。
-- ============================================================
