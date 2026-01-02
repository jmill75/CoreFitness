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

    // Parse URL
    const url = new URL(request.url);
    const path = url.pathname;

    // Health check endpoint (allow GET)
    if (path === '/health' && request.method === 'GET') {
      return jsonResponse({ status: 'ok', environment: env.ENVIRONMENT });
    }

    // Only allow POST requests for AI endpoints
    if (request.method !== 'POST') {
      return jsonResponse({ error: { code: 'METHOD_NOT_ALLOWED', message: 'Only POST requests allowed' } }, 405);
    }

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
        case '/api/ai/parse':
          return await handleParse(request, env);
        case '/health':
          return jsonResponse({ status: 'ok', environment: env.ENVIRONMENT });
        default:
          return jsonResponse({ error: { code: 'NOT_FOUND', message: 'Endpoint not found' } }, 404);
      }
    } catch (error) {
      console.error('Error processing request:', error);

      // Return 429 for quota errors
      if (error instanceof QuotaExceededError) {
        return jsonResponse(
          { error: { code: 'QUOTA_EXCEEDED', message: error.message } },
          429
        );
      }

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

async function handleParse(request: Request, env: Env): Promise<Response> {
  const body = await request.json() as AIRequest;

  if (!body.prompt) {
    return jsonResponse({ error: { code: 'INVALID_REQUEST', message: 'Prompt is required' } }, 400);
  }

  const provider = body.provider || env.DEFAULT_PROVIDER as 'gemini' | 'claude';

  // Use system prompt optimized for JSON output
  const parseSystemPrompt = body.systemPrompt || `You are an expert at parsing workout programs from text.
Extract ALL workouts from the program - every day and every week.

CRITICAL RULES:
1. Return ONLY raw JSON - NO markdown code fences, NO backticks, NO explanation text
2. Return an object with "programName" and "workouts" array containing ALL workout days
3. The response must start with { and end with }
4. Include EVERY workout day from the program

Use this exact structure:
{
    "programName": "Program Name",
    "programDescription": "Brief description of the overall program",
    "difficulty": "Beginner|Intermediate|Advanced",
    "workouts": [
        {
            "name": "Week 1 Day 1 - Chest & Triceps",
            "description": "Brief description",
            "estimatedDuration": 45,
            "exercises": [
                {"name": "Exercise Name", "sets": 3, "reps": "10", "weight": "135 lbs", "restSeconds": 60}
            ]
        },
        {
            "name": "Week 1 Day 2 - Back & Biceps",
            "description": "Brief description",
            "estimatedDuration": 45,
            "exercises": [...]
        }
    ]
}
Keep exercise names simple and standardized (e.g., "Bench Press", "Squat", "Deadlift").
If weight is not mentioned, omit it. Include ALL days from ALL weeks.`;

  const response = await generateAIResponse(body.prompt, parseSystemPrompt, provider, env);

  return jsonResponse(response);
}

// Custom error class for quota exceeded
class QuotaExceededError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'QuotaExceededError';
  }
}

// AI Generation with automatic fallback
async function generateAIResponse(
  prompt: string,
  systemPrompt: string | undefined,
  provider: 'gemini' | 'claude',
  env: Env
): Promise<AIResponse> {
  if (provider === 'gemini') {
    try {
      return await callGemini(prompt, systemPrompt, env);
    } catch (error) {
      // Check if it's a quota/rate limit error (429) - fallback to Claude
      const errorMessage = error instanceof Error ? error.message : '';
      const isQuotaError = errorMessage.includes('429') || errorMessage.includes('quota') || errorMessage.includes('RESOURCE_EXHAUSTED');

      if (isQuotaError) {
        console.log('Gemini quota exceeded, attempting fallback to Claude');
        if (env.CLAUDE_API_KEY) {
          try {
            const response = await callClaude(prompt, systemPrompt, env);
            return { ...response, model: `${response.model} (fallback)` };
          } catch (claudeError) {
            console.error('Claude fallback also failed:', claudeError);
            throw new QuotaExceededError('AI quota exceeded and fallback unavailable. Please try again later.');
          }
        } else {
          throw new QuotaExceededError('AI quota exceeded. Please try again later (quota resets daily).');
        }
      }
      throw error;
    }
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
  // Note: Gemini 2.5 Flash uses "thinking" tokens by default which consume output budget
  // We disable thinking for structured output tasks
  const requestBody: {
    contents: typeof contents;
    generationConfig: { maxOutputTokens: number; temperature: number; thinkingConfig?: { thinkingBudget: number } };
    systemInstruction?: { parts: Array<{ text: string }> };
  } = {
    contents: [
      {
        role: 'user',
        parts: [{ text: prompt }]
      }
    ],
    generationConfig: {
      maxOutputTokens: 65536,  // Max for Gemini 2.5 Flash
      temperature: 0.7,
      thinkingConfig: {
        thinkingBudget: 0  // Disable thinking for faster, direct output
      }
    }
  };

  if (systemPrompt) {
    requestBody.systemInstruction = {
      parts: [{ text: systemPrompt }]
    };
  }

  // Log request for debugging
  console.log('=== GEMINI REQUEST ===');
  console.log('Model:', model);
  console.log('Prompt length:', prompt.length);
  console.log('Prompt preview:', prompt.substring(0, 500) + (prompt.length > 500 ? '...' : ''));
  if (systemPrompt) {
    console.log('System prompt preview:', systemPrompt.substring(0, 200) + '...');
  }

  const response = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(requestBody),
  });

  if (!response.ok) {
    const errorText = await response.text();
    console.error('=== GEMINI ERROR ===');
    console.error('Status:', response.status);
    console.error('Response:', errorText);
    throw new Error(`Gemini API error: ${response.status} - ${errorText}`);
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

  let content = data.candidates?.[0]?.content?.parts?.[0]?.text || '';
  const tokensUsed = data.usageMetadata?.totalTokenCount || null;

  // Strip markdown code fences if present (Gemini sometimes adds them despite instructions)
  content = content
    .replace(/^```json\s*/i, '')
    .replace(/^```\s*/i, '')
    .replace(/\s*```$/i, '')
    .trim();

  // Log response for debugging
  console.log('=== GEMINI RESPONSE ===');
  console.log('Tokens used:', tokensUsed);
  console.log('Response length:', content.length);
  console.log('Response preview:', content.substring(0, 500) + (content.length > 500 ? '...' : ''));

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
