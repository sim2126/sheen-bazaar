/**
 * Firebase Cloud Functions: Gemini AI Proxy
 *
 * Routes all AI calls through the backend so the API key never touches the device.
 * Uses Gemini 1.5 Flash for cost efficiency (~40x cheaper input than Claude Sonnet).
 * Implements Context Caching for the system prompt + full product catalog.
 * Caching activates automatically once cached content exceeds Gemini's 32,768-token
 * minimum — below that threshold it falls back to regular generation transparently.
 *
 * SETUP:
 *   firebase functions:config:set gemini.key="YOUR_GEMINI_API_KEY"
 *   firebase deploy --only functions
 *
 * FUNCTIONS:
 *   geminiChat            — AI shopping assistant (with context caching)
 *   geminiDescribeProduct — Vision: structured product description from image
 */

const functions = require('firebase-functions');
const { defineSecret } = require('firebase-functions/params');
const { GoogleGenerativeAI } = require('@google/generative-ai');
const { GoogleAICacheManager } = require('@google/generative-ai/server');
const admin = require('firebase-admin');

admin.initializeApp();

// Secret stored in Google Secret Manager — set with:
//   firebase functions:secrets:set GEMINI_KEY
const GEMINI_KEY = defineSecret('GEMINI_KEY');

const MODEL_ID = 'gemini-1.5-flash-001';

// ── Static system instruction ────────────────────────────────────────────────
const ASSISTANT_SYSTEM_INSTRUCTION =
  `You are a warm, knowledgeable shopping assistant for Sheen Bazaar — a curated marketplace for authentic Kashmiri handicrafts.\n\n` +
  `Your goal is to help customers find the perfect product. Be concise, culturally warm, and enthusiastic about Kashmir's craft heritage.\n\n` +
  `Rules:\n` +
  `- If no product catalog is provided yet, ask ONE clear clarifying question about category (Pashmina / Papier Mache / Walnut Wood) or budget.\n` +
  `- When products are available, suggest 2–3 specific matches with shop name and price.\n` +
  `- Always use ₹ for prices.\n` +
  `- Never invent products — only recommend what appears in the catalog provided.\n` +
  `- Keep responses under 150 words.\n` +
  `- Greet users with warmth and cultural sensitivity.`;

// ── Module-level cache state (survives warm invocations) ─────────────────────
// { name: string, expiresAt: number } | null
let _assistantCache = null;

/**
 * Fetches all open shops + in-stock products from Firestore.
 * Returns a plain-text catalog string to include in the context cache.
 */
async function fetchFullCatalog() {
  const db = admin.firestore();
  const shopsSnapshot = await db
    .collection('shops')
    .where('isOpen', '==', true)
    .get();

  const lines = ['FULL SHEEN BAZAAR PRODUCT CATALOG:'];

  for (const shopDoc of shopsSnapshot.docs) {
    const shop = shopDoc.data();
    const productsSnap = await db
      .collection('shops')
      .doc(shopDoc.id)
      .collection('products')
      .where('stock', '>', 0)
      .get();

    if (productsSnap.empty) continue;

    lines.push(
      `\nSHOP: ${shop.shopName} | Location: ${shop.location} | Category: ${shop.categoryId}` +
      (shop.isVerified ? ' | ✓ Verified Artisan' : '')
    );

    for (const pd of productsSnap.docs) {
      const p = pd.data();
      lines.push(`  - ${p.name} | ₹${p.price} | Stock: ${p.stock} | ${p.description || ''}`);
    }
  }

  return lines.join('\n');
}

/**
 * Returns a valid Gemini cache name for the assistant context.
 * Creates a new cache (system instruction + full catalog) if none exists or is expiring.
 * Returns null gracefully when content is below Gemini's 32,768-token minimum —
 * geminiChat will fall back to regular generation in that case.
 */
