// lib/screens/chat_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/ai_service.dart';

class ChatScreen extends StatefulWidget {
  /// Contexte d'analyse pré-rempli (depuis l'écran résultat)
  final String? analysisContext;
  /// Message initial envoyé automatiquement (depuis l'écran Apprendre)
  final String? initialMessage;
  const ChatScreen({super.key, this.analysisContext, this.initialMessage});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<AiMessage> _messages = [];
  bool _isLoading = false;

  static const _suggestions = [
    'Explique-moi la gamme de Do majeur',
    'Comment jouer un accord de Sol ?',
    'C\'est quoi la différence entre mineur et majeur ?',
    'Donne-moi un exercice pour mes doigts',
    'Comment lire une partition ?',
  ];

  @override
  void initState() {
    super.initState();
    final welcome = widget.analysisContext != null
        ? 'Bonjour ! J\'ai bien reçu les données de ton analyse. Pose-moi tes questions — je suis là pour t\'aider à comprendre et progresser 🎵'
        : 'Bonjour, je suis **Harmonie**, ton assistant musical. Pose-moi toutes tes questions sur la théorie musicale, les accords, les gammes ou ta pratique instrumentale 🎵';
    _messages.add(AiMessage(role: 'assistant', content: welcome));

    // Déclenche automatiquement le message initial (depuis l'écran Apprendre)
    if (widget.initialMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _send(widget.initialMessage!);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isLoading) return;

    _controller.clear();
    setState(() {
      _messages.add(AiMessage(role: 'user', content: trimmed));
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      // On n'envoie que les vrais messages (pas le welcome) à l'API
      final apiMessages =
          _messages.where((m) => m.role == 'user').isNotEmpty
              ? _messages.sublist(1) // skip welcome
              : _messages;

      final reply = await AiService.chat(
        messages: List.from(apiMessages),
        analysisContext: widget.analysisContext,
      );
      if (mounted) {
        setState(() {
          _messages.add(AiMessage(role: 'assistant', content: reply));
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        final msg = _errorMessage(e);
        setState(() {
          _messages.add(AiMessage(role: 'assistant', content: msg));
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  String _errorMessage(Object e) {
    final err = e.toString();
    if (err.contains('cle_manquante')) {
      return '🔑 Clé API non configurée.\n\nOuvre lib/config/secrets.dart et remplace le placeholder par ta clé Anthropic (sk-ant-api03-...).';
    }
    if (e is HttpException) {
      final msg = e.message;
      if (msg.startsWith('401') || msg.startsWith('403')) {
        return '🔑 Clé API invalide ou révoquée.\nGénère une nouvelle clé sur console.anthropic.com.';
      }
      return '⚠️ Anthropic : $msg';
    }
    if (e is SocketException) {
      return '🌐 Connexion impossible à api.anthropic.com.\nVérifie ta connexion internet.';
    }
    return '⚠️ Erreur : $err';
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
    return Scaffold(
      backgroundColor: HarmonieColors.bg,
      appBar: AppBar(
        backgroundColor: HarmonieColors.bg,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [HarmonieColors.gold, HarmonieColors.accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text('♪', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Harmonie IA',
                  style: TextStyle(
                    fontFamily: GoogleFonts.playfairDisplay().fontFamily,
                    fontSize: 16,
                    color: HarmonieColors.cream,
                  ),
                ),
                const Text(
                  'Assistant musical',
                  style: TextStyle(
                    color: HarmonieColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (_messages.length > 1)
            IconButton(
              icon: const Icon(Icons.refresh_rounded,
                  color: HarmonieColors.muted, size: 20),
              onPressed: () => setState(() {
                _messages.clear();
                _messages.add(AiMessage(
                  role: 'assistant',
                  content:
                      'Nouvelle conversation démarrée. Comment puis-je t\'aider ? 🎵',
                ));
              }),
              tooltip: 'Nouvelle conversation',
            ),
        ],
      ),
      body: Column(
        children: [
          // ─── Messages ─────────────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              physics: const BouncingScrollPhysics(),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, i) {
                if (i == _messages.length) {
                  return const _TypingIndicator();
                }
                final msg = _messages[i];
                return _MessageBubble(message: msg);
              },
            ),
          ),

          // ─── Suggestions (si début de conversation) ───────────────────
          if (_messages.length == 1) ...[
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                physics: const BouncingScrollPhysics(),
                itemCount: _suggestions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) => GestureDetector(
                  onTap: () => _send(_suggestions[i]),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: HarmonieColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border:
                          Border.all(color: HarmonieColors.gold.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      _suggestions[i],
                      style: const TextStyle(
                        color: HarmonieColors.gold,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // ─── Input ────────────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              color: HarmonieColors.surface,
              border: Border(
                  top: BorderSide(color: Color(0x12FFFFFF), width: 1)),
            ),
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              12 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(
                        color: HarmonieColors.cream, fontSize: 14),
                    maxLines: 4,
                    minLines: 1,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      hintText: 'Pose ta question musicale…',
                      hintStyle: const TextStyle(
                          color: HarmonieColors.muted, fontSize: 14),
                      filled: true,
                      fillColor: HarmonieColors.bg,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(
                            color: Color(0x20FFFFFF)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(
                            color: Color(0x20FFFFFF)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(
                            color: HarmonieColors.gold, width: 1.5),
                      ),
                    ),
                    onSubmitted: (v) {
                      if (!HardwareKeyboard.instance.isShiftPressed) {
                        _send(v);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => _send(_controller.text),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _isLoading
                          ? HarmonieColors.surface2
                          : HarmonieColors.gold,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.send_rounded,
                      color: _isLoading ? HarmonieColors.muted : Colors.black,
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

// ─── Widgets internes ─────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final AiMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () {
          Clipboard.setData(ClipboardData(text: message.content));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Copié dans le presse-papier'),
              duration: Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        child: Container(
          margin: EdgeInsets.only(
            top: 6,
            bottom: 6,
            left: isUser ? 48 : 0,
            right: isUser ? 0 : 48,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isUser
                ? HarmonieColors.gold.withValues(alpha: 0.15)
                : HarmonieColors.surface,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isUser ? 18 : 4),
              bottomRight: Radius.circular(isUser ? 4 : 18),
            ),
            border: Border.all(
              color: isUser
                  ? HarmonieColors.gold.withValues(alpha: 0.3)
                  : const Color(0x12FFFFFF),
            ),
          ),
          child: _MarkdownText(text: message.content, isUser: isUser),
        ),
      ),
    );
  }
}

/// Rendu basique du markdown (gras, italique, listes)
class _MarkdownText extends StatelessWidget {
  final String text;
  final bool isUser;
  const _MarkdownText({required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    // On transforme le markdown simple en TextSpans
    final spans = <InlineSpan>[];
    final lines = text.split('\n');
    for (int li = 0; li < lines.length; li++) {
      final line = lines[li];
      if (li > 0) spans.add(const TextSpan(text: '\n'));
      _parseLine(line, spans, isUser);
    }
    return RichText(
      text: TextSpan(
        style: TextStyle(
          color: isUser ? HarmonieColors.cream : HarmonieColors.cream,
          fontSize: 14,
          height: 1.5,
          fontWeight: FontWeight.w300,
        ),
        children: spans,
      ),
    );
  }

  void _parseLine(
      String line, List<InlineSpan> spans, bool isUser) {
    // Liste à puces
    if (line.startsWith('- ') || line.startsWith('• ')) {
      spans.add(const TextSpan(text: '  • '));
      _parseInline(line.substring(2), spans);
      return;
    }
    _parseInline(line, spans);
  }

  void _parseInline(String text, List<InlineSpan> spans) {
    // Gras **...**
    final boldRegex = RegExp(r'\*\*(.+?)\*\*');
    int last = 0;
    for (final match in boldRegex.allMatches(text)) {
      if (match.start > last) {
        spans.add(TextSpan(text: text.substring(last, match.start)));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: const TextStyle(
            fontWeight: FontWeight.w700, color: HarmonieColors.gold),
      ));
      last = match.end;
    }
    if (last < text.length) {
      spans.add(TextSpan(text: text.substring(last)));
    }
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

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
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: HarmonieColors.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
          ),
          border: Border.all(color: const Color(0x12FFFFFF)),
        ),
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) => Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              final opacity =
                  ((_ctrl.value * 3 - i).clamp(0.0, 1.0));
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: HarmonieColors.gold
                      .withValues(alpha: 0.3 + opacity * 0.7),
                  shape: BoxShape.circle,
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
