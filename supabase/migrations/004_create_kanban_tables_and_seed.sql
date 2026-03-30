-- Kanban board schema and seed data based on
-- https://github.com/users/itsjustcozyboy/projects/2

CREATE TABLE IF NOT EXISTS kanban_board (
  board_id BIGSERIAL PRIMARY KEY,
  board_name TEXT NOT NULL,
  source_url TEXT UNIQUE,
  description TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS kanban_column (
  column_id BIGSERIAL PRIMARY KEY,
  board_id BIGINT NOT NULL REFERENCES kanban_board(board_id) ON DELETE CASCADE,
  column_key TEXT NOT NULL,
  column_name TEXT NOT NULL,
  position INT NOT NULL,
  UNIQUE(board_id, column_key),
  UNIQUE(board_id, position)
);

CREATE TABLE IF NOT EXISTS kanban_card (
  card_id BIGSERIAL PRIMARY KEY,
  board_id BIGINT NOT NULL REFERENCES kanban_board(board_id) ON DELETE CASCADE,
  column_id BIGINT NOT NULL REFERENCES kanban_column(column_id) ON DELETE RESTRICT,
  title TEXT NOT NULL,
  detail TEXT,
  github_issue_number INT,
  is_done BOOLEAN NOT NULL DEFAULT FALSE,
  position INT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(board_id, title)
);

WITH upsert_board AS (
  INSERT INTO kanban_board (board_name, source_url, description)
  VALUES (
    '봄동비빔밥 먹기',
    'https://github.com/users/itsjustcozyboy/projects/2',
    '봄동비빔밥 칸반 보드'
  )
  ON CONFLICT (source_url)
  DO UPDATE SET
    board_name = EXCLUDED.board_name,
    description = EXCLUDED.description
  RETURNING board_id
),
board_ref AS (
  SELECT board_id FROM upsert_board
  UNION ALL
  SELECT board_id FROM kanban_board
  WHERE source_url = 'https://github.com/users/itsjustcozyboy/projects/2'
  LIMIT 1
)
INSERT INTO kanban_column (board_id, column_key, column_name, position)
SELECT b.board_id, v.column_key, v.column_name, v.position
FROM board_ref b
JOIN (
  VALUES
    ('todo', 'To Do', 1),
    ('in-progress', 'In Progress', 2),
    ('ready-to-assemble', 'Ready to Assemble', 3),
    ('done', 'Done', 4)
) AS v(column_key, column_name, position) ON TRUE
ON CONFLICT (board_id, column_key)
DO UPDATE SET
  column_name = EXCLUDED.column_name,
  position = EXCLUDED.position;

WITH board_ref AS (
  SELECT board_id
  FROM kanban_board
  WHERE source_url = 'https://github.com/users/itsjustcozyboy/projects/2'
  LIMIT 1
),
col_map AS (
  SELECT c.column_id, c.column_key, c.board_id
  FROM kanban_column c
  JOIN board_ref b ON b.board_id = c.board_id
),
cards AS (
  SELECT * FROM (
    VALUES
      ('todo', '김가루 꺼내기', '봄동비빔밥 준비 작업', 10, FALSE, 1),
      ('todo', '물 또는 국 준비하기', '봄동비빔밥 준비 작업', 3, FALSE, 2),
      ('todo', '먹기 전 숟가락/젓가락 놓기', '봄동비빔밥 준비 작업', 4, FALSE, 3),
      ('todo', '다음번 추가 재료 메모하기', '봄동비빔밥 준비 작업', 5, FALSE, 4),

      ('in-progress', '버섯 볶기', '봄동비빔밥 진행 중 작업', 6, FALSE, 1),
      ('in-progress', '상 차리기', '봄동비빔밥 진행 중 작업', 7, FALSE, 2),
      ('in-progress', '고추장 양 조절하기', '봄동비빔밥 진행 중 작업', 8, FALSE, 3),

      ('ready-to-assemble', '밥 1공기 준비됨', '조립 직전 준비 완료', 9, FALSE, 1),
      ('ready-to-assemble', '손질한 봄동 준비됨', '조립 직전 준비 완료', 12, FALSE, 2),
      ('ready-to-assemble', '당근, 콩나물 준비됨', '조립 직전 준비 완료', 13, FALSE, 3),
      ('ready-to-assemble', '계란 프라이 준비됨', '조립 직전 준비 완료', 14, FALSE, 4),
      ('ready-to-assemble', '참기름 넣기 직전', '조립 직전 준비 완료', 15, FALSE, 5),
      ('ready-to-assemble', '깨 뿌리기 직전', '조립 직전 준비 완료', 16, FALSE, 6),
      ('ready-to-assemble', '버섯만 올리면 완성', '조립 직전 준비 완료', 17, FALSE, 7),

      ('done', '냉장고 재료 확인 완료', '완료된 작업 카드', 20, TRUE, 1),
      ('done', '봄동 씻기 완료', '완료된 작업 카드', 21, TRUE, 2),
      ('done', '봄동 썰기 완료', '완료된 작업 카드', 22, TRUE, 3),
      ('done', '당근 채썰기 완료', '완료된 작업 카드', 23, TRUE, 4),
      ('done', '콩나물 데치기 완료', '완료된 작업 카드', 24, TRUE, 5),
      ('done', '계란 프라이 완료', '완료된 작업 카드', 25, TRUE, 6),
      ('done', '밥 데우기 완료', '완료된 작업 카드', 26, TRUE, 7),
      ('done', '장보기 없이 진행 결정', '완료된 작업 카드', 27, TRUE, 8)
  ) AS t(column_key, title, detail, github_issue_number, is_done, position)
)
INSERT INTO kanban_card (
  board_id,
  column_id,
  title,
  detail,
  github_issue_number,
  is_done,
  position
)
SELECT
  cm.board_id,
  cm.column_id,
  c.title,
  c.detail,
  c.github_issue_number,
  c.is_done,
  c.position
FROM cards c
JOIN col_map cm ON cm.column_key = c.column_key
ON CONFLICT (board_id, title)
DO UPDATE SET
  column_id = EXCLUDED.column_id,
  detail = EXCLUDED.detail,
  github_issue_number = EXCLUDED.github_issue_number,
  is_done = EXCLUDED.is_done,
  position = EXCLUDED.position;
