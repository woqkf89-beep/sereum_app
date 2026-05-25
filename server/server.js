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

app.post('/ai-chat', async (req, res) => {
  try {
    const message = req.body.message || '';
    if (!message) return res.status(400).json({ error: 'message is required' });

    const completion = await openai.chat.completions.create({
      model: 'gpt-4o-mini',
      messages: [
        { role: 'system', content: '너는 한국어 심리상담형 운세 상담사다. 따뜻하고 현실적으로 길게 답해라.' },
        { role: 'user', content: message },
      ],
    });

    res.json({ reply: completion.choices[0].message.content });
  } catch (e) {
    res.status(500).json({ error: 'AI chat error', detail: e.message });
  }
});

app.post('/ai-fortune', async (req, res) => {
  try {
    const { topic, userInfo, partnerInfo, relationshipInfo } = req.body;

    const completion = await openai.chat.completions.create({
      model: 'gpt-4o-mini',
      temperature: 0.85,
      max_tokens: 1800,
      messages: [
        {
          role: 'system',
          content: `
너는 한국어 프리미엄 사주/운세 앱의 전문 상담 AI다.
답변은 절대 짧게 하지 마라.
최소 1800자 이상으로 작성해라.
사용자가 입력한 이름, 생년월일, 음력/양력, 태어난 시간, 성별을 반드시 반영해라.
정보가 부족하면 부족하다고 말하되, 입력된 정보 기준으로 최대한 해석해라.
사주, 연애운, 재물운, 직업운, 신년운세, 궁합, 재회운 주제에 맞게 완전히 다르게 답해라.
구성:
1. 전체 기운
2. 성향 분석
3. 현재 흐름
4. 주제별 핵심 운세
5. 조심해야 할 점
6. 앞으로의 조언
7. 핵심 결론
의료, 법률, 투자 확정 표현은 피하고 현실 조언으로 말해라.
`
        },
        {
          role: 'user',
          content: JSON.stringify({ topic, userInfo, partnerInfo, relationshipInfo }),
        },
      ],
    });

    res.json({ reply: completion.choices[0].message.content });
  } catch (e) {
    res.status(500).json({ error: 'AI fortune error', detail: e.message });
  }
});

app.listen(port, () => {
  console.log(`sereum_app_server running on port ${port}`);
});
