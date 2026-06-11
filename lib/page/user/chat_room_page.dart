import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../service/chatService.dart';
import '../../service/active_chat_service.dart';

class ChatRoomPage extends StatefulWidget {
  final int currentUserId;
  final int userId;
  final int adminId;
  final int? referenceLaporanId;

  const ChatRoomPage({
    super.key,
    required this.currentUserId,
    required this.userId,
    required this.adminId,
    this.referenceLaporanId,
  });

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  static const Color dominantColor = Color(0xFFD8C99B);
  static const Color secondaryColor = Color(0xFF273E47);
  static const Color accentColor = Color(0xFFD8973C);
  static const Color bgLight = Color(0xFFF5F0E8);
  static const Color cardBg = Colors.white;

  static const Color secondaryColor8  = Color(0x14273E47);
  static const Color secondaryColor10 = Color(0x1A273E47);
  static const Color dominantColor50  = Color(0x80D8C99B);
  static const Color dominantColor80  = Color(0xCCD8C99B);
  static const Color secondaryColor45 = Color(0x73273E47);
  static const Color secondaryColor65 = Color(0xA6273E47);
  static const Color secondaryColor60 = Color(0x99273E47);
  static const Color secondaryColor35 = Color(0x59273E47);
  static const Color white65          = Color(0xA6FFFFFF);

  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  bool isLoading = true;
  bool isSending = false;
  bool shouldSendReference = false;

  int? roomId;
  List<dynamic> messages = [];
  int? _lastMessageId;
  final Set<int> _localMessageIds = {};

  RealtimeChannel? chatChannel;

  @override
  void initState() {
    super.initState();
    initChat();
  }

  @override
  void dispose() {
    ActiveChatService.activeRoomId = null;
    if (chatChannel != null) {
      Supabase.instance.client.removeChannel(chatChannel!);
    }
    messageController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  Future<void> initChat() async {
    try {
      final room = await ChatService.getOrCreateRoom(
        userId: widget.userId,
        adminId: widget.adminId,
      );

      roomId = room["id"] is int
      ? room["id"]
      : int.tryParse(room["id"].toString());

ActiveChatService.activeRoomId = roomId;

      ActiveChatService.activeRoomId = roomId;

      await loadMessages();
      shouldSendReference =
      widget.referenceLaporanId != null && !hasReferenceForCurrentLaporan();
      subscribeRealtimeChat();

      if (mounted) {
        setState(() => isLoading = false);
      }

      scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      _showSnackBar("Gagal membuka chat: $e");
    }
  }

  bool hasReferenceForCurrentLaporan() {
    if (widget.referenceLaporanId == null) return false;

    return messages.any((msg) {
      final laporanId = msg["laporan_id"] ?? msg["reference_laporan_id"];

      return laporanId != null &&
          laporanId.toString() == widget.referenceLaporanId.toString();
    });
  }

  void subscribeRealtimeChat() {
    if (roomId == null) return;

    chatChannel = Supabase.instance.client
        .channel("chat_room_$roomId")

        // Pesan baru masuk
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: "public",
          table: "chat_messages",
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: "room_id",
            value: roomId!,
          ),
          callback: (payload) async {
            await loadNewMessages();
            scrollToBottom();
          },
        )

