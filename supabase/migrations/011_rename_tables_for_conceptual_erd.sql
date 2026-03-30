-- ============================================================================
-- 마이그레이션: 도메인 중심 테이블명 변경 (개념모델 ERD용)
-- ============================================================================
-- 목적:
-- kanban_* 접두사 제거 및 도메인 중심 명명으로 개념모델 명확화
-- 
-- 테이블명 변경:
-- kanban_board → recipe_board (요리 보드)
-- kanban_column → recipe_step (요리 단계)
-- kanban_card → recipe_task (요리 작업)
-- kanban_member → team_member (팀 멤버)
-- kanban_card_member → task_assignment (작업 담당)
--
-- ============================================================================

-- ============================================================================
-- Step 1: 외래 키 제약 조건 임시 비활성화
-- ============================================================================

ALTER TABLE kanban_card_member DROP CONSTRAINT kanban_card_member_card_id_fkey;
ALTER TABLE kanban_card_member DROP CONSTRAINT kanban_card_member_member_id_fkey;
ALTER TABLE kanban_card DROP CONSTRAINT kanban_card_column_id_fkey;
ALTER TABLE kanban_card DROP CONSTRAINT kanban_card_board_id_fkey;
ALTER TABLE kanban_column DROP CONSTRAINT kanban_column_board_id_fkey;
ALTER TABLE kanban_member DROP CONSTRAINT kanban_member_board_id_fkey;

-- ============================================================================
-- Step 2: 테이블 이름 변경
-- ============================================================================

ALTER TABLE kanban_board RENAME TO recipe_board;
ALTER TABLE kanban_column RENAME TO recipe_step;
ALTER TABLE kanban_card RENAME TO recipe_task;
ALTER TABLE kanban_member RENAME TO team_member;
ALTER TABLE kanban_card_member RENAME TO task_assignment;

-- ============================================================================
-- Step 3: 외래 키 제약 조건 재설정
-- ============================================================================

-- recipe_step.board_id FK
ALTER TABLE recipe_step
ADD CONSTRAINT recipe_step_board_id_fkey
FOREIGN KEY (board_id) REFERENCES recipe_board(board_id) ON DELETE CASCADE;

-- recipe_task FK
ALTER TABLE recipe_task
ADD CONSTRAINT recipe_task_board_id_fkey
FOREIGN KEY (board_id) REFERENCES recipe_board(board_id) ON DELETE CASCADE;

ALTER TABLE recipe_task
ADD CONSTRAINT recipe_task_column_id_fkey
FOREIGN KEY (column_id) REFERENCES recipe_step(column_id) ON DELETE RESTRICT;

-- team_member FK
ALTER TABLE team_member
ADD CONSTRAINT team_member_board_id_fkey
FOREIGN KEY (board_id) REFERENCES recipe_board(board_id) ON DELETE CASCADE;

-- task_assignment FK (N:M 관계)
ALTER TABLE task_assignment
ADD CONSTRAINT task_assignment_task_id_fkey
FOREIGN KEY (card_id) REFERENCES recipe_task(card_id) ON DELETE CASCADE;

ALTER TABLE task_assignment
ADD CONSTRAINT task_assignment_member_id_fkey
FOREIGN KEY (member_id) REFERENCES team_member(member_id) ON DELETE CASCADE;

-- ============================================================================
-- Step 4: 컬럼명 변경 (semantics 개선)
-- ============================================================================

-- recipe_task 테이블에서 column_id → step_id로 변경 (더 명확한 의미)
ALTER TABLE recipe_task RENAME COLUMN column_id TO step_id;

-- task_assignment 테이블에서 card_id → task_id로 변경 (일관성)
ALTER TABLE task_assignment RENAME COLUMN card_id TO task_id;

-- ============================================================================
-- Step 5: FK 제약 조건명 업데이트
-- ============================================================================

ALTER TABLE recipe_task
DROP CONSTRAINT recipe_task_column_id_fkey;

ALTER TABLE recipe_task
ADD CONSTRAINT recipe_task_step_id_fkey
FOREIGN KEY (step_id) REFERENCES recipe_step(column_id) ON DELETE RESTRICT;

ALTER TABLE task_assignment
DROP CONSTRAINT task_assignment_task_id_fkey;

ALTER TABLE task_assignment
ADD CONSTRAINT task_assignment_task_id_fkey
FOREIGN KEY (task_id) REFERENCES recipe_task(card_id) ON DELETE CASCADE;

-- ============================================================================
-- Step 6: 테이블 주석 업데이트
-- ============================================================================

