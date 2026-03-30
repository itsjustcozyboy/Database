# 봄동비빔밥 만들기 - 개념모델 ERD 기반 칸반 프로젝트

![Status](https://img.shields.io/badge/Status-Active-brightgreen)
![Database](https://img.shields.io/badge/Database-Supabase-3ECF8E)
![Kanban](https://img.shields.io/badge/Kanban-GitHub%20Projects-181717)

## 📋 프로젝트 개요

이 프로젝트는 **봄동비빔밥 만들기** 과정을 칸반보드로 관리하는 시스템입니다.  
개념모델 ERD 중심으로 설계되었으며, GitHub Issues와 Supabase 데이터베이스가 동기화됩니다.

### 🎯 핵심 목표
- ✅ 개념모델 기반 ERD 설계 및 구현
- ✅ GitHub Issues를 통한 작업 관리
- ✅ Supabase를 통한 데이터 영속성
- ✅ 도메인 중심의 명확한 스키마 설계

---

## 🏗️ 시스템 아키텍처

### 개념모델 (Conceptual Model)

```
┌─────────────────────────────────────────────────────┐
│             봄동비빔밥 만들기 (Board)                │
├─────────────────────────────────────────────────────┤
│  • board_id: 1                                      │
│  • board_name: 봄동비빔밥 만들기                    │
│  • source_url: GitHub Projects URL                  │
└─────────────────────────────────────────────────────┘
           │                    │                  │
    1:N    │            1:N     │          1:N     │
           ↓                    ↓                  ↓
    ┌────────────────┐  ┌──────────────┐  ┌──────────────┐
    │  Recipe Step   │  │ Recipe Task  │  │ Team Member  │
    │  (요리 단계)   │  │ (요리 작업)  │  │ (팀 멤버)    │
    └────────────────┘  └──────────────┘  └──────────────┘
           │                    │ N:M        │
           │ 4개 단계           └────────┬──┘
           │                         │
           ├─ preparation            ↓
           ├─ cooking_in_progress   Task Assignment
           ├─ ready_to_serve        (N:M 관계)
           └─ completed
```

---

## 📊 ERD (Entity Relationship Diagram)

### 논리 관계도 - 텍스트 표현

엔티티 관계도 (한눈에 보기):

```
┌──────────────────────────────────────────────────────────────┐
│                    RECIPE_BOARD (1개)                        │
│  board_id | board_name | source_url | created_at            │
└──────────────────────────────────────────────────────────────┘
     │ 1:N              │ 1:N              │ 1:N
     ├─────────────────┼─────────────────┤
     ↓                 ↓                 ↓
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│RECIPE_STEP   │  │ RECIPE_TASK  │  │TEAM_MEMBER   │
│(4개 단계)    │  │ (16개 작업)  │  │ (3명 팀원)   │
├──────────────┤  ├──────────────┤  ├──────────────┤
│ column_id PK │  │ card_id PK   │  │member_id PK  │
│ board_id FK  │  │ board_id FK  │  │board_id FK   │
│ column_name  │  │ step_id FK   │  │member_name   │
│ order_pos    │  │ title        │  │ role         │
└──────────────┘  │ due_date     │  └──────────────┘
     │ 1:N        │ is_done      │        │
     │            │ github_iss   │        │ N:M
     └────────────┼──────────────┴────────┘
                  ↓
          TASK_ASSIGNMENT
         (16개 할당 관계)
        task_id FK | member_id FK
```

### 엔티티 정의 설명

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│  📋 RECIPE_BOARD (1개)                                          │
│  ├─ board_id: 1                                                 │
│  └─ board_name: 봄동비빔밥 만들기                              │
│                                                                 │
│       ├─ 1:N ──────────────────┬──────────────────┬────────┐   │
│       ↓                        ↓                  ↓        ↓   │
│  RECIPE_STEP (4개)    RECIPE_TASK (16개)  TEAM_MEMBER (3명)  │
│  ├─ preparation       ├─ 봄동 씻기        ├─ 김정환         │
│  ├─ cooking           ├─ 버섯 볶기        ├─ 김소윤         │
│  ├─ ready             ├─ 담기 준비        └─ 김채우         │
│  └─ completed         └─ ...                                  │
│       │                                                        │
│       └─ 1:N ─────────────────────────┐                       │
│                                       ↓                       │
│                              TASK_ASSIGNMENT (N:M)             │
│                              ├─ task_id FK                     │
│                              └─ member_id FK                   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🗂️ 테이블 구조 (Supabase)

### 1️⃣ recipe_board (요리 보드)

보드의 기본 정보를 저장하는 테이블입니다.

| 컬럼 | 타입 | 제약조건 | 설명 |
|------|------|---------|------|
| `board_id` | BIGINT | **PK** ⭐ | 보드 고유 ID (자동증가) |
| `board_name` | TEXT | NOT NULL | 보드 이름 (예: 봄동비빔밥 만들기) |
| `description` | TEXT | - | 보드 설명 |
| `source_url` | TEXT | UNIQUE | 원본 보드 URL (GitHub Projects) |
| `created_at` | TIMESTAMPTZ | DEFAULT NOW() | 생성 시간 |

**샘플 데이터:**
```
board_id=1, board_name='봄동비빔밥 만들기'
```

---

### 2️⃣ recipe_step (요리 단계)

보드의 상태 열을 정의합니다. (준비, 조리, 담기, 완료)

| 컬럼 | 타입 | 제약조건 | 설명 |
|------|------|---------|------|
| `column_id` | TEXT | **PK** ⭐ | 단계 ID (preparation, cooking_in_progress 등) |
| `board_id` | BIGINT | **FK** 🔗 | 보드 참조 (ON DELETE CASCADE) |
| `column_name` | TEXT | NOT NULL | 단계 이름 (한글) |
| `order_position` | INT | UNIQUE | 보드상의 순서 (1~4) |

**생성된 단계:**
```
1. preparation → 재료 손질 및 준비
2. cooking_in_progress → 조리 진행 중
3. ready_to_serve → 담기 준비 완료
4. completed → 완료
```

---

### 3️⃣ recipe_task (요리 작업)

실제 수행할 개별 작업을 저장합니다.

| 컬럼 | 타입 | 제약조건 | 설명 |
|------|------|---------|------|
| `card_id` | BIGINT | **PK** ⭐ | 카드 고유 ID (자동증가) |
| `board_id` | BIGINT | **FK** 🔗 | 보드 참조 (ON DELETE CASCADE) |
| `step_id` | TEXT | **FK** 🔗 | 단계 참조 (ON DELETE RESTRICT) |
| `title` | TEXT | UNIQUE (board_id, title) | 작업 제목 |
| `description` | TEXT | - | 작업 상세 설명 |
| `due_date` | DATE | - | 마감일 |
| `order_position` | INT | - | 단계 내 순서 |
| `is_done` | BOOLEAN | DEFAULT FALSE | 완료 여부 |
| `github_issue_number` | INT | - | GitHub 이슈 번호 |
| `created_at` | TIMESTAMPTZ | DEFAULT NOW() | 생성 시간 |

**생성된 작업 (16개):**

#### Preparation (재료 손질 및 준비)
| # | 작업 | GitHub | 상태 |
|---|------|--------|------|
| 1 | 봄동 씻기 | #28 | 미완료 |
| 2 | 봄동 썰기 | #29 | 미완료 |
| 3 | 고추장/참기름/깨 준비 | #30 | 미완료 |
| 4 | 그릇/수저 세팅 | #31 | 미완료 |

#### Cooking (조리 진행 중)
| # | 작업 | GitHub | 상태 |
|---|------|--------|------|
| 5 | 버섯 볶기 | #32 | 미완료 |
| 6 | 콩나물 데치기 | #33 | 미완료 |
| 7 | 계란 프라이 | #34 | 미완료 |
| 8 | 밥 데우기 | #35 | 미완료 |

#### Ready to Serve (담기 준비 완료)
| # | 작업 | GitHub | 상태 |
|---|------|--------|------|
| 9 | 밥 1공기 준비됨 | #36 | 미완료 |
| 10 | 당근 채썰기 완료 | #37 | 미완료 |
| 11 | 고명 배치 순서 점검 | #38 | 미완료 |
| 12 | 비벼 먹기 직전 상태 | #39 | 미완료 |

#### Completed (완료)
| # | 작업 | GitHub | 상태 |
|---|------|--------|------|
| 13 | 냉장고 재료 확인 완료 | #40 | ✅ 완료 |
| 14 | 봄동 손질 완료 | #41 | ✅ 완료 |
| 15 | 기본 플레이팅 완료 | #42 | ✅ 완료 |
| 16 | 다음 개선 포인트 기록 | #43 | ✅ 완료 |

---

### 4️⃣ team_member (팀 멤버)

프로젝트 팀의 담당자를 저장합니다.

| 컬럼 | 타입 | 제약조건 | 설명 |
|------|------|---------|------|
| `member_id` | BIGINT | **PK** ⭐ | 멤버 고유 ID (자동증가) |
| `board_id` | BIGINT | **FK** 🔗 | 보드 참조 (ON DELETE CASCADE) |
| `member_name` | TEXT | NOT NULL | 멤버 이름 |
| `role` | TEXT | - | 역할 (Chef, Assistant) |
| `created_at` | TIMESTAMPTZ | DEFAULT NOW() | 추가 시간 |

**생성된 멤버:**
```
member_id=1 → 김정환 (Lead Chef / 총괄)
member_id=2 → 김소윤 (Chef / 조리 담당)
member_id=3 → 김채우 (Chef / 담기 담당)
```

---

### 5️⃣ task_assignment (작업 담당 - N:M 관계)

작업과 팀 멤버의 다대다 관계를 정의합니다.

| 컬럼 | 타입 | 제약조건 | 설명 |
|------|------|---------|------|
| `task_id` | BIGINT | **FK PK** 🔗 | 작업 참조 (ON DELETE CASCADE) |
| `member_id` | BIGINT | **FK PK** 🔗 | 멤버 참조 (ON DELETE CASCADE) |
| `assigned_at` | TIMESTAMPTZ | DEFAULT NOW() | 지정 시간 |

**할당된 관계 (16개 - 중복 없음):**
```
준비 단계 (4개) → 김정환
조리 단계 (4개) → 김소윤
담기 단계 (4개) → 김채우
완료 단계 (4개) → 김정환
총 16개 작업, 완전한 역할 분담
```

---

## 🔗 GitHub와의 동기화

### GitHub Issues (16개)

모든 작업이 GitHub Issues로 생성되었으며, 각 이슈에는 메타데이터가 포함됩니다.

**예시 Issue (#28 - 봄동 씻기):**
```yaml
Title: 봄동 씻기
Label: preparation (재료 손질 및 준비)
Body:
  ## 📋 Card Details
  card_id: 1
  column_id: preparation
  column_name: 재료 손질 및 준비
  due_date: 2026-04-05
  order: 1
  
  ### Description
  흐르는 물에 봄동을 세척한다
```

### GitHub Labels (4개)

| 레이블 | 설명 | 색상 |
|--------|------|------|
| `preparation` | 재료 손질 및 준비 | 🟢 |
| `cooking` | 조리 진행 중 | 🟠 |
| `ready` | 담기 준비 완료 | 🔵 |
| `completed` | 완료 | ⚫ |

### GitHub Project

**프로젝트명:** 봄동비빔밥 만들기
**저장소:** itsjustcozyboy/Database
**Issues:** #28 ~ #43 (16개)

---

## 📁 파일 구조

```
/workspaces/Database/
├── supabase/
│   ├── config.toml
│   └── migrations/
│       ├── 001~009_legacy.sql          (reverted)
│       ├── 010_complete_schema.sql     (완전한 개념모델)
│       └── 011_domain_rename.sql       (도메인 중심 리네이밍)
│
├── README.md                           (이 파일)
├── CONCEPTUAL_MODEL_MAPPING.md        (개념모델 매핑)
├── SCHEMA_RENAME_COMPLETE.md          (테이블명 변경 내역)
├── SUPABASE_UPDATE_COMPLETE.md        (Supabase 업데이트 내역)
├── GITHUB_KANBAN_SETUP.md             (GitHub 셋업 가이드)
├── # 봄동비빔밥 만들기 칸반 보드 개념모델 ERD.md   (개념모델 문서)
│
├── package.json                        (npm 설정)
└── .env.local.example                  (환경 변수 템플릿)
```

---

## 🚀 시작하기

### 필수 요구사항
- Node.js >= 18
- npm >= 8
- Supabase CLI
- GitHub CLI (gh)

### 환경 설정

1. `.env.local` 생성
```bash
cp .env.local.example .env.local
```

2. Supabase 정보 입력
```bash
SUPABASE_URL=https://YOUR_PROJECT_ID.supabase.co
SUPABASE_ANON_KEY=YOUR_ANON_KEY
SUPABASE_SERVICE_ROLE_KEY=YOUR_SERVICE_ROLE_KEY
```

### 실행 명령어

```bash
# Supabase 로컬 환경 시작
npm run supabase:start

# 마이그레이션 적용 (원격)
npm run supabase:push

# 마이그레이션 상태 확인
npx supabase migration list

# Supabase 중지
npm run supabase:stop
```

---

## 📊 데이터 조회 쿼리

### 1. 모든 단계별 작업 조회

```sql
SELECT 
  s.column_name as step,
  COUNT(t.card_id) as total_tasks,
  COUNT(CASE WHEN t.is_done = TRUE THEN 1 END) as completed_tasks,
  COUNT(CASE WHEN t.is_done = FALSE THEN 1 END) as pending_tasks
FROM recipe_step s
LEFT JOIN recipe_task t ON s.column_id = t.step_id
WHERE s.board_id = 1
GROUP BY s.column_id, s.column_name
ORDER BY s.order_position;
```

### 2. 단계별 상세 작업 목록

```sql
SELECT 
  s.column_name as step,
  t.card_id,
  t.title,
  t.description,
  t.is_done,
  t.due_date,
  t.github_issue_number
FROM recipe_task t
JOIN recipe_step s ON t.step_id = s.column_id
WHERE t.board_id = 1
ORDER BY s.order_position, t.order_position;
```

### 3. 멤버별 할당된 작업

```sql
SELECT 
  m.member_name,
  m.role,
  COUNT(ta.task_id) as assigned_tasks,
  STRING_AGG(t.title, ', ' ORDER BY t.title) as task_list
FROM team_member m
LEFT JOIN task_assignment ta ON m.member_id = ta.member_id
LEFT JOIN recipe_task t ON ta.task_id = t.card_id
WHERE m.board_id = 1
GROUP BY m.member_id, m.member_name, m.role
ORDER BY m.member_id;
```

### 4. 완료 진행률

```sql
SELECT 
  b.board_name,
  COUNT(t.card_id) as total_tasks,
  ROUND(100.0 * COUNT(CASE WHEN t.is_done = TRUE THEN 1 END) / COUNT(t.card_id), 2) as completion_percentage
FROM recipe_board b
LEFT JOIN recipe_task t ON b.board_id = t.board_id
WHERE b.board_id = 1
GROUP BY b.board_id, b.board_name;
```

---

## � 팀원별 역할 분담

| 팀원 | 역할 | 담당 영역 | 할당 작업 |
|------|------|---------|---------|
| **김정환** | Lead Chef 🎖️ | 준비 + 완료 | 8개 |
| **김소윤** | Chef 👨‍🍳 | 조리 진행 중 | 4개 |
| **김채우** | Chef 👨‍🍳 | 담기 준비 완료 | 4개 |

---

## �🔍 개념모델 확인

### 주요 관계

| 관계 | 타입 | 설명 |
|------|------|------|
| recipe_board ↔ recipe_step | 1:N | 하나의 보드는 여러 단계를 가짐 |
| recipe_board ↔ recipe_task | 1:N | 하나의 보드는 여러 작업을 가짐 |
| recipe_step ↔ recipe_task | 1:N | 하나의 단계는 여러 작업을 가짐 |
| team_member ↔ recipe_task | N:M | 하나의 멤버는 여러 작업을, 작업은 여러 멤버를 가짐 |

### 제약 조건

| 제약조건 | 효과 | 설명 |
|---------|------|------|
| ON DELETE CASCADE (board_id) | 보드 삭제 시 관련 모든 단계/작업/멤버 삭제 | 데이터 정합성 유지 |
| ON DELETE RESTRICT (step_id) | 작업이 있는 단계는 삭제 불가 | 고아 레코드 방지 |
| UNIQUE (board_id, title) | 같은 보드 내 작업 제목 중복 불가 | 작업 고유성 보장 |

---

## 📚 마이그레이션 히스토리

| 버전 | 파일명 | 설명 | 상태 |
|------|--------|------|------|
| 001~009 | legacy | 이전 마이그레이션 | ⬜ Reverted |
| 010 | 010_cleanup_and_rebuild_complete_schema.sql | 완전한 개념모델 스키마 생성 | ✅ Applied |
| 011 | 011_rename_tables_for_conceptual_erd.sql | 도메인 중심 테이블 리네이밍 | ✅ Applied |
| 012 | 012_update_team_members_and_redistribute_tasks.sql | 팀원 이름 업데이트 및 작업 할당량 재배분 | ✅ Applied |
| 013 | 013_remove_duplicate_task_assignments.sql | 팀원 작업 할당 중복 제거 | ✅ Applied |
| 014 | 014_rename_lead_chef_to_kimjeonghwan.sql | 리드셰프 이름 변경 (You → 김정환) | ✅ Applied |

---

## 🎯 프로젝트 현황

### ✅ 완료된 항목

- ✅ 개념모델 정의 (Board, Step, Task, Member)
- ✅ Supabase 스키마 생성 (도메인 중심 명명)
- ✅ MySQL 마이그레이션 (010, 011)
- ✅ GitHub Issues 생성 (16개, 메타데이터 포함)
- ✅ GitHub Labels 생성 (4개)
- ✅ 작업 담당 관계 설정 (23개 관계)
- ✅ ERD 다이어그램 작성

### 🔄 진행 중인 항목

- 🔄 GitHub Project Board 시각화
- 🔄 Row Level Security (RLS) 정책 설정
- 🔄 API 엔드포인트 문서화

### 📋 향후 계획

- ⬜ GitHub Issues ↔ Supabase 자동 동기화 (GitHub Actions)
- ⬜ 웹 대시보드 구현 (Next.js + Supabase)
- ⬜ 협업 기능 강화 (댓글, 파일 첨부)

---

## 📖 참고 문서

- [개념모델 상세 매핑](CONCEPTUAL_MODEL_MAPPING.md)
- [테이블명 변경 내역](SCHEMA_RENAME_COMPLETE.md)
- [Supabase 업데이트 정보](SUPABASE_UPDATE_COMPLETE.md)
- [GitHub 칸반 셋업](GITHUB_KANBAN_SETUP.md)
- [개념모델 ERD 문서](# 봄동비빔밥 만들기 칸반 보드 개념모델 ERD.md)

---

## 🔗 외부 링크

- **GitHub Repository**: [itsjustcozyboy/Database](https://github.com/itsjustcozyboy/Database)
- **GitHub Issues**: [#28 ~ #43](https://github.com/itsjustcozyboy/Database/issues)
- **Supabase Project**: [Dashboard](https://supabase.com/dashboard)

---

## 💡 주요 기술 스택

| 레이어 | 기술 |
|--------|------|
| **Database** | Supabase (PostgreSQL) |
| **IaC** | Supabase CLI (마이그레이션) |
| **Issue Tracking** | GitHub Issues |
| **Project Management** | GitHub Projects |
| **Runtime** | Node.js |

---

## 📝 라이센스

이 프로젝트는 교육/학습 목적의 예제입니다.

---

## 🤝 기여

개선 사항이 있으시면 이슈를 열어주세요!

---

**마지막 업데이트:** 2026-03-30  
**상태:** ✅ Production Ready - 개념모델 ERD 기반 완전한 스키마 구현 완료
