# Supabase 테이블명 변경 완료 (도메인 중심)

## ✅ 변경 완료

마이그레이션: `011_rename_tables_for_conceptual_erd.sql`

---

## 📋 테이블명 변경 대조표

| 이전 이름 | 새 이름 | 의미 | 설명 |
|----------|--------|------|------|
| kanban_board | **recipe_board** | 요리 보드 | 봄동비빔밥 만들기 프로젝트 보드 |
| kanban_column | **recipe_step** | 요리 단계 | 요리 과정의 각 단계 (준비, 조리, 담기, 완료) |
| kanban_card | **recipe_task** | 요리 작업 | 각 단계에서 수행할 개별 작업 |
| kanban_member | **team_member** | 팀 멤버 | 프로젝트 팀의 담당자 |
| kanban_card_member | **task_assignment** | 작업 담당 | 작업과 담당자의 N:M 관계 |

---

## 🔄 컬럼명 변경

### recipe_task 테이블
| 이전 컬럼 | 새 컬럼 | 이유 |
|----------|--------|------|
| column_id | **step_id** | recipe_step과의 관계 명확화 |

### task_assignment 테이블
| 이전 컬럼 | 새 컬럼 | 이유 |
|----------|--------|------|
| card_id | **task_id** | recipe_task와의 관계 명확화 |

---

## 📊 최종 스키마 (도메인 중심)

### 1. recipe_board (요리 보드)
```sql
CREATE TABLE recipe_board (
  board_id BIGINT PRIMARY KEY,
  board_name TEXT NOT NULL,
  description TEXT,
  source_url TEXT UNIQUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```
**예시 데이터:**
```
board_id=1, board_name='봄동비빔밥 만들기'
```

### 2. recipe_step (요리 단계)
```sql
CREATE TABLE recipe_step (
  column_id TEXT PRIMARY KEY,
  board_id BIGINT FK → recipe_board,
  column_name TEXT NOT NULL,
  order_position INT NOT NULL
);
```
**생성된 단계 (4개):**
```
1. preparation → 재료 손질 및 준비
2. cooking_in_progress → 조리 진행 중
3. ready_to_serve → 담기 준비 완료
4. completed → 완료
```

### 3. recipe_task (요리 작업)
```sql
CREATE TABLE recipe_task (
  card_id BIGINT PRIMARY KEY,
  board_id BIGINT FK → recipe_board,
  step_id TEXT FK → recipe_step,      -- 변경!
  title TEXT NOT NULL,
  description TEXT,
  due_date DATE,
  order_position INT,
  is_done BOOLEAN DEFAULT FALSE,
  github_issue_number INT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```
**생성된 작업 (16개):**
```
Preparation (4):
  1. 봄동 씻기 (#28)
  2. 봄동 썰기 (#29)
  3. 고추장/참기름/깨 준비 (#30)
  4. 그릇/수저 세팅 (#31)

Cooking (4):
  5. 버섯 볶기 (#32)
  6. 콩나물 데치기 (#33)
  7. 계란 프라이 (#34)
  8. 밥 데우기 (#35)

Ready to Serve (4):
  9. 밥 1공기 준비됨 (#36)
  10. 당근 채썰기 완료 (#37)
  11. 고명 배치 순서 점검 (#38)
  12. 비벼 먹기 직전 상태 (#39)

Completed (4):
  13. 냉장고 재료 확인 완료 (#40)
  14. 봄동 손질 완료 (#41)
  15. 기본 플레이팅 완료 (#42)
  16. 다음 개선 포인트 기록 (#43)
```

### 4. team_member (팀 멤버)
```sql
CREATE TABLE team_member (
  member_id BIGINT PRIMARY KEY,
  board_id BIGINT FK → recipe_board,
  member_name TEXT NOT NULL,
  role TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```
**생성된 멤버 (3명):**
```
1. 나 (Chef)
2. 팀원1 (Assistant)
3. 팀원2 (Assistant)
```

