# 내 PC에서 포켓몬 오토체스 실행하기

이 저장소는 원작의 `prod` 브랜치를 기반으로 합니다. 전투, 상점, 진화, 시너지, 아이템, 방 생성 및 실시간 멀티플레이가 원작 코드에 포함되어 있습니다. 실제 플레이 가능 여부는 아래 설정 후 로그인과 두 브라우저의 대전으로 확인해야 합니다.

## 1. 준비

- Node.js 24와 npm을 설치합니다. 원작이 지정한 버전은 `24.19.0`입니다.
- MongoDB Community를 직접 설치하거나 Docker Desktop을 설치합니다.
- Firebase 프로젝트를 생성합니다. 데이터베이스와 로그인 서비스를 우회하는 모의 게임이 아니라 원작 서버를 실행합니다.

## 2. 데이터베이스

Docker를 사용한다면 저장소 폴더에서 실행합니다.

```powershell
docker compose -f compose.local.yaml up -d
```

직접 설치했다면 MongoDB 서비스를 실행합니다. 기본 주소는 `mongodb://127.0.0.1:27017/dev`입니다. 로컬 Docker 구성은 DB를 PC 내부에서만 접근 가능하게 하고 데이터를 볼륨에 보관합니다.

## 3. Firebase 설정

```powershell
Copy-Item .env.local.example .env
notepad .env
```

- Firebase 콘솔에서 프로젝트를 만들고 웹 앱을 추가합니다.
- 웹 앱 설정의 여섯 항목을 `.env`의 `FIREBASE_*` 항목에 넣습니다.
- Authentication → Sign-in method에서 이메일/비밀번호와 익명 로그인을 활성화합니다.
- Authentication → Settings → Authorized domains에 `localhost`를 추가합니다.
- Project settings → Service accounts에서 관리자 키를 생성합니다. JSON의 `client_email`과 `private_key`를 해당 환경 변수에 넣습니다.
- `private_key`는 큰따옴표 안에 한 줄로 넣고 줄바꿈을 `\n`으로 표시합니다.
- 비밀키 JSON 및 `.env`는 GitHub나 채팅에 업로드하지 않습니다.

## 4. 최초 설치와 실행

```powershell
powershell -ExecutionPolicy Bypass -File scripts/start-local.ps1 -Setup
```

의존성, 별도 음악 저장소, 에셋 도구를 설치하고 에셋을 패킹합니다. 에셋이 많아서 시간과 디스크 공간이 필요합니다. 이후에는 다음 명령만 실행합니다.

```powershell
powershell -ExecutionPolicy Bypass -File scripts/start-local.ps1
```

또는 단계별로 실행합니다.

```powershell
npm ci
npm run assetpack
npm run local:doctor
npm run local:dev
```

브라우저에서 http://localhost:9000 을 엽니다. `local:doctor`는 설정과 로컬 DB 포트를 확인하며 Firebase 자격 증명의 원격 유효성까지 확인하지는 않습니다.

## 5. 친구들과 확인

1. 일반 창과 시크릿 창에서 각각 로그인합니다.
2. 한 명이 방을 만들고 다른 사람이 같은 방에 입장합니다. 방 비밀번호를 설정할 수 있습니다.
3. 두 사람 모두 준비하고 게임을 시작합니다.
4. 구매·배치·자동 전투·라운드 이동·결과 화면을 확인합니다.

같은 PC에서는 두 창 모두 `localhost`로 접속합니다. 같은 와이파이의 친구는 `ipconfig`에 나오는 PC IPv4 주소를 이용해 `http://PC주소:9000`으로 접속합니다. Firebase 허용 도메인에 접속 호스트를 추가하고 Windows 방화벽에서 신뢰하는 개인 네트워크에 한해 TCP 9000을 허용해야 합니다. VPN 등 연결 방식에 따라 추가 네트워크 설정이 필요할 수 있습니다.

집 밖의 친구에게 `localhost` 주소를 보내면 접속할 수 없습니다. 외부 접속은 HTTPS 및 WebSocket을 지원하는 서버에 배포하는 후속 작업이 필요합니다. DB 포트 27017을 외부에 공개할 필요는 없습니다.

봇 대전이 필요하면 MongoDB Compass로 `db-commands/botv2.json`을 `dev` 데이터베이스의 `botv2` 컬렉션에 가져옵니다.

## 기록과 원작

- 작업 기록: [WORKLOG.md](../WORKLOG.md)
- 원작 설치 문서: [README.md](../README.md)
- 원작 배포 문서: [deployment/README.md](../deployment/README.md)
- 원작 소스: https://github.com/keldaanCommunity/pokemonAutoChess
- 원작 GPL-3.0 라이선스와 출처를 유지합니다. 포켓몬 콘텐츠 권리는 원작이 표시한 대로 The Pokémon Company에 있으며 이 프로젝트는 비영리 친구용 서버를 목적으로 합니다.
