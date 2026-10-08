# GitHub Actions 참고 파일

현재 GitHub OAuth 인증에는 `workflow` 권한이 없어 `.github/workflows/` 파일을 게시할 수 없습니다. 자동 CI는 활성화되지 않았습니다.

필요하면 저장소 소유자가 GitHub 웹에서 이 폴더의 YAML을 `.github/workflows/`에 생성할 수 있습니다. `main.yaml`은 main push의 빌드·타입 검사·기존 전투 회귀 테스트용이며 `build-pr.yml`은 main 대상 PR 빌드용입니다. Firebase 비밀키는 CI에 필요하지 않습니다. 에셋 패킹과 실제 로그인 대전은 이 CI의 검사 범위에 포함하지 않습니다.
