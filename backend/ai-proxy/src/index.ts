/**
 * CoreFitness AI Proxy Server
 *
 * Cloudflare Worker that proxies AI requests to Gemini or Claude APIs.
 * Keeps API keys secure on the server side.
 */

// Types
interface Env {
  GEMINI_API_KEY: string;
  CLAUDE_API_KEY: string;
  DEFAULT_PROVIDER: string;
  GEMINI_MODEL: string;
  CLAUDE_MODEL: string;
  RATE_LIMIT_RPM: string;
  ENVIRONMENT: string;
}

interface AIRequest {
  type: 'healthInsight' | 'workoutGeneration' | 'generalTip';
  prompt: string;
  systemPrompt?: string;
  provider: 'gemini' | 'claude';
  model?: string;
}

interface AIResponse {
  content: string;
  tokensUsed: number | null;
  model: string;
  provider: 'gemini' | 'claude';
}

interface ErrorResponse {
  error: {
    code: string;
    message: string;
  };
}

// Rate limiting store (in-memory, resets on worker restart)
const rateLimitStore = new Map<string, { count: number; resetTime: number }>();

// CORS headers
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, X-Device-ID',
  'Content-Type': 'application/json',
};

// Main handler
export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    // Handle CORS preflight
    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: corsHeaders });
    }

    // Only allow POST requests
    if (request.method !== 'POST') {
      return jsonResponse({ error: { code: 'METHOD_NOT_ALLOWED', message: 'Only POST requests allowed' } }, 405);
    }

    // Parse URL
    const url = new URL(request.url);
    const path = url.pathname;

    // Check rate limit
    const deviceId = request.headers.get('X-Device-ID') || 'anonymous';
    const rateLimitResult = checkRateLimit(deviceId, parseInt(env.RATE_LIMIT_RPM || '30'));
    if (!rateLimitResult.allowed) {
      return jsonResponse(
        { error: { code: 'RATE_LIMITED', message: `Rate limit exceeded. Try again in ${rateLimitResult.retryAfter} seconds.` } },
        429
      );
    }

    try {
      // Route to appropriate handler
      switch (path) {
        case '/api/ai/insights':
          return await handleInsights(request, env);
        case '/api/ai/workout':
          return await handleWorkout(request, env);
        case '/api/ai/tip':
          return await handleTip(request, env);
        case '/health':
          return jsonResponse({ status: 'ok', environment: env.ENVIRONMENT });
        default:
          return jsonResponse({ error: { code: 'NOT_FOUND', message: 'Endpoint not found' } }, 404);
      }
    } catch (error) {
      console.error('Error processing request:', error);
      return jsonResponse(
        { error: { code: 'INTERNAL_ERROR', message: error instanceof Error ? error.message : 'Unknown error' } },
        500
      );
    }
  },
};

// Rate limiting
function checkRateLimit(deviceId: string, limit: number): { allowed: boolean; retryAfter?: number } {
  const now = Date.now();
  const windowMs = 60 * 1000; // 1 minute window

  const record = rateLimitStore.get(deviceId);

  if (!record || now > record.resetTime) {
    rateLimitStore.set(deviceId, { count: 1, resetTime: now + windowMs });
    return { allowed: true };
  }

  if (record.count >= limit) {
    return { allowed: false, retryAfter: Math.ceil((record.resetTime - now) / 1000) };
  }

  record.count++;
  return { allowed: true };
}

// Handlers
async function handleInsights(request: Request, env: Env): Promise<Response> {
  const body = await request.json() as AIRequest;

  if (!body.prompt) {
    return jsonResponse({ error: { code: 'INVALID_REQUEST', message: 'Prompt is required' } }, 400);
  }

  const provider = body.provider || env.DEFAULT_PROVIDER as 'gemini' | 'claude';
  const response = await generateAIResponse(body.prompt, body.systemPrompt, provider, env);

  return jsonResponse(response);
}

async function handleWorkout(request: Request, env: Env): Promise<Response> {
  const body = await request.json() as AIRequest;

  if (!body.prompt) {
    return jsonResponse({ error: { code: 'INVALID_REQUEST', message: 'Prompt is required' } }, 400);
  }

  const provider = body.provider || env.DEFAULT_PROVIDER as 'gemini' | 'claude';
  const response = await generateAIResponse(body.prompt, body.systemPrompt, provider, env);

  return jsonResponse(response);
}

