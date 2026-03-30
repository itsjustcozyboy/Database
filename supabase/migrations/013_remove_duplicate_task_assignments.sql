-- Migration 013: 팀원 작업 할당 중복 제거 및 명확한 역할 분담

-- 1. 기존 할당 모두 초기화
DELETE FROM task_assignment 
WHERE task_id IN (SELECT card_id FROM recipe_task WHERE board_id = 1);

-- 2. 새으로운 명확한 배분 (중복 없음)
-- 준비 단계 (4개): You
INSERT INTO task_assignment (task_id, member_id, assigned_at)
SELECT card_id, 1, NOW() 
FROM recipe_task 
WHERE board_id = 1 AND step_id = 'preparation'
ORDER BY order_position;

-- 조리 단계 (4개): 김소윤
INSERT INTO task_assignment (task_id, member_id, assigned_at)
SELECT card_id, 2, NOW() 
FROM recipe_task 
WHERE board_id = 1 AND step_id = 'cooking_in_progress'
ORDER BY order_position;

-- 담기 준비 단계 (4개): 김채우
INSERT INTO task_assignment (task_id, member_id, assigned_at)
SELECT card_id, 3, NOW() 
FROM recipe_task 
WHERE board_id = 1 AND step_id = 'ready_to_serve'
ORDER BY order_position;

-- 완료 단계 (4개): You
INSERT INTO task_assignment (task_id, member_id, assigned_at)
SELECT card_id, 1, NOW() 
FROM recipe_task 
WHERE board_id = 1 AND step_id = 'completed'
ORDER BY order_position;

-- NOTE: 최종 할당
-- You: 4 (준비) + 4 (완료) = 8개
-- 김소윤: 4 (조리) = 4개
-- 김채우: 4 (담기) = 4개
-- 총 16개 (중복 없음)
