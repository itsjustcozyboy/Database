-- Migration 012: 팀원 이름 업데이트 및 작업 할당량 재배분

-- 1. 팀원 이름 업데이트
UPDATE team_member 
SET member_name = '김소윤', role = 'Chef / 조리 담당' 
WHERE member_id = 2 AND board_id = 1;

UPDATE team_member 
SET member_name = '김채우', role = 'Chef / 담기 담당' 
WHERE member_id = 3 AND board_id = 1;

UPDATE team_member
SET member_name = 'You', role = 'Lead Chef / 총괄'
WHERE member_id = 1 AND board_id = 1;

-- 2. 기존 할당 초기화 (선택사항 - 새로운 할당을 더하려면 이 부분 주석처리)
DELETE FROM task_assignment 
WHERE task_id IN (SELECT card_id FROM recipe_task WHERE board_id = 1);

-- 3. 새로운 할당 배분
-- 준비 단계 (4개): You가 담당
INSERT INTO task_assignment (task_id, member_id, assigned_at)
SELECT card_id, 1, NOW() 
FROM recipe_task 
WHERE board_id = 1 AND step_id = 'preparation'
ORDER BY order_position;

-- 조리 단계 (4개): 김소윤이 담당, You도 1개 추가
INSERT INTO task_assignment (task_id, member_id, assigned_at)
SELECT card_id, 2, NOW() 
FROM recipe_task 
WHERE board_id = 1 AND step_id = 'cooking_in_progress'
ORDER BY order_position;

INSERT INTO task_assignment (task_id, member_id, assigned_at)
SELECT card_id, 1, NOW() 
FROM recipe_task 
WHERE board_id = 1 AND step_id = 'cooking_in_progress'
LIMIT 1;

-- 담기 준비 단계 (4개): 김채우가 담당, You도 1개 추가
INSERT INTO task_assignment (task_id, member_id, assigned_at)
SELECT card_id, 3, NOW() 
FROM recipe_task 
WHERE board_id = 1 AND step_id = 'ready_to_serve'
ORDER BY order_position;

INSERT INTO task_assignment (task_id, member_id, assigned_at)
SELECT card_id, 1, NOW() 
FROM recipe_task 
WHERE board_id = 1 AND step_id = 'ready_to_serve'
LIMIT 1;

-- 완료 단계 (4개): You가 담당
INSERT INTO task_assignment (task_id, member_id, assigned_at)
SELECT card_id, 1, NOW() 
FROM recipe_task 
WHERE board_id = 1 AND step_id = 'completed'
ORDER BY order_position;

-- 4. 최종 할당 현황 확인 쿼리
-- SELECT 
--   m.member_name,
--   m.role,
--   s.column_name as step,
--   COUNT(ta.task_id) as task_count
-- FROM team_member m
-- LEFT JOIN task_assignment ta ON m.member_id = ta.member_id
-- LEFT JOIN recipe_task t ON ta.task_id = t.card_id
-- LEFT JOIN recipe_step s ON t.step_id = s.column_id
-- WHERE m.board_id = 1
-- GROUP BY m.member_id, m.member_name, m.role, s.column_id, s.column_name
-- ORDER BY m.member_id, s.order_position;
