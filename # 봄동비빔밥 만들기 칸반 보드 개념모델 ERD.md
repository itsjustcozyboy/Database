# 봄동비빔밥 만들기 칸반 보드 개념모델 ERD

## 1. 개념모델 설명
우리 팀은 **봄동비빔밥 만들기**를 하나의 프로젝트 보드로 보고,  
그 안에서 작업 진행 상태를 관리하는 칸반 보드 서비스 구조를 설계했다.

이때 중심은 요리 레시피 자체가 아니라,  
**작업을 상태별로 나누어 관리하는 구조**에 있다.

따라서 핵심 엔티티를 다음과 같이 정의했다.

- **Board**: 전체 작업 보드
- **Column**: 작업 상태 구분
- **Card**: 실제 작업 단위
- **Member**: 작업 담당자

이 구조를 통해 하나의 보드 안에서 여러 작업이 상태별로 이동하고,  
각 작업에 담당자를 배정할 수 있도록 개념모델을 구성했다.

---

## 2. 엔티티와 관계

### 엔티티
- Board
- Column
- Card
- Member

### 관계
- **Board 1:N Column**
- **Column 1:N Card**
- **Member N:M Card**

---

## 3. 엔티티별 속성

### Board
- board_id
- board_name

### Column
- column_id
- column_name
- order

### Card
- card_id
- card_title
- description
- due_date

### Member
- member_id
- member_name

---

## 4. 엔티티 설명 표

| 엔티티 | 의미 | 예시 |
|--------|------|------|
| Board | 하나의 작업 보드 | 봄동비빔밥 만들기 |
| Column | 작업 상태 구분 | To Do, In Progress, Ready to Assemble, Done |
| Card | 실제 해야 할 작업 | 봄동 씻기, 밥 준비하기, 계란 프라이하기 |
| Member | 작업 담당자 | 나, 팀원1, 팀원2 |

---

## 5. 예시 카드
- 냉장고 재료 확인하기
- 봄동 씻기
- 봄동 썰기
- 밥 준비하기
- 계란 프라이하기
- 버섯 볶기
- 고추장 넣기
- 참기름 넣기
- 비벼서 먹기

---

## 6. 발표용 설명
우리 팀은 "봄동비빔밥 만들기"를 하나의 프로젝트 보드로 정의하고,  
그 안에서 작업 진행 상태를 관리하기 위해 Board, Column, Card를 핵심 엔티티로 설정했다.  
Board는 전체 작업판, Column은 작업 상태 구분, Card는 실제 작업 단위를 의미한다.  
또한 협업 상황을 표현하기 위해 Member 엔티티를 추가했고, Member와 Card는 다대다 관계로 보았다.

---

## 7. Mermaid ERD

```mermaid
erDiagram
    BOARD ||--o{ COLUMN : has
    COLUMN ||--o{ CARD : contains
    MEMBER }o--o{ CARD : assigned_to

    BOARD {
        int board_id
        string board_name
    }

    COLUMN {
        int column_id
        string column_name
        int order
    }

    CARD {
        int card_id
        string card_title
        string description
        date due_date
    }

    MEMBER {
        int member_id
        string member_name
    }