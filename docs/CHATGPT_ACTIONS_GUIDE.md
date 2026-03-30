# ChatGPT GPT Actions 설정 가이드

이 가이드는 ChatGPT의 커스텀 GPT에서 Supabase 자동 입력을 설정하는 방법을 설명합니다.

## 전체 흐름

```
ChatGPT GPT UI (자연어 입력)
           ↓
     GPT가 사용자 입력 클릭
           ↓
    Actions 호출 (/ingest POST)
           ↓
    공개 URL을 통해 로컬 서버로 전송
           ↓
  localhost:8787/ingest 수신
           ↓
    ChatGPT API로 자연어 해석
           ↓
  Supabase에 INSERT/UPSERT
           ↓
    결과 JSON 반환
           ↓
  GPT가 사용자에게 결과 표시
```

## 단계별 설정

### 1단계: 로컬 서버 시작

```bash
npm run chatgpt:server
# 서버 시작: http://localhost:8787
```

### 2단계: ngrok으로 공개 URL 생성

터미널 2에서:

```bash
ngrok http 8787
# 출력 예:
# Forwarding    https://1234-56-78-910-111.ngrok.io -> http://localhost:8787
```

**공개 URL 복사:** `https://1234-56-78-910-111.ngrok.io`

### 3단계: ChatGPT GPT 설정

1. https://chatgpt.com/gpts 접속
2. "Create a GPT" 또는 기존 GPT 편집
3. **Configure** 탭 클릭
4. **Actions** (하단) 클릭
5. **"+ Create new action"** 클릭

### 4단계: Action 설정

**Schema section:**

```json
{
  "openapi": "3.0.0",
  "info": {
    "title": "Supabase Auto-Ingest",
    "version": "1.0.0"
  },
  "servers": [
    {
      "url": "https://1234-56-78-910-111.ngrok.io"
    }
  ],
  "paths": {
    "/ingest": {
      "post": {
        "operationId": "ingestData",
        "summary": "자연어로 Supabase에 데이터 추가",
        "requestBody": {
          "required": true,
          "content": {
            "application/json": {
              "schema": {
                "type": "object",
                "properties": {
                  "text": {
                    "type": "string",
                    "description": "추가할 작업에 대한 자연어 (예: '조리 단계에 두부 굽기 추가')"
                  },
                  "board_id": {
                    "type": "integer",
                    "default": 1
                  },
                  "dry_run": {
                    "type": "boolean",
                    "default": false
                  }
                },
                "required": ["text"]
              }
            }
          }
        },
        "responses": {
          "200": {
            "description": "성공"
          }
        }
      }
    }
  }
}
```

### 5단계: GPT 메인 프롬프트 수정

GPT의 시스템 프롬프트에 추가:

```
사용자가 "추가해줘", "카드 만들어", "할당해줘" 같은 요청을 하면:
1. 그 요청을 자연어로 정리 (예: "조리 단계에 두부 굽기 추가하고 김소윤에게 할당")
2. ingestData Action 호출
3. 결과를 사용자 친화적으로 설명

현재 보드 구조:
- 단계: preparation, cooking_in_progress, ready_to_serve, completed
- 멤버: 김정환, 김소윤, 김채우
```

### 6단계: 테스트

GPT에서 입력:

```
조리 단계에 두부 굽기 작업 추가해줘
```

결과:
- ✅ Action 호출
- ✅ Supabase recipe_task에 행 추가
- ✅ GPT가 사용자에게 결과 반환

## ⚠️ 중요 사항

### 보안
- ngrok URL은 임시입니다. 서버 재시작 시 URL 변경됨
- 프로덕션에서는 고정 URL 사용 권장

### 영구 설정 (프로덕션)
1. Supabase Edge Functions 사용 (더 안전)
2. 또는 AWS/Vercel에 배포

### ngrok 토큰 설정 (권장)
```bash
ngrok config add-authtoken YOUR_NGROK_TOKEN
```

## 자연어 예시

GPT에서 아래 명령어들을 시도해보세요:

- "준비 단계에 봄동 씻기 추가"
- "조리 단계에 버섯 볶기 추가하고 김소윤에게 할당" 
- "담기 단계에 플레이팅 체크 카드 만들어. 마감은 내일"
- "김채우를 팀에 추가해줘"
- "버섯 볶기 작업을 김정환에게 할당"

## 트러블슈팅

### ngrok 연결 끊김
```bash
# 다시 시작
ngrok http 8787
# 새 URL로 GPT Action 업데이트
```

### Action 호출 안 됨
1. 색깔: Actions이 활성화되었는지 확인
2. OpenAPI 스키마 JSON 문법 확인
3. 서버가 실행 중인지 확인: `curl http://localhost:8787/health`

### Supabase 오류
`.env.local`의 키 확인:
```bash
cat .env.local | grep SUPABASE
```

## 다음 단계

- [ ] 프로덕션 배포 (Vercel/fly.io)
- [ ] 고정 도메인 사용
- [ ] Webhook 로깅 추가
- [ ] 사용자 인증 추가
