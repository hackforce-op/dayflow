-- DayFlow - Supabase Storage buckets and RLS policies
--
-- 注意：auth.uid() 使用 (select ...) 子查询包裹，
-- 防止 PostgreSQL 查询规划器内联导致 RLS 策略缓存失效（Supabase 官方推荐做法）。
-- SELECT 策略同时授权 anon 和 authenticated 角色，确保:
--   - 匿名用户可通过公开 URL 访问头像/图片
--   - 已认证用户在 upsert 时内部 SELECT 检查也能通过

INSERT INTO storage.buckets (id, name, public)
VALUES
  ('avatars', 'avatars', true),
  ('diary-images', 'diary-images', true)
ON CONFLICT (id) DO UPDATE
SET public = EXCLUDED.public;

-- ============================================================
-- avatars bucket 策略
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
-- diary-images bucket 策略
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