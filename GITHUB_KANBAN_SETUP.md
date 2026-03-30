# 봄동비빔밥 만들기 - GitHub 칸반 보드 설정 완료

## ✅ 생성 완료 사항

### 1. 레이블 (Labels) 생성
다음 4개의 상태 레이블이 생성되었습니다:
- **preparation** (재료 손질 및 준비)
- **cooking** (조리 진행 중)
- **ready** (담기 준비 완료)
- **completed** (완료)

### 2. Issues 생성 (16개)
각 단계별로 4개씩, 총 16개의 이슈가 생성되었습니다:

#### 재료 손질 및 준비 (preparation) - #26~#29
- #26: 봄동 씻기
- #27: 봄동 썰기
- #28: 고추장/참기름/깨 준비
- #29: 그릇/수저 세팅

#### 조리 진행 중 (cooking) - #32~#35
- #32: 버섯 볶기
- #33: 콩나물 데치기
- #34: 계란 프라이
- #35: 밥 데우기

#### 담기 준비 완료 (ready) - #36~#39
- #36: 밥 1공기 준비됨
- #37: 당근 채썰기 완료
- #38: 고명 배치 순서 점검
- #39: 비벼 먹기 직전 상태

#### 완료 (completed) - #40~#43
- #40: 냉장고 재료 확인 완료
- #41: 봄동 손질 완료
- #42: 기본 플레이팅 완료
- #43: 다음 개선 포인트 기록

### 3. GitHub Project 생성
봄동비빔밥 만들기 프로젝트 보드가 생성되었습니다:
- **프로젝트명**: 봄동비빔밥 만들기
- **설명**: 봄동비빔밥 조리 과정을 칸반으로 관리하는 프로젝트 보드 (개념모델 ERD 기반)

---

## 🔧 GitHub에서 칸반 보드 사용 방법

### 방법 1: 프로젝트 보드 설정 (권장)
1. GitHub 저장소의 **Projects** 탭으로 이동
2. "봄동비빔밥 만들기" 프로젝트 선택
3. **View** 옵션에서 **Table** 또는 **Board** 선택
4. Board 뷰에서 다음과 같이 설정:
   - **준비**: preparation 레이블 이슈
   - **진행중**: cooking 레이블 이슈
   - **준비완료**: ready 레이블 이슈
   - **완료**: completed 레이블 이슈

### 방법 2: Issues 필터링
**Issues** 탭에서 레이블로 필터링하여 상태별로 이슈 관리:
- `label:preparation` - 재료 손질 및 준비
- `label:cooking` - 조리 진행 중
- `label:ready` - 담기 준비 완료
- `label:completed` - 완료

### 방법 3: 프로젝트 스냅샷 (이미지)
프로젝트를 Board 뷰로 설정하면 다음과 같은 구조가 됩니다:

```
┌──────────────────────┬────────────────────┬────────────────────┬───────────────┐
│   준비               │   진행중           │   준비완료         │   완료        │
│ (preparation)        │ (cooking)          │ (ready)            │ (completed)   │
├──────────────────────┼────────────────────┼────────────────────┼───────────────┤
│ #26 봄동 씻기        │ #32 버섯 볶기      │ #36 밥 준비됨      │ #40 재료 확인 │
│ #27 봄동 썰기        │ #33 콩나물 데치기  │ #37 당근 채썰기    │ #41 손질 완료 │
│ #28 양념 준비        │ #34 계란 프라이    │ #38 고명 배치      │ #42 플레이팅 │
│ #29 식기 세팅        │ #35 밥 데우기      │ #39 직전 상태      │ #43 개선점    │
└──────────────────────┴────────────────────┴────────────────────┴───────────────┘
```

---

## 📊 개념모델 ERD 매핑

현재 GitHub Issues 구조는 다음과 같이 Supabase 테이블과 동일하게 매핑됩니다:

```
GitHub Issues              ↔    Supabase
────────────────────────────────────────
Project (봄동비빔밥)       ↔    kanban_board
  ├─ Preparation          ↔    kanban_column (preparation)
  ├─ Cooking              ↔    kanban_column (cooking_in_progress)
  ├─ Ready                ↔    kanban_column (ready_to_serve)
  └─ Completed            ↔    kanban_column (completed)

Issue #26, #27, ...        ↔    kanban_card (각 카드)
  ├─ title                 ↔    card.title
  ├─ body (description)    ↔    card.detail
  └─ labels (상태)         ↔    card.column_id
```

---

## 🚀 다음 단계

1. **GitHub 프로젝트 웹에서 칸반 뷰 설정**
   - Board 또는 Table 뷰로 전환
   - 드래그 앤 드롭으로 이슈 상태 변경 가능

2. **Supabase와 동기화**
   - 현재 두 시스템(GitHub + Supabase)이 별도로 운영됨
   - 향후 필요시 GitHub API + Supabase 연동 자동화 가능

3. **팀 협업**
   - 각 이슈에 Assignee 추가 가능
   - Comments로 진행 상황 업데이트
   - Due date 설정으로 마감일 관리

---

## 📝 Repository 정보

- **Repository**: itsjustcozyboy/Database
- **Created**: 2026-03-30
- **Issues**: 16개 (preparation 4, cooking 4, ready 4, completed 4)
- **Labels**: 4개
- **Project**: 1개

---

## 🔗 링크

- [GitHub Issues](https://github.com/itsjustcozyboy/Database/issues)
- [GitHub Projects](https://github.com/itsjustcozyboy/Database/projects)

---

## 💡 참고사항

이 칸반보드는 다음을 기반으로 설계되었습니다:
- **개념모델**: Board (1) : N Column (1) : N Card
- **도메인**: 봄동비빔밥 만들기 프로세스
- **상태 단계**: 재료 준비 → 조리 진행 → 담기 준비 → 완료
