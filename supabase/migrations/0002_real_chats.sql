-- Knot v0.2: direct chats, safe membership checks, and message update timestamps.
-- Apply after 0001_initial_schema.sql in Supabase SQL Editor.

create or replace function public.is_conversation_member(p_conversation_id uuid)
returns boolean
language sql stable security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.conversation_members cm
    where cm.conversation_id = p_conversation_id and cm.user_id = auth.uid()
  );
$$;
revoke all on function public.is_conversation_member(uuid) from public;
grant execute on function public.is_conversation_member(uuid) to authenticated;

-- Replace the recursive membership policies from migration 0001.
drop policy if exists "Members can view membership" on public.conversation_members;
create policy "Members can view membership" on public.conversation_members
for select to authenticated using (public.is_conversation_member(conversation_id));

drop policy if exists "Members can view conversations" on public.conversations;
create policy "Members can view conversations" on public.conversations
for select to authenticated using (public.is_conversation_member(id));

drop policy if exists "Members can read messages" on public.messages;
create policy "Members can read messages" on public.messages
for select to authenticated using (public.is_conversation_member(conversation_id));

drop policy if exists "Senders can edit own messages" on public.messages;
create policy "Senders can edit own messages" on public.messages
for update to authenticated using (sender_id = auth.uid())
with check (sender_id = auth.uid() and public.is_conversation_member(conversation_id));

drop policy if exists "Members can send as themselves" on public.messages;
create policy "Members can send as themselves" on public.messages
for insert to authenticated with check (
  sender_id = auth.uid() and public.is_conversation_member(conversation_id)
);

-- Find an existing one-to-one chat or create it atomically using a Knot ID.
create or replace function public.create_direct_chat(p_knot_id text)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  target_user uuid;
  existing_chat uuid;
  new_chat uuid;
  current_user_id uuid := auth.uid();
begin
  if current_user_id is null then raise exception 'Authentication required'; end if;
  select p.id into target_user from public.profiles p
    where lower(p.knot_id) = lower(trim(p_knot_id));
  if target_user is null then raise exception 'Пользователь с таким Knot ID не найден'; end if;
  if target_user = current_user_id then raise exception 'Нельзя создать чат с самим собой'; end if;

  perform pg_advisory_xact_lock(hashtextextended(least(current_user_id::text, target_user::text) || ':' || greatest(current_user_id::text, target_user::text), 0));

  select c.id into existing_chat
  from public.conversations c
  where c.kind = 'direct'
    and exists (select 1 from public.conversation_members a where a.conversation_id = c.id and a.user_id = current_user_id)
    and exists (select 1 from public.conversation_members b where b.conversation_id = c.id and b.user_id = target_user)
    and (select count(*) from public.conversation_members x where x.conversation_id = c.id) = 2
  limit 1;
  if existing_chat is not null then return existing_chat; end if;

  insert into public.conversations(kind, created_by) values ('direct', current_user_id) returning id into new_chat;
  insert into public.conversation_members(conversation_id, user_id, role)
  values (new_chat, current_user_id, 'owner'), (new_chat, target_user, 'member');
  return new_chat;
end;
$$;
revoke all on function public.create_direct_chat(text) from public;
grant execute on function public.create_direct_chat(text) to authenticated;

-- Clients may update only their own read marker, never their membership role.
revoke update on public.conversation_members from authenticated;
grant update (last_read_at) on public.conversation_members to authenticated;

create or replace function public.touch_conversation_on_message()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  update public.conversations set updated_at = now() where id = new.conversation_id;
  return new;
end;
$$;
drop trigger if exists messages_touch_conversation on public.messages;
create trigger messages_touch_conversation after insert on public.messages
for each row execute procedure public.touch_conversation_on_message();

-- Ensure messages are available to Supabase Realtime. If already present, this is harmlessly skipped.
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'messages'
  ) then
    alter publication supabase_realtime add table public.messages;
  end if;
end $$;