### 5. task_assignment (작업 담당 - N:M)
```sql
CREATE TABLE task_assignment (
  task_id BIGINT FK → recipe_task,    -- 변경!
  member_id BIGINT FK → team_member,
  assigned_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (task_id, member_id)
);
```
**담당 관계 (23개):**
```
- 모든 16개 작업 → 멤버1 (나)
- 조리 4개 작업 → 멤버2 (팀원1)
- 담기 4개 작업 → 멤버3 (팀원2)
```

---

## 🔗 관계도 (최종)

```
┌──────────────────┐
│   recipe_board   │
│   (요리 보드)    │
└──────────────────┘
         │
         ├──→ recipe_step (1:N)          recipe_task (1:N)          team_member (1:N)
         │    (요리 단계)                  (요리 작업)                (팀 멤버)
         │    ┌──────────┐                ┌──────────┐               ┌──────────┐
         │    │preparation                │Title    │               │Name     │
         │    │cooking_...│                │Description │             │Role     │
         │    │ready_to...│                │step_id ──┐              │         │
         │    │completed│                 │is_done  │              └──────────┘
         │    └──────────┘                │...      │
         │         │                       └──────────┘
         │         └─────→ task_assignment (N:M) ←────┘
         │              (작업 담당)
         └─────────────────────────────────────────────────┘
```

---

## 💡 개념모델 ERD 이점

이제 테이블명이 도메인 중심이므로:

✅ **명확한 의미**
```
recipe_board      → 봄동비빔밥 요리 프로젝트
recipe_step       → 요리 과정의 각 단계
recipe_task       → 각 단계의 구체적 작업
team_member       → 팀 멤버
task_assignment   → 작업 담당자 지정
```

✅ **개념모델 ERD 작성 용이**
- 테이블명만 봐도 엔티티 의미가 명확
- SQL 쿼리도 더 읽기 쉬움
- 같은 도메인 프로젝트에 적용 가능

---

## 🔍 마이그레이션 검증 쿼리

### 테이블명 확인
```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;

-- 결과:
-- recipe_board
-- recipe_step
-- recipe_task
-- task_assignment
-- team_member
```

### 외래 키 확인
```sql
SELECT constraint_name, table_name, column_name
FROM information_schema.key_column_usage
WHERE table_schema = 'public'
ORDER BY table_name;
```

### 데이터 무결성 확인
```sql
SELECT 
  (SELECT COUNT(*) FROM recipe_board) as board_count,
  (SELECT COUNT(*) FROM recipe_step) as step_count,
  (SELECT COUNT(*) FROM recipe_task) as task_count,
  (SELECT COUNT(*) FROM team_member) as member_count,
  (SELECT COUNT(*) FROM task_assignment) as assignment_count;

-- 결과:
-- board_count=1, step_count=4, task_count=16, 
-- member_count=3, assignment_count=23
```

---

## 📈 마이그레이션 히스토리

```
Local: 011  |  Remote: 011  |  Status: ✅ APPLIED
```

**완료된 마이그레이션:**
```
010 - 완전한 개념모델 스키마 생성 (kanban_* 테이블)
011 - 도메인 중심 테이블명 변경 (recipe_*, team_*, task_assignment)
```

---

## 🎯 다음 단계

1. **개념모델 ERD 작성**
   - Mermaid 다이어그램 생성
   - Chen 표기법 또는 Visual ERD

2. **README 업데이트**
   - 새 테이블명 반영
   - 스키마 다이어그램 업데이트

3. **Supabase API 문서**
   - recipe_* 엔드포인트 정의
   - Row Level Security (RLS) 정책 설정

---

## 🎉 최종 상태

| 항목 | 상태 |
|------|------|
| **Supabase 테이블** | ✅ 도메인 중심 명명 (recipe_*, team_*) |
| **외래 키 관계** | ✅ 모두 정상 (FK 검증 완료) |
| **데이터 무결성** | ✅ 16개 작업 + 23개 담당 관계 유지 |
| **개념모델 준비** | ✅ ERD 작성 준비 완료 |
| **마이그레이션** | ✅ 011 적용 완료 |

이제 **개념모델 ERD를 만들기 위한 최적의 스키마**가 완성되었습니다! 🚀