async function handleTip(request: Request, env: Env): Promise<Response> {
  const body = await request.json() as AIRequest;

  if (!body.prompt) {
    return jsonResponse({ error: { code: 'INVALID_REQUEST', message: 'Prompt is required' } }, 400);
  }

  const provider = body.provider || env.DEFAULT_PROVIDER as 'gemini' | 'claude';
  const response = await generateAIResponse(body.prompt, body.systemPrompt, provider, env);

  return jsonResponse(response);
}

// AI Generation
async function generateAIResponse(
  prompt: string,
  systemPrompt: string | undefined,
  provider: 'gemini' | 'claude',
  env: Env
): Promise<AIResponse> {
  if (provider === 'gemini') {
    return await callGemini(prompt, systemPrompt, env);
  } else {
    return await callClaude(prompt, systemPrompt, env);
  }
}

// Gemini API
async function callGemini(prompt: string, systemPrompt: string | undefined, env: Env): Promise<AIResponse> {
  const model = env.GEMINI_MODEL || 'gemini-pro';
  const apiKey = env.GEMINI_API_KEY;

  if (!apiKey) {
    throw new Error('GEMINI_API_KEY not configured');
  }

  const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`;

  // Build the request
  const contents: Array<{ role: string; parts: Array<{ text: string }> }> = [];

  // Add system instruction if provided
  const requestBody: {
    contents: typeof contents;
    generationConfig: { maxOutputTokens: number; temperature: number };
    systemInstruction?: { parts: Array<{ text: string }> };
  } = {
    contents: [
      {
        role: 'user',
        parts: [{ text: prompt }]
      }
    ],
    generationConfig: {
      maxOutputTokens: 2048,
      temperature: 0.7,
    }
  };

  if (systemPrompt) {
    requestBody.systemInstruction = {
      parts: [{ text: systemPrompt }]
    };
  }

  const response = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(requestBody),
  });

  if (!response.ok) {
    const errorText = await response.text();
    console.error('Gemini API error:', errorText);
    throw new Error(`Gemini API error: ${response.status}`);
  }

  const data = await response.json() as {
    candidates?: Array<{
      content?: {
        parts?: Array<{ text?: string }>;
      };
    }>;
    usageMetadata?: {
      totalTokenCount?: number;
    };
  };

  const content = data.candidates?.[0]?.content?.parts?.[0]?.text || '';
  const tokensUsed = data.usageMetadata?.totalTokenCount || null;

  return {
    content,
    tokensUsed,
    model,
    provider: 'gemini',
  };
}

// Claude API
async function callClaude(prompt: string, systemPrompt: string | undefined, env: Env): Promise<AIResponse> {
  const model = env.CLAUDE_MODEL || 'claude-3-haiku-20240307';
  const apiKey = env.CLAUDE_API_KEY;

  if (!apiKey) {
    throw new Error('CLAUDE_API_KEY not configured');
  }

  const url = 'https://api.anthropic.com/v1/messages';

  const requestBody: {
    model: string;
    max_tokens: number;
    messages: Array<{ role: string; content: string }>;
    system?: string;
  } = {
    model,
    max_tokens: 2048,
    messages: [
      { role: 'user', content: prompt }
    ],
  };

  if (systemPrompt) {
    requestBody.system = systemPrompt;
  }

  const response = await fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'x-api-key': apiKey,
      'anthropic-version': '2023-06-01',
    },
    body: JSON.stringify(requestBody),
  });

  if (!response.ok) {
    const errorText = await response.text();
    console.error('Claude API error:', errorText);
    throw new Error(`Claude API error: ${response.status}`);
  }

  const data = await response.json() as {
    content?: Array<{ text?: string }>;
    usage?: {
      input_tokens?: number;
      output_tokens?: number;
    };
  };

  const content = data.content?.[0]?.text || '';
  const tokensUsed = data.usage ? (data.usage.input_tokens || 0) + (data.usage.output_tokens || 0) : null;

  return {
    content,
    tokensUsed,
    model,
    provider: 'claude',
  };
}

// Helper
function jsonResponse(data: AIResponse | ErrorResponse | { status: string; environment: string }, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: corsHeaders,
  });
}
