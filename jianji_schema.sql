-- ============================================================
-- 简记记账 · Supabase 表结构（v2：按记录增量同步）
-- 在 Supabase 控制台（https://supabase.com）的 SQL Editor 里整段执行即可。
-- 说明：仅新建 jianji_records / jianji_meta 两张表，完全不影响你减脂 App 的 sync_state 数据。
-- 旧的 jianji_state 表不会被删除（无害，可留可手动 DROP）。
-- ============================================================

-- 记录表：每笔账目一行（按记录的变更流同步，杜绝整包覆盖丢条）
--   ledger_code : 账本码（即同步码）
--   id          : 记录 UUID（跨端唯一主键，不用数据库自增 ID）
--   data        : 记录完整内容(jsonb)
--   is_deleted  : 软删除标记（禁止物理删除，删除=标记 1）
--   version     : 版本号，每次修改 +1，用于乐观锁并发防覆盖
--   updated_at  : 服务端时间
create table if not exists jianji_records (
  ledger_code text        not null,
  id          text        not null,
  data        jsonb       not null,
  is_deleted  boolean     not null default false,
  version     integer     not null default 1,
  updated_at  timestamptz not null default now(),
  primary key (ledger_code, id)
);

-- 设置表：分类/平台/消费类型，每账本一行（小数据，独立实时同步）
create table if not exists jianji_meta (
  ledger_code text    primary key,
  settings    jsonb   not null default '{}'::jsonb,
  version     integer not null default 1,
  updated_at  timestamptz not null default now()
);

-- 开启 Realtime 实时推送（一方保存，另一方秒级刷新；含 INSERT/UPDATE/DELETE）
do $$
begin
  if not exists (select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='jianji_records') then
    execute 'alter publication supabase_realtime add table jianji_records';
  end if;
  if not exists (select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='jianji_meta') then
    execute 'alter publication supabase_realtime add table jianji_meta';
  end if;
end $$;

-- 关闭行级安全（RLS）：个人私用工具，用账本码做弱隔离即可。
-- （账本码=随机秘密串，等同于访问凭证；知道码才能读写该账本）
alter table jianji_records disable row level security;
alter table jianji_meta    disable row level security;
