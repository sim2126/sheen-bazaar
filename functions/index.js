/**
 * Firebase Cloud Functions: Gemini AI Proxy
 *
 * Routes all AI calls through the backend so the API key never touches the device.
 * Uses Gemini 2.5 Flash for multimodal catalog and product description generation.
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
const { GoogleGenerativeAI, SchemaType } = require('@google/generative-ai');
const { GoogleAICacheManager } = require('@google/generative-ai/server');
const admin = require('firebase-admin');

admin.initializeApp();

// Secret stored in Google Secret Manager — set with:
//   firebase functions:secrets:set GEMINI_KEY
const GEMINI_KEY = defineSecret('GEMINI_KEY');

const MODEL_ID = 'gemini-2.5-flash';

const PRODUCT_DESCRIPTION_SYSTEM_INSTRUCTION =
  `You create accurate, buyer-facing product listing copy for Sheen Bazaar, a Kashmiri handicrafts marketplace.\n\n` +
  `Return concise, factual listing details. Treat the vendor-provided product name and category as hints, not proof of material, grade, age, origin, or technique.\n\n` +
  `Rules:\n` +
  `- Use the image as the primary source when an image is provided.\n` +
  `- If no image is provided, only use facts stated in the product name and category; keep uncertain fields omitted.\n` +
  `- Do not invent exact material grade, dimensions, artisan method, authenticity, age, brand, provenance, or medical/therapeutic claims.\n` +
  `- If a detail is not visible or explicitly stated, omit that field instead of guessing.\n` +
  `- Keep every field plain text: no markdown, bullets, asterisks, emojis, or code fences.\n` +
  `- Write for customers, but avoid exaggerated luxury claims.`;

const PRODUCT_DESCRIPTION_SCHEMA = {
  type: SchemaType.OBJECT,
  properties: {
    tagline: {
      type: SchemaType.STRING,
      description: 'A concise product headline, maximum 12 words.',
    },
    narrative: {
      type: SchemaType.STRING,
      description: 'Two to three factual sentences about visible design, texture, finish, and likely use. Avoid unsupported claims.',
    },
    material: {
      type: SchemaType.STRING,
      description: 'Only material that is visible or explicitly stated in the product name/category.',
    },
    craft: {
      type: SchemaType.STRING,
      description: 'Only the craft technique if visible or explicitly stated.',
    },
    color: {
      type: SchemaType.STRING,
      description: 'Visible dominant and accent colors. Omit when no image is provided.',
    },
    dimensions: {
      type: SchemaType.STRING,
      description: 'Only dimensions explicitly visible from labels/text or provided by the vendor. Do not estimate.',
    },
    occasion: {
      type: SchemaType.STRING,
      description: 'Appropriate use cases based on the product category and visible design.',
    },
    care: {
      type: SchemaType.STRING,
      description: 'General, safe care guidance for the category. Avoid unsupported material-specific claims.',
    },
  },
  required: ['tagline', 'narrative'],
};

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

// ── seedCategories ────────────────────────────────────────────────────────────
const _SEED_DESCRIPTION =
  'Lorem ipsum dolor sit amet consectetur adipiscing elit. sed do eiusmod ' +
  'tempor incididunt ut labore et dolore magna aliqua. Cit enim ad minim ' +
  'veniam. quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea ' +
  'commodo consequat. Duis aute irure dolor in reprehenderit in voluptate ' +
  'velit esse cillum dolore eu fugiat nulla pariatur Excepteur Sint occaecat ' +
  'cupidatat non proident. sunt in culpa qui offcia deserunt mollit anim id ' +
  'est laborum.';

const _CATEGORIES = [
  { id: 'copper_ware',      name: 'Copper Ware',      image: 'assets/images/category-covers/Copperware.jpeg',           sortOrder: 0  },
  { id: 'papier_mache',     name: 'Papier Mache',     image: 'assets/images/category-covers/Papier machie.jpeg',        sortOrder: 1  },
  { id: 'silverware',       name: 'Silverware',        image: 'assets/images/category-covers/Silverware.jpeg',           sortOrder: 2  },
  { id: 'enamelware',       name: 'Enamelware',        image: 'assets/images/category-covers/Enamelware.jpeg',           sortOrder: 3  },
  { id: 'terracotta',       name: 'Terracotta',        image: 'assets/images/category-covers/Terracotta.jpeg',           sortOrder: 4  },
  { id: 'green_serpentine', name: 'Green Serpentine',  image: 'assets/images/category-covers/Green Serpentine.jpeg',     sortOrder: 5  },
  { id: 'coins',            name: 'Coins',             image: 'assets/images/category-covers/Coins.jpeg',                sortOrder: 6  },
  { id: 'shawls',           name: 'Shawls',            image: 'assets/images/category-covers/Shawls.jpeg',               sortOrder: 7  },
  { id: 'jewellery',        name: 'Jewellery',         image: 'assets/images/category-covers/Jewellery.jpeg',            sortOrder: 8  },
  { id: 'carpets',          name: 'Carpets',           image: 'assets/images/category-covers/Carpet.jpeg',               sortOrder: 9  },
  { id: 'willow_wicker',    name: 'Willow Wicker',     image: 'assets/images/category-covers/willow wicker.jpeg',        sortOrder: 10 },
  { id: 'woodwork',         name: 'Woodwork',          image: 'assets/images/category-covers/Woodwork.jpeg',             sortOrder: 11 },
  { id: 'brassware',        name: 'Brass Ware',        image: 'assets/images/category-covers/Brassware.jpeg',            sortOrder: 12 },
];

exports.seedCategories = functions
  .region('asia-south1')
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Must be signed in.');
    }

    const userDoc = await admin.firestore().collection('users').doc(context.auth.uid).get();
    if (!userDoc.exists || userDoc.data().role !== 'admin') {
      throw new functions.https.HttpsError('permission-denied', 'Admin only.');
    }

    const db = admin.firestore();
    const col = db.collection('categories');

    // Delete all existing categories
    const existing = await col.get();
    const deleteBatch = db.batch();
    existing.docs.forEach(doc => deleteBatch.delete(doc.ref));
    await deleteBatch.commit();

    // Write all 14 new categories
    const writeBatch = db.batch();
    _CATEGORIES.forEach(cat => {
      writeBatch.set(col.doc(cat.id), {
        name: cat.name,
        image: cat.image,
        icon: '',
        description: _SEED_DESCRIPTION,
        sortOrder: cat.sortOrder,
      });
    });
    await writeBatch.commit();

    return { count: _CATEGORIES.length };
  });

// ── geminiDescribeProduct ─────────────────────────────────────────────────────
function assertCallableAuth(context) {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be signed in.');
  }
  return context.auth.uid;
}

function asPositiveInt(value, fieldName, max = 99) {
  if (!Number.isInteger(value) || value <= 0 || value > max) {
    throw new functions.https.HttpsError('invalid-argument', `${fieldName} must be between 1 and ${max}.`);
  }
  return value;
}

function asCleanString(value, fieldName, maxLength) {
  if (typeof value !== 'string') {
    throw new functions.https.HttpsError('invalid-argument', `${fieldName} must be a string.`);
  }
  const cleaned = value.trim();
  if (!cleaned || cleaned.length > maxLength) {
    throw new functions.https.HttpsError('invalid-argument', `${fieldName} is invalid.`);
  }
  return cleaned;
}

// ── placeOrder ────────────────────────────────────────────────────────────────
exports.placeOrder = functions
  .region('asia-south1')
  .runWith({ timeoutSeconds: 60, memory: '256MB' })
  .https.onCall(async (data, context) => {
    const uid = assertCallableAuth(context);
    const items = data && data.items;

    if (!Array.isArray(items) || items.length === 0 || items.length > 100) {
      throw new functions.https.HttpsError('invalid-argument', 'Cart must contain 1 to 100 items.');
    }

    const db = admin.firestore();
    const groupedItems = new Map();

    for (const item of items) {
      const shopId = asCleanString(item && item.shopId, 'shopId', 128);
      const productId = asCleanString(item && item.productId, 'productId', 128);
      const qty = asPositiveInt(item && item.qty, 'qty');
      const key = `${shopId}/${productId}`;
      const existing = groupedItems.get(key);
      if (existing) {
        existing.qty = asPositiveInt(existing.qty + qty, 'qty', 99);
      } else {
        groupedItems.set(key, { shopId, productId, qty });
      }
    }

    return await db.runTransaction(async (tx) => {
      const shopDataById = new Map();
      const orderItemsByShop = new Map();
      const productUpdates = [];

      for (const item of groupedItems.values()) {
        let shop = shopDataById.get(item.shopId);
        if (!shop) {
          const shopRef = db.collection('shops').doc(item.shopId);
          const shopSnap = await tx.get(shopRef);
          if (!shopSnap.exists) {
            throw new functions.https.HttpsError('not-found', 'Shop not found.');
          }
          shop = { id: item.shopId, ref: shopRef, data: shopSnap.data() };
          if (shop.data.isOpen !== true) {
            throw new functions.https.HttpsError('failed-precondition', `${shop.data.shopName || 'This shop'} is currently closed.`);
          }
          shopDataById.set(item.shopId, shop);
        }

        const productRef = shop.ref.collection('products').doc(item.productId);
        const productSnap = await tx.get(productRef);
        if (!productSnap.exists) {
          throw new functions.https.HttpsError('not-found', 'Product not found.');
        }

        const product = productSnap.data();
        const stock = Number(product.stock || 0);
        const price = Number(product.price || 0);

        if (!Number.isFinite(price) || price < 0) {
          throw new functions.https.HttpsError('failed-precondition', `${product.name || 'Product'} has an invalid price.`);
        }
        if (!Number.isInteger(stock) || stock < item.qty) {
          throw new functions.https.HttpsError('failed-precondition', `${product.name || 'Product'} does not have enough stock.`);
        }

        productUpdates.push({ ref: productRef, stock: stock - item.qty });

        const orderItems = orderItemsByShop.get(item.shopId) || [];
        orderItems.push({
          productId: item.productId,
          name: product.name || '',
          price,
          qty: item.qty,
          image: product.image || '',
        });
        orderItemsByShop.set(item.shopId, orderItems);
      }

      for (const update of productUpdates) {
        tx.update(update.ref, { stock: update.stock });
      }

      const createdOrders = [];
      for (const [shopId, orderItems] of orderItemsByShop.entries()) {
        const shop = shopDataById.get(shopId);
        const total = orderItems.reduce((sum, item) => sum + item.price * item.qty, 0);
        const orderRef = db.collection('orders').doc();
        tx.set(orderRef, {
          userId: uid,
          shopId,
          shopName: shop.data.shopName || '',
          status: 'placed',
          total,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          items: orderItems,
        });
        createdOrders.push(orderRef.id);
      }

      return { orderIds: createdOrders, count: createdOrders.length };
    });
  });

// ── submitReview ──────────────────────────────────────────────────────────────
exports.submitReview = functions
  .region('asia-south1')
  .runWith({ timeoutSeconds: 60, memory: '256MB' })
  .https.onCall(async (data, context) => {
    const uid = assertCallableAuth(context);
    const orderId = asCleanString(data && data.orderId, 'orderId', 128);
    const rating = asPositiveInt(data && data.rating, 'rating', 5);
    const comment = typeof (data && data.comment) === 'string'
      ? data.comment.trim().slice(0, 1000)
      : '';

    const db = admin.firestore();
    const reviewId = `${orderId}_${uid}`;

    return await db.runTransaction(async (tx) => {
      const orderRef = db.collection('orders').doc(orderId);
      const orderSnap = await tx.get(orderRef);
      if (!orderSnap.exists) {
        throw new functions.https.HttpsError('not-found', 'Order not found.');
      }

      const order = orderSnap.data();
      if (order.userId !== uid) {
        throw new functions.https.HttpsError('permission-denied', 'You can only review your own orders.');
      }
      if (order.status !== 'delivered') {
        throw new functions.https.HttpsError('failed-precondition', 'Only delivered orders can be reviewed.');
      }

      const reviewRef = db.collection('reviews').doc(reviewId);
      const reviewSnap = await tx.get(reviewRef);
      if (reviewSnap.exists) {
        throw new functions.https.HttpsError('already-exists', 'This order has already been reviewed.');
      }

      const userSnap = await tx.get(db.collection('users').doc(uid));
      const user = userSnap.exists ? userSnap.data() : {};
      const userName = user.name || user.email || 'Customer';

      const shopRef = db.collection('shops').doc(order.shopId);
      const shopSnap = await tx.get(shopRef);
      if (!shopSnap.exists) {
        throw new functions.https.HttpsError('not-found', 'Shop not found.');
      }

      const shop = shopSnap.data();
      const currentTotalReviews = Number(shop.totalReviews || 0);
      const currentRating = Number(shop.rating || 0);
      const newTotalReviews = currentTotalReviews + 1;
      const newRating = Math.round(((currentRating * currentTotalReviews) + rating) / newTotalReviews * 10) / 10;

      tx.set(reviewRef, {
        shopId: order.shopId,
        shopName: order.shopName || '',
        orderId,
        userId: uid,
        userName,
        rating,
        comment,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      tx.update(shopRef, {
        rating: newRating,
        totalReviews: newTotalReviews,
      });

      return { reviewId, rating: newRating, totalReviews: newTotalReviews };
    });
  });

exports.geminiDescribeProduct = functions
  .region('asia-south1')
  .runWith({ timeoutSeconds: 60, memory: '512MB', secrets: [GEMINI_KEY] })
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Must be signed in.');
    }

    const {
      productName,
      categoryName,
      imageBase64,
      mediaType = 'image/jpeg',
    } = data;

    if (typeof productName !== 'string' || !productName.trim()) {
      throw new functions.https.HttpsError('invalid-argument', 'productName is required.');
    }
    if (typeof categoryName !== 'string' || !categoryName.trim()) {
      throw new functions.https.HttpsError('invalid-argument', 'categoryName is required.');
    }
    if (!['image/jpeg', 'image/png', 'image/webp'].includes(mediaType)) {
      throw new functions.https.HttpsError('invalid-argument', 'Unsupported image type.');
    }
    if (imageBase64 && (typeof imageBase64 !== 'string' || imageBase64.length > 7_000_000)) {
      throw new functions.https.HttpsError('invalid-argument', 'Image payload is too large.');
    }

    const apiKey = GEMINI_KEY.value();
    if (!apiKey) {
      throw new functions.https.HttpsError('internal', 'Gemini API key not configured.');
    }

    try {
      const genAI = new GoogleGenerativeAI(apiKey);
      const model = genAI.getGenerativeModel({
        model: MODEL_ID,
        systemInstruction: PRODUCT_DESCRIPTION_SYSTEM_INSTRUCTION,
        generationConfig: {
          temperature: 0.2,
          responseMimeType: 'application/json',
          responseSchema: PRODUCT_DESCRIPTION_SCHEMA,
        },
      });

      const parts = [];
      if (imageBase64) {
        parts.push({ inlineData: { mimeType: mediaType, data: imageBase64 } });
      }
      parts.push({
        text:
          `Product name: ${productName.trim()}\n` +
          `Category: ${categoryName.trim()}\n` +
          `Image provided: ${imageBase64 ? 'yes' : 'no'}\n\n` +
          `Create the JSON product description using the schema. ` +
          `If there is no image, do not describe colors, dimensions, grade, or visible motifs unless they are explicitly present in the product name.`,
      });

      const result = await model.generateContent(parts);
      return { text: result.response.text() };
    } catch (err) {
      console.error('geminiDescribeProduct error:', err.message, err.stack);
      throw new functions.https.HttpsError('internal', `${err.message}`);
    }
  });
