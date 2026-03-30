-- ============================================================================
-- 마이그레이션: 기존 모든 데이터 삭제 및 완전한 개념모델 스키마 재구성
-- ============================================================================
-- 목적:
-- 1. 기존 모든 테이블/데이터 삭제
-- 2. 개념모델 기반 완전한 스키마 생성 (Board, Column, Card, Member 포함)
-- 3. 봄동비빔밥 칸반보드 데이터 초기화

-- ============================================================================
-- Step 1: 기존 테이블 모두 삭제
-- ============================================================================

DROP TABLE IF EXISTS kanban_card CASCADE;
DROP TABLE IF EXISTS kanban_column CASCADE;
DROP TABLE IF EXISTS kanban_board CASCADE;
DROP TABLE IF EXISTS kanban_member CASCADE;
DROP TABLE IF EXISTS kanban_card_member CASCADE;

-- ============================================================================
-- Step 2: 새로운 테이블 생성
-- ============================================================================

-- 2.1 kanban_board 테이블
CREATE TABLE kanban_board (
  board_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  board_name TEXT NOT NULL,
  description TEXT,
  source_url TEXT UNIQUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE kanban_board IS '칸반 보드 기본 정보';
COMMENT ON COLUMN kanban_board.board_id IS 'PK - 칸반 보드 고유 ID (자동증가)';
COMMENT ON COLUMN kanban_board.board_name IS '칸반 보드 이름 (예: 봄동비빔밥 만들기)';
COMMENT ON COLUMN kanban_board.description IS '칸반 보드 설명';
COMMENT ON COLUMN kanban_board.source_url IS 'UNIQUE - 원본 보드 URL (예: GitHub Projects URL)';
COMMENT ON COLUMN kanban_board.created_at IS '보드 생성 시간';

-- 2.2 kanban_column 테이블
CREATE TABLE kanban_column (
  column_id TEXT PRIMARY KEY,
  board_id BIGINT NOT NULL REFERENCES kanban_board(board_id) ON DELETE CASCADE,
  column_name TEXT NOT NULL,
  order_position INT NOT NULL,
  UNIQUE(board_id, column_id),
  UNIQUE(board_id, order_position)
);

COMMENT ON TABLE kanban_column IS '칸반 보드의 상태 열 정의';
COMMENT ON COLUMN kanban_column.column_id IS 'PK - 열의 영문 키 (예: preparation, cooking_in_progress)';
COMMENT ON COLUMN kanban_column.board_id IS 'FK → kanban_board.board_id (ON DELETE CASCADE)';
COMMENT ON COLUMN kanban_column.column_name IS '열의 한글 표시 이름 (예: 재료 손질 및 준비)';
COMMENT ON COLUMN kanban_column.order_position IS 'UNIQUE - 보드상의 좌→우 위치';

-- 2.3 kanban_member 테이블
CREATE TABLE kanban_member (
  member_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  board_id BIGINT NOT NULL REFERENCES kanban_board(board_id) ON DELETE CASCADE,
  member_name TEXT NOT NULL,
  role TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE kanban_member IS '칸반 보드의 팀 멤버/담당자';
COMMENT ON COLUMN kanban_member.member_id IS 'PK - 멤버 고유 ID (자동증가)';
COMMENT ON COLUMN kanban_member.board_id IS 'FK → kanban_board.board_id (ON DELETE CASCADE)';
COMMENT ON COLUMN kanban_member.member_name IS '멤버 이름';
COMMENT ON COLUMN kanban_member.role IS '멤버 역할 (예: Chef, Assistant)';
COMMENT ON COLUMN kanban_member.created_at IS '멤버 추가 시간';

-- 2.4 kanban_card 테이블
CREATE TABLE kanban_card (
  card_id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  board_id BIGINT NOT NULL REFERENCES kanban_board(board_id) ON DELETE CASCADE,
  column_id TEXT NOT NULL REFERENCES kanban_column(column_id) ON DELETE RESTRICT,
  title TEXT NOT NULL,
  description TEXT,
  due_date DATE,
  order_position INT NOT NULL,
  is_done BOOLEAN NOT NULL DEFAULT FALSE,
  github_issue_number INT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(board_id, title)
);

COMMENT ON TABLE kanban_card IS '칸반 보드의 개별 카드(작업) 정보';
COMMENT ON COLUMN kanban_card.card_id IS 'PK - 카드 고유 ID (자동증가)';
COMMENT ON COLUMN kanban_card.board_id IS 'FK → kanban_board.board_id (ON DELETE CASCADE)';
COMMENT ON COLUMN kanban_card.column_id IS 'FK → kanban_column.column_id (ON DELETE RESTRICT)';
COMMENT ON COLUMN kanban_card.title IS 'UNIQUE (board_id, title) - 카드 제목';
COMMENT ON COLUMN kanban_card.description IS '카드 상세 설명';
COMMENT ON COLUMN kanban_card.due_date IS '작업 마감일';
COMMENT ON COLUMN kanban_card.order_position IS '해당 열 내에서의 카드 위치 (상→하)';
COMMENT ON COLUMN kanban_card.is_done IS '완료 여부';
COMMENT ON COLUMN kanban_card.github_issue_number IS 'GitHub 이슈 번호 (선택사항)';
COMMENT ON COLUMN kanban_card.created_at IS '카드 생성 시간';

-- 2.5 kanban_card_member 테이블 (N:M 관계)
CREATE TABLE kanban_card_member (
  card_id BIGINT NOT NULL REFERENCES kanban_card(card_id) ON DELETE CASCADE,
  member_id BIGINT NOT NULL REFERENCES kanban_member(member_id) ON DELETE CASCADE,
  assigned_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (card_id, member_id)
);

COMMENT ON TABLE kanban_card_member IS '카드와 담당자의 N:M 관계 (다대다)';
COMMENT ON COLUMN kanban_card_member.card_id IS 'FK → kanban_card.card_id';
COMMENT ON COLUMN kanban_card_member.member_id IS 'FK → kanban_member.member_id';
COMMENT ON COLUMN kanban_card_member.assigned_at IS '담당자 지정 시간';

-- ============================================================================
-- Step 3: 샘플 데이터 생성
-- ============================================================================

-- 3.1 Board 생성
INSERT INTO kanban_board (board_name, description, source_url)
VALUES (
  '봄동비빔밥 만들기',
  '봄동비빔밥 조리 과정을 칸반으로 관리하는 프로젝트 보드 (개념모델 ERD 기반)',
  'https://github.com/users/itsjustcozyboy/projects/2'
);

-- 3.2 Columns 생성
INSERT INTO kanban_column (column_id, board_id, column_name, order_position)
VALUES
  ('preparation', 1, '재료 손질 및 준비', 1),
  ('cooking_in_progress', 1, '조리 진행 중', 2),
  ('ready_to_serve', 1, '담기 준비 완료', 3),
  ('completed', 1, '완료', 4);

-- 3.3 Members 생성
INSERT INTO kanban_member (board_id, member_name, role)
VALUES
  (1, '나', 'Chef'),
  (1, '팀원1', 'Assistant'),
  (1, '팀원2', 'Assistant');

-- 3.4 Cards 생성 (Preparation)
INSERT INTO kanban_card (board_id, column_id, title, description, due_date, order_position, is_done, github_issue_number)
VALUES
  (1, 'preparation', '봄동 씻기', '흐르는 물에 봄동을 세척한다', '2026-04-05', 1, FALSE, 28),
  (1, 'preparation', '봄동 썰기', '먹기 좋은 크기로 자른다', '2026-04-05', 2, FALSE, 29),
  (1, 'preparation', '고추장/참기름/깨 준비', '양념 재료를 미리 꺼내 놓는다', '2026-04-05', 3, FALSE, 30),
  (1, 'preparation', '그릇/수저 세팅', '먹기 전 식기 세팅을 완료한다', '2026-04-05', 4, FALSE, 31);

-- 3.5 Cards 생성 (Cooking)
INSERT INTO kanban_card (board_id, column_id, title, description, due_date, order_position, is_done, github_issue_number)
VALUES
  (1, 'cooking_in_progress', '버섯 볶기', '기름을 두르고 버섯을 볶는다', '2026-04-05', 1, FALSE, 32),
  (1, 'cooking_in_progress', '콩나물 데치기', '콩나물을 짧게 데쳐 식감을 맞춘다', '2026-04-05', 2, FALSE, 33),
  (1, 'cooking_in_progress', '계란 프라이', '반숙 또는 완숙으로 조리한다', '2026-04-05', 3, FALSE, 34),
  (1, 'cooking_in_progress', '밥 데우기', '따뜻한 상태로 준비한다', '2026-04-05', 4, FALSE, 35);

-- 3.6 Cards 생성 (Ready to Serve)
INSERT INTO kanban_card (board_id, column_id, title, description, due_date, order_position, is_done, github_issue_number)
VALUES
  (1, 'ready_to_serve', '밥 1공기 준비됨', '그릇에 밥을 담아 둔다', '2026-04-05', 1, FALSE, 36),
  (1, 'ready_to_serve', '당근 채썰기 완료', '고명용 당근 준비 완료 상태', '2026-04-05', 2, FALSE, 37),
  (1, 'ready_to_serve', '고명 배치 순서 점검', '봄동-나물-버섯-계란 순서 점검', '2026-04-05', 3, FALSE, 38),
  (1, 'ready_to_serve', '비벼 먹기 직전 상태', '양념만 넣으면 바로 식사 가능', '2026-04-05', 4, FALSE, 39);

-- 3.7 Cards 생성 (Completed)
INSERT INTO kanban_card (board_id, column_id, title, description, due_date, order_position, is_done, github_issue_number)
VALUES
  (1, 'completed', '냉장고 재료 확인 완료', '재료 보유 여부 점검 완료', '2026-04-05', 1, TRUE, 40),
  (1, 'completed', '봄동 손질 완료', '씻기/썰기 마무리 상태', '2026-04-05', 2, TRUE, 41),
  (1, 'completed', '기본 플레이팅 완료', '주요 고명 배치 완료 상태', '2026-04-05', 3, TRUE, 42),
  (1, 'completed', '다음 개선 포인트 기록', '다음 조리 때 개선점을 남김', '2026-04-05', 4, TRUE, 43);

-- 3.8 Card-Member 관계 생성 (모든 카드를 '나'에 지정, 조리는 팀원1, 담기는 팀원2)
INSERT INTO kanban_card_member (card_id, member_id)
SELECT card_id, 1 FROM kanban_card WHERE board_id = 1;

-- 조리 담당 (팀원1)
INSERT INTO kanban_card_member (card_id, member_id)
SELECT card_id, 2 FROM kanban_card 
WHERE board_id = 1 AND column_id = 'cooking_in_progress';

-- 담기 담당 (팀원2)
INSERT INTO kanban_card_member (card_id, member_id)
SELECT card_id, 3 FROM kanban_card 
WHERE board_id = 1 AND column_id = 'ready_to_serve';

-- ============================================================================
-- Step 4: PK/FK 관계도 및 검증 쿼리
-- ============================================================================
-- 
-- 관계도:
-- kanban_board (1) ──┬→ kanban_column (N)
--                   ├→ kanban_member (N)
--                   └→ kanban_card (N)
--                         │
--                         └→ kanban_card_member (M) ←→ kanban_member
--
-- ============================================================================

-- 검증 쿼리 (마이그레이션 적용 후 실행 가능)
-- SELECT * FROM kanban_board;
-- SELECT * FROM kanban_column WHERE board_id = 1 ORDER BY order_position;
-- SELECT * FROM kanban_card WHERE board_id = 1 ORDER BY column_id, order_position;
-- SELECT * FROM kanban_member WHERE board_id = 1;
-- SELECT k.card_id, k.title, m.member_name FROM kanban_card_member cm
--   JOIN kanban_card k ON cm.card_id = k.card_id
--   JOIN kanban_member m ON cm.member_id = m.member_id
--   ORDER BY cm.card_id;
