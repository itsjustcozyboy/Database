# GitHub Issue 기반 칸반보드

이 보드는 GitHub 저장소의 오픈 이슈를 라벨 기준으로 정리한 칸반보드입니다.

- 기준 저장소: https://github.com/itsjustcozyboy/Database
- 기준 이슈: #28 ~ #43 (Open)
- 컬럼 기준 라벨: preparation, cooking, ready, completed

## 칸반 보드

| 재료 손질 및 준비 (preparation) | 조리 진행 중 (cooking) | 담기 준비 완료 (ready) | 완료 (completed) |
|---|---|---|---|
| [#28 봄동 씻기](https://github.com/itsjustcozyboy/Database/issues/28) | [#32 버섯 볶기](https://github.com/itsjustcozyboy/Database/issues/32) | [#36 밥 1공기 준비됨](https://github.com/itsjustcozyboy/Database/issues/36) | [#40 냉장고 재료 확인 완료](https://github.com/itsjustcozyboy/Database/issues/40) |
| [#29 봄동 썰기](https://github.com/itsjustcozyboy/Database/issues/29) | [#33 콩나물 데치기](https://github.com/itsjustcozyboy/Database/issues/33) | [#37 당근 채썰기 완료](https://github.com/itsjustcozyboy/Database/issues/37) | [#41 봄동 손질 완료](https://github.com/itsjustcozyboy/Database/issues/41) |
| [#30 고추장/참기름/깨 준비](https://github.com/itsjustcozyboy/Database/issues/30) | [#34 계란 프라이](https://github.com/itsjustcozyboy/Database/issues/34) | [#38 고명 배치 순서 점검](https://github.com/itsjustcozyboy/Database/issues/38) | [#42 기본 플레이팅 완료](https://github.com/itsjustcozyboy/Database/issues/42) |
| [#31 그릇/수저 세팅](https://github.com/itsjustcozyboy/Database/issues/31) | [#35 밥 데우기](https://github.com/itsjustcozyboy/Database/issues/35) | [#39 비벼 먹기 직전 상태](https://github.com/itsjustcozyboy/Database/issues/39) | [#43 다음 개선 포인트 기록](https://github.com/itsjustcozyboy/Database/issues/43) |

## 운영 규칙

- 이슈 이동 방법: 해당 이슈의 라벨을 변경하면 보드 컬럼도 변경됩니다.
- preparation -> cooking -> ready -> completed 흐름으로 관리합니다.
- 새 작업은 라벨을 반드시 1개 지정합니다.

## 참고

현재 토큰 권한 제한으로 GitHub Projects (Projects v2) API 생성/수정은 자동화되지 않았습니다.
권한이 열리면 동일 이슈 세트로 실제 GitHub Project 보드까지 자동 구성할 수 있습니다.
필요 권한 예시: project, read:project, repo.
