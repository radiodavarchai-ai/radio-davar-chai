-- =============================================================
-- Rádio Cristã Online — banco de dados (Supabase)
-- Cole tudo no Supabase: SQL Editor → New query → Run
-- =============================================================

-- PERFIS (criado automaticamente quando alguém se cadastra)
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  nome text,
  role text not null default 'ouvinte' check (role in ('ouvinte','admin')),
  created_at timestamptz not null default now()
);

create or replace function public.is_admin() returns boolean
language sql stable security definer set search_path = public as $$
  select exists(select 1 from public.profiles where id = auth.uid() and role = 'admin');
$$;

create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, nome) values (new.id, coalesce(new.raw_user_meta_data->>'nome', split_part(new.email,'@',1)));
  return new;
end; $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
  for each row execute function public.handle_new_user();

-- DEVOCIONAIS (um por dia; datas futuras ficam agendadas)
create table if not exists public.devocionais (
  id bigint generated always as identity primary key,
  data date not null,
  titulo text not null,
  referencia text not null,
  versiculo text not null,
  texto text not null,
  pergunta text,
  oracao text,
  created_at timestamptz not null default now()
);

-- ESTUDOS BÍBLICOS
create table if not exists public.estudos (
  id bigint generated always as identity primary key,
  titulo text not null,
  serie text,
  referencia text not null,
  contexto text,
  texto text not null,
  perguntas text,
  created_at timestamptz not null default now()
);

-- PEDIDOS DE ORAÇÃO (público = mural; privado = só equipe e o autor)
create table if not exists public.pedidos (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users(id) on delete cascade default auth.uid(),
  nome text not null check (char_length(nome) <= 60),
  pedido text not null check (char_length(pedido) <= 1200),
  publico boolean not null default true,
  status text not null default 'recebido' check (status in ('recebido','orado')),
  oracoes_count int not null default 0,
  created_at timestamptz not null default now()
);

-- QUEM CLICOU "ORAMOS POR VOCÊ" (um registro por pessoa por pedido)
create table if not exists public.oracoes_feitas (
  pedido_id bigint references public.pedidos(id) on delete cascade,
  user_id uuid references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (pedido_id, user_id)
);

create or replace function public.orar_por(p_pedido bigint) returns void
language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null then raise exception 'Entre na sua conta para orar.'; end if;
  if not exists (select 1 from pedidos where id = p_pedido and publico) then raise exception 'Pedido não encontrado.'; end if;
  insert into oracoes_feitas (pedido_id, user_id) values (p_pedido, auth.uid()) on conflict do nothing;
  if found then update pedidos set oracoes_count = oracoes_count + 1 where id = p_pedido; end if;
end; $$;

-- ================= REGRAS DE ACESSO (RLS) =================
alter table public.profiles       enable row level security;
alter table public.devocionais    enable row level security;
alter table public.estudos        enable row level security;
alter table public.pedidos        enable row level security;
alter table public.oracoes_feitas enable row level security;

-- perfis: cada um vê o seu; equipe vê todos. Ninguém muda o próprio papel pelo app.
create policy "perfil proprio" on public.profiles for select using (id = auth.uid() or public.is_admin());

-- conteúdo: todos leem (mesmo sem login); só a equipe publica
create policy "ler devocionais" on public.devocionais for select using (true);
create policy "equipe devocionais" on public.devocionais for all using (public.is_admin()) with check (public.is_admin());
create policy "ler estudos" on public.estudos for select using (true);
create policy "equipe estudos" on public.estudos for all using (public.is_admin()) with check (public.is_admin());

-- pedidos: mural público para todos; privados só para o autor e a equipe
create policy "ver pedidos" on public.pedidos for select
  using (publico or user_id = auth.uid() or public.is_admin());
create policy "criar pedido" on public.pedidos for insert
  with check (auth.uid() = user_id and status = 'recebido' and oracoes_count = 0);
create policy "equipe atualiza" on public.pedidos for update using (public.is_admin()) with check (public.is_admin());
create policy "apagar pedido" on public.pedidos for delete using (user_id = auth.uid() or public.is_admin());

create policy "minhas oracoes" on public.oracoes_feitas for select using (user_id = auth.uid());

grant execute on function public.orar_por(bigint) to authenticated;

-- ================= TESTEMUNHOS =================
-- Enviados pelos ouvintes; só aparecem no app depois que a equipe aprova.
create table if not exists public.testemunhos (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users(id) on delete cascade default auth.uid(),
  nome text not null check (char_length(nome) <= 60),
  cidade text check (char_length(cidade) <= 60),
  categoria text,
  titulo text not null check (char_length(titulo) <= 90),
  texto text not null check (char_length(texto) <= 2000),
  ler_radio boolean not null default false,
  status text not null default 'pendente' check (status in ('pendente','aprovado','recusado')),
  gloria_count int not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.gloria_feita (
  testemunho_id bigint references public.testemunhos(id) on delete cascade,
  user_id uuid references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (testemunho_id, user_id)
);

create or replace function public.gloria_a_deus(p_testemunho bigint) returns void
language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null then raise exception 'Entre na sua conta para dar glória a Deus.'; end if;
  if not exists (select 1 from testemunhos where id = p_testemunho and status = 'aprovado') then raise exception 'Testemunho não encontrado.'; end if;
  insert into gloria_feita (testemunho_id, user_id) values (p_testemunho, auth.uid()) on conflict do nothing;
  if found then update testemunhos set gloria_count = gloria_count + 1 where id = p_testemunho; end if;
end; $$;

alter table public.testemunhos  enable row level security;
alter table public.gloria_feita enable row level security;

-- todos veem os aprovados; o autor vê os seus (inclusive em análise); a equipe vê tudo
create policy "ver testemunhos" on public.testemunhos for select
  using (status = 'aprovado' or user_id = auth.uid() or public.is_admin());
create policy "enviar testemunho" on public.testemunhos for insert
  with check (auth.uid() = user_id and status = 'pendente' and gloria_count = 0);
create policy "equipe modera" on public.testemunhos for update using (public.is_admin()) with check (public.is_admin());
create policy "apagar testemunho" on public.testemunhos for delete using (user_id = auth.uid() or public.is_admin());
create policy "minha gloria" on public.gloria_feita for select using (user_id = auth.uid());
grant execute on function public.gloria_a_deus(bigint) to authenticated;

-- ================= TORNAR ALGUÉM DA EQUIPE =================
-- Depois de se cadastrar no app, rode (trocando o e-mail):
-- update public.profiles set role = 'admin'
--   where id = (select id from auth.users where email = 'seu-email@exemplo.com');
