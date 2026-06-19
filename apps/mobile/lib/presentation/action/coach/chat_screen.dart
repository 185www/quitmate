import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/coach/ai_coach_engine.dart';
import '../../../core/coach/llm_service.dart';
import '../../../core/di/providers.dart';
import '../../../domain/entity/coach_message.dart';
import '../../../domain/entity/game_profile.dart';
import '../../../domain/entity/daily_log.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final List<CoachMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AiCoachEngine _engine = AiCoachEngine();
  bool _isTyping = false;

  // Track which messages have quick replies visible
  final Set<String> _visibleQuickReplies = {};

  @override
  void initState() {
    super.initState();
    _initConversation();
  }

  Future<void> _initConversation() async {
    final user = await ref.read(userUseCaseProvider).getCurrentUser();
    GameProfile? gameProfile;
    DailyLogEntry? todayLog;

    if (user != null) {
      gameProfile = await ref.read(gameUseCaseProvider).getGameProfile(user.id);
      todayLog = await ref.read(logUseCaseProvider).getTodayLog();
    }

    if (!mounted) return;

    final greeting = _engine.generateGreeting(
      user: user,
      gameProfile: gameProfile,
      todayLog: todayLog,
    );

    setState(() {
      _messages.add(greeting);
      if (greeting.quickReplies != null) {
        _visibleQuickReplies.add(greeting.id);
      }
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Add user message
    final userMsg = CoachMessage(
      id: CoachMessage.generateId(),
      isUser: true,
      text: text.trim(),
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMsg);
      _textController.clear();
      // Hide all previous quick replies when user sends a message
      _visibleQuickReplies.clear();
    });

    _scrollToBottom();

    // Show typing indicator
    setState(() => _isTyping = true);
    _scrollToBottom();

    // Get user data for context
    final user = await ref.read(userUseCaseProvider).getCurrentUser();
    GameProfile? gameProfile;
    DailyLogEntry? todayLog;

    if (user != null) {
      gameProfile = await ref.read(gameUseCaseProvider).getGameProfile(user.id);
      todayLog = await ref.read(logUseCaseProvider).getTodayLog();
    }

    // Check if LLM is enabled
    final prefs = await ref.read(userUseCaseProvider).getPreferences();
    final useLlm = prefs['use_llm'] as bool? ?? false;
    final apiKey = prefs['ai_api_key'] as String? ?? '';
    final useLlmNow = useLlm && apiKey.isNotEmpty;

    if (useLlmNow) {
      // Use LLM for response generation
      try {
        final service = LlmService(
          apiKey: apiKey,
          baseUrl:
              prefs['ai_api_base'] as String? ?? 'https://api.openai.com/v1',
          model: prefs['ai_model'] as String? ?? 'gpt-4o-mini',
        );

        // Build conversation history from messages (exclude empty ones)
        final history = _messages
            .where((m) => m.text.isNotEmpty)
            .map((m) => {
                  'role': m.isUser ? 'user' : 'assistant',
                  'content': m.text,
                })
            .toList();

        // Build user context string
        final contextStr = '戒断${user?.daysSinceQuit ?? 0}天 '
            '等级${gameProfile?.levelTitle ?? '未定'} '
            '连续${gameProfile?.streakDays ?? 0}天 '
            '阶段${user?.stage.name ?? 'unknown'}';

        final llmResponse =
            await service.chat(history, userContext: contextStr);

        // Parse [quick reply] suggestions from the response
        final quickReplies = <String>[];
        for (final match in RegExp(r'\[([^\]]+)\]').allMatches(llmResponse)) {
          quickReplies.add(match.group(1)!);
        }
        final cleanText =
            llmResponse.replaceAll(RegExp(r'\[[^\]]+\]'), '').trim();

        if (!mounted) return;

        setState(() {
          _isTyping = false;
          _messages.add(CoachMessage(
            id: CoachMessage.generateId(),
            isUser: false,
            text: cleanText,
            timestamp: DateTime.now(),
            quickReplies: quickReplies.isNotEmpty ? quickReplies : null,
          ));
          _visibleQuickReplies.clear();
        });

        _scrollToBottom();
        return; // Skip fallback
      } catch (e) {
        // LLM failed — fall through to rule-based engine below
        debugPrint('LLM error, falling back to rule-based: $e');
      }
    }

    // Simulate thinking delay (1.5 seconds)
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    // Generate coach response (rule-based fallback or default)
    final response = _engine.generateResponse(
      userInput: text,
      user: user,
      gameProfile: gameProfile,
      todayLog: todayLog,
    );

    setState(() {
      _isTyping = false;
      _messages.add(response);
      // Show quick replies for the latest coach message
      _visibleQuickReplies.clear();
      if (response.quickReplies != null && response.quickReplies!.isNotEmpty) {
        _visibleQuickReplies.add(response.id);
      }
    });

    _scrollToBottom();
  }

  void _onQuickReplyTap(String reply) {
    _sendMessage(reply);
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple.shade400, Colors.purple.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.smart_toy,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'AI戒烟教练',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Hint bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: colorScheme.primaryContainer.withOpacity(0.3),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 16,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '💡 提示：你可以问我关于渴望、情绪、睡眠、社交压力等方面的问题',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.primary.withOpacity(0.8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Messages list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  // Typing indicator
                  return _buildTypingIndicator();
                }
                final message = _messages[index];
                final showQuickReplies =
                    _visibleQuickReplies.contains(message.id);

                return Column(
                  crossAxisAlignment: message.isUser
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    _buildMessageBubble(message, theme),
                    if (showQuickReplies && !message.isUser) ...[
                      const SizedBox(height: 6),
                      _buildQuickReplies(message),
                      const SizedBox(height: 12),
                    ] else
                      const SizedBox(height: 8),
                  ],
                );
              },
            ),
          ),
          // Input area
          _buildInputArea(theme, colorScheme),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(CoachMessage message, ThemeData theme) {
    final colorScheme = theme.colorScheme;

    if (message.isUser) {
      // User message: right-aligned, primary color
      return Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.only(left: 48),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: colorScheme.primary,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(6),
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            message.text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ),
      );
    }

    // Coach message: left-aligned with avatar
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.78,
      ),
      margin: const EdgeInsets.only(right: 48),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Coach avatar
          Container(
            width: 36,
            height: 36,
            margin: const EdgeInsets.only(right: 8, top: 2),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple.shade400, Colors.purple.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.smart_toy,
              color: Colors.white,
              size: 18,
            ),
          ),
          // Message bubble
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withOpacity(0.6),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Coach label
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      'AI教练',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.purple.shade700,
                      ),
                    ),
                  ),
                  // Message text
                  Text(
                    message.text,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickReplies(CoachMessage message) {
    final replies = message.quickReplies;
    if (replies == null || replies.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(left: 44),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: replies.map((reply) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _onQuickReplyTap(reply),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: colorScheme.secondary.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      reply,
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.only(right: 48, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            margin: const EdgeInsets.only(right: 8, top: 2),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple.shade400, Colors.purple.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.smart_toy,
              color: Colors.white,
              size: 18,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withOpacity(0.6),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: _TypingDots(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Text input
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                child: TextField(
                  controller: _textController,
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(_textController.text),
                  style: const TextStyle(fontSize: 15),
                  decoration: InputDecoration(
                    hintText: '输入消息...',
                    hintStyle: TextStyle(
                      color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                      fontSize: 15,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor:
                        colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Send button
            Material(
              color: _textController.text.trim().isNotEmpty
                  ? colorScheme.primary
                  : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                onTap: () => _sendMessage(_textController.text),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: _textController.text.trim().isNotEmpty
                        ? colorScheme.primary
                        : colorScheme.surfaceContainerHighest,
                  ),
                  child: Icon(
                    Icons.send_rounded,
                    color: _textController.text.trim().isNotEmpty
                        ? Colors.white
                        : colorScheme.onSurfaceVariant.withOpacity(0.4),
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Animated typing dots indicator
class _TypingDots extends StatefulWidget {
  final Color color;
  const _TypingDots({required this.color});

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final offset = (index * 0.3) % 1.0;
            final animation = CurvedAnimation(
              parent: _controller,
              curve: Interval(offset, offset + 0.3, curve: Curves.easeInOut),
            );
            final opacity =
                animation.drive(Tween<double>(begin: 0.3, end: 1.0));
            final scale = animation.drive(Tween<double>(begin: 0.8, end: 1.2));
            return Opacity(
              opacity: opacity.value,
              child: Transform.scale(
                scale: scale.value,
                child: child,
              ),
            );
          },
          child: Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
            ),
          ),
        );
      }),
    );
  }
}
