-- supabase.sql을 먼저 실행한 뒤, 아래 SQL을 SQL Editor에서 실행하세요.
-- 실행 결과에 학생별 6자리 PIN이 표시됩니다. 안전한 곳에 기록해 학생별로 전달하세요.
-- 다시 실행하면 모든 학생 PIN이 변경됩니다.
with new_pins as (
 select student_no, lpad((floor(random()*1000000))::int::text,6,'0') as pin
 from public.gallery_students
), updated as (
 update public.gallery_students s set pin_hash=crypt(p.pin,gen_salt('bf'))
 from new_pins p where s.student_no=p.student_no
 returning s.student_no,p.pin
)
select student_no,pin from updated order by student_no;
