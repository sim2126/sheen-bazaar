/**
 * Firebase Cloud Function: Claude API Proxy
 *
 * Proxies requests to the Anthropic API so the Claude API key
 * never needs to be bundled inside the Flutter APK.
 *
 * SETUP INSTRUCTIONS:
 * 1. cd functions && npm install
 * 2. firebase functions:config:set anthropic.key="YOUR_CLAUDE_API_KEY"
 * 3. firebase deploy --only functions
 *
 * After deploying, update lib/config/api_config.dart to use
 * ClaudeService.proxyBaseUrl instead of calling Anthropic directly.
 */

const functions = require('firebase-functions');
const https = require('https');

const ANTHROPIC_API_URL = 'https://api.anthropic.com/v1/messages';
const MODEL = 'claude-sonnet-4-6';

/**
 * Callable function: claudeProxy
 * Called from Flutter via firebase_functions package.
 *
 * Expected request data:
 * {
 *   systemPrompt: string,
 *   messages: Array<{role: string, content: string | Array}>,
 *   maxTokens?: number,      // defaults to 1024
 * }
 *
 * Returns: { text: string }
 */
exports.claudeProxy = functions
  .region('asia-south1')  // closest region to Kashmir/India
  .runWith({ timeoutSeconds: 60, memory: '256MB' })
  .https.onCall(async (data, context) => {
    // Require authentication — no anonymous AI calls
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'Must be signed in to use the AI assistant.'
      );
    }

    const { systemPrompt, messages, maxTokens = 1024 } = data;

    if (!systemPrompt || !messages || !Array.isArray(messages)) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'systemPrompt and messages are required.'
      );
    }

    const apiKey = functions.config().anthropic.key;
    if (!apiKey) {
      throw new functions.https.HttpsError(
        'internal',
        'API key not configured.'
      );
    }

    const requestBody = JSON.stringify({
      model: MODEL,
      max_tokens: Math.min(maxTokens, 4096),
      system: systemPrompt,
      messages,
    });

    try {
      const responseText = await new Promise((resolve, reject) => {
        const options = {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'x-api-key': apiKey,
            'anthropic-version': '2023-06-01',
          },
        };

        const req = https.request(ANTHROPIC_API_URL, options, (res) => {
          let body = '';
          res.on('data', (chunk) => (body += chunk));
          res.on('end', () => {
            if (res.statusCode === 200) {
              const parsed = JSON.parse(body);
              resolve(parsed.content[0].text);
            } else {
              reject(new Error(`Anthropic API error ${res.statusCode}: ${body}`));
            }
          });
        });

        req.on('error', reject);
        req.write(requestBody);
        req.end();
      });

      return { text: responseText };
    } catch (err) {
      console.error('Claude proxy error:', err);
      throw new functions.https.HttpsError('internal', 'AI request failed.');
    }
  });
