-- Knot initial schema. Apply to a fresh Supabase project.
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  knot_id text unique not null default ('knot_' || lower(substr(encode(gen_random_bytes(8), 'hex'), 1, 12))),
  display_name text not null default 'Knot user',
  avatar_path text,
  bio text not null default '',
  onboarding_complete boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.conversations (
  id uuid primary key default gen_random_uuid(),
  kind text not null check (kind in ('direct', 'group', 'channel')),
  title text,
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.conversation_members (
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null default 'member' check (role in ('owner', 'admin', 'member')),
  joined_at timestamptz not null default now(),
  last_read_at timestamptz,
  primary key (conversation_id, user_id)
);

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  sender_id uuid not null references auth.users(id),
  body text,
  message_type text not null default 'text' check (message_type in ('text', 'image', 'video', 'file', 'audio', 'system')),
  attachment_path text,
  reply_to uuid references public.messages(id) on delete set null,
  created_at timestamptz not null default now(),
  edited_at timestamptz,
  deleted_at timestamptz,
  constraint message_has_content check (body is not null or attachment_path is not null)
);

create table if not exists public.device_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  token text not null unique,
  platform text not null check (platform in ('ios', 'android')),
  created_at timestamptz not null default now(),
  last_seen_at timestamptz not null default now()
);

create index if not exists messages_conversation_created_idx on public.messages(conversation_id, created_at desc);
create index if not exists members_user_idx on public.conversation_members(user_id, conversation_id);

-- Automatically create a private profile row for every newly authenticated account.
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  insert into public.profiles (id, display_name)
  values (new.id, coalesce(new.raw_user_meta_data ->> 'display_name', 'Knot user'))
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
for each row execute procedure public.handle_new_user();

alter table public.profiles enable row level security;
alter table public.conversations enable row level security;
alter table public.conversation_members enable row level security;
alter table public.messages enable row level security;
alter table public.device_tokens enable row level security;

-- Profiles are discoverable by authenticated users by Knot ID/display name only.
create policy "Authenticated users can view profiles" on public.profiles
for select to authenticated using (true);
create policy "Users can update own profile" on public.profiles
for update to authenticated using (auth.uid() = id) with check (auth.uid() = id);

create policy "Members can view conversations" on public.conversations
for select to authenticated using (
  exists (select 1 from public.conversation_members cm where cm.conversation_id = id and cm.user_id = auth.uid())
);
create policy "Authenticated users can create conversations" on public.conversations
for insert to authenticated with check (created_by = auth.uid());
create policy "Owners can update conversations" on public.conversations
for update to authenticated using (
  exists (select 1 from public.conversation_members cm where cm.conversation_id = id and cm.user_id = auth.uid() and cm.role in ('owner','admin'))
);


-- Atomic conversation creation: creator becomes owner in the same transaction.
create or replace function public.create_conversation(p_kind text, p_title text default null)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  new_id uuid;
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;
  if p_kind not in ('direct', 'group', 'channel') then
    raise exception 'Invalid conversation kind';
  end if;
  insert into public.conversations (kind, title, created_by)
  values (p_kind, nullif(trim(p_title), ''), auth.uid())
  returning id into new_id;
  insert into public.conversation_members (conversation_id, user_id, role)
  values (new_id, auth.uid(), 'owner');
  return new_id;
end;
$$;
revoke all on function public.create_conversation(text, text) from public;
grant execute on function public.create_conversation(text, text) to authenticated;

create policy "Members can view membership" on public.conversation_members
for select to authenticated using (
  exists (select 1 from public.conversation_members mine where mine.conversation_id = conversation_id and mine.user_id = auth.uid())
);
-- Membership is created through the controlled RPC below, never by direct client insert.
create policy "Users can leave or update own membership read marker" on public.conversation_members
for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "Users can leave own membership" on public.conversation_members
for delete to authenticated using (user_id = auth.uid());

create policy "Members can read messages" on public.messages
for select to authenticated using (
  exists (select 1 from public.conversation_members cm where cm.conversation_id = conversation_id and cm.user_id = auth.uid())
);
create policy "Members can send as themselves" on public.messages
for insert to authenticated with check (
  sender_id = auth.uid() and
  exists (select 1 from public.conversation_members cm where cm.conversation_id = conversation_id and cm.user_id = auth.uid())
);
create policy "Senders can edit own messages" on public.messages
for update to authenticated using (sender_id = auth.uid()) with check (sender_id = auth.uid());
create policy "Senders can delete own messages" on public.messages
for delete to authenticated using (sender_id = auth.uid());

create policy "Users manage own device tokens" on public.device_tokens
for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

-- Enable Realtime for message updates. Confirm publication exists in the target project.
alter publication supabase_realtime add table public.messages;
