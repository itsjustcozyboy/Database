-- ============================================================================
-- 마이그레이션: column_id를 의미있는 텍스트 키로 변경
-- ============================================================================
-- 목적:
-- 1. column_id를 BIGINT(1,2,3,4) → TEXT('preparation', 'cooking_in_progress', etc)로 변경
-- 2. PK/FK 관계 재정의
-- 3. 데이터 무결성 유지

-- ============================================================================
-- Step 1: 새로운 구조의 임시 테이블 생성
-- ============================================================================

-- 기존 kanban_column 데이터를 백업하고 새 구조의 테이블 생성
DROP TABLE IF EXISTS kanban_column_new;

CREATE TABLE kanban_column_new (
  column_id TEXT PRIMARY KEY,
  board_id BIGINT NOT NULL REFERENCES kanban_board(board_id) ON DELETE CASCADE,
  column_key TEXT NOT NULL,
  column_name TEXT NOT NULL,
  position INT NOT NULL,
  UNIQUE(board_id, column_key),
  UNIQUE(board_id, position)
);

-- ============================================================================
-- Step 2: 기존 데이터를 새 테이블에 복사 (column_key 값으로 ID 설정)
-- ============================================================================

INSERT INTO kanban_column_new (column_id, board_id, column_key, column_name, position)
SELECT 
  column_key,  -- column_key 값을 새 column_id로 사용
  board_id,
  column_key,
  column_name,
  position
FROM kanban_column;

-- ============================================================================
-- Step 3: kanban_card 테이블의 FK 업데이트 (임시)
-- ============================================================================

-- 먼저 kanban_card에서 FK 제약조건 제거
ALTER TABLE kanban_card
DROP CONSTRAINT IF EXISTS kanban_card_column_id_fkey;

-- kanban_card에 새 TEXT 컬럼을 만들고 기존 numeric column_id를 column_key로 매핑
ALTER TABLE kanban_card
ADD COLUMN column_id_new TEXT;

UPDATE kanban_card kc
SET column_id_new = c.column_key
FROM kanban_column c
WHERE kc.column_id = c.column_id;

ALTER TABLE kanban_card
DROP COLUMN column_id;

ALTER TABLE kanban_card
RENAME COLUMN column_id_new TO column_id;

ALTER TABLE kanban_card
ALTER COLUMN column_id SET NOT NULL;

-- 새로운 FK 제약조건 추가
ALTER TABLE kanban_card
ADD CONSTRAINT kanban_card_column_id_fkey
FOREIGN KEY (column_id) REFERENCES kanban_column_new(column_id) ON DELETE RESTRICT;

-- ============================================================================
-- Step 4: 기존 테이블 제거 및 새 테이블 이름 변경
-- ============================================================================

DROP TABLE kanban_column;

ALTER TABLE kanban_column_new
RENAME TO kanban_column;

-- ============================================================================
-- Step 5: 테이블 및 컬럼 주석 업데이트
-- ============================================================================

COMMENT ON COLUMN kanban_column.column_id IS 'PK (TEXT) - 열의 문자 기반 ID (예: preparation, cooking_in_progress, ready_to_serve, completed)';
COMMENT ON COLUMN kanban_column.board_id IS 'FK → kanban_board.board_id (ON DELETE CASCADE) - 소속 보드';
COMMENT ON COLUMN kanban_column.column_key IS 'UNIQUE (board_id, column_key) - 열의 英文 키 (현재 column_id와 동일)';
COMMENT ON COLUMN kanban_column.column_name IS '열의 한글 표시 이름 (예: 재료 손질 및 준비)';
COMMENT ON COLUMN kanban_column.position IS 'UNIQUE (board_id, position) - 열의 보드 상 위치 (좌→우 순서)';

COMMENT ON COLUMN kanban_card.column_id IS 'FK → kanban_column.column_id (ON DELETE RESTRICT) - 현재 상태 열 ID (TEXT 형식)';

-- ============================================================================
-- Step 6: 데이터 검증
-- ============================================================================

-- 샘플 데이터 확인
SELECT 
  c.column_id,
  c.column_name,
  c.position,
  COUNT(k.card_id) as card_count
FROM kanban_column c
LEFT JOIN kanban_card k ON c.column_id = k.column_id
GROUP BY c.column_id, c.column_name, c.position
ORDER BY c.position;

-- ============================================================================
-- 변경 요약
-- ============================================================================
--
-- kanban_column 테이블 변경:
--   column_id: BIGINT(1,2,3,4) → TEXT('preparation', 'cooking_in_progress', 'ready_to_serve', 'completed')
--   
-- kanban_card 테이블 변경:
--   column_id FK: BIGINT → TEXT (kanban_column.column_key 기준으로 매핑)
--
-- 의미있는 텍스트 키:
--   'preparation'         → 재료 손질 및 준비
--   'cooking_in_progress' → 조리 진행 중
--   'ready_to_serve'      → 담기 준비 완료
--   'completed'           → 완료
--
-- ============================================================================
