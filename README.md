# egocore.ai

**egocore.ai** — персональный ИИ-ассистент нового поколения.

Универсальный голосовой и текстовый помощник, работающий в Telegram, MAX и веб-интерфейсе. Отвечает на любые вопросы, помогает с поиском услуг и мастеров, интегрируется с платформами GoodWork и BountyHub.

## Возможности

- 🎙️ **Голосовой ввод и вывод** — распознавание речи через OpenAI Whisper, синтез через OpenAI TTS (голос Nova)
- 🤖 **Claude Sonnet** — интеллектуальные ответы на любые вопросы
- 📱 **Мультиплатформенность** — Telegram, MAX Messenger, Web
- 🔧 **GoodWork** — биржа услуг: поиск мастеров и исполнителей
- 🏖️ **BountyHub** — маркетплейс сертификатов на услуги в Таиланде
- 🌐 **Веб-интерфейс** — голосовой чат прямо в браузере

## Технологии

- **AI**: Anthropic Claude Sonnet, OpenAI Whisper STT, OpenAI TTS
- **Backend**: Python (Telegram/MAX боты), Node.js + Express (веб-панель)
- **Frontend**: React + Vite + TypeScript + Tailwind CSS
- **Infrastructure**: Docker, PostgreSQL, SQLite

## Структура

```
ego-core/
├── bot/          — Telegram & MAX боты (Python)
├── webapp/       — Веб-панель оператора (React + Express)
└── docs/         — Документация
```

## Лицензия

MIT — см. [LICENSE](LICENSE)

## Торговая марка

egocore.ai является зарегистрированной торговой маркой. См. [TRADEMARK.md](TRADEMARK.md)