COMMENT ON TABLE recipe_board IS '요리 보드 기본 정보';
COMMENT ON COLUMN recipe_board.board_id IS 'PK - 요리 보드 고유 ID (자동증가)';
COMMENT ON COLUMN recipe_board.board_name IS '요리 보드 이름 (예: 봄동비빔밥 만들기)';
COMMENT ON COLUMN recipe_board.description IS '요리 보드 설명';
COMMENT ON COLUMN recipe_board.source_url IS 'UNIQUE - 원본 보드 URL (예: GitHub Projects URL)';
COMMENT ON COLUMN recipe_board.created_at IS '보드 생성 시간';

COMMENT ON TABLE recipe_step IS '요리 단계 정의 (준비, 조리, 담기 등)';
COMMENT ON COLUMN recipe_step.column_id IS 'PK - 단계 ID (예: preparation, cooking_in_progress)';
COMMENT ON COLUMN recipe_step.board_id IS 'FK → recipe_board.board_id (ON DELETE CASCADE)';
COMMENT ON COLUMN recipe_step.column_name IS '단계 이름 (예: 재료 손질 및 준비)';
COMMENT ON COLUMN recipe_step.order_position IS 'UNIQUE - 보드상의 순서';

COMMENT ON TABLE recipe_task IS '요리 작업 (개별 작업 단위)';
COMMENT ON COLUMN recipe_task.card_id IS 'PK - 작업 고유 ID (자동증가)';
COMMENT ON COLUMN recipe_task.board_id IS 'FK → recipe_board.board_id (ON DELETE CASCADE)';
COMMENT ON COLUMN recipe_task.step_id IS 'FK → recipe_step.column_id (ON DELETE RESTRICT)';
COMMENT ON COLUMN recipe_task.title IS 'UNIQUE (board_id, title) - 작업 제목';
COMMENT ON COLUMN recipe_task.description IS '작업 상세 설명';
COMMENT ON COLUMN recipe_task.due_date IS '작업 마감일';
COMMENT ON COLUMN recipe_task.order_position IS '단계 내 작업 순서 (상→하)';
COMMENT ON COLUMN recipe_task.is_done IS '완료 여부';
COMMENT ON COLUMN recipe_task.github_issue_number IS 'GitHub 이슈 번호 (선택사항)';
COMMENT ON COLUMN recipe_task.created_at IS '작업 생성 시간';

COMMENT ON TABLE team_member IS '요리 보드의 팀 멤버/담당자';
COMMENT ON COLUMN team_member.member_id IS 'PK - 멤버 고유 ID (자동증가)';
COMMENT ON COLUMN team_member.board_id IS 'FK → recipe_board.board_id (ON DELETE CASCADE)';
COMMENT ON COLUMN team_member.member_name IS '멤버 이름';
COMMENT ON COLUMN team_member.role IS '멤버 역할 (예: Chef, Assistant)';
COMMENT ON COLUMN team_member.created_at IS '멤버 추가 시간';

COMMENT ON TABLE task_assignment IS '작업과 담당자의 N:M 관계';
COMMENT ON COLUMN task_assignment.task_id IS 'FK → recipe_task.card_id (ON DELETE CASCADE)';
COMMENT ON COLUMN task_assignment.member_id IS 'FK → team_member.member_id (ON DELETE CASCADE)';
COMMENT ON COLUMN task_assignment.assigned_at IS '담당자 지정 시간';

-- ============================================================================
-- Step 7: 관계도 (최종)
-- ============================================================================
--
-- recipe_board (1) ──┬→ recipe_step (N)
--                   ├→ team_member (N)
--                   └→ recipe_task (N)
--                         │
--                         ↓ (step_id)
--                   recipe_step
--                         │
--                    task_assignment (M)
--                         │
--                         ↓ (member_id)
--                   team_member
--
-- ============================================================================

-- 검증 쿼리 (마이그레이션 적용 후 실행)
-- SELECT * FROM recipe_board;
-- SELECT * FROM recipe_step WHERE board_id = 1 ORDER BY order_position;
-- SELECT * FROM recipe_task WHERE board_id = 1 ORDER BY step_id, order_position;
-- SELECT * FROM team_member WHERE board_id = 1;
-- SELECT rt.card_id, rt.title, tm.member_name FROM task_assignment ta
--   JOIN recipe_task rt ON ta.task_id = rt.card_id
--   JOIN team_member tm ON ta.member_id = tm.member_id
--   ORDER BY ta.task_id;
