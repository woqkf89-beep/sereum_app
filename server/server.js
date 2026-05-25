const express = require('express');
const cors = require('cors');
const OpenAI = require('openai');

const app = express();
const port = process.env.PORT || 3000;

app.use(cors());
app.use(express.json({ limit: '1mb' }));

const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

app.get('/health', (req, res) => res.json({ ok: true, service: 'sereum_app_server' }));

app.post('/ai-chat', async (req, res) => {
  try {
    const message = req.body.message || '';
    if (!message) return res.status(400).json({ error: 'message is required' });

    const completion = await openai.chat.completions.create({
      model: 'gpt-4o-mini',
      temperature: 0.8,
      max_tokens: 1200,
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

app.post('/ai-fortune', async (req, res) => {
  try {
    const { topic, userInfo, partnerInfo, relationshipInfo } = req.body;

    const topicPrompt = {
      '사주': '사주는 연애운, 재물운, 직업운, 신년운세를 섞지 마라. 오직 타고난 기질, 성격, 강점, 약점, 인생 흐름, 현재 기운만 1800자 이상 분석해라.',
      '연애운': '연애운만 봐라. 어떤 사람을 만날 가능성이 높은지, 상대 성향, 만남 경로, 끌리는 타입, 피해야 할 타입, 가까운 연애 흐름을 1800자 이상 분석해라.',
      '재물운': '재물운만 봐라. 돈 버는 방식, 돈 새는 패턴, 소비 습관, 부업 가능성, 장사/직장 수입 흐름, 모으는 방법을 1800자 이상 분석해라.',
      '직업운': '직업운만 봐라. 맞는 일, 안 맞는 일, 조직생활, 이직운, 성장 방향, 직장 내 평가를 1800자 이상 분석해라.',
      '신년운세': '올해 운세만 봐라. 월별 흐름, 인간관계, 돈, 일, 조심할 시기를 1800자 이상 분석해라.',
      '궁합': '두 사람 궁합만 봐라. 성향 차이, 끌림, 충돌 포인트, 장기궁합, 결혼/동거 궁합을 1800자 이상 분석해라.',
      '재회운': '재회운만 봐라. 상대 심리, 재회 가능성, 연락 타이밍, 하면 안 되는 행동, 현실 조언을 1800자 이상 분석해라.'
    }[topic] || '주제에 맞게 1800자 이상 분석해라.';

    const completion = await openai.chat.completions.create({
      model: 'gpt-4o-mini',
      temperature: 0.85,
      max_tokens: 2200,
      messages: [
        {
          role: 'system',
          content: `너는 한국어 프리미엄 사주/운세 상담 AI다. 반드시 사용자가 선택한 주제만 답해라. 다른 운세 항목을 섞지 마라. ${topicPrompt}`
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

app.listen(port, () => console.log(`sereum_app_server running on port ${port}`));