async function getOrCreateAssistantCache(cacheManager) {
  const now = Date.now();
  const REFRESH_BEFORE_MS = 5 * 60 * 1000; // refresh 5 min before expiry

  if (_assistantCache && _assistantCache.expiresAt > now + REFRESH_BEFORE_MS) {
    return _assistantCache.name; // reuse existing cache
  }

  try {
    const catalog = await fetchFullCatalog();

    const cache = await cacheManager.create({
      model: `models/${MODEL_ID}`,
      displayName: 'sheen-bazaar-assistant',
      systemInstruction: ASSISTANT_SYSTEM_INSTRUCTION,
      contents: [
        {
          role: 'user',
          parts: [{ text: `Here is the current product catalog:\n\n${catalog}` }],
        },
        {
          role: 'model',
          parts: [{ text: 'I have the full catalog loaded. How can I help you find the perfect Kashmiri craft today?' }],
        },
      ],
      ttlSeconds: 3600,
    });

    _assistantCache = { name: cache.name, expiresAt: now + 3600 * 1000 };
    console.log('Context cache created:', cache.name);
    return cache.name;
  } catch (err) {
    // Below 32,768-token minimum or other transient error — fall back silently
    console.warn('Context cache skipped, using regular generation:', err.message);
    _assistantCache = null;
    return null;
  }
}

// ── geminiChat ────────────────────────────────────────────────────────────────
exports.geminiChat = functions
  .region('asia-south1')
  .runWith({ timeoutSeconds: 60, memory: '256MB', secrets: [GEMINI_KEY] })
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Must be signed in to use the AI assistant.');
    }

    const { systemPrompt, messages } = data;
    if (!systemPrompt || !Array.isArray(messages)) {
      throw new functions.https.HttpsError('invalid-argument', 'systemPrompt and messages are required.');
    }

    const apiKey = GEMINI_KEY.value();
    if (!apiKey) {
      throw new functions.https.HttpsError('internal', 'Gemini API key not configured.');
    }

    try {
      const genAI = new GoogleGenerativeAI(apiKey);
      const cacheManager = new GoogleAICacheManager(apiKey);

      const cacheName = await getOrCreateAssistantCache(cacheManager);

      let model;
      if (cacheName) {
        // Cached path: system instruction + catalog already loaded, only pay for new tokens
        const cachedContent = await cacheManager.get(cacheName);
        model = genAI.getGenerativeModelFromCachedContent(cachedContent);
      } else {
        // Fallback: standard generation with system instruction from request
        model = genAI.getGenerativeModel({
          model: MODEL_ID,
          systemInstruction: systemPrompt,
        });
      }

      // Convert Flutter message format → Gemini format
      // Flutter sends: { role: 'user' | 'assistant', content: string }
      // Gemini expects: { role: 'user' | 'model', parts: [{ text }] }
      const history = messages.slice(0, -1).map(m => ({
        role: m.role === 'assistant' ? 'model' : 'user',
        parts: [{ text: m.content }],
      }));
      const lastMessage = messages[messages.length - 1];

      const chat = model.startChat({ history });
      const result = await chat.sendMessage(lastMessage.content);

      return { text: result.response.text() };
    } catch (err) {
      console.error('geminiChat error:', err);
      throw new functions.https.HttpsError('internal', 'AI request failed.');
    }
  });

// ── geminiDescribeProduct ─────────────────────────────────────────────────────
exports.geminiDescribeProduct = functions
  .region('asia-south1')
  .runWith({ timeoutSeconds: 60, memory: '512MB', secrets: [GEMINI_KEY] })
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Must be signed in.');
    }

    const { systemPrompt, userText, imageBase64, mediaType = 'image/jpeg' } = data;
    if (!systemPrompt || !userText) {
      throw new functions.https.HttpsError('invalid-argument', 'systemPrompt and userText are required.');
    }

    const apiKey = GEMINI_KEY.value();
    if (!apiKey) {
      throw new functions.https.HttpsError('internal', 'Gemini API key not configured.');
    }

    try {
      const genAI = new GoogleGenerativeAI(apiKey);
      const model = genAI.getGenerativeModel({
        model: MODEL_ID,
        systemInstruction: systemPrompt,
      });

      const parts = [];
      if (imageBase64) {
        parts.push({ inlineData: { mimeType: mediaType, data: imageBase64 } });
      }
      parts.push({ text: userText });

      const result = await model.generateContent(parts);
      return { text: result.response.text() };
    } catch (err) {
      console.error('geminiDescribeProduct error:', err);
      throw new functions.https.HttpsError('internal', 'AI description failed.');
    }
  });
