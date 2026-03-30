/// DayFlow - Supabase 数据库迁移脚本
///
/// 创建核心数据表：profiles、diary_entries、tasks、news_summaries、news_bookmarks
/// 包含行级安全策略 (RLS) 确保数据隔离

-- ============================================================
-- 用户扩展信息表
-- ============================================================
CREATE TABLE IF NOT EXISTS profiles (
  id          UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name TEXT,
  avatar_url  TEXT,
  settings    JSONB DEFAULT '{}',
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- 启用 RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- 用户只能访问自己的 profile
CREATE POLICY "Users can view own profile"
  ON profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can insert own profile"
  ON profiles FOR INSERT WITH CHECK (auth.uid() = id);

-- ============================================================
-- 日记表
-- ============================================================
CREATE TABLE IF NOT EXISTS diary_entries (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  content     TEXT NOT NULL,
  mood        TEXT,
  date        TIMESTAMPTZ NOT NULL,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  updated_at  TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE diary_entries ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can CRUD own diary entries"
  ON diary_entries FOR ALL USING (auth.uid() = user_id);

-- ============================================================
-- 任务表
-- ============================================================
CREATE TABLE IF NOT EXISTS tasks (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  title       TEXT NOT NULL,
  description TEXT,
  priority    SMALLINT DEFAULT 2,
  status      TEXT DEFAULT 'todo',
  due_date    TIMESTAMPTZ,
  sort_order  INTEGER DEFAULT 0,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can CRUD own tasks"
  ON tasks FOR ALL USING (auth.uid() = user_id);

-- ============================================================
-- 新闻摘要表（全局共享）
-- ============================================================
CREATE TABLE IF NOT EXISTS news_summaries (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  date        DATE NOT NULL,
  category    TEXT NOT NULL,
  headline    TEXT NOT NULL,
  summary     TEXT NOT NULL,
  source_url  TEXT,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE news_summaries ENABLE ROW LEVEL SECURITY;

-- 所有已登录用户可读
CREATE POLICY "Authenticated users can read news"
  ON news_summaries FOR SELECT USING (auth.role() = 'authenticated');

-- ============================================================
-- 新闻收藏表
-- ============================================================
CREATE TABLE IF NOT EXISTS news_bookmarks (
  user_id     UUID REFERENCES profiles(id) ON DELETE CASCADE,
  news_id     UUID REFERENCES news_summaries(id) ON DELETE CASCADE,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (user_id, news_id)
);

ALTER TABLE news_bookmarks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can CRUD own bookmarks"
  ON news_bookmarks FOR ALL USING (auth.uid() = user_id);

-- ============================================================
-- 索引优化
-- ============================================================
CREATE INDEX idx_diary_user_date ON diary_entries(user_id, date DESC);
CREATE INDEX idx_tasks_user_status ON tasks(user_id, status);
CREATE INDEX idx_tasks_user_due ON tasks(user_id, due_date);
CREATE INDEX idx_news_date_category ON news_summaries(date DESC, category);

-- ============================================================
-- 自动创建 profile 触发器
-- 当新用户注册时自动在 profiles 表中创建记录
-- ============================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, display_name, avatar_url)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'display_name', NEW.email),
    NEW.raw_user_meta_data->>'avatar_url'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
