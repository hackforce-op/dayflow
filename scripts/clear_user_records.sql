-- 用法：
-- psql "$SUPABASE_DB_URL" -v user_id="<USER_UUID>" -f scripts/clear_user_records.sql

BEGIN;

DELETE FROM public.diary_entries WHERE user_id = :'user_id'::uuid;
DELETE FROM public.tasks WHERE user_id = :'user_id'::uuid;
DELETE FROM public.news_bookmarks WHERE user_id = :'user_id'::uuid;
DELETE FROM public.profiles WHERE id = :'user_id'::uuid;

COMMIT;
