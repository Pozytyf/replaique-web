create type public.app_role as enum ('admin','user');
create table public.user_roles (id uuid primary key default gen_random_uuid(), user_id uuid references auth.users(id) on delete cascade not null, role app_role not null, unique(user_id, role));
grant select on public.user_roles to authenticated; grant all on public.user_roles to service_role;
alter table public.user_roles enable row level security;
create policy "own roles" on public.user_roles for select to authenticated using (user_id = auth.uid());
create or replace function public.has_role(_user_id uuid, _role app_role) returns boolean language sql stable security definer set search_path = public as $$ select exists (select 1 from public.user_roles where user_id=_user_id and role=_role) $$;

create table public.equipes (id uuid primary key default gen_random_uuid(), code text not null unique, nom text not null default '', tel text not null default '', actif boolean not null default true, created_at timestamptz not null default now());
create table public.chantiers (id uuid primary key default gen_random_uuid(), code text not null unique, equipe_id uuid references public.equipes(id) on delete set null, client_nom text not null default '', client_tel text not null default '', modele text not null default '', lieu text not null default '', date_debut date, date_fin_prevue date, conducteur_nom text not null default '', conducteur_tel text not null default '', planning_valide boolean not null default false, created_at timestamptz not null default now(), updated_at timestamptz not null default now());
create table public.etapes (id uuid primary key default gen_random_uuid(), chantier_id uuid not null references public.chantiers(id) on delete cascade, ordre int not null default 0, titre text not null default '', detail text not null default '', date_debut_prevue date, date_fin_prevue date, date_reelle date, statut text not null default 'a_venir', poids int not null default 1);
create table public.journal (id uuid primary key default gen_random_uuid(), chantier_id uuid not null references public.chantiers(id) on delete cascade, etape_id uuid references public.etapes(id) on delete set null, auteur text not null default '', texte text not null default '', photos text[] not null default '{}', created_at timestamptz not null default now());
create table public.comptes_simulation (id uuid primary key default gen_random_uuid(), token text not null unique, nom text not null, telephone text not null, email text not null default '', ville text not null default '', autorisees int not null default 10, utilisees int not null default 0, created_at timestamptz not null default now());

do $$ declare t text; begin foreach t in array array['equipes','chantiers','etapes','journal','comptes_simulation'] loop
 execute format('grant select, insert, update, delete on public.%I to authenticated', t);
 execute format('grant all on public.%I to service_role', t);
 execute format('alter table public.%I enable row level security', t);
 execute format('create policy "admin all" on public.%I for all to authenticated using (public.has_role(auth.uid(),''admin'')) with check (public.has_role(auth.uid(),''admin''))', t);
end loop; end $$;

insert into public.equipes (id, code, nom, tel) values ('11111111-1111-1111-1111-111111111111','EQ-DEMO','Equipe Bassam','+2250768986457');
insert into public.chantiers (id, code, equipe_id, client_nom, modele, lieu, date_debut, date_fin_prevue, conducteur_nom, conducteur_tel, planning_valide) values ('22222222-2222-2222-2222-222222222222','WD-DEMO','11111111-1111-1111-1111-111111111111','Famille Kouassi','Maison en ossature bois « Oasis » — 3 pieces','Grand-Bassam', current_date - 40, current_date + 62, 'Yao Konan', '+2250768986457', true);
insert into public.etapes (chantier_id, ordre, titre, detail, date_debut_prevue, date_fin_prevue, date_reelle, statut, poids) values
('22222222-2222-2222-2222-222222222222',1,'Preparation du terrain','Debroussaillage, implantation des axes, nivellement et acces au chantier.',current_date-40,current_date-33,current_date-33,'terminee',1),
('22222222-2222-2222-2222-222222222222',2,'Fondations','Fouilles, semelles, longrines et dalle beton.',current_date-33,current_date-19,current_date-18,'terminee',3),
('22222222-2222-2222-2222-222222222222',3,'Ossature bois','Montage des murs a ossature, contreventement et charpente.',current_date-19,current_date+2,null,'en_cours',3),
('22222222-2222-2222-2222-222222222222',4,'Toiture','Couverture, etancheite, gouttieres et descentes.',current_date+2,current_date+12,null,'a_venir',2),
('22222222-2222-2222-2222-222222222222',5,'Menuiseries exterieures','Portes, fenetres, volets et bardage.',current_date+12,current_date+22,null,'a_venir',2),
('22222222-2222-2222-2222-222222222222',6,'Second oeuvre','Electricite, plomberie, cloisons et isolation.',current_date+22,current_date+43,null,'a_venir',3),
('22222222-2222-2222-2222-222222222222',7,'Finitions','Peinture, parquets, sanitaires et cuisine.',current_date+43,current_date+57,null,'a_venir',2),
('22222222-2222-2222-2222-222222222222',8,'Reception','Nettoyage, levee des reserves et remise des cles.',current_date+57,current_date+62,null,'a_venir',1);
insert into public.journal (chantier_id, auteur, texte, created_at) values
('22222222-2222-2222-2222-222222222222','Equipe Bassam','Dalle coulee et sechage termine. Debut du montage des murs lundi.', now()-interval '18 days'),
('22222222-2222-2222-2222-222222222222','Equipe Bassam','Murs nord et est montes, contreventement en cours.', now()-interval '3 days');