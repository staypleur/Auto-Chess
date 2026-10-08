# 작업 기록

## 2026-10-08 (Asia/Seoul)

### 요청 및 결정

- 원작 https://pokemon-auto-chess.com/ 과 같은 게임을 친구들과 플레이하고 코드와 기록을 https://github.com/staypleur/Auto-Chess 에 저장.
- 사용자 선택: PC에서 먼저 실행. Firebase 프로젝트는 아직 없음.
- 빈 대상 저장소에 원작 공개 소스를 가져옴. 별도의 축약 게임 대신 원작 서버·클라이언트 및 게임 데이터를 사용.
- 기준: https://github.com/keldaanCommunity/pokemonAutoChess 의 `prod`, 커밋 `07367c341fe928763da2b565c2eee010433e4fc1`, 게임 버전 `6.11.1`.
- 원작 LICENSE(GPL-3.0), 저작자 표시, 음악 별도 다운로드 방식 유지. upstream 원격 저장소 유지. 원작 전체 과거 기록을 복제한 것은 아님. 얕은 기록의 누락 객체로 첫 push가 실패해 원작 커밋을 위에 명시한 독립 루트 스냅샷 이력으로 업로드.

### 추가 및 수정

- Windows 최초 설치/실행: `scripts/start-local.ps1`.
- 필수 환경 변수, PEM 키 형식, 에셋, 로컬 MongoDB 포트 검사: `scripts/local-doctor.cjs`.
- `local:doctor`, `local:dev` npm 스크립트.
- 비밀 값 없는 `.env.local.example`.
- 로컬 전용 MongoDB Docker 구성 `compose.local.yaml`: 루프백 포트, 영속 볼륨, 상태 확인.
- 한국어 Firebase/MongoDB 설정 및 친구와 두 브라우저 테스트 안내 `docs/LOCAL-KO.md`.
- GitHub Actions 예제를 `main` 브랜치와 비밀 설정 없는 빌드·타입 검사·기존 전투 회귀 테스트에 맞춤. GitHub OAuth 인증에 `workflow` 권한이 없어 업로드가 거절되어 실제 자동 실행 파일 대신 `docs/ci/`에 참고 파일로 보관. 자동 CI는 활성화되지 않음.
- package 메타데이터의 저장소 링크를 대상 저장소로 변경하고 라이선스 항목을 실제 LICENSE와 일치시킴.
- 원작 잠금 파일의 누락된 `gcp-metadata`, `gaxios`, `node-fetch`, `data-uri-to-buffer` 등 의존성 정보를 npm으로 재생성. `npm ci`가 실패했던 불일치 보완.

### 검증

- 의존성 설치 성공.
- 음악 다운로드 및 에셋 도구 설치 성공.
- 전체 에셋 패킹 성공(약 198초). 생성된 atlas 및 서비스 워커 버전 반영 후 빌드 재실행.
- 클라이언트 빌드 `node esbuild.js --build`: 통과.
- 서버 빌드 `tsc`: 통과.
- TypeScript 검사 `tsc --noEmit`: 통과.
- 원작 Headlong Rush 전투 테스트: 1개 통과.
- 수정한 잠금 파일의 `npm ci --dry-run --ignore-scripts`: 통과.
- 로컬 진단: 미설정 Firebase/MongoDB 환경 변수를 값 노출 없이 감지하고 종료 코드 1로 중단.

### 남은 실행 조건

- MongoDB 또는 Docker가 현재 PC에서 발견되지 않음. 설치/실행 필요.
- 사용자가 Firebase 프로젝트를 생성하고 PC의 `.env`에 설정 필요.
- 실제 서버 시작, 브라우저 로그인, 두 플레이어 대전, 외부 친구 접속은 아직 검증하지 않음.
- 원작 에셋 도구 설치 시 npm audit가 취약점 22개(중간 5, 높음 12, 치명적 5)를 보고함. 의존성을 강제 업그레이드하지 않았으며 외부 공개 전 검토가 필요함.
- 빌드 산출물·음악 다운로드·비밀 설정은 GitHub에 넣지 않고 소스와 재현 절차를 기록.

### 저장 결과

- `main` 최초 업로드 성공. 기반 스냅샷 커밋: `cd875c48a`.
- `.env`는 Git ignore 적용을 확인했으며 게시하지 않음.
- Firebase 프로젝트 생성과 MongoDB 실행 후 `npm run local:doctor`를 다시 수행하고 두 브라우저 대전을 확인하는 것이 다음 단계.
