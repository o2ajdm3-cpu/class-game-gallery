-- Supabase SQL Editor에서 전체 실행합니다. 기존 테이블은 삭제하지 않습니다.
create extension if not exists pgcrypto;
create table if not exists public.gallery_students (student_no int primary key check(student_no between 1 and 16), pin_hash text not null);
create table if not exists public.gallery_games (student_no int primary key references public.gallery_students(student_no), title text not null, description text not null, prompt text not null, html text not null, updated_at timestamptz not null default now(), constraint game_limits check(length(title) between 1 and 60 and length(description)<=400 and length(prompt)<=20000 and length(html) between 1 and 200000));
create table if not exists public.gallery_feedback (id bigint generated always as identity primary key, game_student_no int not null references public.gallery_students(student_no), author_no int not null references public.gallery_students(student_no), good text not null, improve text not null, created_at timestamptz not null default now(), unique(game_student_no,author_no), check(game_student_no<>author_no), check(length(good) between 1 and 500 and length(improve) between 1 and 500));
create table if not exists public.gallery_teacher (id int primary key default 1 check(id=1), pin_hash text not null);
alter table public.gallery_students enable row level security;
alter table public.gallery_games enable row level security;
alter table public.gallery_feedback enable row level security;
alter table public.gallery_teacher enable row level security;
revoke all on public.gallery_students,public.gallery_games,public.gallery_feedback,public.gallery_teacher from anon,authenticated;
-- 최초 실행 시에만 학생별 랜덤 6자리 PIN 생성
insert into public.gallery_students(student_no,pin_hash)
select n,crypt(lpad((floor(random()*1000000))::int::text,6,'0'),gen_salt('bf')) from generate_series(1,16) n
on conflict(student_no) do nothing;
-- 교사 비밀번호를 아래 CHANGE_ME 부분에 직접 입력해 변경하세요. 12자 이상 권장.
insert into public.gallery_teacher(id,pin_hash) values(1,crypt('CHANGE_ME_TEACHER_PASSWORD',gen_salt('bf')))
on conflict(id) do nothing;
-- 학생 PIN은 해시로만 저장되므로 초기 PIN을 조회할 수 없습니다.
-- 아래 구문을 각 학생별 원하는 6자리 PIN으로 변경해 SQL Editor에서 실행하세요.
-- update public.gallery_students set pin_hash=crypt('123456',gen_salt('bf')) where student_no=1;

create or replace function public.gallery_check_student(p_no int,p_pin text) returns boolean language sql security definer set search_path=public as $$
select exists(select 1 from gallery_students where student_no=p_no and pin_hash=crypt(p_pin,pin_hash)) $$;
create or replace function public.gallery_check_teacher(p_pin text) returns boolean language sql security definer set search_path=public as $$
select exists(select 1 from gallery_teacher where id=1 and pin_hash=crypt(p_pin,pin_hash)) $$;
create or replace function public.gallery_list() returns jsonb language sql security definer set search_path=public as $$
select jsonb_build_object('games',coalesce((select jsonb_agg(jsonb_build_object('student_no',student_no,'title',title,'description',description,'updated_at',updated_at) order by student_no) from gallery_games),'[]'::jsonb),'counts',coalesce((select jsonb_object_agg(game_student_no,cnt) from (select game_student_no,count(*) cnt from gallery_feedback group by game_student_no) a),'{}'::jsonb)) $$;
create or replace function public.gallery_get(p_no int) returns jsonb language sql security definer set search_path=public as $$
select coalesce((select jsonb_build_object('student_no',student_no,'title',title,'description',description,'prompt',prompt,'html',html,'feedback',coalesce((select jsonb_agg(jsonb_build_object('id',f.id,'author_no',f.author_no,'good',f.good,'improve',f.improve,'created_at',f.created_at) order by f.created_at desc) from gallery_feedback f where f.game_student_no=p_no),'[]'::jsonb)) from gallery_games where student_no=p_no),'null'::jsonb) $$;
create or replace function public.gallery_save(p_no int,p_pin text,p_title text,p_description text,p_prompt text,p_html text) returns jsonb language plpgsql security definer set search_path=public as $$
begin
 if not gallery_check_student(p_no,p_pin) then raise exception '학생 번호 또는 비밀번호가 올바르지 않습니다.'; end if;
 if length(trim(p_title))<1 or length(p_title)>60 or length(p_description)>400 or length(p_prompt)>20000 or length(p_html)<1 or length(p_html)>200000 then raise exception '입력 글자 수를 확인하세요.'; end if;
 insert into gallery_games(student_no,title,description,prompt,html) values(p_no,p_title,p_description,p_prompt,p_html) on conflict(student_no) do update set title=excluded.title,description=excluded.description,prompt=excluded.prompt,html=excluded.html,updated_at=now();
 return jsonb_build_object('ok',true);
