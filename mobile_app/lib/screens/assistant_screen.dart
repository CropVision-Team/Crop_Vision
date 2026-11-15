import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/supabase_service.dart';
import '../widgets/gradient_app_bar.dart';
import '../theme/app_theme.dart';

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _ChatMessage {
  final String role; // 'user' | 'assistant'
  final String content;
  _ChatMessage(this.role, this.content);
}

class _AssistantScreenState extends State<AssistantScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _sending = false;
  String? _diagnosisContext;
  bool _contextLoaded = false;

  @override
  void initState() {
    super.initState();
    // We read route arguments in didChangeDependencies (context is available there)
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_contextLoaded) {
      _contextLoaded = true;
      // Read diagnosis context passed from ResultScreen
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        _diagnosisContext = args['diagnosisContext'] as String?;
      }
      _initChat();
    }
  }

  Future<void> _initChat() async {
    final service = context.read<SupabaseService>();

    // Load history from DB
    try {
      final history = await service.fetchChatHistory();
      if (mounted) {
        setState(() {
          _messages.addAll(
            history.map(
                (m) => _ChatMessage(m['role'] as String, m['content'] as String)),
          );
        });
      }
    } catch (_) {
      // History load failure is non-fatal
    }

    // If we arrived from the result screen with a diagnosis context,
    // automatically send a greeting message about the diagnosis
    if (_diagnosisContext != null && mounted) {
      await _sendAutoContext();
    } else if (_messages.isEmpty && mounted) {
      // Fresh open with no history — show welcome message
      _addLocalMessage(
        'assistant',
        '👋 Hello! I\'m your CropVision AI Agronomy Assistant.\n\n'
        'Ask me anything about:\n'
        '• Crop diseases (Tomato, Potato, Corn, Apple, Grape)\n'
        '• Treatment & fungicide schedules\n'
        '• Watering, soil & fertilizer tips\n'
        '• G0/G1/G2/G3 severity stages\n\n'
        'What would you like to know? 🌱',
      );
    }
  }

  /// Called when navigating from the result screen — auto-asks the AI
  /// about the specific diagnosis that was just made.
  Future<void> _sendAutoContext() async {
    if (_diagnosisContext == null) return;
    final service = context.read<SupabaseService>();

    final autoQuestion =
        'I just scanned my crop leaf and got this diagnosis result:\n\n'
        '$_diagnosisContext\n\n'
        'Can you explain this disease in detail and give me the best treatment steps?';

    setState(() {
      _messages.add(_ChatMessage('user', '🔍 About my recent scan result...'));
      _sending = true;
    });

    String reply;
    try {
      reply = await service.askAssistant(autoQuestion,
          diagnosisContext: _diagnosisContext);
    } catch (e) {
      reply = service.buildOfflineContextReply(_diagnosisContext!);
    }

    if (mounted) {
      setState(() {
        _messages.add(_ChatMessage('assistant', reply));
        _sending = false;
      });
      _scrollToBottom();
    }

    // Save to history
    try {
      await service.saveChatMessage('user', autoQuestion);
      await service.saveChatMessage('assistant', reply);
    } catch (_) {}
  }

  void _addLocalMessage(String role, String content) {
    setState(() => _messages.add(_ChatMessage(role, content)));
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

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    final service = context.read<SupabaseService>();

    setState(() {
      _messages.add(_ChatMessage('user', text));
      _sending = true;
    });
    _controller.clear();
    _scrollToBottom();

    // Save user message (non-blocking, failure is non-fatal)
    service.saveChatMessage('user', text).catchError((_) {});

    String reply;
    try {
      reply = await service.askAssistant(text,
          diagnosisContext: _diagnosisContext);
    } catch (e) {
      // askAssistant already falls back to local knowledge — this
      // catch is just a last-resort safety net
      reply = '🌱 I\'m having trouble connecting right now. Please try again in a moment.\n\n'
          'In the meantime, ask me about: Tomato, Potato, Corn, Apple, Grape diseases, spraying, or soil tips!';
    }

    if (mounted) {
      setState(() {
        _messages.add(_ChatMessage('assistant', reply));
        _sending = false;
      });
      _scrollToBottom();
    }

    service.saveChatMessage('assistant', reply).catchError((_) {});
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cardBg =
        Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final mutedTextColor = Theme.of(context).colorScheme.onSurfaceVariant;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const GradientAppBar(title: 'AI Assistant'),
      body: Column(
        children: [
          // Context banner — shown when the user arrived from a scan result
          if (_diagnosisContext != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: AppColors.teal.withValues(alpha: 0.10),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 16, color: AppColors.teal.withValues(alpha: 0.8)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Asking about your recent scan result',
                      style: TextStyle(
                          fontSize: 12,
                          color: AppColors.teal.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),

          // Chat messages list
          Expanded(
            child: _messages.isEmpty && !_sending
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.teal.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.smart_toy_outlined,
                              size: 44,
                              color: AppColors.teal.withValues(alpha: 0.6)),
                        ),
                        const SizedBox(height: 12),
                        Text('Ask me about your crops',
                            style: TextStyle(color: mutedTextColor)),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isUser = msg.role == 'user';
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          mainAxisAlignment: isUser
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (!isUser) ...[
                              CircleAvatar(
                                radius: 15,
                                backgroundColor:
                                    AppColors.teal.withValues(alpha: 0.15),
                                child: const Icon(Icons.eco,
                                    size: 16, color: AppColors.teal),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.75,
                                ),
                                decoration: BoxDecoration(
                                  gradient: isUser
                                      ? const LinearGradient(colors: [
                                          AppColors.teal,
                                          AppColors.indigo,
                                        ])
                                      : null,
                                  color: isUser ? null : cardBg,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(18),
                                    topRight: const Radius.circular(18),
                                    bottomLeft:
                                        Radius.circular(isUser ? 18 : 4),
                                    bottomRight:
                                        Radius.circular(isUser ? 4 : 18),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  msg.content,
                                  style: TextStyle(
                                    color: isUser ? Colors.white : textColor,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // Typing indicator
          if (_sending)
            Padding(
              padding: const EdgeInsets.only(bottom: 4, left: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: AppColors.teal.withValues(alpha: 0.15),
                      child: const Icon(Icons.eco,
                          size: 13, color: AppColors.teal),
                    ),
                    const SizedBox(width: 8),
                    Text('Assistant is thinking…',
                        style:
                            TextStyle(color: mutedTextColor, fontSize: 12)),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: AppColors.teal.withValues(alpha: 0.6)),
                    ),
                  ],
                ),
              ),
            ),

          // Input bar
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            child: Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      enabled: !_sending,
                      textInputAction: TextInputAction.send,
                      decoration: InputDecoration(
                        hintText: 'Ask about your crop...',
                        hintStyle:
                            TextStyle(color: mutedTextColor.withValues(alpha: 0.6)),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 14),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: _sending
                          ? null
                          : const LinearGradient(
                              colors: [AppColors.teal, AppColors.indigo],
                            ),
                      color: _sending
                          ? AppColors.teal.withValues(alpha: 0.3)
                          : null,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white, size: 20),
                      onPressed: _sending ? null : _send,
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
}
