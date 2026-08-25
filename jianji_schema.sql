-- ============================================================
-- 简记记账 · Supabase 表结构
-- 在 Supabase 控制台（https://supabase.com）的 SQL Editor 里整段执行即可。
-- 说明：仅新建 jianji_state 一张表，完全不影响你减脂 App 的 sync_state 数据。
-- ============================================================

-- 账本同步表：每个「账本码」一行，data 内存放 records + settings 的整体快照
create table if not exists jianji_state (
  ledger_code text primary key,
  data        jsonb not null default '{}'::jsonb,
  updated_at  timestamptz not null default now()
);

-- 开启 Realtime 实时推送（一方保存，另一端秒级刷新）
alter publication supabase_realtime add table jianji_state;

-- 关闭行级安全（RLS）：个人私用工具，用账本码做弱隔离即可。
-- （账本码=随机秘密串，等同于访问凭证；知道码才能读写该账本）
alter table jianji_state disable row level security;
