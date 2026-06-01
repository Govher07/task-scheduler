import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../models/event.dart';
import '../providers.dart';

// AssistantChatSheet is a ConsumerStatefulWidget so it can read the Supabase client
// and call the ai-assistant Edge Function whenever the user sends a message.
class AssistantChatSheet extends ConsumerStatefulWidget {
  const AssistantChatSheet({super.key, this.initialPrompt});

  /// When provided, this prompt is sent automatically as soon as the sheet
  /// opens — used by the Home page's quick-suggestion pills.
  final String? initialPrompt;

  @override
  ConsumerState<AssistantChatSheet> createState() => _AssistantChatSheetState();
}

class _AssistantChatSheetState extends ConsumerState<AssistantChatSheet> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    final prompt = widget.initialPrompt?.trim();
    if (prompt != null && prompt.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _controller.text = prompt;
        _sendMessage();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Sends the user's message to the ai-assistant Edge Function and appends
  /// the AI reply to the chat. The Edge Function handles all tool calls
  /// (including create_event) internally before returning the final reply.
  /// If the Edge Function fails (e.g. missing API key, 500 error), we fall back
  /// to a smart local event parser.
  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _controller.clear();
      _isSending = true;
    });
    _scrollToBottom();

    try {
      final client = ref.read(supabaseClientProvider);

      // Build the full conversation history for the stateless Edge Function.
      final history = _messages
          .map((m) => {'role': m.isUser ? 'user' : 'assistant', 'content': m.text})
          .toList();

      final response = await client.functions.invoke(
        'ai-assistant',
        body: {'messages': history},
      );

      final reply = (response.data as Map<String, dynamic>)['reply'] as String? ??
          'Sorry, I could not process your request.';

      setState(() {
        _messages.add(_ChatMessage(text: reply, isUser: false));
      });
    } catch (e) {
      // Gracefully fall back to local parser when the remote Edge Function fails
      try {
        final reply = await _parseAndCreateEventLocally(text);
        setState(() {
          _messages.add(_ChatMessage(text: reply, isUser: false));
        });
      } catch (localError) {
        setState(() {
          _messages.add(_ChatMessage(
            text: 'Error: ${localError.toString()}',
            isUser: false,
          ));
        });
      }
    } finally {
      setState(() => _isSending = false);
      _scrollToBottom();
    }
  }

  /// Parses the user message locally and inserts a new event into the database.
  /// This ensures functionality works even without an Anthropic API Key.
  Future<String> _parseAndCreateEventLocally(String text) async {
    final lower = text.toLowerCase();
    
    if (lower.contains('event') ||
        lower.contains('meeting') ||
        lower.contains('appointment') ||
        lower.contains('schedule') ||
        lower.contains('add') ||
        lower.contains('create')) {
      DateTime startTime = DateTime.now();
      startTime = DateTime(startTime.year, startTime.month, startTime.day, startTime.hour + 1, 0);

      // Try to extract date first
      final months = {
        'january': 1, 'jan': 1,
        'february': 2, 'feb': 2,
        'march': 3, 'mar': 3,
        'april': 4, 'apr': 4,
        'may': 5,
        'june': 6, 'jun': 6,
        'july': 7, 'jul': 7,
        'august': 8, 'aug': 8,
        'september': 9, 'sep': 9,
        'october': 10, 'oct': 10,
        'november': 11, 'nov': 11,
        'december': 12, 'dec': 12,
      };

      int? detectedMonth;
      int? detectedDay;

      for (final entry in months.entries) {
        if (lower.contains(entry.key)) {
          detectedMonth = entry.value;
          final dayReg = RegExp(entry.key + r'\s+(\d{1,2})(?:st|nd|rd|th)?', caseSensitive: false);
          final dayMatch = dayReg.firstMatch(lower);
          if (dayMatch != null) {
            detectedDay = int.tryParse(dayMatch.group(1) ?? '');
          } else {
            final dayRegBefore = RegExp(r'(\d{1,2})(?:st|nd|rd|th)?\s+(?:of\s+)?' + entry.key, caseSensitive: false);
            final dayMatchBefore = dayRegBefore.firstMatch(lower);
            if (dayMatchBefore != null) {
              detectedDay = int.tryParse(dayMatchBefore.group(1) ?? '');
            }
          }
          break;
        }
      }

      if (detectedMonth != null && detectedDay != null) {
        final now = DateTime.now();
        int year = now.year;
        if (detectedMonth < now.month || (detectedMonth == now.month && detectedDay < now.day)) {
          year += 1;
        }
        startTime = DateTime(year, detectedMonth, detectedDay, startTime.hour, startTime.minute);
      } else if (lower.contains('tomorrow')) {
        startTime = startTime.add(const Duration(days: 1));
      }

      // Extract time (e.g., 3pm, 10am, 15:00)
      final timeReg = RegExp(r'(\d{1,2})(?::(\d{2}))?\s*(am|pm)?', caseSensitive: false);
      final timeMatches = timeReg.allMatches(text);
      if (timeMatches.isNotEmpty) {
        var timeMatch = timeMatches.first;
        for (final m in timeMatches) {
          final startIdx = m.start;
          final beforeText = text.substring(0, startIdx).toLowerCase();
          if (beforeText.endsWith('at ') || beforeText.endsWith('at') || m.group(3) != null) {
            timeMatch = m;
            break;
          }
        }
        
        int hours = int.tryParse(timeMatch.group(1) ?? '') ?? startTime.hour;
        final minutes = int.tryParse(timeMatch.group(2) ?? '') ?? 0;
        final ampm = timeMatch.group(3)?.toLowerCase();

        if (ampm == 'pm' && hours < 12) {
          hours += 12;
        } else if (ampm == 'am' && hours == 12) {
          hours = 0;
        }
        startTime = DateTime(startTime.year, startTime.month, startTime.day, hours, minutes);
      }

      final endTime = startTime.add(const Duration(hours: 1));

      // Clean up the name
      String name = text;
      // Remove leading action words
      name = name.replaceFirst(RegExp(r'^(?:create|add|new|schedule)\s+', caseSensitive: false), '');
      // Remove leading event type if generic
      name = name.replaceFirst(RegExp(r'^(?:a|an|the)\s+(?:meeting|event|appointment)\s+(?:at|on|for)\s+', caseSensitive: false), '');
      name = name.replaceFirst(RegExp(r'^(?:a|an|the)\s+(?:meeting|event|appointment)\s+', caseSensitive: false), '');
      name = name.replaceFirst(RegExp(r'^(?:a|an|the)\s+', caseSensitive: false), '');

      // Remove date/time phrases
      name = name.replaceAll(RegExp(r'\b(?:tomorrow|today)\b', caseSensitive: false), '');
      name = name.replaceAll(RegExp(r'\b(?:at|on|for)?\s*\d{1,2}(?::\d{2})?\s*(?:am|pm)\b', caseSensitive: false), '');
      name = name.replaceAll(RegExp(r'\b(?:at|on|for)?\s*\d{1,2}:\d{2}\b', caseSensitive: false), '');
      for (final monthName in months.keys) {
        name = name.replaceAll(RegExp(r'\b(?:at|on|for)?\s*' + monthName + r'\s+\d{1,2}(?:st|nd|rd|th)?\b', caseSensitive: false), '');
        name = name.replaceAll(RegExp(r'\b\d{1,2}(?:st|nd|rd|th)?\s+(?:of\s+)?' + monthName + r'\b', caseSensitive: false), '');
      }
      
      // Clean up leading/trailing prepositions and spaces
      name = name.replaceAll(RegExp(r'\s+'), ' ').trim();
      name = name.replaceFirst(RegExp(r'^(?:at|on|for|with)\s+', caseSensitive: false), '');
      name = name.replaceFirst(RegExp(r'\s+(?:at|on|for|with)$', caseSensitive: false), '');
      name = name.trim();

      final lowerName = name.toLowerCase();
      if (lowerName.isEmpty || 
          lowerName == 'meeting' || 
          lowerName == 'event' || 
          lowerName == 'appointment') {
        name = 'Meeting';
      } else {
        if (lowerName.startsWith('meeting with ')) {
          name = 'Meeting with ' + name.substring(13);
        } else if (lowerName.startsWith('1:1 with ')) {
          name = '1:1 with ' + name.substring(9);
        } else {
          if (lower.contains('meeting with ') && !name.toLowerCase().startsWith('meeting with ')) {
            name = 'Meeting with ' + name;
          } else if (lower.contains('1:1 with ') && !name.toLowerCase().startsWith('1:1 with ')) {
            name = '1:1 with ' + name;
          } else {
            name = name[0].toUpperCase() + name.substring(1);
          }
        }
      }

      try {
        final repo = ref.read(eventRepositoryProvider);
        final newEvent = Event(
          id: const Uuid().v4(),
          name: name,
          startTime: startTime,
          endTime: endTime,
          isRepeating: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await repo.createEvent(newEvent);

        final dateStr = DateFormat('EEE, MMM d').format(startTime);
        final timeStr = DateFormat('h:mm a').format(startTime);
        return 'I have successfully created the event "$name" for $dateStr at $timeStr!';
      } catch (e) {
        return 'I tried to create the event "$name" but failed: ${e.toString()}';
      }
    }

    return 'Hi! I am the support assistant. How can I help you today? You can ask me to "create an event named Standup tomorrow at 3pm".';
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                const Icon(Icons.support_agent, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Support Chat',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 48,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'How can I help you today?',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Try: "Add a meeting tomorrow at 3pm"',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Or: "What should I work on? I have 30 minutes"',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_isSending ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length) {
                        // Typing indicator while waiting for AI reply
                        return const Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: EdgeInsets.only(bottom: 8),
                            child: _TypingIndicator(),
                          ),
                        );
                      }
                      return _MessageBubble(message: _messages[index]);
                    },
                  ),
          ),
          Padding(
            padding: EdgeInsets.only(
              left: 12,
              right: 12,
              top: 8,
              bottom: MediaQuery.of(context).viewInsets.bottom + 12,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _isSending ? null : _sendMessage,
                  icon: _isSending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  const _ChatMessage({required this.text, required this.isUser});
  final String text;
  final bool isUser;
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? theme.colorScheme.primary
              : theme.colorScheme.secondaryContainer,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
        ),
        child: Text(
          message.text,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isUser
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSecondaryContainer,
          ),
        ),
      ),
    );
  }
}

/// Three animated dots that show the AI is "thinking".
class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
          bottomLeft: Radius.circular(4),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              final opacity = ((_ctrl.value * 3 - i).clamp(0.0, 1.0) *
                  (1 - (_ctrl.value * 3 - i - 1).clamp(0.0, 1.0)));
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Opacity(
                  opacity: 0.3 + 0.7 * opacity,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
