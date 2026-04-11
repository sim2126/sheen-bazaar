import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/gemini_service.dart';

class AiAssistant extends StatefulWidget {
  const AiAssistant({super.key});

  @override
  State<AiAssistant> createState() => _AiAssistantState();
}

class _AiAssistantState extends State<AiAssistant> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _loading = false;

  // Catalog is loaded lazily once we have enough context from the user.
  String? _loadedCatalog; // null = not loaded yet
  bool _catalogLoading = false;

  // Minimum signal needed before we bother fetching the catalog.
  // We extract these from the conversation to build a targeted Firestore query.
  String? _detectedCategory; // 'pashmina' | 'papier_mache' | 'wood' | null
  int? _detectedMaxPrice;

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
  }

  void _addWelcomeMessage() {
    _messages.add(_ChatMessage(
      text:
          'Hello and Assalamu Alaikum! 👋 I\'m your Sheen Bazaar shopping assistant.\n\n'
          'Tell me what you\'re looking for — a gift, a shawl, a wooden craft — and I\'ll find the best matches for you.\n\n'
          'You can also mention your budget, like "under ₹2000".',
      isUser: false,
    ));
  }

  /// Parses the conversation for category and budget signals so we can
  /// fetch only relevant products instead of the entire catalog.
  void _detectIntent(String text) {
    final lower = text.toLowerCase();

    // Category detection
    if (lower.contains('pashmina') || lower.contains('shawl') || lower.contains('stole') || lower.contains('wool')) {
      _detectedCategory = 'pashmina';
    } else if (lower.contains('papier') || lower.contains('mache') || lower.contains('lacquer') || lower.contains('painted')) {
      _detectedCategory = 'papier_mache';
    } else if (lower.contains('wood') || lower.contains('walnut') || lower.contains('carv')) {
      _detectedCategory = 'wood';
    }

    // Budget detection — look for ₹NNN or "under NNN" or "below NNN"
    final budgetMatch = RegExp(r'(?:under|below|₹|rs\.?)\s*(\d[\d,]*)').firstMatch(lower);
    if (budgetMatch != null) {
      final priceStr = budgetMatch.group(1)!.replaceAll(',', '');
      _detectedMaxPrice = int.tryParse(priceStr);
    }
  }

  /// Fetches a targeted product catalog based on detected intent.
  /// If intent is still unclear, returns an empty string so Claude asks
  /// clarifying questions instead of guessing.
  Future<String> _fetchCatalog() async {
    setState(() => _catalogLoading = true);
    try {
      Query shopsQuery = FirebaseFirestore.instance
          .collection('shops')
          .where('isOpen', isEqualTo: true);

      if (_detectedCategory != null) {
        shopsQuery = shopsQuery.where('categoryId', isEqualTo: _detectedCategory);
      }

      final shopsSnap = await shopsQuery.get();
      final buffer = StringBuffer();
      buffer.writeln('MATCHING PRODUCTS IN SHEEN BAZAAR:');

      for (final shopDoc in shopsSnap.docs) {
        final shopData = shopDoc.data() as Map<String, dynamic>;
        Query productsQuery = FirebaseFirestore.instance
            .collection('shops')
            .doc(shopDoc.id)
            .collection('products')
            .where('stock', isGreaterThan: 0);

        final productsSnap = await productsQuery.get();
        final matchingProducts = productsSnap.docs.where((d) {
          if (_detectedMaxPrice == null) return true;
          final price = (d['price'] ?? 0) as num;
          return price <= _detectedMaxPrice!;
        }).toList();

        if (matchingProducts.isNotEmpty) {
          buffer.writeln('\nSHOP: ${shopData['shopName']} | Location: ${shopData['location']}');
          for (final pd in matchingProducts) {
            final p = pd.data() as Map<String, dynamic>;
            buffer.writeln('  - ${p['name']} | ₹${p['price']} | ${p['description']}');
          }
        }
      }

      final catalog = buffer.toString();
      setState(() { _loadedCatalog = catalog; _catalogLoading = false; });
      return catalog;
    } catch (_) {
      setState(() => _catalogLoading = false);
      return '';
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _loading) return;

    _detectIntent(text);

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _loading = true;
      _controller.clear();
    });

    _scrollToBottom();

    // Decide whether we have enough context to fetch the catalog now
    final bool hasEnoughContext = _detectedCategory != null || _detectedMaxPrice != null;
    String catalog = _loadedCatalog ?? '';

    // Fetch catalog on first message that gives us context, or if already loaded refresh if needed
    if (hasEnoughContext && _loadedCatalog == null) {
      catalog = await _fetchCatalog();
    }

    // Build conversation history (skip welcome message at index 0)
    final conversationHistory = _messages
        .where((m) => m.isUser || _messages.indexOf(m) > 0)
        .map((m) => {'role': m.isUser ? 'user' : 'assistant', 'content': m.text})
        .toList();

    final String catalogSection = catalog.isNotEmpty
        ? 'Here are the products matching the customer\'s needs:\n$catalog'
        : 'The product catalog has not been loaded yet because we need more context. '
          'Ask the customer for their preferred category (Pashmina / Papier Mache / Walnut Wood) '
          'or budget before suggesting products.';

    final systemPrompt = '''
You are a warm, knowledgeable shopping assistant for Sheen Bazaar — a marketplace for authentic Kashmiri handicrafts.

Your goal: help customers find the perfect product. Be concise, culturally warm, and enthusiastic.

Rules:
- If the catalog section says "not loaded yet", ask ONE clear clarifying question (category or budget).
- When catalog is available, suggest 2–3 specific products with shop name and price.
- Always use ₹ for prices.
- Never make up products — only recommend what is in the catalog.
- Keep responses under 150 words.

$catalogSection
''';

    final response = await GeminiService.sendMessage(
      systemPrompt: systemPrompt,
      messages: conversationHistory,
    );

    setState(() {
      _messages.add(_ChatMessage(text: response, isUser: false));
      _loading = false;
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((
      _,
    ) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController
              .position
              .maxScrollExtent,
          duration: const Duration(
            milliseconds: 300,
          ),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EDE0),
      appBar: AppBar(
        title: const Row(
          children: [
            Text(
              '✨ ',
              style: TextStyle(fontSize: 18),
            ),
            Text('AI Shopping Assistant'),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // ── Catalog loading indicator ──
          if (_catalogLoading)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: const Color(0xFFEDE0CC),
              child: const Row(
                children: [
                  SizedBox(
                    width: 14, height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFC8821A)),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Finding matching products...',
                    style: TextStyle(fontSize: 12, color: Color(0xFF8FA8A0), fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),

          // ── Chat messages ──
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _MessageBubble(
                  message: _messages[index],
                );
              },
            ),
          ),

          // ── Typing indicator ──
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(
                left: 16,
                bottom: 8,
              ),
              child: Row(
                children: [_TypingIndicator()],
              ),
            ),

          // ── Input bar ──
          Container(
            padding: const EdgeInsets.fromLTRB(
              16,
              8,
              16,
              16,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: const Color(
                    0xFF3D2B1F,
                  ).withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onSubmitted: (_) =>
                        _sendMessage(),
                    decoration: InputDecoration(
                      hintText:
                          'Ask about products...',
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: const Color(
                        0xFFF5EDE0,
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(
                              24,
                            ),
                        borderSide:
                            BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    padding: const EdgeInsets.all(
                      12,
                    ),
                    decoration:
                        const BoxDecoration(
                          color: Color(
                            0xFF3D2B1F,
                          ),
                          shape: BoxShape.circle,
                        ),
                    child: const Icon(
                      Icons.send_rounded,
                      color: Color(0xFFC9A55A),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Message Bubble ──
class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Align(
      alignment: isUser
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth:
              MediaQuery.of(context).size.width *
              0.78,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? const Color(0xFF3D2B1F)
              : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(
              isUser ? 16 : 4,
            ),
            bottomRight: Radius.circular(
              isUser ? 4 : 16,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(
                0xFF3D2B1F,
              ).withOpacity(0.07),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          message.text,
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: isUser
                ? const Color(0xFFF5EDE0)
                : const Color(0xFF3D2B1F),
          ),
        ),
      ),
    );
  }
}

// ── Typing Indicator ──
class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() =>
      _TypingIndicatorState();
}

class _TypingIndicatorState
    extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(
              0xFF3D2B1F,
            ).withOpacity(0.07),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final delay = index * 0.3;
              final value =
                  ((_controller.value - delay) %
                          1.0)
                      .clamp(0.0, 1.0);
              final opacity =
                  (value < 0.5
                          ? value * 2
                          : 2 - value * 2)
                      .clamp(0.3, 1.0);
              return Opacity(
                opacity: opacity,
                child: child,
              );
            },
            child: Container(
              margin: const EdgeInsets.symmetric(
                horizontal: 3,
              ),
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFFC9A55A),
                shape: BoxShape.circle,
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  _ChatMessage({
    required this.text,
    required this.isUser,
  });
}
