# Database - 봄동비빔밥 칸반 보드 스키마

Supabase를 사용한 칸반 보드 데이터베이스 관리 프로젝트입니다.

## 📋 목차

- [데이터베이스 스키마](#-데이터베이스-스키마)
- [테이블 구조](#-테이블-구조)
- [설정 및 실행](#-설정-및-실행)

---

## 🏗️ 데이터베이스 스키마

### ERD (Entity Relationship Diagram)

```
┌─────────────────────────────────────────────────────────────┐
│                    kanban_board                              │
├─────────────────────────────────────────────────────────────┤
│ PK board_id (BIGINT) ⭐                                      │
│ board_name (TEXT)                                            │
│ source_url (TEXT) - UNIQUE                                   │
│ description (TEXT)                                           │
│ created_at (TIMESTAMPTZ)                                     │
└─────────────────────────────────────────────────────────────┘
              │                       │
              │ 1:N                   │ 1:N
              ↓                       ↓
┌──────────────────────────────┐  ┌──────────────────────────────┐
│     kanban_column            │  │      kanban_card             │
├──────────────────────────────┤  ├──────────────────────────────┤
│ PK column_id (BIGINT) ⭐     │  │ PK card_id (BIGINT) ⭐       │
│ FK board_id (BIGINT) 🔗      │  │ FK board_id (BIGINT) 🔗      │
│ column_key (TEXT)            │  │ FK column_id (BIGINT) 🔗     │
│ column_name (TEXT)           │  │ title (TEXT)                 │
│ position (INT)               │  │ detail (TEXT)                │
│                              │  │ github_issue_number (INT)    │
│ UNIQUE: (board_id, key)      │  │ is_done (BOOLEAN)            │
│ UNIQUE: (board_id, position) │  │ position (INT)               │
│                              │  │ created_at (TIMESTAMPTZ)     │
│                              │  │                              │
│                              │  │ UNIQUE: (board_id, title)    │
└──────────────────────────────┘  └──────────────────────────────┘
              │                              │
              └──────────────→ ON DELETE RESTRICT
```

---

## 📊 테이블 구조

### 1️⃣ kanban_board (칸반 보드)

**설명**: 칸반 보드의 기본 정보를 저장합니다.

| 컬럼명 | 타입 | 제약조건 | 설명 |
|--------|------|---------|------|
| `board_id` | BIGINT | **PK** ⭐ | 칸반 보드 고유 ID (자동증가) |
| `board_name` | TEXT | NOT NULL | 보드 이름 (예: 봄동비빔밥 먹기) |
| `source_url` | TEXT | UNIQUE | 원본 보드 URL (예: GitHub Projects URL) |
| `description` | TEXT | - | 보드 설명 |
| `created_at` | TIMESTAMPTZ | DEFAULT NOW() | 보드 생성 시간 |

**예시**:
```
board_id | board_name      | source_url                        | created_at
---------|-----------------|-----------------------------------|-----------
1        | 봄동비빔밥 먹기  | https://github.com/.../projects/2 | 2026-03-30
```

---

### 2️⃣ kanban_column (상태 열)

**설명**: 칸반 보드의 상태(준비, 진행중, 준비완료, 완료)를 정의합니다.

| 컬럼명 | 타입 | 제약조건 | 설명 |
|--------|------|---------|------|
| `column_id` | TEXT | **PK** ⭐ | 열의 문자 기반 고유 ID (예: preparation, cooking_in_progress, ready_to_serve, completed) |
| `board_id` | BIGINT | **FK** 🔗 | 소속 보드 ID (ON DELETE CASCADE) |
| `column_key` | TEXT | UNIQUE (board_id, key) | 열의 영문 키 |
| `column_name` | TEXT | NOT NULL | 열의 한글 표시 이름 |
| `position` | INT | UNIQUE (board_id, pos) | 보드상의 좌→우 위치 |

**column_id 매핑 (의미있는 텍스트 키)**:

| column_id | column_name | 순서 | 설명 |
|-----------|-------------|------|------|
| `preparation` | 재료 손질 및 준비 | 1️⃣ | 준비할 작업 목록 |
| `cooking_in_progress` | 조리 진행 중 | 2️⃣ | 현재 진행 중인 작업 |
| `ready_to_serve` | 담기 준비 완료 | 3️⃣ | 완성 직전 준비 완료 |
| `completed` | 완료 | 4️⃣ | 완료된 작업 |

**예시**:
```
column_id | board_id | column_key | column_name | position
----------|----------|-----------|-------------|----------
preparation | 1 | preparation | 재료 손질 및 준비 | 1
cooking_in_progress | 1 | cooking_in_progress | 조리 진행 중 | 2
ready_to_serve | 1 | ready_to_serve | 담기 준비 완료 | 3
completed | 1 | completed | 완료 | 4
```

---

### 3️⃣ kanban_card (카드/작업)

**설명**: 칸반 보드의 개별 카드(작업)를 저장합니다.

| 컬럼명 | 타입 | 제약조건 | 설명 |
|--------|------|---------|------|
| `card_id` | BIGINT | **PK** ⭐ | 카드 고유 ID (자동증가) |
| `board_id` | BIGINT | **FK** 🔗 | 소속 보드 ID (ON DELETE CASCADE) |
| `column_id` | TEXT | **FK** 🔗 | 현재 상태 열 ID - 의미있는 텍스트 키 (예: preparation) (ON DELETE RESTRICT) |
| `title` | TEXT | UNIQUE (board_id, title) | 카드 제목 (예: 봄동 씻기) |
| `detail` | TEXT | - | 카드 상세 설명 |
| `github_issue_number` | INT | - | GitHub 이슈 번호 (선택사항) |
| `is_done` | BOOLEAN | DEFAULT FALSE | 완료 여부 |
| `position` | INT | - | 해당 열 내 위치 (상→하) |
| `created_at` | TIMESTAMPTZ | DEFAULT NOW() | 카드 생성 시간 |

**예시**:
```
card_id | board_id | column_id | title | is_done | position
--------|----------|-----------|-------|---------|----------
1       | 1        | preparation | 봄동 씻기 | FALSE | 1
2       | 1        | preparation | 당근 채썰기 | FALSE | 2
3       | 1        | cooking_in_progress | 버섯 볶기 | FALSE | 1
4       | 1        | completed | 냉장고 재료 확인 완료 | TRUE | 1
```

---

## 📌 중요 관계 규칙

### 1️⃣ kanban_board → kanban_column (1:N)
- **관계**: 하나의 보드는 여러 개의 상태 열을 가짐
- **삭제 규칙**: ON DELETE CASCADE
- **의미**: 보드가 삭제되면 관련된 모든 열도 삭제됨

### 2️⃣ kanban_board → kanban_card (1:N)
- **관계**: 하나의 보드는 여러 개의 카드를 가짐
- **삭제 규칙**: ON DELETE CASCADE
- **의미**: 보드가 삭제되면 관련된 모든 카드도 삭제됨

### 3️⃣ kanban_column → kanban_card (1:N)
- **관계**: 하나의 상태 열은 여러 개의 카드를 가짐
- **삭제 규칙**: ON DELETE RESTRICT ⛔
- **의미**: 열 삭제 불가 - 카드가 있는 열은 삭제할 수 없음

---

## 🔑 PK / FK 명명 규칙

### Primary Key (PK) - 식별자 ⭐

각 테이블의 PK는 **`{테이블명}_id`** 형식으로 명명합니다:
- `kanban_board.board_id`
- `kanban_column.column_id`
- `kanban_card.card_id`

**특징**:
- 타입: BIGINT (큰 수를 처리할 수 있음)
- 자동증가: BIGSERIAL (INSERT 시 자동으로 1씩 증가)
- NOT NULL and UNIQUE

### Foreign Key (FK) - 관계 🔗

FK는 **`{참조테이블명}_id`** 형식으로 명명합니다:
- `kanban_column.board_id` → `kanban_board.board_id` 참조
- `kanban_card.board_id` → `kanban_board.board_id` 참조
- `kanban_card.column_id` → `kanban_column.column_id` 참조

**특징**:
- 타입: 참조하는 PK와 동일 (kanban_card.column_id는 TEXT)
- NOT NULL (모든 카드/열은 반드시 보드에 속함)
- 참조 무결성 보장
- 의미있는 텍스트 키로 직관적 식별 가능

---

## 🛠️ 설정 및 실행

### 필수 요구사항
- Node.js >= 18
- npm >= 8
- Supabase CLI

### 환경 설정

1. `.env.local.example`을 `.env.local`로 복사:
   ```bash
   cp .env.local.example .env.local
   ```

2. Supabase 프로젝트 정보 입력:
   ```bash
   SUPABASE_URL=https://YOUR_PROJECT_ID.supabase.co
   SUPABASE_ANON_KEY=YOUR_ANON_KEY
   SUPABASE_SERVICE_ROLE_KEY=YOUR_SERVICE_ROLE_KEY
   ```

### 로컬 개발 서버 시작

```bash
# Supabase 로컬 환경 시작
npm run supabase:start

# 마이그레이션 실행
npm run db:push
```

### 유용한 명령어

```bash
# Supabase 로컬 환경 시작
npm run supabase:start

# 마이그레이션 실행 (원격)
npm run supabase:push

# 스키마 풀 (원격 → 로컬)
npm run supabase:pull

# 로컬 환경 중지
npm run supabase:stop
```

### Studio 접근

로컬 개발 중 Supabase Studio:
- **URL**: http://localhost:3000
- **API Port**: 54321

---

## 📁 파일 구조

```
/workspaces/Database/
├── supabase/
│   ├── config.toml              # Supabase CLI 설정
│   └── migrations/              # SQL 마이그레이션 파일
│       ├── 001_create_test_table.sql
│       ├── 002_create_schema.sql
│       ├── 003_insert_sample_data.sql
│       ├── 004_create_kanban_tables_and_seed.sql
│       ├── 005_cleanup_except_bomdong_kanban.sql
│       ├── 006_improve_kanban_schema_with_meaningful_keys.sql
│       └── 007_change_column_id_to_meaningful_text_keys.sql
├── package.json
├── README.md                    # 이 파일
└── .env.local.example           # 환경 변수 템플릿
```

---

## 📚 마이그레이션 파일 설명

| 파일 | 설명 |
|------|------|
| `001_create_test_table.sql` | 테스트 테이블 (이미 원격 적용됨) |
| `002_create_schema.sql` | 스키마 생성 (이미 원격 적용됨) |
| `003_insert_sample_data.sql` | 샘플 데이터 (이미 원격 적용됨) |
| `004_create_kanban_tables_and_seed.sql` | 칸반 테이블 및 초기 데이터 생성 |
| `005_cleanup_except_bomdong_kanban.sql` | 불필요한 데이터 정리 |
| `006_improve_kanban_schema_with_meaningful_keys.sql` | 스키마 개선: PK/FK 명확화, 의미있는 키 추가 |
| `007_change_column_id_to_meaningful_text_keys.sql` | column_id를 숫자(1,2,3,4) → 의미있는 텍스트로 변경 |

---

## 📖 추가 학습 자료

- [Supabase 공식 문서](https://supabase.com/docs)
- [Supabase CLI 가이드](https://supabase.com/docs/guides/cli)
- [PostgreSQL 기초](https://www.postgresql.org/docs/current/)