-- ============================================================================
-- 마이그레이션: 칸반 보드 스키마 개선 - 의미있는 키와 명확한 PK/FK 정의
-- ============================================================================
-- 목적: 
-- 1. column_key를 더 의미있는 이름으로 변경
-- 2. PK/FK 관계를 명확하게 정의
-- 3. 데이터베이스 문서화 개선

-- ============================================================================
-- 칸반 보드 테이블 스키마 정의
-- ============================================================================

-- 1. kanban_board
-- PK: board_id (BIGINT)
-- 칸반 보드의 기본 정보를 저장하는 테이블
-- 
COMMENT ON TABLE kanban_board IS '칸반 보드 기본 정보';
COMMENT ON COLUMN kanban_board.board_id IS 'PK - 칸반 보드 고유 ID (자동증가)';
COMMENT ON COLUMN kanban_board.board_name IS '칸반 보드 이름 (예: 봄동비빔밥 먹기)';
COMMENT ON COLUMN kanban_board.source_url IS 'UNIQUE - 원본 보드 URL (예: GitHub Projects URL)';
COMMENT ON COLUMN kanban_board.description IS '칸반 보드 설명';
COMMENT ON COLUMN kanban_board.created_at IS '보드 생성 시간';

-- ============================================================================
-- 2. kanban_column
-- PK: column_id (BIGINT)
-- FK: board_id → kanban_board.board_id (ON DELETE CASCADE)
-- 칸반 보드의 상태 열(To Do, In Progress, Ready, Done)을 정의
--
-- column_key 매핑 표:
-- ┌─────────────────────┬───────────────────────┬─────────────────────────────┐
-- │ column_key (OLD)    │ column_key (NEW)      │ column_name (한글)          │
-- ├─────────────────────┼───────────────────────┼─────────────────────────────┤
-- │ todo                │ preparation           │ 재료 손질 및 준비             │
-- │ in-progress         │ cooking_in_progress   │ 조리 진행 중                 │
-- │ ready-to-assemble   │ ready_to_serve        │ 담기 준비 완료               │
-- │ done                │ completed             │ 완료                        │
-- └─────────────────────┴───────────────────────┴─────────────────────────────┘
--

COMMENT ON TABLE kanban_column IS '칸반 보드의 상태 열 정의';
COMMENT ON COLUMN kanban_column.column_id IS 'PK - 칸반 열 고유 ID (자동증가)';
COMMENT ON COLUMN kanban_column.board_id IS 'FK → kanban_board.board_id (ON DELETE CASCADE) - 소속 보드';
COMMENT ON COLUMN kanban_column.column_key IS 'UNIQUE (board_id, column_key) - 열의 영문 키 (예: preparation, cooking_in_progress)';
COMMENT ON COLUMN kanban_column.column_name IS '열의 한글 표시 이름 (예: 재료 손질 및 준비)';
COMMENT ON COLUMN kanban_column.position IS 'UNIQUE (board_id, position) - 열의 보드 상 위치 (좌→우 순서)';

-- ============================================================================
-- 3. kanban_card
-- PK: card_id (BIGINT)
-- FK: board_id → kanban_board.board_id (ON DELETE CASCADE)
-- FK: column_id → kanban_column.column_id (ON DELETE RESTRICT)
-- 칸반 보드의 개별 카드(작업)를 저장
--

COMMENT ON TABLE kanban_card IS '칸반 보드의 개별 카드(작업) 정보';
COMMENT ON COLUMN kanban_card.card_id IS 'PK - 카드 고유 ID (자동증가)';
COMMENT ON COLUMN kanban_card.board_id IS 'FK → kanban_board.board_id (ON DELETE CASCADE) - 소속 보드';
COMMENT ON COLUMN kanban_card.column_id IS 'FK → kanban_column.column_id (ON DELETE RESTRICT) - 현재 상태 열';
COMMENT ON COLUMN kanban_card.title IS 'UNIQUE (board_id, title) - 카드 제목 (예: 봄동 씻기)';
COMMENT ON COLUMN kanban_card.detail IS '카드 상세 설명';
COMMENT ON COLUMN kanban_card.github_issue_number IS 'GitHub 이슈 번호 (선택사항)';
COMMENT ON COLUMN kanban_card.is_done IS '완료 여부 (completed 열에 있는 카드는 TRUE)';
COMMENT ON COLUMN kanban_card.position IS '해당 열 내에서의 카드 위치 (상→하 순서)';
COMMENT ON COLUMN kanban_card.created_at IS '카드 생성 시간';

-- ============================================================================
-- column_key 업데이트
-- ============================================================================

UPDATE kanban_column
SET column_key = 'preparation',
    column_name = '재료 손질 및 준비'
WHERE column_key = 'todo';

UPDATE kanban_column
SET column_key = 'cooking_in_progress',
    column_name = '조리 진행 중'
WHERE column_key = 'in-progress';

UPDATE kanban_column
SET column_key = 'ready_to_serve',
    column_name = '담기 준비 완료'
WHERE column_key = 'ready-to-assemble';

UPDATE kanban_column
SET column_key = 'completed',
    column_name = '완료'
WHERE column_key = 'done';

-- ============================================================================
-- PK/FK 관계도
-- ============================================================================
--
-- kanban_board (보드 정보)
--     │
--     ├─→ board_id (PK)
--     │
--     ├─→ kanban_column (상태 열)
--     │   │
--     │   ├─→ column_id (PK)
--     │   ├─→ board_id (FK)
--     │   │
--     │   └─→ kanban_card (개별 작업)
--     │       │
--     │       ├─→ card_id (PK)
--     │       ├─→ board_id (FK)
--     │       └─→ column_id (FK)
--     │
--     └─→ kanban_card (개별 작업)
--         │
--         ├─→ card_id (PK)
--         ├─→ board_id (FK)
--         └─→ column_id (FK)
--
-- ============================================================================
-- 관계 설명:
-- ============================================================================
--
-- 1:N 관계 (kanban_board → kanban_column)
--   - 하나의 보드는 여러 개의 상태 열을 가짐
--   - board_id 변경 시 관련된 모든 열 삭제 (CASCADE)
--
-- 1:N 관계 (kanban_board → kanban_card)
--   - 하나의 보드는 여러 개의 카드를 가짐
--   - board_id 변경 시 관련된 모든 카드 삭제 (CASCADE)
--
-- 1:N 관계 (kanban_column → kanban_card)
--   - 하나의 상태 열은 여러 개의 카드를 가짐
--   - column_id 삭제 시도 시 RESTRICT - 카드가 있으면 삭제 불가
--
-- ============================================================================
