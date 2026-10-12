
create function newsroom_private.guard_workflow() returns trigger language plpgsql security invoker set search_path='' as $$
begin
 if tg_op='UPDATE' then
  if old.published_at is not null and new.published_at is distinct from old.published_at then raise exception 'Original publication date is immutable'; end if;
  if new.status<>old.status and not (
   (old.status='draft' and new.status='in_review') or
   (old.status='in_review' and new.status in ('changes_requested','approved')) or
   (old.status='changes_requested' and new.status in ('draft','in_review')) or
   (old.status='approved' and new.status in ('draft','scheduled','published')) or
   (old.status='scheduled' and new.status in ('draft','published')) or
   (old.status='published' and new.status='archived') or
   (old.status='archived' and new.status='draft')
  ) then raise exception 'Invalid editorial transition: % -> %',old.status,new.status; end if;
 end if;
 return new;
end $$;
revoke all on function newsroom_private.guard_workflow() from public,anon,authenticated;
create trigger workflow_guard before update on public.articles for each row execute function newsroom_private.guard_workflow();
create function newsroom_private.protect_admin_membership() returns trigger language plpgsql security invoker set search_path='' as $$
begin
 if auth.uid() is not null and old.user_id=auth.uid() and old.role='super_admin' then
  if tg_op='DELETE' then raise exception 'Super Admin cannot remove their own access'; end if;
  if new.role<>'super_admin' or not new.active or new.user_id<>old.user_id then raise exception 'Super Admin cannot remove their own access'; end if;
 end if;
 return case when tg_op='DELETE' then old else new end;
end $$;
revoke all on function newsroom_private.protect_admin_membership() from public,anon,authenticated;
create trigger protect_admin before update or delete on public.staff_members for each row execute function newsroom_private.protect_admin_membership();

