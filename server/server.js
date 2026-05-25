require('dotenv').config();

const express = require('express');
const cors = require('cors');
const OpenAI = require('openai');

const app = express();
const port = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

app.get('/health', (req, res) => {
  res.json({ ok: true, service: 'sereum_app_server' });
});

app.post('/ai-chat', async (req, res) => {
  try {
    const message = req.body.message || req.body.text || '';

    if (!message) {
      return res.status(400).json({ error: 'message is required' });
    }

    const completion = await openai.chat.completions.create({
      model: 'gpt-4o-mini',
      messages: [
        {
          role: 'system',
          content: '너는 한국어로 답하는 프리미엄 사주/운세 상담 AI다. 답변은 짧고 신비롭지만 현실적으로 해라.',
        },
        {
          role: 'user',
          content: message,
        },
      ],
    });

    res.json({
      reply: completion.choices[0].message.content,
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({
      error: 'AI server error',
      detail: error.message,
    });
  }
});

app.post('/ai-fortune', async (req, res) => {
  try {
    const input = req.body.input || req.body.inputData || req.body.message || '';

    const completion = await openai.chat.completions.create({
      model: 'gpt-4o-mini',
      messages: [
        {
          role: 'system',
          content: '너는 한국어 사주/운세 앱의 AI 상담사다. 운세 결과를 제목, 총평, 조언, 행운의 색, 행운의 숫자로 구성해라.',
        },
        {
          role: 'user',
          content: input || '오늘의 운세를 알려줘',
        },
      ],
    });

    res.json({
      reply: completion.choices[0].message.content,
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({
      error: 'AI fortune error',
      detail: error.message,
    });
  }
});

app.listen(port, () => {
  console.log(`sereum_app_server running on port ${port}`);
});
