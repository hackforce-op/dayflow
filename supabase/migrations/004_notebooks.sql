-- DayFlow - 日记本功能数据库迁移
--
-- 新增 notebooks 表和 diary_entries.notebook_id 关联字段。
-- notebook-covers Storage Bucket 及对应 RLS 策略。

-- ============================================================
-- 日记本表
-- ============================================================
CREATE TABLE IF NOT EXISTS notebooks (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  name        TEXT NOT NULL,
  cover_url   TEXT,
  sort_order  INTEGER DEFAULT 0,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  updated_at  TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE notebooks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can CRUD own notebooks"
  ON notebooks FOR ALL USING ((select auth.uid()) = user_id);

CREATE INDEX idx_notebooks_user_sort ON notebooks(user_id, sort_order);

-- ============================================================
-- diary_entries 增加 notebook_id 关联
-- ============================================================
ALTER TABLE diary_entries
  ADD COLUMN IF NOT EXISTS notebook_id UUID REFERENCES notebooks(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_diary_notebook ON diary_entries(notebook_id);

-- ============================================================
-- notebook-covers Storage Bucket
-- ============================================================
INSERT INTO storage.buckets (id, name, public)
VALUES ('notebook-covers', 'notebook-covers', true)
ON CONFLICT (id) DO UPDATE SET public = EXCLUDED.public;

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
