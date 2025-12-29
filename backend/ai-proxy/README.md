# CoreFitness AI Proxy Server

Cloudflare Worker that securely proxies AI requests from the CoreFitness iOS app to Gemini and Claude APIs.

## Features

- **Dual Provider Support**: Gemini (default) and Claude APIs
- **Secure**: API keys stored as Cloudflare secrets, never exposed to clients
- **Rate Limiting**: Per-device rate limiting to prevent abuse
- **CORS Enabled**: Works with web clients if needed
- **Serverless**: Auto-scaling, no server management

## Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/ai/insights` | POST | Generate health insights |
| `/api/ai/workout` | POST | Generate workout plans |
| `/api/ai/tip` | POST | Generate quick fitness tips |
| `/health` | GET | Health check |

## Request Format

```json
{
  "type": "healthInsight",
  "prompt": "User health context: Recovery score low, HRV below baseline...",
  "systemPrompt": "You are a supportive fitness coach...",
  "provider": "gemini"
}
```

## Response Format

```json
{
  "content": "Based on your recovery metrics...",
  "tokensUsed": 150,
  "model": "gemini-pro",
  "provider": "gemini"
}
```

## Setup

### Prerequisites

1. [Node.js](https://nodejs.org/) 18+
2. [Cloudflare Account](https://dash.cloudflare.com/sign-up)
3. [Wrangler CLI](https://developers.cloudflare.com/workers/wrangler/)

### Installation

```bash
cd backend/ai-proxy
npm install
```

### Configure Wrangler

Login to Cloudflare:

```bash
npx wrangler login
```

### Set API Keys as Secrets

```bash
# Set Gemini API key
npx wrangler secret put GEMINI_API_KEY
# Paste your Gemini API key when prompted

# Set Claude API key (optional, for future use)
npx wrangler secret put CLAUDE_API_KEY
# Paste your Claude API key when prompted
```

### Get API Keys

- **Gemini**: [Google AI Studio](https://aistudio.google.com/apikey)
- **Claude**: [Anthropic Console](https://console.anthropic.com/)

## Development

Run locally:

```bash
npm run dev
```

This starts a local dev server at `http://localhost:8787`.

Test with curl:

```bash
curl -X POST http://localhost:8787/api/ai/insights \
  -H "Content-Type: application/json" \
  -H "X-Device-ID: test-device" \
  -d '{
    "prompt": "User context: low HRV, 5 hours sleep, elevated resting HR",
    "systemPrompt": "You are a fitness coach. Provide brief health insights.",
    "provider": "gemini"
  }'
```

## Deployment

Deploy to Cloudflare:

```bash
npm run deploy
```

After deployment, you'll get a URL like:
```
https://corefitness-ai-proxy.<your-subdomain>.workers.dev
```

## Update iOS App

Update `AIProxyService.swift` with your deployed URL:

```swift
private var baseURL: String {
    #if DEBUG
    return "http://localhost:8787/api/ai"
    #else
    return "https://corefitness-ai-proxy.<your-subdomain>.workers.dev/api/ai"
    #endif
}
```

## Configuration

Edit `wrangler.toml` to customize:

| Variable | Default | Description |
|----------|---------|-------------|
| `DEFAULT_PROVIDER` | `gemini` | Default AI provider |
| `GEMINI_MODEL` | `gemini-pro` | Gemini model to use |
| `CLAUDE_MODEL` | `claude-3-haiku-20240307` | Claude model to use |
| `RATE_LIMIT_RPM` | `30` | Requests per minute per device |

## Rate Limiting

- Default: 30 requests/minute per device
- Device identified by `X-Device-ID` header
- Returns 429 status when exceeded

## Error Responses

| Code | Status | Description |
|------|--------|-------------|
| `RATE_LIMITED` | 429 | Too many requests |
| `INVALID_REQUEST` | 400 | Missing required fields |
| `NOT_FOUND` | 404 | Unknown endpoint |
| `INTERNAL_ERROR` | 500 | Server error |

## Monitoring

View logs in real-time:

```bash
npm run tail
```

## Costs

- **Cloudflare Workers Free Tier**: 100,000 requests/day
- **Gemini Free Tier**: Generous free quota
- **Claude**: Pay-per-use (when enabled)

## Security Notes

1. API keys are stored as Cloudflare secrets
2. Never commit API keys to git
3. Rate limiting prevents abuse
4. CORS configured for all origins (customize for production)
