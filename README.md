# 🎮 우리 반 게임 전시회

초등학교 16명의 HTML 게임 공유·실행·피드백 사이트입니다. GitHub Pages(화면) + Supabase(데이터) 구성입니다.

## 처음 설치하기

1. Supabase 프로젝트의 **SQL Editor**에서 `supabase.sql` 전체를 실행합니다.
2. SQL Editor에서 교사 비밀번호를 설정합니다. 아래 `원하는_강한_비밀번호`를 실제 비밀번호로 바꾸세요.
   ```sql
   update public.gallery_teacher
   set pin_hash=crypt('원하는_강한_비밀번호',gen_salt('bf'))
   where id=1;
   ```
3. SQL Editor에서 `setup-pins.sql`을 실행하고 결과에 나온 학생 1~16번 PIN을 안전하게 기록합니다. **다시 실행하면 PIN이 모두 바뀝니다.**
4. Supabase의 **Project Settings → API**에서 Project URL과 `anon`/publishable 키를 확인하여 `config.js`에 입력합니다. **service_role/secret 키는 절대 넣지 마세요.**
5. GitHub에서 새 **공개 저장소**를 만들고 `index.html`, `style.css`, `app.js`, `config.js`를 저장소 루트에 업로드합니다. SQL 파일과 학생 PIN 목록은 업로드할 필요가 없습니다.
6. GitHub 저장소 **Settings → Pages → Deploy from a branch → main / (root) → Save**로 배포합니다. 생성된 주소를 학생들에게 공유합니다.

## 학생 이용 방법

- 학생 로그인: 학생 번호 + 교사가 준 개인 PIN
- 게임 등록: 게임 제목, 설명, ChatGPT 프롬프트 입력 + HTML 파일 업로드 **또는** 코드 붙여넣기
- 게임 카드 선택: 브라우저 안에서 실행
- 다른 학생의 게임에 피드백 작성: 좋았던 점과 개선점. 학생 1명당 게임별 피드백 1개(수정 가능)
- 자기 게임 재등록: 기존 게임 수정

## 교사 이용 방법

- 교사 모드 → 비밀번호 입력 → 16명 제출 현황 확인, 게임/피드백 삭제
- 학생 PIN 재발급(예: 3번):
  ```sql
  update public.gallery_students set pin_hash=crypt('새로운6자리PIN',gen_salt('bf')) where student_no=3;
  ```

## 중요 제한 및 안전

- 사이트에 올린 HTML 게임은 `sandbox="allow-scripts"` iframe으로 분리해 실행합니다. CSP로 외부 네트워크 요청, 외부 이미지/스크립트 등을 제한합니다. 따라서 CDN·외부 이미지·서버 연결이 필요한 HTML 게임은 정상 실행되지 않을 수 있습니다. HTML/CSS/JS가 한 파일에 포함된 게임을 권장합니다.
- HTML 크기는 최대 약 200KB, 프롬프트 최대 20,000자입니다.
- 등록된 게임 코드와 프롬프트 및 학생 번호별 피드백은 사이트 방문자에게 공개됩니다. 학생 실명이나 개인 정보는 입력하지 마세요.
- 개인 PIN은 브라우저 메모리에만 보관하고 페이지 새로고침 시 사라집니다.
- 학급 한정 시범 사용을 전제로 합니다. 공개 URL을 인터넷에 널리 배포할 경우 비밀번호 대입 공격 방지, CAPTCHA, 속도 제한, 서버 측 파일 검증, 추가 인증 등이 필요합니다. 이 버전은 그러한 운영 보안까지 완비된 서비스가 아닙니다.
- Supabase 무료 요금제 사용량 제한이 적용됩니다.