end $$;
create or replace function public.gallery_feedback_save(p_no int,p_pin text,p_game_no int,p_good text,p_improve text) returns jsonb language plpgsql security definer set search_path=public as $$
begin
 if not gallery_check_student(p_no,p_pin) then raise exception '학생 번호 또는 비밀번호가 올바르지 않습니다.'; end if;
 if p_no=p_game_no then raise exception '자신의 게임에는 피드백을 남길 수 없습니다.'; end if;
 if length(trim(p_good))<1 or length(trim(p_improve))<1 or length(p_good)>500 or length(p_improve)>500 then raise exception '피드백은 각각 1~500자로 작성하세요.'; end if;
 insert into gallery_feedback(game_student_no,author_no,good,improve) values(p_game_no,p_no,p_good,p_improve) on conflict(game_student_no,author_no) do update set good=excluded.good,improve=excluded.improve,created_at=now();
 return jsonb_build_object('ok',true);
end $$;
create or replace function public.gallery_teacher_delete_feedback(p_pin text,p_id bigint) returns jsonb language plpgsql security definer set search_path=public as $$
begin
 if not gallery_check_teacher(p_pin) then raise exception '교사 비밀번호가 올바르지 않습니다.'; end if;
 delete from gallery_feedback where id=p_id; return jsonb_build_object('ok',true);
end $$;
create or replace function public.gallery_teacher_delete_game(p_pin text,p_no int) returns jsonb language plpgsql security definer set search_path=public as $$
begin
 if not gallery_check_teacher(p_pin) then raise exception '교사 비밀번호가 올바르지 않습니다.'; end if;
 delete from gallery_feedback where game_student_no=p_no; delete from gallery_games where student_no=p_no; return jsonb_build_object('ok',true);
end $$;
revoke all on function public.gallery_check_student(int,text),public.gallery_check_teacher(text) from public,anon,authenticated;
revoke all on function public.gallery_list(),public.gallery_get(int),public.gallery_save(int,text,text,text,text,text),public.gallery_feedback_save(int,text,int,text,text),public.gallery_teacher_delete_feedback(text,bigint),public.gallery_teacher_delete_game(text,int) from public;
grant execute on function public.gallery_list(),public.gallery_get(int),public.gallery_save(int,text,text,text,text,text),public.gallery_feedback_save(int,text,int,text,text),public.gallery_teacher_delete_feedback(text,bigint),public.gallery_teacher_delete_game(text,int) to anon,authenticated;
-- 중요: 이 사이트는 학급 활동용입니다. 비밀번호 추측 방지를 위해 공개 배포 시 별도 인증/요청 제한이 필요합니다.
create or replace function public.gallery_login(p_no int,p_pin text) returns boolean language sql security definer set search_path=public as $$ select gallery_check_student(p_no,p_pin) $$;
create or replace function public.gallery_teacher_login(p_pin text) returns boolean language sql security definer set search_path=public as $$ select gallery_check_teacher(p_pin) $$;
revoke all on function public.gallery_login(int,text),public.gallery_teacher_login(text) from public;
grant execute on function public.gallery_login(int,text),public.gallery_teacher_login(text) to anon,authenticated;
