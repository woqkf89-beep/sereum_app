const express = require('express');
const cors = require('cors');
const OpenAI = require('openai');

const app = express();
const port = process.env.PORT || 3000;

app.use(cors());
app.use(express.json({ limit: '1mb' }));

const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

app.get('/health', (req, res) => {
  res.json({ ok: true, service: 'sereum_app_server' });
});

function topicPrompt(topic) {
  const prompts = {
    '사주': `
오직 정통 사주 풀이만 작성해라.
연애운, 재물운, 직업운, 신년운세, 재회운을 메뉴처럼 섞지 마라.
반드시 포함:
1. 사주 핵심 요약
2. 오행 분석: 목/화/토/금/수 강약
3. 강한 기운과 부족한 기운
4. 일간 성향처럼 보이는 타고난 기질
5. 성격, 고집, 판단력, 감정 패턴
6. 인간관계 스타일
7. 인생 흐름과 현재 기운
8. 조심해야 할 점
9. 현실 조언
최소 2500자 이상.
`,
    '연애운': `
오직 연애운만 작성해라.
반드시 포함:
어떤 사람을 만날 가능성이 높은지, 상대 성향, 만남 경로, 끌리는 타입, 피해야 할 타입, 연애 스타일, 가까운 연애 흐름, 조심할 말과 행동.
최소 2200자 이상.
`,
    '재물운': `
오직 재물운만 작성해라.
돈 버는 방식, 돈 새는 패턴, 소비 습관, 부업 가능성, 장사/직장 수입 흐름, 모으는 방법, 조심할 돈 문제.
최소 2200자 이상.
`,
    '직업운': `
오직 직업운만 작성해라.
맞는 일, 안 맞는 일, 조직생활, 이직운, 성장 방향, 직장 내 평가, 장기 커리어 전략.
최소 2200자 이상.
`,
    '신년운세': `
오직 신년운세만 작성해라.
올해 전체 흐름, 상반기/하반기 흐름, 월별 포인트, 사람운, 돈운, 일운, 조심할 시기.
최소 2200자 이상.
`,
    '궁합': `
오직 두 사람 궁합만 작성해라.
성향 차이, 끌림, 충돌 포인트, 대화 방식, 장기궁합, 결혼/동거 궁합, 관계 유지 조언.
최소 2200자 이상.
`,
    '재회운': `
오직 재회운만 작성해라.
상대 심리, 재회 가능성, 연락 타이밍, 하면 안 되는 행동, 다시 만날 때 조건, 현실 조언.
최소 2200자 이상.
`
  };
  return prompts[topic] || prompts['사주'];
}

app.post('/ai-fortune', async (req, res) => {
  try {
    const { topic, userInfo, partnerInfo, relationshipInfo } = req.body;

    const completion = await openai.chat.completions.create({
      model: 'gpt-4o-mini',
      temperature: 0.85,
      max_tokens: 3000,
      messages: [
        {
          role: 'system',
          content: `
너는 한국어 프리미엄 사주/운세 앱의 전문 상담 AI다.
사용자가 선택한 topic에 맞는 내용만 작성해라.
흔한 짧은 운세 문구 금지.
입력된 이름, 성별, 생년월일, 음력/양력, 태어난 시간을 반드시 반영해라.
사실처럼 확정하지 말고 "경향", "가능성", "흐름"으로 말해라.
의료/법률/투자 확정 조언 금지.
${topicPrompt(topic)}
`
        },
        {
          role: 'user',
          content: JSON.stringify({ topic, userInfo, partnerInfo, relationshipInfo })
        }
      ]
    });

    res.json({ reply: completion.choices[0].message.content });
  } catch (e) {
    res.status(500).json({ error: 'AI fortune error', detail: e.message });
  }
});

app.post('/ai-chat', async (req, res) => {
  try {
    const message = req.body.message || '';
    if (!message) return res.status(400).json({ error: 'message is required' });

    const completion = await openai.chat.completions.create({
      model: 'gpt-4o-mini',
      temperature: 0.8,
      max_tokens: 1500,
      messages: [
        { role: 'system', content: '너는 한국어 심리상담 AI다. 따뜻하고 현실적으로 상담하라.' },
        { role: 'user', content: message }
      ]
    });

    res.json({ reply: completion.choices[0].message.content });
  } catch (e) {
    res.status(500).json({ error: 'AI chat error', detail: e.message });
  }
});

app.listen(port, () => console.log(`sereum_app_server running on port ${port}`));