        // is_read berubah
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: "public",
          table: "chat_messages",
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: "room_id",
            value: roomId!,
          ),
          callback: (payload) {
            final updatedMessage = payload.newRecord;

            final int? updatedId = updatedMessage["id"] is int
                ? updatedMessage["id"]
                : int.tryParse(updatedMessage["id"].toString());

            if (updatedId == null) return;
            if (!mounted) return;

            setState(() {
              messages = messages.map((msg) {
                final int? msgId = msg["id"] is int
                    ? msg["id"]
                    : int.tryParse(msg["id"].toString());

                if (msgId == updatedId) {
                  return {
                    ...Map<String, dynamic>.from(msg),
                    ...updatedMessage,
                  };
                }

                return msg;
              }).toList();
            });
          },
        )
        .subscribe();
  }

  Future<void> loadMessages() async {
    if (roomId == null) return;

    try {
      await ChatService.markMessagesAsRead(
        roomId: roomId!,
        userId: widget.currentUserId,
      );

      final data = await ChatService.getMessagesByRoom(roomId!);

      if (!mounted) return;

      if (data.isNotEmpty) {
        _lastMessageId = data.last["id"] is int
            ? data.last["id"]
            : int.tryParse(data.last["id"].toString());
      }

      _localMessageIds.clear();
      setState(() => messages = data);
    } catch (e) {
      debugPrint("Gagal mengambil pesan: $e");
    }
  }

  Future<void> loadNewMessages() async {
    if (roomId == null) return;

    try {
      await ChatService.markMessagesAsRead(
        roomId: roomId!,
        userId: widget.currentUserId,
      );

      final newData = await ChatService.getNewMessages(
        roomId: roomId!,
        afterId: _lastMessageId,
      );

      if (!mounted || newData.isEmpty) return;

      // Filter pesan yang sudah di-append secara lokal — cegah duplikasi
      final filtered = newData.where((msg) {
        final id = msg["id"] is int
            ? msg["id"]
            : int.tryParse(msg["id"].toString());
        return id != null && !_localMessageIds.contains(id);
      }).toList();

      if (filtered.isEmpty) return;

      _lastMessageId = newData.last["id"] is int
          ? newData.last["id"]
          : int.tryParse(newData.last["id"].toString());

      _localMessageIds.clear();

      setState(() => messages = [...messages, ...filtered]);
    } catch (e) {
      debugPrint("Gagal mengambil pesan baru: $e");
    }
  }

  Future<void> sendMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty || roomId == null || isSending) return;

    setState(() => isSending = true);

    final int? refId = shouldSendReference ? widget.referenceLaporanId : null;
    messageController.clear();

    try {
      final sentMsg = await ChatService.sendMessage(
        roomId: roomId!,
        senderId: widget.currentUserId,
        message: text,
        referenceLaporanId: refId,
      );

      shouldSendReference = false;

      if (mounted && sentMsg != null) {
        final id = sentMsg["id"] is int
            ? sentMsg["id"]
            : int.tryParse(sentMsg["id"].toString());

        if (id != null) {
          _localMessageIds.add(id);
          _lastMessageId = id;
        }

        setState(() => messages = [...messages, sentMsg]);
      }

      scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      _showSnackBar("Gagal mengirim pesan: $e");
    } finally {
      if (mounted) setState(() => isSending = false);
    }
  }

  void scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 250), () {
      if (!scrollController.hasClients) return;
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  String formatJam(dynamic rawDate) {
    if (rawDate == null || rawDate.toString().isEmpty) return "";
    try {
      final date = DateTime.parse(rawDate.toString()).toLocal();
      return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return "";
    }
  }

  String formatStatus(String? status) {
    switch (status) {
      case "laporan_terkirim":                return "Laporan Terkirim";
      case "telah_dibaca":
      case "laporan_telah_dibaca":            return "Telah Dibaca";
      case "dalam_proses_tindak_lanjut":      return "Dalam Proses";
      case "laporan_selesai_ditindaklanjuti": return "Selesai";
      default:                                return status ?? "-";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: secondaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: dominantColor),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.currentUserId == widget.adminId
                  ? "Chat Pelapor"
                  : "Chat Admin",
              style: const TextStyle(
                color: dominantColor,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              widget.currentUserId == widget.adminId
                  ? "Admin WadulGuse"
                  : "WadulGuse",
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: secondaryColor),
            )
          : Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    color: secondaryColor,
                    onRefresh: loadMessages,
                    child: _ChatList(
                      messages: messages,
                      currentUserId: widget.currentUserId,
                      scrollController: scrollController,
                      formatJam: formatJam,
                      formatStatus: formatStatus,
                    ),
                  ),
                ),
                _InputBar(
                  controller: messageController,
                  isSending: isSending,
                  onSend: sendMessage,
                ),
              ],
            ),
    );
  }
}

// ─── Chat List ────────────────────────────────────────────────────────────────

class _ChatList extends StatelessWidget {
  final List<dynamic> messages;
  final int currentUserId;
  final ScrollController scrollController;
  final String Function(dynamic) formatJam;
  final String Function(String?) formatStatus;

  const _ChatList({
    required this.messages,
    required this.currentUserId,
    required this.scrollController,
    required this.formatJam,
    required this.formatStatus,
  });

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.chat_bubble_outline_rounded,
                size: 60,
                color: _ChatRoomPageState.secondaryColor35,
              ),
              SizedBox(height: 14),
              Text(
                "Belum ada pesan",
                style: TextStyle(
                  color: _ChatRoomPageState.secondaryColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 6),
              Text(
                "Kirim pesan pertama untuk memulai chat.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _ChatRoomPageState.secondaryColor60,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final msg = messages[index];
        return RepaintBoundary(
          key: ValueKey(msg["id"]),
          child: _MessageBubble(
            msg: msg,
            currentUserId: currentUserId,
            formatJam: formatJam,
            formatStatus: formatStatus,
          ),
        );
      },
    );
  }
}

