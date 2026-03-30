-- Keep only the latest linked Bomdong Bibimbap kanban data
-- and remove all previously created non-kanban datasets.

-- 1) Keep only the target kanban board data
WITH target AS (
  SELECT board_id
  FROM kanban_board
  WHERE source_url = 'https://github.com/users/itsjustcozyboy/projects/2'
)
DELETE FROM kanban_card
WHERE board_id NOT IN (SELECT board_id FROM target);

WITH target AS (
  SELECT board_id
  FROM kanban_board
  WHERE source_url = 'https://github.com/users/itsjustcozyboy/projects/2'
)
DELETE FROM kanban_column
WHERE board_id NOT IN (SELECT board_id FROM target);

DELETE FROM kanban_board
WHERE source_url <> 'https://github.com/users/itsjustcozyboy/projects/2';

-- 2) Remove previous schema/data tables that are unrelated
DROP TABLE IF EXISTS enrollment CASCADE;
DROP TABLE IF EXISTS student CASCADE;
DROP TABLE IF EXISTS course CASCADE;
DROP TABLE IF EXISTS department CASCADE;
DROP TABLE IF EXISTS test CASCADE;
