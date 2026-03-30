-- Migration 014: 팀원 이름 변경 (You → 김정환)

UPDATE team_member 
SET member_name = '김정환'
WHERE member_id = 1 AND board_id = 1;
