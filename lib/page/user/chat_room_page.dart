import 'package:flutter/material.dart';
import '../../service/chatService.dart';

class ChatRoomPage extends StatefulWidget {
  final int userId;
  final int adminId;
  final int? referenceLaporanId;

  const ChatRoomPage({
    super.key,
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

  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  bool isLoading = true;
  bool isSending = false;

  int? roomId;
  List<dynamic> messages = [];

  @override
  void initState() {
    super.initState();
    initChat();
  }

  @override
  void dispose() {
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

      roomId = room["id"];

      await loadMessages();

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }

      scrollToBottom();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal membuka chat: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> loadMessages() async {
    if (roomId == null) return;

    try {
      final data = await ChatService.getMessagesByRoom(roomId!);

      if (!mounted) return;

      setState(() {
        messages = data;
      });
    } catch (e) {
      debugPrint("Gagal mengambil pesan: $e");
    }
  }

  Future<void> sendMessage() async {
    final text = messageController.text.trim();

    if (text.isEmpty || roomId == null || isSending) return;

    setState(() {
      isSending = true;
    });

    try {
      await ChatService.sendMessage(
        roomId: roomId!,
        senderId: widget.userId,
        message: text,
        referenceLaporanId: messages.isEmpty ? widget.referenceLaporanId : null,
      );

      messageController.clear();

      await loadMessages();

      scrollToBottom();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal mengirim pesan: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSending = false;
        });
      }
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

  String formatStatus(String? status) {
    switch (status) {
      case "laporan_terkirim":
        return "Laporan Terkirim";
      case "telah_dibaca":
      case "laporan_telah_dibaca":
        return "Telah Dibaca";
      case "dalam_proses_tindak_lanjut":
        return "Dalam Proses";
      case "laporan_selesai_ditindaklanjuti":
        return "Selesai";
      default:
        return status ?? "-";
    }
  }

  Widget referenceCard(dynamic msg) {
    final laporanId = msg["laporan_id"];
    final judul = msg["laporan_judul"];
    final deskripsi = msg["laporan_deskripsi"];
    final media = msg["laporan_media"];
    final status = msg["laporan_status"];

    if (laporanId == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bgLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: dominantColor.withOpacity(0.8),
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: media != null && media.toString().isNotEmpty
                ? Image.network(
                    media,
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return laporanPlaceholder();
                    },
                  )
                : laporanPlaceholder(),
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
                    color: secondaryColor,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  deskripsi?.toString() ?? "-",
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: secondaryColor.withOpacity(0.65),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  formatStatus(status?.toString()),
                  style: const TextStyle(
                    color: accentColor,
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

  Widget laporanPlaceholder() {
    return Container(
      width: 52,
      height: 52,
      color: dominantColor.withOpacity(0.5),
      child: const Icon(
        Icons.report_rounded,
        color: secondaryColor,
      ),
    );
  }

  Widget messageBubble(dynamic msg) {
    final int senderId = msg["sender_id"] is int
        ? msg["sender_id"]
        : int.tryParse(msg["sender_id"].toString()) ?? 0;

    final bool isMe = senderId == widget.userId;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? secondaryColor : cardBg,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(
              color: secondaryColor.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            referenceCard(msg),
            Text(
              msg["message"]?.toString() ?? "",
              style: TextStyle(
                color: isMe ? Colors.white : secondaryColor,
                fontSize: 14,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget chatList() {
    if (messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.chat_bubble_outline_rounded,
                size: 60,
                color: secondaryColor.withOpacity(0.35),
              ),
              const SizedBox(height: 14),
              const Text(
                "Belum ada pesan",
                style: TextStyle(
                  color: secondaryColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Kirim pesan pertama untuk memulai chat dengan admin.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: secondaryColor.withOpacity(0.6),
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
        return messageBubble(messages[index]);
      },
    );
  }

  Widget inputBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        decoration: BoxDecoration(
          color: cardBg,
          boxShadow: [
            BoxShadow(
              color: secondaryColor.withOpacity(0.10),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: messageController,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: "Tulis pesan...",
                  hintStyle: TextStyle(
                    color: secondaryColor.withOpacity(0.45),
                  ),
                  filled: true,
                  fillColor: bgLight,
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
            GestureDetector(
              onTap: isSending ? null : sendMessage,
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: isSending ? secondaryColor.withOpacity(0.4) : accentColor,
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
                        color: secondaryColor,
                        size: 22,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: secondaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: dominantColor),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Chat Admin",
              style: TextStyle(
                color: dominantColor,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "WadulGuse",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: secondaryColor,
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    color: secondaryColor,
                    onRefresh: loadMessages,
                    child: chatList(),
                  ),
                ),
                inputBar(),
              ],
            ),
    );
  }
}