// ─── Message Bubble ───────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final dynamic msg;
  final int currentUserId;
  final String Function(dynamic) formatJam;
  final String Function(String?) formatStatus;

  const _MessageBubble({
    super.key,
    required this.msg,
    required this.currentUserId,
    required this.formatJam,
    required this.formatStatus,
  });

  @override
  Widget build(BuildContext context) {
    final int senderId = msg["sender_id"] is int
        ? msg["sender_id"]
        : int.tryParse(msg["sender_id"].toString()) ?? 0;

    final bool isMe   = senderId == currentUserId;
    final bool isRead = msg["is_read"] == true;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe
              ? _ChatRoomPageState.secondaryColor
              : _ChatRoomPageState.cardBg,
          borderRadius: BorderRadius.only(
            topLeft:     const Radius.circular(18),
            topRight:    const Radius.circular(18),
            bottomLeft:  Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
          boxShadow: const [
            BoxShadow(
              color:     _ChatRoomPageState.secondaryColor8,
              blurRadius: 8,
              offset:    Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            _ReferenceCard(msg: msg, formatStatus: formatStatus),
            Text(
              msg["message"]?.toString() ?? "",
              style: TextStyle(
                color: isMe ? Colors.white : _ChatRoomPageState.secondaryColor,
                fontSize: 14,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 5),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment:
                  isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: [
                Text(
                  formatJam(msg["created_at"]),
                  style: TextStyle(
                    color: isMe
                        ? _ChatRoomPageState.white65
                        : _ChatRoomPageState.secondaryColor45,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 5),
                  Icon(
                    isRead ? Icons.done_all_rounded : Icons.done_rounded,
                    size: 14,
                    color: isRead
                        ? Colors.lightBlueAccent
                        : _ChatRoomPageState.white65,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Reference Card ───────────────────────────────────────────────────────────

class _ReferenceCard extends StatelessWidget {
  final dynamic msg;
  final String Function(String?) formatStatus;

  const _ReferenceCard({required this.msg, required this.formatStatus});

  static const Widget _empty = SizedBox.shrink();

  static const Widget _placeholder = SizedBox(
    width: 52,
    height: 52,
    child: ColoredBox(
      color: _ChatRoomPageState.dominantColor50,
      child: Icon(
        Icons.report_rounded,
        color: _ChatRoomPageState.secondaryColor,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final laporanId = msg["laporan_id"];
    if (laporanId == null) return _empty;

    final judul    = msg["laporan_judul"];
    final deskripsi = msg["laporan_deskripsi"];
    final media    = msg["laporan_media"];
    final status   = msg["laporan_status"];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: const BoxDecoration(
        color: _ChatRoomPageState.bgLight,
        borderRadius: BorderRadius.all(Radius.circular(14)),
        border: Border.fromBorderSide(
          BorderSide(color: _ChatRoomPageState.dominantColor80),
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(10)),
            child: media != null && media.toString().isNotEmpty
                ? Image.network(
                    media.toString(),
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholder,
                  )
                : _placeholder,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  judul?.toString() ?? "Laporan",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ChatRoomPageState.secondaryColor,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  deskripsi?.toString() ?? "-",
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ChatRoomPageState.secondaryColor65,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  formatStatus(status?.toString()),
                  style: const TextStyle(
                    color: _ChatRoomPageState.accentColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
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

// ─── Input Bar ────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  const _InputBar({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        decoration: const BoxDecoration(
          color: _ChatRoomPageState.cardBg,
          boxShadow: [
            BoxShadow(
              color:     _ChatRoomPageState.secondaryColor10,
              blurRadius: 10,
              offset:    Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: "Tulis pesan...",
                  hintStyle: const TextStyle(
                    color: _ChatRoomPageState.secondaryColor45,
                  ),
                  filled: true,
                  fillColor: _ChatRoomPageState.bgLight,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            _SendButton(isSending: isSending, onSend: onSend),
          ],
        ),
      ),
    );
  }
}

// ─── Send Button ──────────────────────────────────────────────────────────────

class _SendButton extends StatelessWidget {
  final bool isSending;
  final VoidCallback onSend;

  const _SendButton({required this.isSending, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isSending ? null : onSend,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: isSending
              ? const Color(0x66273E47)
              : _ChatRoomPageState.accentColor,
          shape: BoxShape.circle,
        ),
        child: isSending
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(
                Icons.send_rounded,
                color: _ChatRoomPageState.secondaryColor,
                size: 22,
              ),
      ),
    );
  }
}