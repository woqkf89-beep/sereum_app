require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { Configuration, OpenAIApi } = require('openai');

const app = express();
const port = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

const configuration = new Configuration({
  apiKey: process.env.OPENAI_API_KEY,
});
const openai = new OpenAIApi(configuration);

app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok' });
});

app.post('/ai-fortune', async (req, res) => {
  try {
    const { inputData } = req.body;
    if (!inputData) {
      return res.status(400).json({ error: 'inputData is required' });
    }

    const prompt = `You are a premium fortune teller. Provide a detailed fortune based on the following input:\n${inputData}\n\nFortune:`;

    const completion = await openai.createCompletion({
      model: 'text-davinci-003',
      prompt: prompt,
      max_tokens: 500,
      temperature: 0.8,
    });

    const fortune = completion.data.choices[0].text.trim();
    res.json({ fortune });
  } catch (error) {
    console.error('Error in /ai-fortune:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.post('/ai-chat', async (req, res) => {
  try {
    const { message } = req.body;
    if (!message) {
      return res.status(400).json({ error: 'message is required' });
    }

    const prompt = `You are a helpful AI assistant for fortune telling. Respond to the user message:\n${message}\n\nResponse:`;

    const completion = await openai.createCompletion({
      model: 'text-davinci-003',
      prompt: prompt,
      max_tokens: 300,
      temperature: 0.7,
    });

    const response = completion.data.choices[0].text.trim();
    res.json({ response });
  } catch (error) {
    console.error('Error in /ai-chat:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.listen(port, () => {
  console.log(`Server running on port ${port}`);
});